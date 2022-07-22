#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" -- ${1+"$@"}

# Copyright: 2015-2021 Paul Obermeier (obermeier@tcl3d.org)
# Distributed under BSD license.

namespace eval BawtHelp {

    proc GetProcShortName { procFullName } {
        return [lindex [split $procFullName ":"] end]
    }

    proc GetProcList {} {
        set procFullNameList [list]
        foreach ns { "BawtLog" "BawtZip" "BawtFile" "BawtBuild" "BawtMain" } {
            set procList [lsort -dictionary [info commands ::${ns}::*]]
            foreach procFullName $procList {
                set procShortName [GetProcShortName $procFullName]
                if { [string match "_*" $procShortName] } {
                    # Internal procedures start with "_". Do not add to table.
                    continue
                }
                lappend procFullNameList $procFullName
            }
        }
        return $procFullNameList
    }
}

namespace eval BawtLog {

    namespace export GetLogLevel SetLogLevel
    namespace export GetOutputLogDir GetLogFile
    namespace export Log GetLastLogMsg
    namespace export SetErrorMessage
    namespace export EnableLogFile
    namespace export SetLogTiming UseLogTiming
    namespace export GetWarningList GetErrorList ErrorAppend
    namespace export HaveFatalError
    namespace export WriteBuildLog
    namespace export GetBawtLogViewerProg
    namespace export StartBawtLogViewerProg

    variable sLogLevel       3
    variable sUseLogTiming   true
    variable sUseLogFile     true
    variable sErrorList      [list]
    variable sWarningList    [list]
    variable sHaveFatalError false

    proc GetLogLevel {} {
        variable sLogLevel

        return $sLogLevel
    }

    proc SetLogLevel { logLevel } {
        variable sLogLevel

        set sLogLevel $logLevel
        if { $logLevel > 0 } {
            EnableLogFile true
        } else {
            EnableLogFile false
        }
    }

    proc GetOutputLogDir {} {
        set dir [file join [GetOutputArchDir] "Logs"]
        return $dir
    }

    proc GetLogFile {} {
        return [file join [GetOutputLogDir] "_BawtBuild.log"]
    }

    proc SetLogTiming { onOff } {
        variable sUseLogTiming

        set sUseLogTiming $onOff
    }

    proc UseLogTiming {} {
        variable sUseLogTiming

        return $sUseLogTiming
    }

    proc EnableLogFile { { useLogFile true } } {
        variable sUseLogFile

        if { $useLogFile } {
            set sUseLogFile true
            set logFile [GetLogFile]
            CreateBackupFile $logFile false
            Log "LogFile $logFile" 0 false
        } else {
            set sUseLogFile false
        }
    }

    proc GetLastLogMsg {} {
        variable sLastLogMsg

        return $sLastLogMsg
    }

    proc Log { message { numSpaces 0 } { useTimeStr true } } {
        variable sUseLogFile
        variable sLastLogMsg
      
        set sLastLogMsg $message
        if { [expr [GetLogLevel] * 2] > $numSpaces } {
            if { $useTimeStr && [UseLogTiming] } {
                set timeStr [clock format [clock seconds] -format "%H:%M:%S"]
            } else {
                set timeStr [string repeat " " 8]
            }
            set logMsg ""
            if { $message ne "" } {
                append logMsg $timeStr
                if { $useTimeStr } {
                    append logMsg " > "
                } else {
                    append logMsg "   "
                }
                if { $numSpaces > 0 } {
                    append logMsg [string repeat " " $numSpaces]
                }
                append logMsg $message
            }

            puts $logMsg
            flush stdout

            if { $sUseLogFile } {
                if { ! [file isdirectory [GetOutputLogDir]] } {
                    file mkdir [GetOutputLogDir]
                }
                set fp [open [GetLogFile] "a"]
                puts $fp $logMsg
                close $fp
            }
        }
    }

    proc SetErrorMessage { message } {
        set caller [info frame -2]
        set procName [lindex [dict get $caller cmd] 0]
        Log "Error in $procName: $message" 2
    }

    proc GetErrorList {} {
        variable sErrorList

        return $sErrorList
    }

    proc GetWarningList {} {
        variable sWarningList

        return $sWarningList
    }

    proc ErrorAppend { msg { errorType "Error" } } {
        variable sErrorList
        variable sWarningList

        if { $errorType eq "Warning" } {
            lappend sWarningList $msg
        } else {
            lappend sErrorList $msg
        }
        if { [GetLogLevel] > 0 } {
            Log "\n$errorType > $msg" 0 false
        } else {
            puts "\n$errorType > $msg"
            flush stdout
        }
        if { $errorType eq "FATAL" } {
            if { [ExitOnFatalError] } {
                PrintSummary
                exit 1
            }
            HaveFatalError true
        }
    }
    
    proc HaveFatalError { { onOff "" } } {
        variable sHaveFatalError

        if { $onOff eq "" } {
            return $sHaveFatalError
        } else {
            set sHaveFatalError $onOff
        }
    }

    proc WriteBuildLog { libName appendToFile logMsg } {
        if { [GetLogLevel] > 0 } {
            set logFile [file join [GetOutputLogDir] [format "%s.log" $libName]]
            if { $appendToFile } {
                set mode "a"
            } else {
                set mode "w"
                CreateBackupFile $logFile false
            }
            set fp [open $logFile $mode]
            puts $fp $logMsg
            close $fp
        }
    }

    proc GetBawtLogViewerProg {} {
        set progName "BawtLogViewer[GetExeSuffix]"
        set logPath [file join [GetBootstrapDir] $progName]
        if { [file exists $logPath] } {
            return $logPath
        }
        set logCmd [auto_execok $progName]
        if { $logCmd eq "" } {
            ErrorAppend "Can not find $progName" "Warning"
        }
        return $logCmd
    }

    proc StartBawtLogViewerProg { logFile } {
        set logProg [GetBawtLogViewerProg]
        if { $logProg eq "" } {
            return
        }
        eval exec $logProg --nosaveonexit $logFile &
    }
}

namespace eval BawtZip {

    namespace export Get7ZipDistDir
    namespace export Get7ZipProg
    namespace export GetZipDistDir
    namespace export GetZipProg
    namespace export Unzip
    namespace export TarGzip
    namespace export Bootstrap

    # Code for _Vfs* Zip procedures taken from http://wiki.tcl-lang.org/36689
    proc _VfsUnzip { zname to } {
        set zfile [file normalize ${zname}]
        if { ! [file readable ${zfile}] } {
            ErrorAppend "Cannot read Zip file $zname" "FATAL"
        }
        
        if { ![file isdirectory ${to}] } {
            file mkdir ${to}
        }
        
        set items [_VfsZipStat ${zname}]
        
        foreach item [dict keys ${items}] {
            set target [file join ${to} ${item}]
            set type [dict get ${items} ${item} type]
            if { ${type} eq "directory" } {
                file mkdir ${target}
            } else {
                _VfsZipCopy ${zname} ${item} ${to}
            }
        }
    }

    proc _VfsZipCopy { zname path to } {
        set zmount [file normalize ${zname}]
        set from [file join ${zmount} ${path}]
        set to [file normalize [file join ${to} ${path}]]
        file mkdir [file dirname ${to}]
        set zid [vfs::zip::Mount ${zmount} ${zmount}]
        file copy ${from} ${to}
        set sdict [::vfs::zip::stat ${zid} ${path}]
        set mode [dict get ${sdict} mode]
        set mtime [dict get ${sdict} mtime]
        set atime [dict get ${sdict} atime]
        if { $::tcl_platform(platform) eq "unix" } {
            file attributes ${to} -permissions ${mode}
        }
        file mtime ${to} ${mtime}
        file atime ${to} ${atime}
        ::vfs::zip::Unmount ${zid} ${zmount}
    }

    proc _VfsZipStat { zname } {
        set zfile [file normalize ${zname}]
        set fd [::zip::open ${zfile}]
        set items [dict create]
        foreach item [lsort [array names ::zip::$fd.toc]] {
            ::zip::stat ${fd} ${item} stat
            if { $stat(name) ne "" && $stat(ctime) > 0 } {
                set vdict [dict create {*}[array get stat]]
                set name $stat(name)
                dict unset vdict name
                if { [string index ${name} end] eq "/" } {
                    dict set vdict type directory
                    set name [string trimright ${name} "/"]
                }
                dict set items ${name} ${vdict}
            }
        }
        ::zip::_close ${fd}
        return ${items}
    }

    proc Get7ZipDistDir {} {
        return [file join [GetOutputDevDir] "opt" "7-Zip"]
    }

    proc GetZipDistDir {} {
        return [Get7ZipDistDir]
    }

    proc Get7ZipProg { { exitOnError true } } {
        set progName "7z[GetExeSuffix]"
        set zipCmd [auto_execok $progName]
        if { [IsWindows] } {
            if { $zipCmd eq "" } {
                set bawtZipProg [file join [Get7ZipDistDir] $progName]
                if { [file exists $bawtZipProg] } {
                    set zipCmd $bawtZipProg
                }
            }
        } else {
            if { $zipCmd eq "" } {
                set zipCmd [auto_execok "7zr"]
                if { $zipCmd eq "" } {
                    set bawtZipProg [file join [Get7ZipDistDir] "7z"]
                    if { [file exists $bawtZipProg] } {
                        set zipCmd $bawtZipProg
                    }
                }
            }
        }
        if { $zipCmd eq "" && $exitOnError } {
            ErrorAppend "Can not find 7-Zip program" "FATAL"
        }
        return $zipCmd
    }

    proc GetZipProg { { exitOnError true } } {
        set progName "zip[GetExeSuffix]"
        set zipCmd [auto_execok $progName]
        if { $zipCmd eq "" } {
            set bawtZipProg [file join [GetZipDistDir] $progName]
            if { [file exists $bawtZipProg] } {
                set zipCmd $bawtZipProg
            }
        }
        if { $zipCmd eq "" && $exitOnError } {
            ErrorAppend "Can not find zip program" "FATAL"
        }
        return $zipCmd
    }

    proc Unzip { zipFile dir { zipTool "7Zip" } } {
        if { $zipTool eq "7Zip" } {
            set zipProg [Get7ZipProg]
            exec -ignorestderr {*}$zipProg x $zipFile -y -bd -o[file nativename $dir]
        } else {
            package require vfs::zip
            _VfsUnzip $zipFile $dir
        }
    }

    proc TarGzip { tarFile dir } {
        Log "TarGzip" 2
        Log "Source directory: $dir"     4 false
        Log "Tar file        : $tarFile" 4 false
        set rootDir [file dirname $dir]
        set cwd [pwd]
        cd $rootDir
        exec tar czf $tarFile [file tail $dir]
        cd $cwd
    }

    # Bootstrapping needed for Windows and Darwin.
    # Windows needs 7-Zip and the MSys/MinGW package.
    # Darwin needs 7-Zip.
    proc Bootstrap {} {

    proc Downloadgcc { fileName } {
        set curlProg [GetCurlProg]
        set sourceFileUrl [format "%s/%s/%s" [GetBawtUrl] Bootstrap-Windows $fileName]
        set targetFile [file join [GetBootstrapDir] $fileName]
        Log "Source file: $sourceFileUrl" 4 false
        Log "Target file: $targetFile"    4 false
        set cmd "$curlProg -L $sourceFileUrl -o $targetFile"
        set result [eval exec "[auto_execok $curlProg ] -L -s $sourceFileUrl -o $targetFile" ]
        if { [string match -nocase "*404 Not Found*" $result] } {
            ErrorAppend "File $sourceFileUrl not existent." $errorType
            return
   		}
	}
        Log "Bootstrap"

        # First check, if bootstrap tool 7-Zip is either available on the system
        # or is in the Bootstrap directory as compressed file.
        # Note:
        # The 7-Zip distribution must be compressed with standard ZIP, so that
        # it can be extracted with the vfs::zip package contained in the tclkit. 
        # All other tools and libraries are compressed in 7-Zip format because of
        # better compression rates (Example: MSys/MinGW is 2 times smaller with 7z).
        set zipProg [Get7ZipProg false]
        set haveZipProg [expr { $zipProg ne "" ? true : false }]
        if { $haveZipProg } {
            Log "7-Zip available: $zipProg" 2 false
        } else {
            set zipFile [file join [GetBootstrapDir] "7-Zip.zip"]
            if { ! [file exists $zipFile] } {
                ErrorAppend "Can not find 7-Zip program" "FATAL"
            }
            Log "Extract 7-Zip" 2 false
            Log "Source file     : $zipFile"         4 false
            Log "Target directory: [Get7ZipDistDir]" 4 false
            Unzip $zipFile [file dirname [Get7ZipDistDir]] "vfs"
            SetFilePermissions [file join [Get7ZipDistDir] "7z"] "u+rwx"
        }

        # Tcl 8.7 needs the zip command line utility. 
        # Check, if it is either available on the system or is in
        # the Bootstrap directory as compressed file.
        set zipProg [GetZipProg false]
        set haveZipProg [expr { $zipProg ne "" ? true : false }]
        if { $haveZipProg } {
            Log "zip available: $zipProg" 2 false
        } else {
            set zipFile [file join [GetBootstrapDir] "zip.zip"]
            if { [file exists $zipFile] } {
                Log "Extract zip" 2 false
                Log "Source file     : $zipFile" 4 false
                Log "Target directory: [GetZipDistDir]"  4 false
                Unzip $zipFile [GetZipDistDir] "vfs"
                SetFilePermissions [file join [GetZipDistDir] "zip"] "u+rwx"
            }
        }

        # Now check, if bootstrap tool MSys/MinGW is already extracted in the correct
        # architecture and gcc version.
        # Note:
        # This step is only needed for Windows, as on Unix systems we assume a development
        # package to be installed, ex. XCode for Mac, C/C++ development package for Linux.
        if { [IsWindows] } {
		set gccname [ GetGccWinPack ]
		if { ![ file exists [file join [GetBootstrapDir] $gccname]] } {
                Log "Downloading MSys/MinGW for Windows" 2 false
		Downloadgcc $gccname
		} else {
                Log "MSys/MinGW for Windows found" 2 false
		}
            set msysDistDir [file join [GetOutputToolsDir] [GetMingwDir]]
            if { ! [file isdirectory $msysDistDir] } {
                set toolList [lsort [glob -nocomplain [GetBootstrapDir]/gcc*]]
                set haveMSys false
                foreach zipFile $toolList {
                    if { [file rootname [file tail $zipFile]] eq [GetMingwDir] } {
                        set fileExt [string tolower [file extension $zipFile]]
                        if { $fileExt eq ".7z" || $fileExt eq ".zip" } {
                            Log "Extract MSys/MinGW" 2 false
                            Log "Source file     : $zipFile"     4 false
                            Log "Target directory: $msysDistDir" 4 false
                            if { ! [file isdirectory [GetOutputToolsDir]] } {
                                file mkdir [GetOutputToolsDir]
                            }
                            Unzip $zipFile [GetOutputToolsDir]

                            # Adjust MinGw/MSys pathes in the /etc/fstab file.
                            if { [HaveMSys2] } {
                                set fstabFile [file join [GetMSysDir 2] "etc" "fstab"]
                                Log "Adjust MSYS2 fstab file $fstabFile" 4 false
                                set fp [open $fstabFile "a"]
                                fconfigure $fp -translation "lf"
                                puts $fp "[file join $msysDistDir [GetMingwSubDir]] /mingw"
                                close $fp
                            }
                            set fstabFile [file join [GetMSysDir 1] "etc" "fstab"]
                            Log "Adjust MSYS1 fstab file $fstabFile" 4 false
                            set fp [open $fstabFile "w"]
                            fconfigure $fp -translation "lf"
                            puts $fp "# Win32_Path    Mount_Point"
                            puts $fp "[file join $msysDistDir [GetMingwSubDir]] /mingw"
                            close $fp

                            if { [HaveMSys2] } {
                                # Add /mingw to PATH.
                                set profileFile [file join [GetMSysDir 2] "etc" "profile"]
                                Log "Adjust MSYS2 profile file $profileFile" 4 false
                                set fp [open $profileFile "a"]
                                fconfigure $fp -translation "lf"
                                puts $fp "export PATH=\"/mingw/bin:\$PATH\""
                                close $fp
                            }
                            # Comment out "cd $HOME" in the /etc/profile file.
                            set profileFile [file join [GetMSysDir 1] "etc" "profile"]
                            Log "Adjust MSYS1 profile file $profileFile" 4 false
                            ReplaceLine $profileFile "cd \"\$HOME\"" ""
                            set haveMSys true
                        }
                    }
                }
                if { ! $haveMSys } {
                    ErrorAppend "Can not find MSys/MinGW [GetMingwDir]" "FATAL"
                }
            }
            if { [file isdirectory $msysDistDir] } {
                Log "MinGW available: $msysDistDir"     2 false
                Log "MSys available:  [GetMSysConsole]" 2 false
            }
        }
    }
}

namespace eval BawtFile {

    namespace export SetFilePermissions
    namespace export GetCurlProg GetMd5Prog
    namespace export CreateBackupFile
    namespace export DownloadFile
    namespace export GetMSysDir GetMSysBinDir
    namespace export SetMSysVersion
    namespace export GetMSysConsole
    namespace export MSysPath HaveMSys2 UseMSys2
    namespace export CheckMatchList
    namespace export GetDirList
    namespace export StripRecursive
    namespace export StripLibraries
    namespace export CopyRecursive
    namespace export DirCopy
    namespace export DirDelete
    namespace export DirCreate
    namespace export DirTouch
    namespace export SingleFileCopy
    namespace export MultiFileCopy
    namespace export LibFileCopy
    namespace export CopySysIncludeFiles
    namespace export FileRename
    namespace export FindFile
    namespace export AddToFile WriteToFile
    namespace export ReplaceKeywords ReplaceLine
    namespace export ReplaceKeywordsRecursive

    proc SetFilePermissions { fileName permissions { recursiveFlag false } } {
        if { [IsUnix] } {
            if { $recursiveFlag } {
                exec chmod -R $permissions $fileName
            } else {
                exec chmod $permissions $fileName
            }
        }
    }

    proc SetMSysVersion { msysVersion } {
        variable sMSysVersion

        set sMSysVersion $msysVersion
    }

    proc UseMSys2 {} {
        variable sMSysVersion

        set retVal false

        if { [info exists sMSysVersion] } {
            if { $sMSysVersion == 2 && ! [HaveMSys2] } {
                ErrorAppend "Requested MSYS version 2 is not available." "FATAL"
            }
            if { $sMSysVersion == 2 } {
                set retVal true
            }
        } else {
            if { [HaveMSys2] } {
                set retVal true
            }
        }
        return $retVal
    }

    proc HaveMSys2 {} {
        set dir [file join [GetOutputToolsDir] [GetMingwDir] "msys32"]
        if { [file isdirectory $dir] } {
            return true
        } else {
            return false
        }
    }

    proc GetMSysDir { { msysVersion -1 } } {
        set msys1Dir [file join [GetOutputToolsDir] [GetMingwDir] "msys"]
        set msys2Dir [file join [GetOutputToolsDir] [GetMingwDir] "msys32"]
        if { $msysVersion == 1 } {
            return $msys1Dir
        } elseif { $msysVersion == 2 } {
            return $msys2Dir
        } else {
            if { [UseMSys2] } {
                return $msys2Dir
            } else {
                return $msys1Dir
            }
        }
    }
  
    proc GetMSysBinDir {} {
        if { [UseMSys2] } {
            return [file join [GetMSysDir] "usr" "bin"]
        } else {
            return [file join [GetMSysDir] "bin"]
        }
    }

    proc GetMSysConsole {} {
        if { [UseMSys2] } {
            set msys [file join [GetMSysDir] "mingw32.exe"]
            #set msys [file join [GetMSysDir] "mingw[GetBits].exe"]
        } else {
            set msys [file join [GetMSysDir] "msys.bat"]
        }
        return $msys
    }

    proc GetCurlProg { { exitOnError true } } {
        set progName "curl[GetExeSuffix]"
        set curlCmd [auto_execok $progName]
        if { $curlCmd eq "" } {
            if { [IsWindows] } {
                set curlPath [file join [GetMSysBinDir] $progName]
                if { [file exists $curlPath] } {
                    return $curlPath
                }
            }
        }
        if { $curlCmd eq "" && $exitOnError } {
            ErrorAppend "Can not find curl program" "FATAL"
        }
        return $curlCmd
    }

    proc GetMd5Prog { { exitOnError true } } {
        set progName "md5sum[GetExeSuffix]"
        if { [IsDarwin] } {
            set progName "md5"
        }
        set md5Cmd [auto_execok $progName]
        if { $md5Cmd eq "" } {
            if { [IsWindows] } {
                set md5Path [file join [GetMSysBinDir] $progName]
                if { [file exists $md5Path] } {
                    return $md5Path
                }
            }
        }
        if { $md5Cmd eq "" && $exitOnError } {
            ErrorAppend "Can not find md5sum/md5 program" "FATAL"
        }
        return $md5Cmd
    }

    proc CreateBackupFile { fileName { useLog true } } {
        set backupFile [format "%s.bak" $fileName]
        if { [file exists $fileName] } {
            if { $useLog } {
                Log "Backup file: $backupFile" 4 false
            }
            file delete -force $backupFile
            file rename $fileName $backupFile
        }
    }

    proc _CheckMd5Hash { libName fileName { errorType "FATAL" } } {
        set md5Prog [GetMd5Prog]
        set hashKeyRepo [GetHashKey $libName [file tail $fileName]]
        if { [IsDarwin] } {
            set hashKeyLine [eval exec $md5Prog -q $fileName]
        } else {
            set hashKeyLine [eval exec $md5Prog $fileName]
        }
        set hashKeyFile [string trim [lindex [split $hashKeyLine] 0]]

        if { $hashKeyRepo ne $hashKeyFile } {
            ErrorAppend "Hash keys of file $fileName differ." $errorType
        }
        Log "Hash key   : $hashKeyFile"  4 false
    }

    proc DownloadFile { libName subDir fileName outFile { errorType "FATAL" } } {
        set curlProg [GetCurlProg]
        set sourceFileUrl [format "%s/%s/%s" [GetBawtUrl] $subDir $fileName]
        set targetFile    [MSysPath $outFile]
        if { ! [file isdirectory [file dirname $outFile]] } {
            file mkdir [file dirname $outFile]
        }

        Log "DownloadFile" 2
        Log "Source file: $sourceFileUrl" 4 false
        Log "Target file: $targetFile"    4 false

        CreateBackupFile $outFile

        set cmd "$curlProg -I $sourceFileUrl"
        set result [MSysRun $libName "DownloadFile" "" "$cmd"]
        if { [string match -nocase "*404 Not Found*" $result] } {
            ErrorAppend "File $sourceFileUrl not existent." $errorType
            return
        }

        set cmd "$curlProg -L -s -o $targetFile $sourceFileUrl"
        MSysRun $libName "DownloadFile" "" "$cmd"

        if { $errorType eq "FATAL" } {
            _CheckMd5Hash $libName $outFile
        }
    }

    proc MSysPath { path } {
        if { [IsWindows] } {
            # Convert C:/Dev and C:\Dev to /C/Dev and /C/Dev
            if { [string first "/" $path] == 0 } {
                return $path
            } else {
                return [format "/%s" [string map { "\\" "/" ":" "" } $path]]
            }
        } else {
            return $path
        }
    }

    proc CheckMatchList { searchString matchList { ignCase false } } {
        # Compare a string against a list of glob-style patterns.
        #
        # searchString - String to be compared.
        # matchList    - List of glob-style patterns.
        # ignCase      - Ignore case when matching. 
        #
        # Return true, if the searchString matches a pattern in the matchList.
        # Otherwise return false.

        if { $ignCase } {
            set matchCmd "string match -nocase"
        } else {
            set matchCmd "string match"
        }
        foreach matchString $matchList {
            if { [eval $matchCmd {$matchString $searchString}] } {
                return true
            }
        }
        return false
    }

    proc GetDirList {dirName {showDirs 1} {showFiles 1} {showHiddenDirs 1} {showHiddenFiles 1} {dirPattern *} {filePattern *}} {
        set curDir [pwd]
        set catchVal [catch {cd $dirName}]
        if { $catchVal } {
            return [list]
        }

        set absDirList  [list]
        set relFileList [list]

        if { $showDirs } {
            set relDirList [glob -nocomplain -types d -- {*}$dirPattern]
            foreach dir $relDirList {
                if { [string index $dir 0] eq "~" } {
                    set dir [format "./%s" $dir]
                }
                set absName [file join $dirName $dir]
                lappend absDirList $absName
            }
            if { $showHiddenDirs } {
                set relHiddenDirList \
                    [glob -nocomplain -types {d hidden} -- {*}$dirPattern]
                foreach dir $relHiddenDirList {
                    if { $dir eq "." || $dir eq ".." } {
                        continue
                    }
                    set absName [file join $dirName $dir]
                    lappend absDirList $absName
                }
            }
        }
        if { $showFiles } {
            set relFileList [glob -nocomplain -types f -- {*}$filePattern]
            if { $showHiddenFiles } {
                set relHiddenFileList \
                    [glob -nocomplain -types {f hidden} -- {*}$filePattern]
                if { [llength $relHiddenFileList] != 0 } {
                    set relFileList [concat $relFileList $relHiddenFileList]
                }
            }
        }
        cd $curDir

        return [list $absDirList $relFileList]
    }

    proc StripRecursive { srcDir pattern } {
        set retVal [catch { cd $srcDir } ]
        if { $retVal } {
            ErrorAppend "Could not read directory \"$srcDir\"" "FATAL"
            return
        }
        set dirCont [GetDirList $srcDir 1 1  1 1]
        set dirList  [lindex $dirCont 0]
        set fileList [lindex $dirCont 1]
        foreach dir $dirList {
            set dirName [file tail $dir]
            set subSrcDir  [file join $srcDir  $dirName]
            StripRecursive $subSrcDir $pattern
        }
        foreach fileName $fileList {
            if { [string first "~" $fileName] == 0 } {
                # File starts with tilde.
                set fileName [format "./%s" $fileName]
            }
            set fileAbs [file join $srcDir $fileName]
            if { [CheckMatchList [file tail $fileAbs] $pattern false] } {
                set fileAbsMSys [MSysPath $fileAbs]
                set cmd "chmod u+rwx $fileAbsMSys ; "
                if { [IsDarwin] } {
                    append cmd "strip -x $fileAbsMSys"
                } else {
                    append cmd "strip $fileAbsMSys"
                }
                MSysRun "Strip" "Strip" "" "$cmd"
            }
        }
    }

    proc StripLibraries { { dir "" } } {
        if { ! [StripLibs] || [IsDebugBuild] } {
            return
        }
        set pattern [GetLibPattern]
        if { $dir eq "" } {
            set dir [GetOutputDistDir]
        }
        StripRecursive $dir $pattern
    }

    proc CopyRecursive { srcDir destDir keepFolders pattern ignDirPattern } {
        variable sCopyCount

        set retVal [catch { cd $srcDir } ]
        if { $retVal } {
            ErrorAppend "Could not read directory \"$srcDir\"" "FATAL"
            return
        }
        set dirCont [GetDirList $srcDir 1 1  1 1]
        set dirList  [lindex $dirCont 0]
        set fileList [lindex $dirCont 1]
        foreach dir $dirList {
            set dirName [file tail $dir]
            if { [CheckMatchList $dirName $ignDirPattern false] } {
                continue
            }
            set subSrcDir [file join $srcDir $dirName]
            if { $keepFolders } {
                set subDestDir [file join $destDir $dirName]
            } else {
                set subDestDir $destDir
            }
            CopyRecursive $subSrcDir $subDestDir $keepFolders $pattern $ignDirPattern
        }
        foreach fileName $fileList {
            if { [string first "~" $fileName] == 0 } {
                # File starts with tilde.
                set fileName [format "./%s" $fileName]
            }
            set fileAbs [file join $srcDir $fileName]
            if { [CheckMatchList [file tail $fileAbs] $pattern false] } {
                Log "Copy $fileAbs" 6 false
                if { ! [file isdirectory $destDir] } {
                    file mkdir $destDir
                }
                file copy -force $fileAbs $destDir
                incr sCopyCount
            }
        }
    }

    proc DirDelete { dir } {
        Log "DirDelete" 2 false
        Log "Directory: $dir" 4 false

        set count  0
        set retVal 1
        set maxTime [GetTimeout]
        while { $retVal != 0 && $count <= $maxTime } {
            set retVal [catch {file delete -force $dir} errMsg]
            if { $retVal == 0 } {
                break
            }
            Log "$errMsg  ... retrying" 6 false
            incr count 1000
            after 1000
        }
        if { $retVal != 0 } {
            ErrorAppend $errMsg "FATAL"
        }
    }

    proc DirCreate { dir } {
        if { [file isdirectory $dir] } {
            return
        }

        Log "DirCreate" 2 false
        Log "Directory: $dir" 4 false

        set count  0
        set retVal 1
        set maxTime [GetTimeout]
        while { $retVal != 0 && $count <= $maxTime } {
            set retVal [catch {file mkdir $dir} errMsg]
            if { $retVal == 0 } {
                break
            }
            Log "$errMsg  ... retrying" 6 false
            incr count 1000
            after 1000
        }
        if { $retVal != 0 } {
            ErrorAppend $errMsg "FATAL"
        }
    }

    proc DirTouch { dir } {
        if { ! [file isdirectory $dir] } {
            return
        }

        Log "DirTouch" 2 false
        Log "Directory: $dir" 4 false

        set count  0
        set retVal 1
        set maxTime [GetTimeout]
        while { $retVal != 0 && $count <= $maxTime } {
            set touchTime [clock seconds]
            set retVal [catch {file mtime $dir $touchTime} errMsg]
            if { $retVal == 0 } {
                break
            }
            Log "$errMsg  ... retrying" 6 false
            incr count 1000
            after 1000
        }
        if { $retVal != 0 } {
            ErrorAppend $errMsg "FATAL"
        }
    }

    proc DirCopy { sourceDir targetDir } {
        Log "DirCopy" 2
        Log "Source directory: $sourceDir" 4 false
        Log "Target directory: $targetDir" 4 false

        if { ! [file isdirectory [file dirname $targetDir]] } {
            file mkdir [file dirname $targetDir]
        }
        if { ! [file isdirectory $sourceDir] } {
            ErrorAppend "Directory $sourceDir does not exist." "FATAL"
        } else {
            file copy -force $sourceDir $targetDir
        }
    }

    proc SingleFileCopy { sourceFile targetDir { newName "" } } {
        Log "SingleFileCopy" 2
        Log "Source file     : $sourceFile" 4 false
        Log "Target directory: $targetDir"  4 false
        if { $newName ne "" } {
            Log "New name        : $newName"  4 false
        } else {
            set newName [file tail $sourceFile]
        }

        if { ! [file isdirectory $targetDir] } {
            file mkdir $targetDir
        }
        if { ! [file exists $sourceFile] } {
            ErrorAppend "File $sourceFile does not exist." "FATAL"
        } else {
            file copy -force $sourceFile [file join $targetDir $newName]
        }
    }

    proc MultiFileCopy { sourceDir targetDir { pattern "*" } { keepFolders false } { warnNoFilesCopied true } } {
        variable sCopyCount

        Log "MultiFileCopy" 2
        Log "Source directory: $sourceDir" 4 false
        Log "Target directory: $targetDir" 4 false
        Log "File pattern    : $pattern"   4 false

        set curDir [pwd]
        set sCopyCount 0
        CopyRecursive $sourceDir $targetDir $keepFolders $pattern ".svn"
        cd $curDir
        if { $warnNoFilesCopied && $sCopyCount == 0 } {
            ErrorAppend "MultiFileCopy: No files copied from $sourceDir." "Warning"
        } else {
            Log "Number of copied files: $sCopyCount" 4 false
        }
    }

    proc LibFileCopy { sourceDir targetDir { pattern "*" } { keepFolders false } } {
        Log "LibFileCopy" 2

        set sourceLibDir1 [file join $sourceDir "lib"]
        set sourceLibDir2 [file join $sourceDir "lib64"]
        set targetLibDir  [file join $targetDir "lib"]

        if { ! [file isdirectory $sourceLibDir1] && ! [file isdirectory $sourceLibDir2] } {
            set errMsg    "No source library directory available.\n"
            append errMsg "Neither \"$sourceLibDir1\" nor \"$sourceLibDir2\""
            ErrorAppend $errMsg "FATAL"
        }
        if { [file isdirectory $sourceLibDir1] } {
            MultiFileCopy $sourceLibDir1 $targetLibDir $pattern $keepFolders
        }
        if { [file isdirectory $sourceLibDir2] } {
            MultiFileCopy $sourceLibDir2 $targetLibDir $pattern $keepFolders
        }
    }

    proc CopySysIncludeFiles { libName targetDir } {
        # Need system libraries in VisualStudio format because of dependencies on other libraries,
        # which were compiled with MSys.
        if { [UseWinCompiler $libName "vs"] } {
            foreach includeFile [list "stdbool.h" "stdint.h" "inttypes.h"] {
                SingleFileCopy [file join [GetInputResourceDir] "VisualStudio" $includeFile] "$targetDir"
            }
        }
    }

    proc FileRename { source target } {
        Log "FileRename" 2
        Log "Source: $source" 4 false
        Log "Target: $target" 4 false

        if { [file normalize $source] eq [file normalize $target] } {
            ErrorAppend "Source and target are identical. No action." "Warning"
            return
        }

        file delete -force $target

        set count  0
        set retVal 1
        set maxTime [GetTimeout]
        while { $retVal != 0 && $count <= $maxTime } {
            set retVal [catch {file rename $source $target} errMsg]
            if { $retVal == 0 } {
                break
            }
            Log "$errMsg  ... retrying" 6 false
            incr count 1000
            after 1000
        }
        if { $retVal != 0 } {
            ErrorAppend $errMsg "FATAL"
        }
    }

    proc FindFile { dir filePattern { exitOnError true } } {
        set fullPath [file join $dir $filePattern]
        set fileList [glob -nocomplain $fullPath]
        if { [llength $fileList] == 0 } {
            if { $exitOnError } {
                ErrorAppend "No file matching $filePattern in directory $dir" "FATAL"
            } else {
                return ""
            }
        }
        if { [llength $fileList] > 1 } {
            ErrorAppend "More than 1 file matching $filePattern in directory $dir" "Warning"
        }
        return [file tail [lindex $fileList 0]]
    }

    proc AddToFile { fileName string { where "top" } } {
        Log "AddToFile" 2
        Log "File  : $fileName" 4 false
        Log "String: [string range $string 0 20] ..." 4 false

        set retVal [catch {open $fileName "r"} fp]
        if { $retVal != 0 } {
            ErrorAppend "AddToFile: Cannot read from file $fileName" "FATAL"
            return
        }
        set fileContent [read $fp]
        close $fp

        if { $where eq "top" } {
            set final $string
            append final $fileContent
        } else {
            set final $fileContent
            append final $string
        }

        set retVal [catch {open $fileName "w"} fp]
        if { $retVal != 0 } {
            ErrorAppend "AddToFile: Cannot write to file $fileName" "FATAL"
            return
        }
        puts $fp $final
        close $fp
    }

    proc WriteToFile { fileName string { mode "w" } } {
        set retVal [catch {open $fileName $mode} outFp]
        if { $retVal != 0 } {
            ErrorAppend "Cannot write to file $fileName" "FATAL"
        } else {
            puts -nonewline $outFp $string
            close $outFp
        }
    }

    proc _QuoteRegexpChars { str } {
        # Quote all regexp special chars: "^$*+.?()|[]\"

        regsub -all -- {\^|\$|\*|\+|\.|\?|\(|\)|\||\[|\]|\\} $str {\\&} tmpStr
        return $tmpStr
    }

    proc ReplaceKeywords { fileName replaceList } {
        Log "ReplaceKeywords" 2
        Log "File   : $fileName" 4 false

        set retVal [catch {open $fileName "r"} fp]
        if { $retVal != 0 } {
            ErrorAppend "ReplaceKeywords: Cannot read from file $fileName" "FATAL"
            return
        }
        set fileContent [read $fp]
        close $fp

        foreach { key val } $replaceList {
            Log "Replace: $key -> $val" 4 false
            set searchStr [_QuoteRegexpChars $key]
            set num [regsub -all -- $searchStr $fileContent $val fileContent]
            if { $num == 0 } {
                ErrorAppend "ReplaceKeywords \"$key\": No keywords replaced." "Warning"
            }
        }

        set retVal [catch {open $fileName "w"} fp]
        if { $retVal != 0 } {
            ErrorAppend "ReplaceKeywords: Cannot write to file $fileName" "FATAL"
            return
        }
        puts $fp $fileContent
        close $fp
    }

    proc ReplaceKeywordsRecursive { rootDir filePattern replaceList } {
        set retVal [catch { cd $rootDir } ]
        if { $retVal } {
            ErrorAppend "Could not read directory \"$rootDir\"" "FATAL"
            return
        }
        set dirCont [GetDirList $rootDir 1 1  1 1]
        set dirList  [lindex $dirCont 0]
        set fileList [lindex $dirCont 1]
        foreach dir $dirList {
            set dirName [file tail $dir]
            set subSrcDir  [file join $rootDir  $dirName]
            ReplaceKeywordsRecursive $subSrcDir $filePattern $replaceList
        }
        foreach fileName $fileList {
            if { [string first "~" $fileName] == 0 } {
                # File starts with tilde.
                set fileName [format "./%s" $fileName]
            }
            set fileAbs [file join $rootDir $fileName]
            if { [CheckMatchList [file tail $fileAbs] $filePattern false] } {
                ReplaceKeywords $fileAbs $replaceList
            }
        }
    }

    proc ReplaceLine { fileName searchLine replaceLine } {
        Log "ReplaceLine" 2
        Log "File   : $fileName"    4 false
        Log "Search : $searchLine"  4 false
        Log "Replace: $replaceLine" 4 false

        set retVal [catch {open $fileName "r"} fp]
        if { $retVal != 0 } {
            ErrorAppend "ReplaceLine: Cannot read from file $fileName" "FATAL"
            return
        }
        set fileContent [read $fp]
        close $fp

        set searchStr [_QuoteRegexpChars $searchLine]
        set num [regsub -all -- $searchStr $fileContent $replaceLine fileContent]
        Log "Number of replaced lines: $num" 4 false
        if { $num == 0 } {
            ErrorAppend "ReplaceLine \"$searchLine\": No lines replaced." "Warning"
        }

        set retVal [catch {open $fileName "w"} fp]
        if { $retVal != 0 } {
            ErrorAppend "ReplaceLine: Cannot write to file $fileName" "FATAL"
            return
        }
        puts $fp $fileContent
        close $fp
    }
}

namespace eval BawtBuild {

    namespace export GetValidSortModes
    namespace export MakeStarpack MakeStarpackTcl MakeStarpackTk
    namespace export AddCheckOption GetCheckOptions IsSimulationMode
    namespace export AddUserConfig GetUserConfig GetUserConfigValue GetUserCFlags
    namespace export UpdateLib SetLibUpdated AnyLibsUpdated LibNeedsUpdate GetLibUpdateCause
    namespace export CheckRecursiveDependencies UseRecursiveDependencies
    namespace export EnableStage EnableStages EnableAllStages
    namespace export DisableStage DisableStages DisableAllStages
    namespace export UseStage IsBuildStage GetUsedStages
    namespace export UseTclPkgVersion ExitOnFatalError
    namespace export SetBuildType GetBuildType GetValidBuildTypes
    namespace export SetCompilerVersion GetCompilerVersion
    namespace export SetCompilerVersions GetCompilerVersions
    namespace export GetValidCompilerVersions
    namespace export SetNumJobs GetNumJobs
    namespace export SetTimeout GetTimeout
    namespace export GetGccWinPack
    namespace export GetMingwVersion GetMingwGccVersion SetMingwGccVersion
    namespace export GetMingwDir GetMingwSubDir GetMingwIncludeDir
    namespace export GetMingwLib GetPthreadLib GetSehLib
    namespace export HaveYasmProg
    namespace export GetGendefProg GetSWIGDistDir
    namespace export GetCMakeDistDir GetCMakeProg GetCMakeMSysOption
    namespace export GetMSysCppOption
    namespace export GetInnoDistDir GetInnoProg
    namespace export GetVcvarsProg SetVcvarsProg
    namespace export GetVSRuntimeLibDir SetVSRuntimeLibDir
    namespace export GetVSEditions
    namespace export UseVisualStudio GetVisualStudioVersion
    namespace export GetMscVer
    namespace export GetGccCompilerVersion IsGccCompilerNewer
    namespace export GetMSysShell GetCmdShell
    namespace export IsReleaseBuild IsDebugBuild 
    namespace export GetDebugSuffix GetWinDebugSuffix
    namespace export SetArchitecture GetArchitecture GetValidArchitectures
    namespace export Is32Bit Is64Bit GetBits
    namespace export IsWindows IsLinux IsDarwin IsUnix
    namespace export GetMajor GetMinor GetPatch GetMajorMinor GetMajorMinorPatch
    namespace export VersionCompare
    namespace export GetPlatformName GetMsBuildPlatform
    namespace export GetExeSuffix GetBatchSuffix
    namespace export GetLibSuffix GetImportLibSuffix GetStaticLibSuffix GetLibPattern
    namespace export SetFinalizeFile GetFinalizeFile
    namespace export SetTclkitIconFile GetTclkitIconFile
    namespace export SetTclkitResourceFile GetTclkitResourceFile
    namespace export SetTclkitCompanyName GetTclkitCompanyName
    namespace export SetTclkitLegalCopyright GetTclkitLegalCopyright
    namespace export SetTclkitFileDescription GetTclkitFileDescription
    namespace export SetTclkitProductName GetTclkitProductName
    namespace export SetTclkitProductVersion GetTclkitProductVersion
    namespace export SetTclkitFileVersion GetTclkitFileVersion
    namespace export SetTclVersion GetTclVersion 
    namespace export SetTkVersion GetTkVersion 
    namespace export GetPythonVersion
    namespace export SetImgVersion GetImgVersion
    namespace export SetOsgVersion GetOsgVersion
    namespace export SetTclDir GetTclDir
    namespace export SetPythonDir GetPythonDir
    namespace export GetTclLibDir GetTclBinDir GetTclIncDir
    namespace export GetPythonLibDir GetPythonBinDir GetPythonIncDir
    namespace export GetDevTclDir GetDevTclLibDir GetDevTclBinDir GetDevTclIncDir
    namespace export GetDevPythonDir GetDevPythonLibDir GetDevPythonBinDir GetDevPythonIncDir
    namespace export GetTclLibName GetTkLibName
    namespace export GetTclStubLib GetTkStubLib
    namespace export GetTclshName GetTclshPath 
    namespace export GetWishName GetWishPath
    namespace export GetItclDir GetPngLibDir
    namespace export GetOutputArchDir GetOutputDevDir GetOutputTypeDir GetOutputBuildDir GetOutputInstDir 
    namespace export SetShortRootDir UseShortRootDir
    namespace export SetOutputDistDir GetOutputDistDir
    namespace export CreateDefaultDirs
    namespace export CleanLib
    namespace export BuildLib
    namespace export CMakeConfig CMakeBuild
    namespace export NMakeBuild
    namespace export MsBuild
    namespace export MSysConfig MSysRun MSysBuild
    namespace export TeaConfig
    namespace export NeedDll2Lib Dll2Lib
    namespace export DosRun

    variable sBuildStages
    array set sBuildStages {
        Check,all        false
        Clean,all        false
        Extract,all      false
        Configure,all    false
        Compile,all      false
        Distribute,all   false
        Finalize,all     false
        Update,all       false
        Touch,all        false
    }
    variable sStageOrder
    set sStageOrder [list Clean Extract Configure Compile Distribute Finalize Touch]

    variable sBuildOpts
    array set sBuildOpts {
        TclVersion               "8.6.12"
        ImgVersion               "1.4.13"
        OsgVersion               "3.6.5"
        TclDir                   "HammerDB"
        PythonDir                "opt/Python"
        DistDir                  ""
        Tclkit,IconFile          ""
        Tclkit,ResourceFile      ""
        Tclkit,CompanyName       ""
        Tclkit,LegalCopyright    ""
        Tclkit,FileDescription   ""
        Tclkit,ProductName       ""
        Tclkit,ProductVersion    ""
        Tclkit,FileVersion       ""
        FinalizeFile             ""
        BuildType                "NA"
        GccVersion               "8.1.0"
	GccWinPack 		 "gcc8.1.0_x86_64-w64-mingw32.7z"
        all,NumJobs              1
        Timeout                  30000          ; # Default timeout 30 seconds.
        UseTclPkgVersion         true
        ExitOnFatalError         true
        UseRecursiveDependencies true
        UseShortRootDir          false
    }

    proc GetValidSortModes {} {
        return [list "dependencies" "dictionary" "none"]
    }

    proc MakeStarpackTcl { appScript appName starpackName buildDir args } {
        _MakeStarpack "Tcl" $appScript $appName $starpackName $buildDir {*}$args
    }

    proc MakeStarpackTk { appScript appName starpackName buildDir args } {
        _MakeStarpack "Tk" $appScript $appName $starpackName $buildDir {*}$args
    }

    proc MakeStarpack { appScript appName starpackName buildDir args } {
        _MakeStarpack "Tk" $appScript $appName $starpackName $buildDir {*}$args
    }

    proc _MakeStarpack { type appScript appName starpackName buildDir args } {
        Log "MakeStarpack" 2
        if { ! [file isdirectory $buildDir] } {
            file mkdir $buildDir
        }

        set outPlatform "[GetPlatformName true][GetBits]"

        set tclBinDir [GetDevTclBinDir]
        set tclLibDir [GetDevTclLibDir]

        set runtimeTcl [file join $tclBinDir "tclkit-${outPlatform}-tcl[GetExeSuffix]"]
        set runtimeTk  [file join $tclBinDir "tclkit-${outPlatform}-tk[GetExeSuffix]"]
        set tclkit     [file join $buildDir  "tclkit-${outPlatform}-sh[GetExeSuffix]"]

        if { ! [file exists $runtimeTcl] } {
            ErrorAppend "MakeStarpack${type}: tclkit-tcl not found ($runtimeTcl)" "FATAL"
        }
        if { ! [file exists $runtimeTk] } {
            ErrorAppend "MakeStarpack${type}: tclkit-tk not found ($runtimeTk)" "FATAL"
        }
        if { ! [file exists $appScript] } {
            ErrorAppend "MakeStarpack${type}: Script not found ($appScript)" "FATAL"
        }

        set starpackExe       [file join $buildDir $starpackName]
        set starpackVfs       [format "%s.vfs" $appName]
        set starpackVfsDir    [file join $buildDir $starpackVfs]
        set starpackVfsLibDir [file join $starpackVfsDir "lib"]
        set starpackVfsRunDir [file join $starpackVfsDir "runtime"]

        Log "Output file: $starpackExe"  4 false

        file delete -force $starpackExe
        file copy $runtimeTcl $tclkit

        file mkdir $starpackVfsDir
        file mkdir $starpackVfsLibDir
        file mkdir $starpackVfsRunDir

        set cwd [pwd]
        cd $tclLibDir
        foreach pkg $args {
            if { [string trim $pkg] eq "" } {
                continue
            } elseif { [string first "--" $pkg] == 0 } {
                Log "Add option : $pkg" 4 false
                if { $pkg eq "--runtime-vs" } {
                    if { [GetVSRuntimeLibDir] ne "" } {
                        MultiFileCopy [GetVSRuntimeLibDir] $starpackVfsRunDir "vcruntime*.dll"
                    }
                } elseif { $pkg eq "--runtime-gcc" } {
                    SingleFileCopy [GetPthreadLib] $starpackVfsRunDir
                    SingleFileCopy [GetSehLib]     $starpackVfsRunDir
                }
            } elseif { [file isfile $pkg] } {
                Log "Add file   : $pkg" 4 false
                file copy $pkg $starpackVfsLibDir
            } else {
                Log "Add package: $pkg" 4 false
                if { ! [file isdirectory $pkg] } {
                    set tmpList [glob -nocomplain -types d -- "$pkg*"]
                    set dirList [list]
                    # Windows file names are not case sensitive, so we get double entries for
                    # ex. Img and imgtools. So check directory names with string match.
                    foreach dir $tmpList {
                        if { [string match "$pkg*" $dir] } {
                            lappend dirList $dir
                        }
                    }
                    if { [llength $dirList] == 0 } {
                        # Make this only a warning, so that packages needed / available only
                        # for a single platform (ex. Twapi) do not break the build.
                        ErrorAppend "MakeStarpack${type} $starpackName: Can not find Tcl package $pkg" "Warning"
                        continue
                    }
                    if { [llength $dirList] > 1 } {
                        # More than 1 package was found. This is typically due to adding a new version
                        # of a library and not using the "--noversion" command line option.
                        # Example: cawt2.4.6 and cawt2.4.7
                        # In such a case you should remove the old library versions from the build directory.
                        #
                        # There is one case however, where this is not a possible error: tcllib.
                        # There are tcllibc and tcllib1.19 directories, which are both needed.
                        if { [file tail $pkg] ne "tcllib" } {
                            ErrorAppend "MakeStarpack${type} $starpackName: Found more than 1 package with prefix [file tail ${pkg}]*:\n \
                                        [join $dirList "\n  "]" "Warning"
                        }
                        foreach pkg $dirList {
                            file copy $pkg [file join $starpackVfsLibDir [file tail $pkg]]
                        }
                        continue
                    }
                    set pkg [lindex $dirList 0]
                }
                file copy $pkg [file join $starpackVfsLibDir [file tail $pkg]]
            }
        }
        file copy $appScript $starpackVfsLibDir

        set mainFile [file join $starpackVfsDir "main.tcl"]

        append startupCode "package require starkit\n"
        if { $type eq "Tk" } {
            append startupCode "package require Tk\n"
        }
        append startupCode "starkit::startup\n"
        append startupCode "source \[file join \$starkit::topdir lib [file tail $appScript]\]\n"

        set retVal [catch {open $mainFile "w"} fp]
        if { $retVal != 0 } {
            ErrorAppend "MakeStarpack${type}: Cannot write to file $mainFile" "FATAL"
            return
        }
        puts $fp $startupCode
        close $fp

        if { [IsDarwin] } {
            set templateDir [file join [GetInputResourceDir] "Template.app"]
            file copy $templateDir $buildDir
        }

        set winInfo ""
        set macInfo [list]
        lappend macInfo "@EXECUTABLE@" "$starpackName"

        if { [GetTclkitCompanyName $appName] ne "" } {
            append  winInfo "CompanyName \"[GetTclkitCompanyName $appName]\"\n"
        }
        if { [GetTclkitLegalCopyright $appName] ne "" } {
            append  winInfo "LegalCopyright \"[GetTclkitLegalCopyright $appName]\"\n"
            lappend macInfo "@LEGALCOPYRIGHT@" "[GetTclkitLegalCopyright $appName]"
        }
        if { [GetTclkitFileDescription $appName] ne "" } {
            append  winInfo "FileDescription \"[GetTclkitFileDescription $appName]\"\n"
            lappend macInfo "@FILEDESCRIPTION@" "[GetTclkitFileDescription $appName]"
        }
        if { [GetTclkitProductName $appName] ne "" } {
            append  winInfo "ProductName \"[GetTclkitProductName $appName]\"\n"
            lappend macInfo "@PRODUCTNAME@" "[GetTclkitProductName $appName]"
        }
        if { [GetTclkitProductVersion $appName] ne "" } {
            append  winInfo "ProductVersion \"[GetTclkitProductVersion $appName]\"\n"
            lappend macInfo "@PRODUCTVERSION@" "[GetTclkitProductVersion $appName]"
        }
        if { [GetTclkitFileVersion $appName] ne "" } {
            append winInfo "FileVersion \"[GetTclkitFileVersion $appName]\"\n"
        }
        if { [GetTclkitIconFile $appName] ne "" } {
            lappend macInfo "@ICONFILE@" [file tail [GetTclkitIconFile $appName]]
        }


        if { [IsWindows] && $winInfo ne "" } {
            set infoFile [file join $starpackVfsDir "tclkit.inf"]
            set retVal [catch {open $infoFile "w"} fp]
            if { $retVal != 0 } {
                ErrorAppend "MakeStarpack${type}: Cannot write to file $infoFile" "FATAL"
                return
            }
            puts $fp $winInfo
            close $fp
        }

        cd $buildDir
        if { $type eq "Tcl" } {
            set runtime $runtimeTcl
        } else {
            set runtime $runtimeTk
        }
        exec $tclkit [file join $tclBinDir sdx.kit] wrap $appName -runtime $runtime
        if { $appName ne [file tail $starpackExe] } {
            file rename $appName $starpackExe
        }

        if { [IsDarwin] } {
            set appDir [file join $buildDir "${appName}.app"]
            Log "Output app : $appDir" 4
            if { [GetTclkitIconFile $appName] ne "" } {
                set iconFile [GetTclkitIconFile $appName]
                if { ! [file exists $iconFile] } {
                    set iconFile [file join [GetInputResourceDir] [file tail $iconFile]]
                    if { ! [file exists $iconFile] } {
                        ErrorAppend "MakeStarpack${type}: Can not find icon file [GetTclkitIconFile $appName]" "FATAL"
                    }
                }
                file copy $iconFile [file join $buildDir "Template.app" "Contents" "Resources"] 
            }
            set infoFile [file join $buildDir "Template.app" "Contents" "Info.plist"]
            ReplaceKeywords $infoFile $macInfo
            file copy $starpackExe [file join $buildDir "Template.app" "Contents" "MacOS"]
            file rename [file join $buildDir "Template.app"] [file join $buildDir "${appName}.app"]
        }

        if { [IsWindows] } {
            set starpackBatchName [format "%sBatch%s" [file rootname ${starpackName}] [file extension ${starpackName}]]
            set starpackBatchExe [file join $buildDir ${starpackBatchName}]
            Log "Batch starpack for Windows: $starpackBatchExe" 4
            set tkVersionNative [GetTkLibName [GetTkVersion]]
            set tkVersionUnix   [GetMajorMinor [GetTkVersion] "."]
            set tkDir [file join $starpackVfsLibDir "Tk"]
            file mkdir $tkDir
            SingleFileCopy [file join $tclBinDir ${tkVersionNative}.dll] $tkDir
            MultiFileCopy  [file join $tclLibDir tk${tkVersionUnix}] [file join $starpackVfsLibDir tk${tkVersionUnix}] "*" true
            ReplaceKeywords [file join $starpackVfsLibDir tk${tkVersionUnix} "pkgIndex.tcl"] [list ".. bin" "Tk"]

            cd $buildDir
            exec $tclkit [file join $tclBinDir sdx.kit] wrap $appName -runtime $runtimeTcl
            file rename $appName $starpackBatchExe
        }

        cd $cwd
    }

    proc AddCheckOption { checkOption } {
        variable sBuildCheckOption

        lappend sBuildCheckOption $checkOption
    }

    proc GetCheckOptions {} {
        variable sBuildCheckOption

        if { [info exists sBuildCheckOption] } {
            return $sBuildCheckOption
        } else {
            return [list]
        }
    }

    proc AddUserConfig { libName configOpt } {
        variable sBuildUserConfig

        set libName [string tolower $libName]
        lappend sBuildUserConfig($libName) $configOpt
    }

    proc GetUserConfig { libName } {
        variable sBuildUserConfig

        set libName [string tolower $libName]
        if { ! [info exists sBuildUserConfig] || ! [info exists sBuildUserConfig($libName)] } {
            return [list]
        }
        return $sBuildUserConfig($libName)
    }

    proc GetUserConfigValue { libName configKey } {
        set configValue ""
        foreach configOpt [GetUserConfig $libName] {
            if { [string match "${configKey}=*" $configOpt] } {
                set configValue [string trim [lindex [split $configOpt "="] 1]]
            }
        }
        return $configValue
    }

    proc GetUserCFlags { libName } {
        set cflags ""
        set userConfig [GetUserConfig $libName]
        if { [llength $userConfig] > 0 } {
            append cflags "CFLAGS=\" "
            foreach arg $userConfig {
                append cflags "$arg "
            }
            append cflags "\" "
        }
        return $cflags
    }

    proc IsSimulationMode {} {
        if { [UseStage "Update"] && [lsearch -exact [GetCheckOptions] "Stages"] >= 0 } {
            return true
        }
        return false
    }

    proc UpdateLib { libName why } {
        EnableStages $libName "Clean" "Extract" "Configure" "Compile" "Distribute"
        SetLibUpdated $libName $why
    }

    proc SetLibUpdated { libName why } {
        variable sUpdatedLibs

        Log "Update cause: $why" 2 false
        set sUpdatedLibs($libName) $why
    }

    proc AnyLibUpdated {} {
        variable sUpdatedLibs

        if { [info exists sUpdatedLibs] } {
            return true
        }
        return false
    }

    proc GetLibUpdateCause { libName } {
        variable sUpdatedLibs

        if { [info exists sUpdatedLibs($libName)] } {
            return $sUpdatedLibs($libName)
        }
        return ""
    }

    proc LibNeedsUpdate { libName } {
        variable sUpdatedLibs

        if { ! [CheckRecursiveDependencies] } {
            return ""
        }
        foreach dependency [GetLibDependencies $libName] {
            if { [string equal -nocase $dependency "All"] || \
                 [info exists sUpdatedLibs($dependency)] } {
                return $dependency
            }
        }
        return ""
    }

    proc CheckRecursiveDependencies {} {
        variable sBuildOpts

        return $sBuildOpts(UseRecursiveDependencies)
    }

    proc UseRecursiveDependencies { onOff } {
        variable sBuildOpts

        set sBuildOpts(UseRecursiveDependencies) $onOff
    }

    proc EnableStage { stage { libName "all" } } {
        variable sBuildStages

        set sBuildStages($stage,$libName) true
    }

    proc EnableStages { libName args } {
        foreach stage $args {
            EnableStage $stage $libName
        }
    }

    proc EnableAllStages { { libName "all" } } {
        EnableStages $libName "Clean" "Extract" "Configure" "Compile" "Distribute" "Finalize"
    }

    proc DisableStage { stage { libName "all" } } {
        variable sBuildStages

        set sBuildStages($stage,$libName) false
    }

    proc DisableStages { libName args } {
        foreach stage $args {
            DisableStage $stage $libName
        }
    }

    proc DisableAllStages { { libName "all" } } {
        DisableStage "Clean"      $libName
        DisableStage "Extract"    $libName
        DisableStage "Configure"  $libName
        DisableStage "Compile"    $libName
        DisableStage "Distribute" $libName
        DisableStage "Finalize"   $libName
        DisableStage "Touch"      $libName
    }

    proc UseStage { stage { libName "all" } } {
        variable sBuildStages

        if { [HaveFatalError] } {
            return false
        }

        if { [info exists sBuildStages($stage,$libName)] } {
            return $sBuildStages($stage,$libName)
        } else {
            if { [info exists sBuildStages($stage,all)] } {
                return $sBuildStages($stage,all)
            } else {
                return false
            }
        }
    }

    proc IsBuildStage { { libName "all" } } {
        return [expr \
            [UseStage "Extract" $libName]   || \
            [UseStage "Configure" $libName] || \
            [UseStage "Compile" $libName]   || \
            [UseStage "Distribute" $libName]]
    }

    proc GetUsedStages { { libName "all" } } {
        variable sBuildStages
        variable sStageOrder

        set usedStages [list]
        foreach stage $sStageOrder {
            if { [info exists sBuildStages($stage,$libName)] && $sBuildStages($stage,$libName) } {
                lappend usedStages $stage
            }
        }
        if { [llength $usedStages] == 0 } {
            return "None"
        } else {
            return $usedStages
        }
    }

    proc UseTclPkgVersion { { onOff "" } } {
        variable sBuildOpts

        if { $onOff eq "" } {
            return $sBuildOpts(UseTclPkgVersion)
        } else {
            set sBuildOpts(UseTclPkgVersion) $onOff
        }
    }

    proc ExitOnFatalError { { onOff "" } } {
        variable sBuildOpts

        if { $onOff eq "" } {
            return $sBuildOpts(ExitOnFatalError)
        } else {
            set sBuildOpts(ExitOnFatalError) $onOff
        }
    }

    proc SetCompilerVersion { version } {
        variable sBuildOpts

        if { $version eq "gcc" } {
            set sBuildOpts(CompilerVersion) [GetPlatformName]
        } else {
            set sBuildOpts(CompilerVersion) $version
        }
    }

    proc SetCompilerVersions { args } {
        variable sBuildOpts

        set sBuildOpts(CompilerVersions) [list]
        foreach version $args {
            lappend sBuildOpts(CompilerVersions) $version
        }
    }

    proc GetCompilerVersions {} {
        variable sBuildOpts

        return $sBuildOpts(CompilerVersions)
    }

    proc GetCompilerVersion { args } {
        variable sBuildOpts

        set showPlatformName false
        if { [lsearch -exact $args "-platform"] >= 0 } {
            set showPlatformName true
        }
        set showNumericVersion false
        if { [lsearch -exact $args "-numeric"] >= 0 } {
            set showNumericVersion true
        }
        set showVisualStudioVersion false
        if { [lsearch -exact $args "-vs"] >= 0 } {
            set showVisualStudioVersion true
        }
        set libName ""
        set ind [lsearch -exact $args "-lib"]
        if { $ind >= 0 } {
            set libName [lindex $args [expr { $ind + 1 }]]
        }

        if { ! [IsWindows] } {
            if { $showPlatformName } {
                return [GetPlatformName]
            } else {
                return "gcc"
            }
        }

        if { $libName ne "" } {
            if { [GetWinCompiler $libName] eq "" } {
                return ""
            }
            foreach version [GetCompilerVersions] {
                if { [string match "vs*" $version] && [UseWinCompiler $libName "vs"] } {
                    if { $showNumericVersion } {
                        return [string range $version 2 end]
                    } else {
                        return $version
                    }
                } elseif { $version eq "gcc" && [UseWinCompiler $libName "gcc"] } {
                    if { $showPlatformName } {
                        return [GetPlatformName]
                    } else {
                        return $version
                    }
                }
            }
            ErrorAppend "GetCompilerVersion: No compiler found for library $libName." "FATAL"
        }

        if { $showVisualStudioVersion } {
            foreach version [GetCompilerVersions] {
                if { [string match "vs*" $version] } {
                    if { $showNumericVersion } {
                        return [string range $version 2 end]
                    } else {
                        return $version
                    }
                }
            }
            ErrorAppend "GetCompilerVersion: No VisualStudio compiler specified." "FATAL"
        }

        set version [lindex [GetCompilerVersions] 0]
        if { [string match "vs*" $version] } {
            if { $showNumericVersion } {
                return [string range $version 2 end]
            } else {
                return $version
            }
        } else {
            if { $showPlatformName } {
                return [GetPlatformName]
            } else {
                return $version
            }
        }
    }

    proc GetVisualStudioVersion {} {
        return [GetCompilerVersion -vs -numeric]
    }

    proc GetGccCompilerVersion {} {
        if { [IsWindows] } {
            return [GetMingwGccVersion]
        } else {
            try {
                set result [exec gcc -v]
            } trap NONE result {
            }

            set version ""
            foreach line [split $result "\n"] {
                set line [string trim $line]
                if { [string match "gcc version*" $line] } {
                    scan $line "gcc version %s" version
                    break
                } elseif { [string match "Apple clang version*" $line] } {
                    scan $line "Apple clang version %s" version
                    break
                }
            }
            return $version
        }
    }

    proc GetValidCompilerVersions {} {
        return [list "gcc" "vs2008" "vs2010" "vs2012" "vs2013" "vs2015" "vs2017" "vs2019" "vs2022"]
    }

    proc _Min { a b } {
        if { $a < $b } {
            return $a
        } else {
            return $b
        }
    }

    proc SetNumJobs { numJobs { libName "all" } { winCompiler "" } } {
        variable sBuildOpts

        Log "SetNumJobs $numJobs $libName $winCompiler"
        set libName [string tolower $libName]
        if { $winCompiler ne "" } {
            set sBuildOpts($libName,NumJobs,$winCompiler) $numJobs
        } else {
            set sBuildOpts($libName,NumJobs) $numJobs
        }
    }

    proc GetNumJobs { { libName "all" } { winCompiler "" } } {
        variable sBuildOpts

        set libName [string tolower $libName]
        if { $winCompiler ne "" && [info exists sBuildOpts($libName,NumJobs,$winCompiler)] } {
            return [_Min $sBuildOpts($libName,NumJobs,$winCompiler) $sBuildOpts(all,NumJobs)]
        } elseif { [info exists sBuildOpts($libName,NumJobs)] } {
            return [_Min $sBuildOpts($libName,NumJobs) $sBuildOpts(all,NumJobs)]
        } else {
            return $sBuildOpts(all,NumJobs)
        }
    }

    proc _SupportsParallelBuild {} {
        if { [UseVisualStudio] } {
            # VisualStudio 2008 Express does not support option /m.
            if { [GetCompilerVersion -vs] eq "vs2008" } {
                return false
            }
        }
        return true
    }

    proc SetTimeout { secs } {
        variable sBuildOpts

        if { $secs < 0.0 } {
            set secs 0.0 
        }
        set sBuildOpts(Timeout) [expr int ($secs * 1000.0)]
    }

    proc GetTimeout { { unit "ms" } } {
        variable sBuildOpts

        if { $unit eq "ms" } {
            return $sBuildOpts(Timeout)
        } else {
            return [expr $sBuildOpts(Timeout) / 1000.0]
        }
    }

    proc HaveYasmProg {} {
        if { [auto_execok yasm] ne "" } {
            return true
        }
        if { [auto_execok "[GetOutputDevDir]/bin/yasm[GetExeSuffix]"] ne "" } {
            return true
        }
        return false
    }

    proc GetGendefProg {} {
        return [file join [GetOutputToolsDir] [GetMingwDir] [GetMingwSubDir] "bin" "gendef.exe"]
    }

    proc GetSWIGDistDir {} {
        return [file join [GetOutputDevDir] "opt" "SWIG" "bin"]
    }

    proc GetCMakeDistDir {} {
        return [file join [GetOutputDevDir] "opt" "CMake" "bin"]
    }

    proc GetCMakeProg {} {
        set cmakeCmd [auto_execok "[GetCMakeDistDir]/cmake[GetExeSuffix]"]
        if { $cmakeCmd eq "" } {
            set cmakeCmd [auto_execok "cmake[GetExeSuffix]"]
            if { $cmakeCmd eq "" } {
                ErrorAppend "Can not find CMake program" "FATAL"
            }
        }
        return $cmakeCmd
    }

    proc GetCMakeMSysOption { libName } {
        set cmakeMSysOpt ""
        if { [UseWinCompiler $libName "gcc"] } {
            set cmakeMSysOpt "-GMSYS Makefiles"
        }
        return $cmakeMSysOpt
    }

    proc GetMSysCppOption { libName } {
        set opt ""
        if { [UseWinCompiler $libName "gcc"] } {
            set opt "CXX='g++ -static-libstdc++ -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive' "
        }
        return $opt
    }

    proc GetInnoDistDir {} {
        return [file join [GetOutputDevDir] "opt" "InnoSetup"]
    }

    proc GetInnoProg {} {
        set progName "ISCC[GetExeSuffix]"
        set innoCmd [auto_execok $progName]
        if { [IsWindows] } {
            if { $innoCmd eq "" } {
                set innoCmd [auto_execok "[GetInnoDistDir]/$progName"]
            }
            if { $innoCmd eq "" } {
                ErrorAppend "Can not find InnoSetup program ISCC.exe" "FATAL"
            }
        }
        return $innoCmd
    }

    proc SetMingwGccVersion { gccVersion } {
        variable sBuildOpts

        set sBuildOpts(GccVersion) $gccVersion
    }

    proc GetMingwGccVersion {} {
        variable sBuildOpts

        return $sBuildOpts(GccVersion)
    }

    proc GetGccWinPack {} {
        variable sBuildOpts

        return $sBuildOpts(GccWinPack)
    }

    proc GetMingwVersion {} {
        set mingwVersion ""
        if { [Is64Bit] } {
            set mingwVersion "x86_64-w64-mingw32"
        } else {
            set mingwVersion "i686-w64-mingw32"
        }
        return $mingwVersion
    }

    proc GetMingwDir {} {
        set gccVersion   [GetMingwGccVersion]
        set mingwVersion [GetMingwVersion]
        set mingwDir     "gcc${gccVersion}_${mingwVersion}"
        return $mingwDir
    }

    proc GetMingwSubDir {} {
        if { [Is64Bit] } {
            set mingwSubDir "mingw64"
        } elseif { [Is32Bit] } {
            set mingwSubDir "mingw32"
        }
        return $mingwSubDir
    }

    proc GetMingwIncludeDir {} {
        return [file join [GetOutputToolsDir] [GetMingwDir] [GetMingwSubDir] \
                "lib" "gcc" [GetMingwVersion] [GetMingwGccVersion] "include"]
    }

    proc GetMingwLib { libName } {
        set path [file join [GetOutputToolsDir] [GetMingwDir] [GetMingwSubDir] "bin" $libName]
        if { [file exists $path] } {
            return $path
        }
        ErrorAppend "GetMingwLib: Library $libName not found." "FATAL"
    }

    proc GetPthreadLib {} {
        return [GetMingwLib "libwinpthread-1.dll"]
    }

    proc GetSehLib {} {
        if { [Is64Bit] } {
            return [GetMingwLib "libgcc_s_seh-1.dll"]
        } else {
            return [GetMingwLib "libgcc_s_dw2-1.dll"]
        }
    }

    proc GetMSysShell {} {
        if { [IsWindows] } {
            return [file join [GetMSysBinDir] "sh.exe"]
        } else {
            return "/bin/bash"
        }
    }

    proc GetCmdShell {} {
        global env

        if { [IsWindows] } {
            if { [Is64Bit] } {
                return [file join $env(windir) "SysWOW64" "cmd.exe"]
            } else {
                return [file join $env(windir) "system32" "cmd.exe"]
            }
        } else {
            return "/bin/bash"
        }
    }

    proc SetBuildType { buildType } {
        variable sBuildOpts

        set sBuildOpts(BuildType) $buildType
    }

    proc GetBuildType {} {
        variable sBuildOpts

        return $sBuildOpts(BuildType)
    }

    proc GetValidBuildTypes {} {
        return [list "Release" "Debug"]
    }

    proc IsReleaseBuild {} {
        if { [GetBuildType] eq "Release" } {
            return true
        } else {
            return false
        }
    }

    proc IsDebugBuild {} {
        if { [GetBuildType] eq "Debug" } {
            return true
        } else {
            return false
        }
    }

    proc GetDebugSuffix { { suffix "g" } } {
        set debugSuffix ""
        if { [IsDebugBuild] } {
            set debugSuffix $suffix
        }
        return $debugSuffix
    }

    proc GetWinDebugSuffix { { suffix "g" } } {
        set debugSuffix ""
        if { [IsDebugBuild] && [IsWindows] } {
            set debugSuffix $suffix
        }
        return $debugSuffix
    }

    proc SetArchitecture { architecture } {
        variable sBuildOpts

        set sBuildOpts(Architecture) $architecture
    }

    proc GetArchitecture {} {
        variable sBuildOpts

        return $sBuildOpts(Architecture)
    }

    proc GetValidArchitectures {} {
        return [list "x86" "x64"]
    }

    proc Is32Bit {} {
        if { [GetArchitecture] eq "x86" } {
            return true
        } else {
            return false
        }
    }

    proc Is64Bit {} {
        if { [GetArchitecture] eq "x64" } {
            return true
        } else {
            return false
        }
    }

    proc GetBits { { show64BitOnly false } } {
        if { [Is64Bit] } {
            return 64
        } else {
            if { $show64BitOnly } {
                return ""
            } else {
                return 32
            }
        }
    }

    proc GetMajor { libVersion } {
        return [lindex [split $libVersion "."] 0]
    }

    proc GetMinor { libVersion } {
        return [lindex [split $libVersion "."] 1]
    }

    proc GetPatch { libVersion } {
        return [lindex [split $libVersion "."] 2]
    }

    proc GetMajorMinor { libVersion { combineChar "NotSpecified" } } {
        set combine ""
        if { $combineChar eq "NotSpecified" } {
            if { [IsUnix] } {
                set combine "."
            }
        } else {
            set combine $combineChar
        }
        set versionList [split $libVersion "."]
        return [format "%s%s%s" [lindex $versionList 0] $combine [lindex $versionList 1]]
    }

    proc GetMajorMinorPatch { libVersion { combineChar "NotSpecified" } } {
        set combine ""
        if { $combineChar eq "NotSpecified" } {
            if { [IsUnix] } {
                set combine "."
            }
        } else {
            set combine $combineChar
        }
        set versionList [split $libVersion "."]
        return [format "%s%s%s%s%s" [lindex $versionList 0] $combine \
                                    [lindex $versionList 1] $combine \
                                    [lindex $versionList 2] ]
    }

    proc VersionCompare { version1 version2 } {
        # A wrapper around package vcompare to handle alpha or beta versions
        # containing "a" or "b", ex. 8.7.a4 
        set patchVersion1 [GetPatch $version1]
        set patchVersion2 [GetPatch $version2]
        if { ! [string is integer -strict $patchVersion1] } {
            set version1 [format "%d.%d.%d" [GetMajor $version1] [GetMinor $version1] 0]
        }
        if { ! [string is integer -strict $patchVersion2] } {
            set version2 [format "%d.%d.%d" [GetMajor $version2] [GetMinor $version2] 0]
        }
        return [package vcompare $version1 $version2]
    }

    proc GetPlatformName { { useShortName false } } {
        if { [IsWindows] } {
            if { $useShortName } {
                return "win"
            } else {
                return "Windows"
            }
        } elseif { [IsLinux] } {
            return "Linux"
        } elseif { [IsDarwin] } {
            return "Darwin"
        } else {
            return "Unknown"
        }
    }

    proc GetMsBuildPlatform {} {
        if { [GetArchitecture] eq "x86" } {
            return "Win32"
        } else {
            return "x64"
        }
    }

    proc GetBatchSuffix { { dot "." } } {
        set suf $dot
        if { [IsWindows] } {
            append suf "bat"
        } else {
            append suf "sh"
        }
        return $suf
    }

    proc GetExeSuffix { { dot "." } } {
        set suf $dot
        if { [IsWindows] } {
            append suf "exe"
        } else {
            return ""
        }
        return $suf
    }

    proc GetLibSuffix { { dot "." } } {
        set suf $dot
        if { [IsWindows] } {
            append suf "dll"
        } elseif { [IsLinux] } {
            append suf "so"
        } else {
            append suf "dylib"
        }
        return $suf
    }

    proc GetImportLibSuffix { { dot "." } } {
        set suf $dot
        if { [IsWindows] } {
            append suf "lib"
        } elseif { [IsLinux] } {
            append suf "so"
        } else {
            append suf "dylib"
        }
        return $suf
    }

    proc GetStaticLibSuffix { { dot "." } } {
        set suf $dot
        if { [IsWindows] } {
            append suf "lib"
        } elseif { [IsLinux] } {
            append suf "a"
        } else {
            append suf "a"
        }
        return $suf
    }

    proc GetLibPattern {} {
        return "*[GetLibSuffix]"
    }

    proc IsWindows {} {
        if { $::tcl_platform(platform) eq "windows" } {
            return true
        } else {
            return false
        }
    }

    proc IsLinux {} {
        if { $::tcl_platform(os) eq "Linux" } {
            return true
        } else {
            return false
        }
    }

    proc IsDarwin {} {
        if { $::tcl_platform(os) eq "Darwin" } {
            return true
        } else {
            return false
        }
    }

    proc IsUnix {} {
        if { $::tcl_platform(platform) eq "unix" } {
            return true
        } else {
            return false
        }
    }

    proc CreateDefaultDirs {} {
        if { ! [file isdirectory [GetOutputArchDir]] } {
            file mkdir [GetOutputArchDir]
        }
        if { ! [file isdirectory [GetOutputDevDir]] } {
            file mkdir [GetOutputDevDir]
        }
        if { ! [file isdirectory [GetOutputBuildDir]] } {
            file mkdir [GetOutputBuildDir]
        }
        if { ! [file isdirectory [GetOutputInstDir]] } {
            file mkdir [GetOutputInstDir]
        }
        if { ! [file isdirectory [GetOutputDistDir]] } {
            file mkdir [GetOutputDistDir]
        }
    }

    proc SetShortRootDir { onOff } {
        variable sBuildOpts

        set sBuildOpts(UseShortRootDir) $onOff
    }

    proc UseShortRootDir {} {
        variable sBuildOpts

        return $sBuildOpts(UseShortRootDir)
    }

    proc GetOutputArchDir {} {
        if { [UseShortRootDir] } {
            return [GetOutputRootDir]
        } else {
            return [file join [GetOutputRootDir] [GetCompilerVersion -platform] [GetArchitecture]]
        }
    }

    proc GetOutputDevDir {} {
        return [file join [GetOutputArchDir] "Development"]
    }

    proc GetOutputTypeDir {} {
        return [file join [GetOutputArchDir] [GetBuildType]]
    }

    proc GetOutputBuildDir {} {
        return [file join [GetOutputTypeDir] "Build"]
    }

    proc GetOutputInstDir {} {
        return [file join [GetOutputTypeDir] "Install"]
    }

    proc SetOutputDistDir { dir } {
        variable sBuildOpts

        set sBuildOpts(DistDir) [file normalize $dir]
    }

    proc GetOutputDistDir {} {
        variable sBuildOpts

        if { $sBuildOpts(DistDir) ne "" } {
            return $sBuildOpts(DistDir)
        } else {
            return [file join [GetOutputTypeDir] "Distribution"]
        }
    }

    proc SetFinalizeFile { fileName } {
        variable sBuildOpts

        set found [file exists $fileName]
        if { $found } {
            set sBuildOpts(FinalizeFile) [file normalize $fileName]
        } else {
            ErrorAppend "SetFinalizeFile: Script file $fileName not found." "FATAL"
        }
    }

    proc GetFinalizeFile {} {
        variable sBuildOpts

        return $sBuildOpts(FinalizeFile)
    }

    proc _GetTclkitAttribute { libName attrName } {
        variable sBuildOpts

        if { [info exists sBuildOpts(Tclkit,$libName,$attrName)] } {
            return $sBuildOpts(Tclkit,$libName,$attrName)
        }
        if { [info exists sBuildOpts(Tclkit,All,$attrName)] } {
            return $sBuildOpts(Tclkit,All,$attrName)
        }
        return ""
    }

    proc SetTclkitIconFile { libName fileName } {
        variable sBuildOpts

        set found [file exists $fileName]
        if { ! $found } {
            if { [file pathtype $fileName] eq "relative" } {
                set testFile [file join [GetInputResourceDir] $fileName]
                if { [file exists $testFile] } {
                    set fileName $testFile
                    set found true
                }
            }
        }
        if { $found } {
            set sBuildOpts(Tclkit,$libName,IconFile) [file normalize $fileName]
        } else {
            ErrorAppend "SetTclkitIconFile: Icon file $fileName not found. Using default icon file." "Warning"
        }
    }

    proc GetTclkitIconFile { libName } {
        return [_GetTclkitAttribute $libName "IconFile"]
    }

    proc SetTclkitResourceFile { libName fileName } {
        variable sBuildOpts

        set found [file exists $fileName]
        if { ! $found } {
            if { [file pathtype $fileName] eq "relative" } {
                set testFile [file join [GetInputResourceDir] $fileName]
                if { [file exists $testFile] } {
                    set fileName $testFile
                    set found true
                }
            }
        }
        if { $found } {
            set sBuildOpts(Tclkit,$libName,ResourceFile) [file normalize $fileName]
        } else {
            ErrorAppend "SetTclkitResourceFile: Resource file $fileName not found. Using default icon file." "Warning"
        }
    }

    proc GetTclkitResourceFile { libName } {
        return [_GetTclkitAttribute $libName "ResourceFile"]
    }

    proc SetTclkitCompanyName { libName value } {
        variable sBuildOpts

        set sBuildOpts(Tclkit,$libName,CompanyName) $value
    }

    proc GetTclkitCompanyName { libName } {
        return [_GetTclkitAttribute $libName "CompanyName"]
    }

    proc SetTclkitLegalCopyright { libName value } {
        variable sBuildOpts

        set sBuildOpts(Tclkit,$libName,LegalCopyright) $value
    }

    proc GetTclkitLegalCopyright { libName } {
        return [_GetTclkitAttribute $libName "LegalCopyright"]
    }

    proc SetTclkitFileDescription { libName value } {
        variable sBuildOpts

        set sBuildOpts(Tclkit,$libName,FileDescription) $value
    }

    proc GetTclkitFileDescription { libName } {
        return [_GetTclkitAttribute $libName "FileDescription"]
    }

    proc SetTclkitProductName { libName value } {
        variable sBuildOpts

        set sBuildOpts(Tclkit,$libName,ProductName) $value
    }

    proc GetTclkitProductName { libName } {
        return [_GetTclkitAttribute $libName "ProductName"]
    }

    proc SetTclkitProductVersion { libName value } {
        variable sBuildOpts

        set sBuildOpts(Tclkit,$libName,ProductVersion) $value
    }

    proc GetTclkitProductVersion { libName } {
        return [_GetTclkitAttribute $libName "ProductVersion"]
    }

    proc SetTclkitFileVersion { libName value } {
        variable sBuildOpts

        set sBuildOpts(Tclkit,$libName,FileVersion) $value
    }

    proc GetTclkitFileVersion { libName } {
        return [_GetTclkitAttribute $libName "FileVersion"]
    }

    proc SetTclVersion { version } {
        variable sBuildOpts

        set sBuildOpts(TclVersion) $version
    }

    proc GetTclVersion {} {
        variable sBuildOpts

        return $sBuildOpts(TclVersion)
    }

    proc SetTkVersion { version } {
        variable sBuildOpts

        set sBuildOpts(TkVersion) $version
    }

    proc GetTkVersion {} {
        variable sBuildOpts

        if { [info exists sBuildOpts(TkVersion)] } {
            return $sBuildOpts(TkVersion)
        } else {
            return [GetTclVersion]
        }
    }

    proc GetPythonVersion {} {
        set pythonVersion "0.0.0"
        # First try the BAWT supplied Python executable.
        set pythonExe [file join [GetDevPythonBinDir] "python.exe"]
        if { ! [file exists $pythonExe] } {
            # Look for an installed Python version.
            # Note, that on Win10 there might be files Python3.exe
            # and Python.exe with zero size in directory
            # %LOCALAPPDATA%\Microsoft\WindowsApps.
            # To get rid of these files, disable Python3 and Python in the
            # system settings: "Apps & features"->"App execution aliases"
            set pythonExe [auto_execok "python3"]
            if { $pythonExe eq "" || [file size $pythonExe] == 0 } {
                set pythonExe [auto_execok "python"]
                if { $pythonExe eq "" || [file size $pythonExe] == 0 } {
                    set pythonExe ""
                }
            }
        }
        if { $pythonExe ne "" } {
            catch { eval ::exec $pythonExe --version } pythonVersionString
            set pythonVersion [lindex [split $pythonVersionString] 1]
        }
        return $pythonVersion
    }

    proc SetOsgVersion { version } {
        variable sBuildOpts

        set sBuildOpts(OsgVersion) $version
    }

    proc GetOsgVersion {} {
        variable sBuildOpts

        return $sBuildOpts(OsgVersion)
    }

    proc SetImgVersion { version } {
        variable sBuildOpts

        set sBuildOpts(ImgVersion) $version
    }

    proc GetImgVersion {} {
        variable sBuildOpts

        return $sBuildOpts(ImgVersion)
    }

    proc SetTclDir { dir } {
        variable sBuildOpts

        set sBuildOpts(TclDir) $dir
    }

    proc SetPythonDir { dir } {
        variable sBuildOpts

        set sBuildOpts(PythonDir) $dir
    }

    proc GetTclDir {} {
        variable sBuildOpts

        return $sBuildOpts(TclDir)
    }

    proc GetPythonDir {} {
        variable sBuildOpts

        return $sBuildOpts(PythonDir)
    }

    proc GetTclLibDir {} {
        return [file join [GetTclDir] "lib"]
    }

    proc GetPythonLibDir {} {
        return [file join [GetPythonDir] "lib"]
    }

    proc GetDevTclLibDir {} {
        return [file join [GetOutputDevDir] [GetTclLibDir]]
    }

    proc GetDevPythonLibDir {} {
        return [file join [GetOutputDevDir] [GetPythonLibDir]]
    }

    proc GetTclBinDir {} {
        return [file join [GetTclDir] "bin"]
    }

    proc GetPythonBinDir {} {
        return [GetPythonDir]
    }

    proc GetDevTclBinDir {} {
        return [file join [GetOutputDevDir] [GetTclBinDir]]
    }

    proc GetDevPythonBinDir {} {
        return [file join [GetOutputDevDir] [GetPythonBinDir]]
    }

    proc GetTclIncDir {} {
        return [file join [GetTclDir] "include"]
    }

    proc GetPythonIncDir {} {
        return [file join [GetPythonDir] "include"]
    }

    proc GetDevTclDir {} {
        return [file join [GetOutputDevDir] [GetTclDir]]
    }

    proc GetDevPythonDir {} {
        return [file join [GetOutputDevDir] [GetPythonDir]]
    }

    proc GetDevTclIncDir {} {
        return [file join [GetOutputDevDir] [GetTclIncDir]]
    }

    proc GetDevPythonIncDir {} {
        return [file join [GetOutputDevDir] [GetPythonIncDir]]
    }

    proc _GetTclTkLibName { tclOrTk libVersion } {
        set debugSuffix ""
        if { [IsDebugBuild] && [IsWindows] } {
            set debugSuffix "g"
        }
        set libName [format "%s%s%s" $tclOrTk [GetMajorMinor $libVersion] $debugSuffix]
        return $libName
    }

    proc GetTclLibName { libVersion { stub "" } } {
        return [_GetTclTkLibName "tcl$stub" $libVersion]
    }

    proc GetTkLibName { libVersion { stub "" } } {
        return [_GetTclTkLibName "tk$stub" $libVersion]
    }

    proc GetTclStubLib { libVersion { compilerType "gcc" } } {
        set tclLibDir [GetDevTclLibDir]
        set debugSuf [list ""]
        if { [IsDebugBuild] && [IsWindows] } {
            set debugSuf [list "g" ""]
        }
        foreach suf $debugSuf {
            set libName [format "tclstub%s%s" [GetMajorMinor $libVersion] $suf]
            if { $compilerType eq "vs" && [IsWindows] } {
                set stubName [format "%s.lib"  $libName]
            } else {
                set stubName [format "lib%s.a" $libName]
            }
            set stubFile [file join $tclLibDir $stubName]
            if { [file exists $stubFile] } {
                return $stubFile
            }
        }
        ErrorAppend "GetTclStubLib: No Tcl stub file in $tclLibDir found." "FATAL"
    }

    proc GetTkStubLib { libVersion { compilerType "gcc" } } {
        set tclLibDir [GetDevTclLibDir]
        set debugSuf [list ""]
        if { [IsDebugBuild] && [IsWindows] } {
            set debugSuf [list "g" ""]
        }
        foreach suf $debugSuf {
            set libName [format "tkstub%s%s" [GetMajorMinor $libVersion] $suf]
            if { $compilerType eq "vs" && [IsWindows] } {
                set stubName [format "%s.lib"  $libName]
            } else {
                set stubName [format "lib%s.a" $libName]
            }
            set stubFile [file join $tclLibDir $stubName]
            if { [file exists $stubFile] } {
                return $stubFile
            }
        }
        ErrorAppend "GetTkStubLib: No Tk stub file in $tclLibDir found." "FATAL"
    }

    proc _GetTclshWishName { tclshOrWish libName { libVersion "" } } {
        set debugSuffix ""
        if { [IsDebugBuild] && [IsWindows] } {
            set debugSuffix "g"
        }
        set threadSuffix ""
        if { [IsWindows] && [UseWinCompiler $libName "vs"] } {
            set threadSuffix "t"
        }
        if { $libVersion eq "" } {
            set versionStr ""
        } else {
            set versionStr [GetMajorMinor $libVersion]
        }
        set name [format "%s%s%s%s%s" $tclshOrWish $versionStr $threadSuffix $debugSuffix [GetExeSuffix]]
        return $name
    }


    proc GetTclshName { { libVersion "" } } {
        return [_GetTclshWishName "tclsh" "Tcl" $libVersion]
    }

    proc GetTclshPath { { libVersion "" } } {
        return [file join [GetOutputDevDir] [GetTclBinDir] [GetTclshName $libVersion]]
    }

    proc GetWishName { { libVersion "" } } {
        return [_GetTclshWishName "wish" "Tk" $libVersion]
    } 

    proc GetWishPath { { libVersion "" } } {
        return [file join [GetOutputDevDir] [GetTclBinDir] [GetWishName $libVersion]]
    }

    proc GetItclDir {} {
        foreach libDir { lib lib64 } {
            set dir [glob -nocomplain -type d [GetOutputInstDir]/Tcl/$libDir/itcl*]
            if { [llength $dir] == 1 && [file isdirectory $dir] } {
                return $dir
            }
        }
        ErrorAppend "GetItclDir: No Itcl directory found." "FATAL"
    }

    proc GetPngLibDir {} {
        foreach libDir { /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu } {
            set fileList [glob -nocomplain -type f $libDir/libpng*.so]
            if { [llength $fileList] != 0 } {
                return $libDir
            }
        }
        ErrorAppend "GetPngLibDir: No PNG library found." "FATAL"
    }

    proc CleanLib { libName } {
        set buildDir [file join [GetOutputBuildDir] $libName]
        set instDir  [file join [GetOutputInstDir] $libName]

        DirDelete $buildDir
        DirDelete $instDir
    }

    proc _GetBawtProgressFile { libName } {
        return [file join [GetOutputLogDir] "_${libName}_[GetBuildType].progress"]
    }

    proc _BawtProgress { libName { onOff -1 } } {
        set runFile [_GetBawtProgressFile $libName]
        if { $onOff == -1 } {
            return [file exists $runFile]
        } elseif { $onOff == 1 } {
            set retVal [catch {open $runFile "w"} fp]
            if { $retVal != 0 } {
                ErrorAppend "Cannot create progress file $runFile" "FATAL"
                return
            }
            puts $fp ""
            close $fp
        } else {
            file delete -force $runFile
        }
    }

    proc BuildLib { libName libVersion buildTypeList } {
        HaveFatalError false
        if { [info commands Build_$libName] eq "" } {
            ErrorAppend "Library $libName: No Build_$libName command defined." "FATAL"
            return
        }
        if { ! [IsSupportedPlatform $libName] } {
            SetBuildError $libName "[GetPlatforms $libName] only"
            Log [format "End %s: Excluded from build (%s)" $libName [GetBuildError $libName]]
            return -1.0
        }
        if { [GetExcludeOption $libName] ne "" } {
            SetBuildError $libName "Option [GetExcludeOption $libName]"
            Log [format "End %s: Excluded from build (%s)" $libName [GetBuildError $libName]]
            return -1.0
        }
        if { [GetExcludeCompiler $libName] ne "" } {
            SetBuildError $libName "Compiler [GetExcludeCompiler $libName]"
            Log [format "End %s: Excluded from build (%s)" $libName [GetBuildError $libName]]
            return -1.0
        }

        set t1 [clock clicks -milliseconds]

        set retVal 0
        foreach buildType $buildTypeList {
            SetBuildType $buildType
            set buildDir [file join [GetOutputBuildDir] $libName]
            set instDir  [file join [GetOutputInstDir] $libName]
            set devDir   [GetOutputDevDir]
            set distDir  [GetOutputDistDir]

            if { [info commands Env_$libName] ne "" } {
                Env_$libName $libName $libVersion $buildDir $instDir $devDir $distDir
            }
            if { [UseStage "Update" $libName] } {
                set libNeedsUpdate [LibNeedsUpdate $libName]
                set zipFileOrDir [file join [GetInputRootDir] [GetLibZipDir $libName] [GetLibZipFile $libName]]
                if { ! [file isdirectory $buildDir] } {
                    UpdateLib $libName "Build directory not existent"
                } elseif { [file mtime $buildDir] < [file mtime [GetLibBuildFile $libName]] } {
                    UpdateLib $libName "Build file newer than build dir"
                } elseif { [file mtime $buildDir] < [file mtime $zipFileOrDir] } {
                    UpdateLib $libName "Source file newer than build dir"
                } elseif { [_BawtProgress $libName] } {
                    UpdateLib $libName "Progress file existent"
                } elseif { $libNeedsUpdate ne "" } {
                    if { ! [string equal -nocase $libNeedsUpdate "All"] || \
                         ( [string equal -nocase $libNeedsUpdate "All"] && [AnyLibUpdated] ) } {
                        UpdateLib $libName "Recursive dependency on $libNeedsUpdate"
                    }
                }
            }
            set retVal 1
            if { ! [IsSimulationMode] } {
                if { [UseStage "Clean" $libName] } {
                    Log "Clean $libName ($buildType)"
                    CleanLib $libName
                }
                Log "Build $libName [GetLibVersion $libName] ($buildType)"
                if { ! [UseStage "Check"] } {
                    CreateDefaultDirs
                }
                if { [UseStage "Touch"] } {
                    DirTouch $buildDir
                }
                if { [IsBuildStage $libName] } {
                    if { ! [UseStage "Check"] } {
                        DirCreate $buildDir
                        DirCreate $instDir
                    }
                    _BawtProgress $libName 1
                    WriteBuildLog $libName false "> Start Build_$libName\n"
                    set retVal [eval [list Build_$libName $libName $libVersion $buildDir $instDir $devDir $distDir]]
                    if { $retVal } {
                        _WriteMSysStartConsoleFile $libName $buildDir
                    }
                    WriteBuildLog $libName true "\n> End Build_$libName"
                    _BawtProgress $libName 0
                }
            } else {
                Log [format "End %s %s: Simulation mode" $libName [GetLibVersion $libName]]
                return -2.0
            }
        }

        if { $retVal } {
            set t2 [clock clicks -milliseconds]
            set buildTime [expr ($t2-$t1) / 1000.0 / 60.0]
            if { [UseLogTiming] } {
                Log [format "End %s %s: %.2f minutes" $libName [GetLibVersion $libName] $buildTime]
            } else {
                Log [format "End %s %s" $libName [GetLibVersion $libName]]
            }
        } else {
            SetBuildError $libName [GetLastLogMsg]
            Log [format "End %s %s: Excluded from build (%s)" $libName [GetLibVersion $libName] [GetBuildError $libName]]
            set buildTime -1.0
        }
        HaveFatalError false
        return $buildTime
    }

    proc _IsMSysGenerator { generator } {
        return [string match "MSYS*" $generator]
    }

    proc _GetCallCmd { generator } {
        if { [_IsMSysGenerator $generator] || [IsUnix] } {
            return ""
        } else {
            return "CALL "
        }
    }

    proc _GetBuildCount { libName buildInfra } {
        variable sBuildCount

        set key "$libName,[GetBuildType],$buildInfra"
        if { ! [info exists sBuildCount($key)] } {
            set sBuildCount($key) 1
            return ""
        } else {
            incr sBuildCount($key)
            return $sBuildCount($key)
        }
    }

    proc CMakeConfig { libName sourceDir buildDir installDir args } {
        set version [GetCompilerVersion -platform -lib $libName]
        switch -exact -nocase $version {
            "vs2008"  { set generator "Visual Studio 9 2008"  }
            "vs2010"  { set generator "Visual Studio 10 2010" }
            "vs2012"  { set generator "Visual Studio 11 2012" }
            "vs2013"  { set generator "Visual Studio 12 2013" }
            "vs2015"  { set generator "Visual Studio 14 2015" }
            "vs2017"  { set generator "Visual Studio 15 2017" }
            "vs2019"  { set generator "Visual Studio 16 2019" }
            "vs2022"  { set generator "Visual Studio 17 2022" }
            "Windows" { set generator "MSYS Makefiles" }
            "Linux"   { set generator "Unix Makefiles" }
            "Darwin"  { set generator "Unix Makefiles" }
            default   { ErrorAppend "CMakeConfig: Unsupported compiler version \"$version\"" "FATAL" }
        }

        set argStr ""
        foreach arg $args {
            if { [string match "-G*" $arg] } {
                if { [IsWindows] } {
                    set generator [string range $arg 2 end]
                }
            } else {
                append argStr "$arg "
            }
        }

        # Determine CMake version. Starting with version 3.14, the architecture is not part of the
        # generator string anymore, but must be specified via the "-A" command line option.
        set cmakeVersion [GetLibVersion "CMake"]
        if { $cmakeVersion eq "" } {
            ErrorAppend "CMakeConfig: CMake version not specified." "FATAL"
        }
        set isVsGen false
        if { [string match "Visual*" $generator] } {
            set isVsGen true
        }

        set archOpt ""
        if { [VersionCompare "3.14.0" $cmakeVersion] < 0 } {
            if { $isVsGen } {
                if { [Is64Bit] } {
                    set archOpt "-Ax64"
                } else {
                    set archOpt "-AWin32"
                }
            }
        } else {
            if { [Is64Bit] && $isVsGen } {
                append generator " Win64"
            }
        }

        foreach arg [GetUserConfig $libName] {
            append argStr "$arg "
        }

        set CMakeProg [GetCMakeProg]

        Log "CMakeConfig" 2
        Log "CMake program    : $CMakeProg"   4 false
        Log "Source directory : $sourceDir"   4 false
        Log "Build directory  : $buildDir"    4 false
        Log "Install directory: $installDir"  4 false
        Log "Generator        : $generator"   4 false
        Log "Architecture     : $archOpt"     4 false
        if { $argStr ne "" } {
            Log "Configuration    : $argStr"  4 false
        }

        file mkdir "$buildDir" "$installDir"

        set    cmd ""
        append cmd "[_GetCallCmd $generator] $CMakeProg "
        append cmd     "-G\"$generator\" "
        append cmd     "$archOpt "
        if { [GetSdkVersion $libName] ne "" } {
            append cmd "-DCMAKE_SYSTEM_VERSION=\"[GetSdkVersion $libName]\" "
        }
        append cmd     "-DCMAKE_BUILD_TYPE=[GetBuildType] "
        append cmd     "-DCMAKE_VERBOSE_MAKEFILE=1 "
        append cmd     "-DCMAKE_INSTALL_PREFIX:STRING=\"$installDir\" "
        append cmd     "$argStr "
        append cmd     "\"$sourceDir\" "

        set originator "CMakeConfig[_GetBuildCount $libName CMakeConfig]"
        # Call CMake configure twice, as some libraries do not have a 
        # valid configuration after the first call.
        if { [IsUnix] || [_IsMSysGenerator $generator] } {
            MSysRun $libName $originator $buildDir "$cmd"
            MSysRun $libName $originator $buildDir "$cmd"
        } else {
            DosRun $libName $originator $buildDir "$cmd"
            DosRun $libName $originator $buildDir "$cmd"
        }
    }

    proc CMakeBuild { libName buildDir cmakeTarget buildConfig args } {
        Log "CMakeBuild" 2
        Log "Build directory : $buildDir"    4 false
        Log "Build target    : $cmakeTarget" 4 false
        Log "Configuration   : $buildConfig" 4 false

        set generator ""
        foreach arg $args {
            if { [IsWindows] && [string match "-G*" $arg] } {
                set generator [string range $arg 2 end]
            }
        }
        set CMakeProg [GetCMakeProg]
        set    cmd ""
        append cmd "[_GetCallCmd $generator] $CMakeProg "
        append cmd     "--build . "
        append cmd     "--target \"$cmakeTarget\" "
        append cmd     "--config \"$buildConfig\" "
        set numJobs [GetNumJobs $libName [GetWinCompiler $libName]]
        if { [IsUnix] || [_IsMSysGenerator $generator] } {
            if { $numJobs > 1 } {
                append cmd "-- -j $numJobs "
            }
        } else {
            if { $numJobs > 1 && [_SupportsParallelBuild] } {
                append cmd "-- /m:$numJobs /p:BuildInParallel=true "
            }
        }

        set originator "CMakeBuild[_GetBuildCount $libName CMakeBuild]"
        if { [IsUnix] || [_IsMSysGenerator $generator] } {
            MSysRun $libName $originator $buildDir "$cmd"
        } else {
            DosRun $libName $originator $buildDir "$cmd"
        }
    }

    proc NMakeBuild { libName sourceDir makeFile args } {
        Log "NMakeBuild" 2
        Log "Source directory: $sourceDir"  4 false
        Log "Makefile        : $makeFile"   4 false
        if { [llength $args] > 0 } {
            Log "Options         : $args"   4 false
        }
        set    cmd ""
        append cmd "CALL nmake.exe "
        append cmd     "/nologo "
        append cmd     "/f \"$makeFile\" "
	#Filename arguments with spaces get wrapped with curly braces
	#replace with double quotes
	regsub -all {\}|\{} $args "\"" args
        append cmd     "$args "
        set originator "NMakeBuild[_GetBuildCount $libName NMakeBuild]"
        DosRun $libName $originator $sourceDir "$cmd"
    }

    proc MsBuild { libName sourceDir slnFile configuration { target "" } { buildPlatform "" } } {
        Log "MsBuild" 2
        Log "Source directory: $sourceDir"     4 false
        Log "Solution file   : $slnFile"       4 false
        Log "Configuration   : $configuration" 4 false
        if { $target ne "" } {
            Log "Build target    : $target"    4 false
        }

        set cmd ""
        append cmd "CALL MsBuild.exe "
        append cmd    "\"$slnFile\" "
        append cmd    "/v:detailed "
        append cmd    "/p:Configuration=\"$configuration\" "
        if { $buildPlatform eq "" } {
            set buildPlatform [GetMsBuildPlatform]
        }
        append cmd    "/p:Platform=\"$buildPlatform\" "
        set numJobs [GetNumJobs $libName [GetWinCompiler $libName]]
        if { $numJobs > 1 && [_SupportsParallelBuild] } {
            append cmd "/m:$numJobs /p:BuildInParallel=true "
        }
        if { $target ne "" } {
            append cmd "/t:\"$target\" "
        }

        set originator "MsBuild[_GetBuildCount $libName MsBuild]"
        DosRun $libName $originator $sourceDir "$cmd"
    }

    proc _LogCmd { cmd { sep " -" } } {
        foreach line [split $cmd ";"] {
            if { [string first $sep $line] >= 0 } {
                set sepInd1 [string first $sep $line]
                set sepInd2 $sepInd1
                Log "> [string trim [string range $line 0 $sepInd1]]" 4 false
                while { [string first $sep $line [expr $sepInd1 + 2]] >= 0 } {
                    set sepInd2 [string first $sep $line [expr $sepInd1 +2]]
                    Log "  [string trim [string range $line $sepInd1 $sepInd2]]" 4 false
                    set sepInd1 $sepInd2
                }
                Log "  [string trim [string range $line $sepInd2 end]]" 4 false
            } else {
                Log "> [string trim $line]" 4 false
            }
        }
    }
    
    proc _WriteMSysStartConsoleFile { libName buildDir } {
        if { [IsWindows] } {
            set batchFile [file join $buildDir "_Bawt_StartMSysConsole.bat"]
            Log "WriteConsoleFile" 2 false
            Log "File: $batchFile" 4 false
            set retVal [catch {open $batchFile "w"} fp]
            if { $retVal != 0 } {
                ErrorAppend "Cannot write to file $batchFile" "FATAL"
            }
            puts $fp "SET HOME=[file nativename $buildDir]"
            puts $fp "[GetMSysConsole]"
            close $fp
        }
    }

    proc _WriteMSysBatchFile { libName buildDir batchPrefix cmd } {
        set buildDirMSys [MSysPath $buildDir]
        if { [IsUnix] } {
            set batchFile "$batchPrefix.sh"
        } else {
            set batchFile "$batchPrefix.bat"
        }
        set batchPath [file join $buildDir $batchFile]
        Log "Batch file     : $batchPath"  4 false
        set retVal [catch {open $batchPath "w"} fp]
        if { $retVal != 0 } {
            ErrorAppend "Cannot write to file $batchPath" "FATAL"
            return ""
        }
        puts $fp "#!/bin/bash"
        if { [IsWindows] && [UseMSys2] } {
            puts $fp "export MSYSTEM=MINGW32"
            puts $fp "export HOME=[MSysPath $buildDir]"
        }
        puts $fp "export PATH=\"[GetPathes unix]\$PATH\""
        if { [IsUnix] } {
            puts $fp "export LD_LIBRARY_PATH=\"[GetOutputDevDir]/lib:\$LD_LIBRARY_PATH\""
        }
        puts $fp "export TCLLIBPATH=\"\$TCLLIBPATH [MSysPath [GetDevTclLibDir]]\""
        puts $fp "export PKG_CONFIG_PATH=\"[MSysPath [GetOutputDevDir]/bin]\""
        puts $fp "export BAWT_DEV_DIR=\"[MSysPath [GetOutputDevDir]]\""
        foreach { envVar envVal } [GetUseEnvVars] {
            puts $fp "export $envVar=\"$envVal\""
        }
        puts $fp "pushd $buildDirMSys"
        puts $fp "$cmd"
        puts $fp "retVal=\$?"
        puts $fp "popd"
        if { [GetIgnoreBuildError $libName] } {
            puts $fp "echo \$retVal"
        } else {
            puts $fp "exit \$retVal"
        }
        close $fp
        return $batchPath
    }

    proc _WriteDosBatchFile { libName buildDir batchPrefix cmd vcvarsProg vcvarsParam } {
        if { [IsUnix] } {
            return [_WriteMSysBatchFile $libName $buildDir $batchPrefix $cmd]
        }

        set batchFile "$batchPrefix.bat"
        set batchPath [file join $buildDir $batchFile]
        Log "Batch file     : $batchPath"  4 false
        set retVal [catch {open $batchPath "w"} fp]
        if { $retVal != 0 } {
            ErrorAppend "Cannot write to file $batchPath" "FATAL"
            return ""
        }
        puts $fp "CALL \"$vcvarsProg\" $vcvarsParam"
        puts $fp "SET Path=[GetPathes win]%Path%"
        foreach { envVar envVal } [GetUseEnvVars] {
            puts $fp "SET $envVar=$envVal"
        }
        puts $fp "PUSHD \"$buildDir\""
        puts $fp "$cmd"
        puts $fp "SET retVal=%errorlevel%"
        puts $fp "POPD"
        if { [GetIgnoreBuildError $libName] } {
            puts $fp "ECHO %retVal%"
        } else {
            puts $fp "EXIT %retVal%"
        }
        close $fp
        return $batchPath
    }

    proc MSysRun { libName originator buildDir cmd } {
        variable sOpts
        set buildDirMSys [MSysPath $buildDir]

        Log "MSysRun (Caller: $originator)" 2
        Log "Shell          : [GetMSysShell]"  4 false
        if { $buildDir ne "" } {
            Log "Build directory: $buildDirMSys"   4 false
        }

        set status "OK"
        set result "FATAL"

        if { $buildDir ne "" } {
            set batchFile [_WriteMSysBatchFile $libName $buildDir "_Bawt_MSysRun_$originator" $cmd]
        }
        _LogCmd $cmd " --"

        try {
            if { $buildDir ne "" } {
                set curDir [pwd]
                cd $buildDir
                if { [IsWindows] } {
                    set result [eval exec [GetCmdShell] /d /c [GetMSysShell] --login [list $batchFile]]
                } else {
                    set result [eval exec [GetMSysShell] [list $batchFile]]
                }
                cd $curDir
            } else {
                if { [IsWindows] } {
                    set result [eval exec [GetCmdShell] /d /c [GetMSysShell] --login -i -c [list $cmd]]
                } else {
                    set result [eval exec [GetMSysShell] -c [list $cmd]]
                }
            }
        } trap NONE result {
            # $result now holds the message that was written to stderr and everything written to stdout
            append status " (Messages have been written to stderr)"
        } trap CHILDSTATUS { - opts } {
            # process $pid exited with non-zero exit code $status
            lassign [dict get $opts -errorcode] -> pid status
            set errorMsg [dict get $opts -errorinfo]
            ErrorAppend "MSysRun: Error running command:\n$cmd\nError message:\n$errorMsg" $result
        }

        Log "Status: $status" 4 false
        WriteBuildLog $libName true $result
        return $result
    }

    proc MSysBuild { libName buildDir buildTarget { buildFlags "" } } {
        set buildDirMSys [MSysPath $buildDir]

        Log "MSysBuild" 2
        Log "Build directory: $buildDirMSys"  4 false
        Log "Build target   : $buildTarget"   4 false
        if { $buildFlags ne "" } {
            Log "Build flags   : $buildFlags"  4 false
        }

        set cmd ""
        append cmd "cd $buildDirMSys ; "
        if { $buildFlags ne "" } {
            append cmd "$buildFlags "
        }
        set numJobs [GetNumJobs $libName [GetWinCompiler $libName]]
        if { $numJobs > 1 } {
            append cmd "make -j $numJobs ; "
        } else {
            append cmd "make ; "
        }
        append cmd "make $buildTarget "

        set originator "MSysBuild[_GetBuildCount $libName MSysBuild]"
        MSysRun $libName $originator $buildDir "$cmd"
    }

    proc MSysConfig { libName buildDir installDir { cflags "" } args } {
        set buildDirMSys     [MSysPath $buildDir]
        set instDirMSys      [MSysPath $installDir]
        set rootBuildDirMSys [MSysPath [GetOutputBuildDir]]

        Log "MSysConfig" 2
        Log "Build directory  : $buildDir"   4 false
        Log "Install directory: $installDir" 4 false

        set cmd ""
        append cmd "$cflags "
        append cmd "$buildDirMSys/configure "
        append cmd     "--prefix=$instDirMSys --exec-prefix=$instDirMSys "
        if { [IsWindows] } {
            append cmd "--build=[GetMingwVersion] "
        }
        if { [IsDebugBuild] } {
            append cmd "--enable-symbols "
        } else {
            append cmd "--disable-symbols "
        }
        foreach arg $args {
            append cmd " $arg "
        }

        set originator "MSysConfig[_GetBuildCount $libName MSysConfig]"
        MSysRun $libName $originator $buildDir "$cmd"
    }

    proc TeaConfig { libName buildDir installDir { cflags "" } args } {
        set buildDirMSys     [MSysPath $buildDir]
        set instDirMSys      [MSysPath $installDir]
        set rootBuildDirMSys [MSysPath [GetOutputBuildDir]]

        Log "TeaConfig" 2
        Log "Build directory  : $buildDir"   4 false
        Log "Install directory: $installDir" 4 false

        set cmd ""
        append cmd "$cflags "
        append cmd "$buildDirMSys/configure "
        append cmd     "--enable-shared "
        append cmd     "--enable-threads "
        append cmd     "--prefix=$instDirMSys --exec-prefix=$instDirMSys "
        append cmd     "--with-tcl=$rootBuildDirMSys/Tcl "
        append cmd     "--with-tk=$rootBuildDirMSys/Tk "
        if { [IsWindows] } {
            append cmd "--build=[GetMingwVersion] "
        }
        if { [Is64Bit] } {
            append cmd "--enable-64bit "
        }
        if { [IsDebugBuild] } {
            append cmd "--enable-symbols "
        } else {
            append cmd "--disable-symbols "
        }
        append cmd "$args "

        set originator "TeaConfig[_GetBuildCount $libName TeaConfig]"
        MSysRun $libName $originator $buildDir "$cmd"
    }

    proc NeedDll2Lib { libName } {
        if { [UseWinCompiler $libName "gcc"] && [UseVisualStudio] } {
            return true
        }
        return false
    }

    proc Dll2Lib { libName dllDir dllFile defFile libFile } {
        # On Unix or if creating import libs is disabled, do nothing.
        if { ! [IsWindows] || ! [CreateImportLibs] } {
            return
        }
        # If Windows, but not using VisualStudio, print out a warning.
        if { ! [UseVisualStudio] } {
            ErrorAppend "Dll2Lib $libFile: Creating import libraries needs VisualStudio." "Warning"
            return
        }

        Log "Dll2Lib" 2
        Log "Directory: $dllDir"  4 false
        Log "DLL file : $dllFile" 4 false
        Log "Def file : $defFile" 4 false
        Log "Lib file : $libFile" 4 false

        set GendefProg [GetGendefProg]

        if { ! [file executable $GendefProg] } {
            ErrorAppend "Dll2Lib: gendef program not found." "FATAL"
        }

        set exitOnError [expr [IsWindows]]
        set dllFile [FindFile $dllDir $dllFile $exitOnError]

        set dllFullPath [file join $dllDir $dllFile]
        if { ! [file exists $dllFullPath] } {
            ErrorAppend "Dll2Lib: DLL $dllFullPath not found." "FATAL"
        }

        set cmd ""
        append cmd "CALL $GendefProg - \"$dllFile\" > \"$defFile\"\n"
        append cmd "CALL lib.exe "
        append cmd     "/def:[file nativename $defFile] "
        append cmd     "/out:[file nativename $libFile] "
        append cmd     "/machine:[GetArchitecture] "

        DosRun $libName "Dll2Lib" $dllDir "$cmd"
    }

    proc GetVSEditions {} {
        return { "Ultimate" "Professional" "Community" "Preview" }
    }

    proc SetVSRuntimeLibDir { dir } {
        variable sOpts

        if { ! [file isdirectory $dir] } {
            ErrorAppend "SetVSRuntimeLibDir: Specified directory $dir not found." "FATAL"
        }
        set sOpts(VSRuntimeLibDir) [file normalize $dir]
    }

    proc _FindVSRuntimeDir { version versionNum } {
        set pathTemplate "C:/%s/Microsoft Visual Studio/%s/%s/VC/Redist/MSVC"
        foreach edition [GetVSEditions] {
            foreach progFiles [list "Program Files (x86)" "Program Files"] {
                set path1 [format $pathTemplate $progFiles $version $edition]
                if { [file isdirectory $path1] } {
                    set dirList [lindex [GetDirList $path1 1 0  0 0] 0]
                    foreach dir $dirList {
                        set path2 [file join $dir [GetArchitecture]]
                        if { [file isdirectory $path2] } {
                            set path3 [file join $path2 "Microsoft.VC$versionNum.CRT"]
                            if { [file isdirectory $path3] } {
                                return $path3
                            }
                        }
                    }
                }
            }
        }
        return ""
    }

    proc GetVSRuntimeLibDir {} {
        variable sOpts

        if { [info exists sOpts(VSRuntimeLibDir)] } {
            set libPath $sOpts(VSRuntimeLibDir)
        } else {
            # If path to VS runtime libraries has not been specified with SetVSRuntimeLibDir,
            # use some heuristics to find the corresponding directory.
            set path "C:/Program Files (x86)/Microsoft Visual Studio %s/VC/redist/%s/Microsoft.VC%s.CRT"
            set version [GetCompilerVersion -vs]
            switch -exact -nocase $version {
                "vs2008"  { set version  "9.0" ; set versionNum  "90" }
                "vs2010"  { set version "10.0" ; set versionNum "100" }
                "vs2012"  { set version "11.0" ; set versionNum "110" }
                "vs2013"  { set version "12.0" ; set versionNum "120" }
                "vs2015"  { set version "14.0" ; set versionNum "140" }
                "vs2017"  { return [_FindVSRuntimeDir "2017" "141"] }
                "vs2019"  { return [_FindVSRuntimeDir "2019" "142"] }
                "vs2022"  { return [_FindVSRuntimeDir "2022" "143"] }
                "Windows" { return "" }
                default   { ErrorAppend "GetVSRuntimeLibDir: Unsupported compiler version \"$version\"" "FATAL" }
            }
            set libPath [format $path $version [GetArchitecture] $versionNum]
        }
        if { ! [file isdirectory $libPath] } {
            ErrorAppend "GetVSRuntimeLibDir: Runtime directory $libPath not found." "Warning"
            return ""
        }
        return $libPath
    }

    proc UseVisualStudio { { type "" } } {
        set count 1
        foreach version [GetCompilerVersions] {
            if { [string match "vs*" $version] } {
                if { $type eq "" || ( $count == 1 && $type eq "primary" ) } {
                    return true
                }
                if { $type eq "" || ( $count == 2 && $type eq "secondary" ) } {
                    return true
                }
            }
            incr count
        }
        return false
    }

    proc IsGccCompilerNewer { gccVersion } {
        if { [VersionCompare $gccVersion [GetGccCompilerVersion]] < 0 } {
            return true
        } else {
            return false
        }
    }

    proc GetMscVer {} {
        set version [GetCompilerVersion -vs]
        switch -exact -nocase $version {
            "vs2008" { set version "1500" }
            "vs2010" { set version "1600" }
            "vs2012" { set version "1700" }
            "vs2013" { set version "1800" }
            "vs2015" { set version "1900" }
            "vs2017" { set version "1910" }
            "vs2019" { set version "1920" }
            "vs2022" { set version "1930" }
            default  { ErrorAppend "GetMscVer: Unsupported compiler version \"$version\"" "FATAL" }
        }
        return $version
    }

    proc SetVcvarsProg { vcvarsProg } {
        variable sOpts

        if { ! [file isfile $vcvarsProg] || ! [file executable $vcvarsProg] } {
            ErrorAppend "SetVcvarsProg: Batch file vcvarsall.bat not found ($vcvarsProg)." "FATAL"
        }
        set sOpts(VcvarsProg) [file normalize $vcvarsProg]
    }

    proc GetVcvarsProg {} {
        variable sOpts

        if { [info exists sOpts(VcvarsProg)] } {
            return $sOpts(VcvarsProg)
        }

        # If path to vsvarsall.bat has not been specified with SetVcvarsProg,
        # use some heuristics to find the batch script.
        set vcvarsProg ""
        set pathTemplate(1) "C:/Program Files (x86)/Microsoft Visual Studio %s/VC/vcvarsall.bat"
        set pathTemplate(2) "C:/%s/Microsoft Visual Studio/%s/%s/VC/Auxiliary/Build/vcvarsall.bat"
        set version [GetCompilerVersion -vs]
        switch -exact -nocase $version {
            "vs2008" { set version  "9.0" ; set template 1 }
            "vs2010" { set version "10.0" ; set template 1 }
            "vs2012" { set version "11.0" ; set template 1 }
            "vs2013" { set version "12.0" ; set template 1 }
            "vs2015" { set version "14.0" ; set template 1 }
            "vs2017" { set version "2017" ; set template 2 }
            "vs2019" { set version "2019" ; set template 2 }
            "vs2022" { set version "2022" ; set template 2 }
            default  { ErrorAppend "GetVcvarsProg: Unsupported compiler version \"$version\"" "FATAL" }
        }
        if { $template == 1 } {
            set vcvarsProg [format $pathTemplate(1) $version]
            if { ! [file isfile $vcvarsProg] || ! [file executable $vcvarsProg] } {
                ErrorAppend "GetVcvarsProg: Batch file vcvarsall.bat not found ($vcvarsProg)." "FATAL"
            }
        } elseif { $template == 2 } {
            set found false
            foreach edition [GetVSEditions] {
                foreach progFiles [list "Program Files (x86)" "Program Files"] {
                    set vcvarsProg [format $pathTemplate(2) $progFiles $version $edition]
                    if { [file isfile $vcvarsProg] && [file executable $vcvarsProg] } {
                        return $vcvarsProg
                    }
                }
            }
            if { ! $found } {
                ErrorAppend "GetVcvarsProg: Batch file vcvarsall.bat not found ($vcvarsProg)." "FATAL"
            }
        } else {
            ErrorAppend "GetVcvarsProg: Unsupported template $template." "FATAL"
        }
        return $vcvarsProg
    }

    proc DosRun { libName originator buildDir cmd } {
        Log "DosRun (Caller: $originator)" 2
        Log "Shell          : [GetCmdShell]"  4 false

        if { [IsWindows] } {
            set vcvarsProg [GetVcvarsProg]

            if { [Is32Bit] } {
                set vcvarsParam "x86 [GetSdkVersion $libName]"
            } else {
                set vcvarsParam "x86_amd64 [GetSdkVersion $libName]"
            }
            set batchFile [_WriteDosBatchFile $libName $buildDir "_Bawt_DosRun_$originator" $cmd $vcvarsProg $vcvarsParam]
            Log "Environment    : $vcvarsProg $vcvarsParam" 4 false
 
        } else {
            set batchFile [_WriteMSysBatchFile $libName $buildDir "_Bawt_DosRun_$originator" $cmd]
        }

        Log "Build directory: $buildDir"  4 false
        _LogCmd $cmd

        set status "OK"
        set result "FATAL"
        try {
            set curDir [pwd]
            cd $buildDir
            if { [IsWindows] } {
                set result [eval exec [GetCmdShell] /d /c [list $batchFile]]
            } else {
                set result [eval exec [GetCmdShell] [list $batchFile]]
            }
            cd $curDir
        } trap NONE result {
            # $result now holds the message that was written to stderr and everything written to stdout
            append status " (Messages have been written to stderr)"
        } trap CHILDSTATUS { - opts } {
            # process $pid exited with non-zero exit code $status
            lassign [dict get $opts -errorcode] -> pid status
            set errorMsg [dict get $opts -errorinfo]
            ErrorAppend "DosRun: Error running command:\n$cmd\nError message:\n$errorMsg" $result
        }
        Log "Status: $status" 4 false
        WriteBuildLog $libName true $result
    }
}

namespace eval BawtMain {

    namespace export SetBawtUrl GetBawtUrl
    namespace export SetStartTime GetTotalTime
    namespace export SetBuildTime GetBuildTime
    namespace export SetBuildError GetBuildError
    namespace export SetIgnoreBuildError GetIgnoreBuildError
    namespace export SetWorkingSet AppendToWorkingSet GetWorkingSet
    namespace export SortLibsByDependencies SortLibsByDictionary
    namespace export GetLibs GetNumLibs GetLibName GetLibNumber GetLibIndex
    namespace export AppendLib PrintLibNames
    namespace export GenerateHtml
    namespace export GetUsageMsg PrintUsage GetVersion PrintVersion SetRemoteVersion
    namespace export HaveLibZipFile GetLibZipFile SetLibZipFile
    namespace export HaveLibBuildFile GetLibBuildFile SetLibBuildFile
    namespace export GetSetupFile SetSetupFile
    namespace export GetInputLibsDirs GetBawtLibInputDir AddInputLibsDir
    namespace export GetLibZipDir SetLibZipDir
    namespace export GetLibVersion SetLibVersion
    namespace export GetLibHomepage SetLibHomepage
    namespace export GetLibDependencies SetLibDependencies
    namespace export PrintLibDependency
    namespace export GetPlatforms SetPlatforms GetValidPlatforms IsSupportedPlatform
    namespace export GetWinCompilers SetWinCompilers
    namespace export GetSdkVersion SetSdkVersion
    namespace export GetScriptAuthorName GetScriptAuthorMail SetScriptAuthor
    namespace export CreateImportLibs CopyRuntimeLibs StripLibs 
    namespace export UseUserBuildFiles SetUserBuildFile GetUserBuildFile
    namespace export UseOnlineRepository
    namespace export GetEnvVars SetEnvVar AddEnvVar AddToPathEnv
    namespace export GetUseEnvVars UseEnvVar
    namespace export AppendBuildType GetBuildTypes
    namespace export SetExcludeOption GetExcludeOption
    namespace export SetExcludeCompiler GetExcludeCompiler
    namespace export SetWinCompiler GetWinCompiler UseWinCompiler
    namespace export SetInputRootDir GetInputRootDir
    namespace export SetInputResourceDir GetInputResourceDir
    namespace export SetOutputRootDir GetOutputRootDir
    namespace export SetOutputToolsDir GetOutputToolsDir
    namespace export GetBootstrapDir
    namespace export ExtractLibrary
    namespace export AddPath GetPathes SetPathes
    namespace export ModificationTime GetModificationTime
    namespace export HashKey GetHashKey
    namespace export GetVersionFromFileName
    namespace export AddIncludePath Include Setup
    namespace export PrintSummary

    proc _Init {} {
        variable sOpts

        SetInputRootDir    [file dirname [info script]]
        SetOutputRootDir   [file join [pwd] "BawtBuild"]

        CreateImportLibs    true
        CopyRuntimeLibs     true
        StripLibs           true
        UseOnlineRepository true
        UseUserBuildFiles   true
        GenerateHtml        false

        if { $::tcl_platform(pointerSize) == 8 } {
            SetArchitecture "x64"
        } else {
            SetArchitecture "x86"
        }
        SetCompilerVersions "gcc"
        SetStartTime
        SetSetupFile ""
        AddIncludePath      [file join [GetInputRootDir] "Setup"] false
        AddInputLibsDir     [file join [GetInputRootDir] "InputLibs"] false
        AddInputLibsDir     [file join [pwd] "InputLibs"] false
        SetInputResourceDir [file join [GetInputRootDir] "Resources"]
        SetBawtUrl          "http://www.bawt.tcl3d.org/download"

        set sOpts(EnvVarPath) [list]
        set sOpts(Path)       [list]
        set sOpts(WorkingSet) [list]
        set sOpts(LibNames)   [list]
        set sOpts(BuildTypes,ForceBuildType) [list]
    }

    proc GetBawtUrl {} {
        variable sOpts

        return $sOpts(BawtUrl)
    }

    proc SetBawtUrl { url } {
        variable sOpts

        set sOpts(BawtUrl) $url
    }

    proc SetStartTime {} {
        variable sOpts

        set sOpts(StartTime) [clock clicks -milliseconds]
    }

    proc GetTotalTime {} {
        variable sOpts

        return [expr [clock clicks -milliseconds] - $sOpts(StartTime)]
    }

    proc SetBuildTime { libName buildTime } {
        variable sOpts

        set sOpts(BuildTime,$libName) $buildTime
    }

    proc GetBuildTime { libName } {
        variable sOpts

        if { [info exists sOpts(BuildTime,$libName)] } {
            return $sOpts(BuildTime,$libName)
        } else {
            return -1.0
        }
    }

    proc SetBuildError { libName buildError } {
        variable sOpts

        set sOpts(BuildError,$libName) $buildError
    }

    proc GetBuildError { libName } {
        variable sOpts

        if { [info exists sOpts(BuildError,$libName)] } {
            return $sOpts(BuildError,$libName)
        } else {
            return ""
        }
    }

    proc SetIgnoreBuildError { libName onOff } {
        variable sOpts

        set sOpts(IgnoreBuildError,$libName) $onOff
    }

    proc GetIgnoreBuildError { libName } {
        variable sOpts

        if { [info exists sOpts(IgnoreBuildError,$libName)] } {
            return $sOpts(IgnoreBuildError,$libName)
        } else {
            return false
        }
    }

    proc SetWorkingSet { libNameList } {
        variable sOpts

        set sOpts(WorkingSet) $libNameList
    }

    proc AppendToWorkingSet { libName } {
        variable sOpts

        lappend sOpts(WorkingSet) $libName
    }

    proc GetWorkingSet {} {
        variable sOpts

        return $sOpts(WorkingSet)
    }

    proc _lremove { list item } {
        return [lsearch -all -inline -not -exact -nocase $list $item]
    }

    proc SortLibsByDictionary {} {
        variable sOpts

        Log "SortLibsByDictionary"

        set sOpts(LibNames) [lsort -dictionary [GetLibs]]
    }

    proc PrintLibDependency { libName } {
        set depList [list]
        foreach lib [GetLibs] {
            set dependencies [GetLibDependencies $lib]
            if { [lsearch -exact -nocase $dependencies $libName] >= 0 } {
                lappend depList $lib
            }
        }
        puts "Libraries depending on $libName:"
        foreach lib [lsort -dictionary $depList] {
            puts "  $lib"
        }
    }

    proc SortLibsByDependencies {} {
        variable sOpts

        Log "SortLibsByDependencies"

        set sortedList [list]
        set lastList   [list]

        foreach libName [GetLibs] {
            set dependencies [GetLibDependencies $libName]
            if { [lsearch -exact -nocase $dependencies $libName] >= 0 } {
                ErrorAppend "$libName depends on itself" "FATAL"
            }
            if { [lsearch -exact -nocase $dependencies "All"] >= 0 } {
                lappend lastList $libName
            } else {
                set sLibs($libName) $dependencies
            }
        }

        set iteration 1
        set oldSize [array size sLibs]
        while { [array size sLibs] > 0 } {
            # puts "Iteration $iteration: [array size sLibs]"
            # parray sLibs
            # First loop: Copy all libraries with no (more) dependencies into sorted list.
            foreach libName [lsort [array names sLibs]] {
                if { [llength $sLibs($libName)] == 0 } {
                    lappend sortedList $libName
                    unset sLibs($libName)
                    # Second loop: Remove all occurrences of copied library in dependencies list.
                    foreach lib [array names sLibs] {
                        set sLibs($lib) [_lremove $sLibs($lib) $libName]
                    }
                }
            }
            if { $oldSize == [array size sLibs] } {
                foreach lib [lsort -dictionary [array names sLibs]] {
                    Log "Library $lib depends on $sLibs($lib), which is not included in build file." 2 false
                }
                ErrorAppend "Error in dependencies" "FATAL"
                break
            }
            set oldSize [array size sLibs]
            incr iteration
        }
        set sOpts(LibNames) [concat $sortedList $lastList]
    }

    proc GetLibIndex { libName } {
        return [lsearch -nocase -exact [GetLibs] $libName]
    }

    proc GetLibNumber { libName } {
        return [expr [GetLibIndex $libName] + 1]
    }

    proc GetLibName { libNumber } {
        return [lindex [GetLibs] [expr $libNumber - 1]]
    }

    proc AppendLib { libName } {
        variable sOpts

        lappend sOpts(LibNames) $libName
    }

    proc GetLibs {} {
        variable sOpts

        return $sOpts(LibNames)
    }

    proc GetNumLibs {} {
        return [llength [GetLibs]]
    }

    proc GenerateHtml { { onOff "" } } {
        variable sOpts

        if { $onOff eq "" } {
            return $sOpts(GenerateHtml)
        } else {
            set sOpts(GenerateHtml) $onOff
        }
    }

    proc PrintLibNames {} {
        # First determine maximum string length of each column for pretty output.
        set typeList [list # Name Version Platforms Compilers Dependencies ScriptAuthor Homepage Stages]
        foreach type $typeList {
            set max($type) [string length $type]
        }
        set count 0
        foreach libName [GetLibs] {
            set opt($count,#)       [GetLibNumber  $libName]
            set opt($count,Name)    $libName
            set opt($count,Version) [GetLibVersion $libName]

            set opt($count,Platforms)    [join [GetPlatforms $libName]]
            set opt($count,Compilers)    [join [GetWinCompilers $libName]]
            set opt($count,Dependencies) [join [GetLibDependencies $libName]]
            set opt($count,ScriptAuthor) [GetScriptAuthorName $libName]
            set opt($count,Homepage)     [GetLibHomepage $libName]
            set opt($count,Stages)       [GetUsedStages $libName]
            
            foreach type $typeList {
                if { [string length $opt($count,$type)] > $max($type) } {
                    set max($type) [string length $opt($count,$type)]
                }
            }
            incr count
        }

        # Output header line.
        puts -nonewline [format "%$max(#)s: %-$max(Name)s %-$max(Version)s" "#" "Name" "Version"]
        foreach option [GetCheckOptions] {
            if { [info exists opt(0,$option)] } {
                puts -nonewline [format " %-$max($option)s" $option]
            }
        }
        puts ""
        puts -nonewline [format "%s--%s-%s" \
             [string repeat "-" $max(#)] [string repeat "-" $max(Name)] [string repeat "-" $max(Version)]]
        foreach option [GetCheckOptions] {
            if { [info exists opt(0,$option)] } {
                puts -nonewline [format "%s" [string repeat "-" $max($option)]]
            }
        }
        puts ""

        # Output information line for each library.
        set count 0
        foreach libName [GetLibs] {
            puts -nonewline [format "%$max(#)d: %-$max(Name)s %-$max(Version)s" \
                 $opt($count,#) $opt($count,Name) $opt($count,Version)]
            foreach option [GetCheckOptions] {
                if { [info exists opt($count,$option)] } {
                    if { $option eq "Homepage" && [GenerateHtml] } {
                        puts -nonewline [format " <a href=\"%s\" target=\"_%s\">%s</a>" \
                             $opt($count,$option) $libName $opt($count,$option)]
                    } else {
                        puts -nonewline [format " %-$max($option)s" $opt($count,$option)]
                    }
                }
            }
            puts ""
            incr count
        }
        _PrintErrorsAndWarnings
    }

    proc GetUsageMsg {} {
        set msg ""
        append msg "\n"
        append msg "Usage: Bawt.tcl \[Options\] SetupFile LibraryName \[LibraryNameN\]\n"
        append msg "\n"
        append msg "Start the BAWT automatic library build process.\n"
        append msg "When using \"all\" as target library name, all libraries specified\n"
        append msg "in the setup file are built.\n"
        append msg "It is also possible to specify the numbers of the libraries as printed\n"
        append msg "by option \"--list\" or specify a range of numbers (e.g: 2-5).\n"
        append msg "Note, that at least either a list or build action option must be specified.\n"
        append msg "\n"
        append msg "General options:\n"
        append msg "--help          : Print this help message and exit.\n"
        append msg "--version       : Print version number and exit.\n"
        append msg "--procs         : Print all available procedures and exit.\n"
        append msg "--proc <string> : Print documentation of specified procedure and exit.\n"
        append msg "--loglevel <int>: Specify log message verbosity.\n"
        append msg "                  Choices: 0 - 4. Default: [GetLogLevel].\n"
        append msg "--nologtime     : Do not write time strings with log messages.\n"
        append msg "                  Default: Write time strings.\n"
        append msg "--logviewer     : Start graphical log viewer program BawtLogViewer.\n"
        append msg "                  Only working, if log level is greater than 1. Default: No.\n"
        append msg "\n"
        append msg "List action options:\n"
        append msg "--list          : Print all available library names and versions and exit.\n"
        append msg "--platforms     : Additionally print supported platforms.\n"
        append msg "--wincompilers  : Additionally print supported Windows compilers.\n"
        append msg "--authors       : Additionally print script authors.\n"
        append msg "--homepages     : Additionally print library homepages.\n"
        append msg "--dependencies  : Additionally print library dependencies.\n"
        append msg "--dependency    : Print dependencies of specified target libraries.\n"
        append msg "\n"
        append msg "Build action options:\n"
        append msg "--clean     : Clean library specific build and install directories.\n"
        append msg "--extract   : Extract library source from a ZIP file or a directory.\n"
        append msg "\n"
        append msg "--configure : Perform the configure stage of the build process.\n"
        append msg "--compile   : Perform the compile stage of the build process.\n"
        append msg "--distribute: Perform the distribution stage of the build process.\n"
        append msg "\n"
        append msg "--finalize  : Generate environment file and call user supplied Finalize procedure.\n"
        append msg "--complete  : Perform the following stages in order:\n"
        append msg "              clean, extract, configure, compile, distribute, finalize.\n"
        append msg "\n"
        append msg "--update    : Perform necessary stages depending on modification times.\n"
        append msg "              Note: Global stage finalize is always executed.\n"
        append msg "--simulate  : Simulate update action without actually building libraries.\n"
        append msg "--touch     : Set modification times of library build directories to current time.\n"
        append msg "\n"
        append msg "Build configuration options:\n"
        append msg "--architecture <string>: Build for specified processor architecture.\n"
        append msg "                         Choices: [GetValidArchitectures].\n"
        append msg "                         Default: [GetArchitecture].\n"
        append msg "--compiler <string>    : Build with specified compiler version.\n"
        append msg "                         Choices: gcc vs2008 vs2010 vs2012 vs2013 vs2015 vs2017 vs2019 vs2022.\n"
        append msg "                         Specify primary and secondary compiler by adding a plus sign\n"
        append msg "                         in between. Example: gcc+vs2013.\n"
        append msg "                         Default: [GetCompilerVersion].\n"
        append msg "--gccversion <string>  : Build with specified MinGW gcc version. Windows only.\n"
        append msg "                         Choices: 4.9.2 5.2.0 7.2.0 8.1.0.\n"
        append msg "                         Default: [GetMingwGccVersion].\n"
        append msg "--msysversion <string> : Build with specified MSYS version. Windows only.\n"
        append msg "                         Choices: 1 2.\n"
        append msg "                         Default: Version 2 if available, otherwise version 1.\n"
        append msg "--tclversion <string>  : Build Tcl, Tk and Tclkit for specified version.\n"
        append msg "                         Choices: 8.6.7 8.6.8 8.6.9 8.6.10 8.6.11 8.6.12 8.7.a5.\n"
        append msg "                         Default: [GetTclVersion].\n"
        append msg "--tkversion <string>   : Build Tk and Tclkit for specified version.\n"
        append msg "                         Choices: 8.6.7 8.6.8 8.6.9 8.6.10 8.6.11 8.6.12 8.7.a5.\n"
        append msg "                         Default: [GetTkVersion].\n"
        append msg "--imgversion <string>  : Build Img for specified version.\n"
        append msg "                         Choices: 1.4.9 1.4.10 1.4.11 1.4.13 1.5.0.\n"
        append msg "                         Default: [GetImgVersion].\n"
        append msg "--osgversion <string>  : Build OpenSceneGraph for specified version.\n"
        append msg "                         Choices: 3.4.1 3.6.4 3.6.5.\n"
        append msg "                         Default: [GetOsgVersion].\n"
        append msg "--buildtype <string>   : Use specified build type.\n"
        append msg "                         Choices: [GetValidBuildTypes].\n"
        append msg "                         Default: Specified in setup file.\n"
        append msg "--exclude <string>     : Force exclusion of build for specified library name.\n"
        append msg "\n"
        append msg "--wincc <lib> <string> : Use specified Windows compiler, if supported by build script.\n"
        append msg "                         Choices: \"gcc\" \"vs\".\n"
        append msg "--sdk <lib> <string>   : Use specified Microsoft SDK version.\n"
        append msg "                         To use the SDK version for all libraries,\n"
        append msg "                         specify \"all\" as library name.\n"
        append msg "--copt <lib> <string>  : Specify library specific configuration option.\n"
        append msg "--user <lib> <string>  : Specify library specific user build file.\n"
        append msg "\n"
        append msg "--url <string>         : Specify BAWT download server.\n"
        append msg "                         Default: [GetBawtUrl].\n"
        append msg "--toolsdir <string>    : Specify directory containing MSys/MinGW.\n"
        append msg "                         Default: [GetOutputToolsDir].\n"
        append msg "--rootdir <string>     : Specify build output root directory.\n"
        append msg "                         Default: [GetOutputRootDir].\n"
        append msg "--libdir <string>      : Add a directory containing library source and build files.\n"
        append msg "                         Default: [GetInputLibsDirs].\n"
        append msg "--distdir <string>     : Specify distribution root directory.\n"
        append msg "                         Default: [GetOutputDistDir].\n"
        append msg "--finalizefile <string>: Specify file with user supplied Finalize procedure.\n"
        append msg "                         Default: None.\n"
        append msg "\n"
        append msg "--sort <string>        : Sort libraries according to specified sorting mode.\n"
        append msg "                         Choices: [GetValidSortModes].\n"
        append msg "                         Default: [lindex [GetValidSortModes] 0].\n"
        append msg "--noversion            : Do not use version number for Tcl package directories.\n"
        append msg "                         Default: Library name and version number.\n"
        append msg "--noexit               : Do not exit build process after fatal error, but try to continue.\n"
        append msg "                         Default: Exit build process after a fatal error.\n"
        append msg "--noimportlibs         : Do not create import libraries on Windows.\n"
        append msg "                         Default: Create import libraries. Needs Visual Studio.\n"
        append msg "--noruntimelibs        : Do not copy VisualStudio runtime libraries.\n"
        append msg "                         Default: Copy runtime libraries. Needs Visual Studio.\n"
        append msg "--nostrip              : Do not strip libraries in distribution directory.\n"
        append msg "                         Default: Strip libraries.\n"
        append msg "--noonline             : Do not check or download from online repository.\n"
        append msg "                         Default: Use [GetBawtUrl].\n"
        append msg "--norecursive          : Do not check recursive dependencies.\n"
        append msg "                         Default: Use recursive dependencies.\n"
        append msg "--nosubdirs            : Do not create compiler and architecture sub directories.\n"
        append msg "                         Default: Create compiler and architecture sub directories.\n"
        append msg "--nouserbuilds         : Do not consider user build files.\n"
        append msg "                         Default: User build files: \"LibraryName_User.bawt\".\n"
        append msg "\n"
        append msg "--iconfile <string>    : Use specified icon file for tclkits and starpacks.\n"
        append msg "                         Default: Standard tclkit icon. Windows only.\n"
        append msg "--resourcefile <string>: Use specified resource file for tclkits and starpacks.\n"
        append msg "                         Default: Standard tclkit resource file. Windows only.\n"
        append msg "\n"
        append msg "--numjobs <int>        : Number of parallel compile jobs.\n"
        append msg "                         Default: [GetNumJobs]\n"
        append msg "--timeout <float>      : Number of seconds to try renaming or deleting directories.\n"
        append msg "                         Default: [GetTimeout s]\n"
        return $msg
    }

    proc PrintUsage { { msg "" } } {
        if { $msg ne "" } {
            puts "ERROR: $msg"
        }
        puts [GetUsageMsg]
    }

    proc GetVersion {} {
        return "2.1.0"
    }

    proc PrintVersion { { versionNumOnly false } } {
        set versionNum [GetVersion]
        if { $versionNumOnly } {
            puts "$versionNum"
        } else {
            puts "BAWT $versionNum"
            puts "Copyright 2016-2021 Paul Obermeier"
        }
    }

    proc SetRemoteVersion { versionNum } {
        if { [GetMajor $versionNum] !=  [GetMajor [GetVersion]] } {
            ErrorAppend "Remote major version $versionNum different to major local version [GetVersion]" "FATAL"
        } elseif { [GetMinor $versionNum] !=  [GetMinor [GetVersion]] } {
            ErrorAppend "Remote minor version $versionNum different to minor local version [GetVersion]" "FATAL"
        } else {
            if { [VersionCompare $versionNum [GetVersion]] > 0 } {
                ErrorAppend "Remote version $versionNum newer than local version [GetVersion]" "Warning"
            }
        }
    }

    proc GetSetupFile {} {
        variable sOpts

        return $sOpts(SetupFile)
    }

    proc SetSetupFile { fileName } {
        variable sOpts

        set sOpts(SetupFile) [file normalize $fileName]
    }

    proc GetInputLibsDirs {} {
        variable sOpts

        return $sOpts(InputLibs)
    }

    proc GetBawtLibInputDir {} {
        return [lindex [GetInputLibsDirs] end]
    }

    proc AddInputLibsDir { dir { useLog true } } {
        variable sOpts

        set normDir [file normalize $dir]
        if { ! [info exists sOpts(InputLibs)] } {
            set sOpts(InputLibs) [list]
        }
        if { [lsearch -exact $sOpts(InputLibs) $normDir] < 0 } {
            set sOpts(InputLibs) [linsert $sOpts(InputLibs) 0 $normDir]
            if { $useLog } {
                Log "AddInputLibsDir $normDir"
            }
        }
    }

    proc HaveLibZipFile { libName } {
        variable sOpts

        return [info exists sOpts($libName,ZipFile)]
    }

    proc GetLibZipFile { libName } {
        variable sOpts

        return $sOpts($libName,ZipFile)
    }

    proc SetLibZipFile { libName zipFile } {
        variable sOpts

        set sOpts($libName,ZipFile) $zipFile
    }

    proc HaveLibBuildFile { libName } {
        variable sOpts

        return [info exists sOpts($libName,BuildFile)]
    }

    proc GetLibBuildFile { libName } {
        variable sOpts

        return $sOpts($libName,BuildFile)
    }

    proc SetLibBuildFile { libName buildFile } {
        variable sOpts

        set sOpts($libName,BuildFile) $buildFile
    }

    proc GetLibZipDir { libName } {
        variable sOpts

        return $sOpts($libName,ZipDir)
    }

    proc SetLibZipDir { libName zipDir } {
        variable sOpts

        set sOpts($libName,ZipDir) $zipDir
    }

    proc GetLibVersion { libName } {
        variable sOpts

        if { [info exists sOpts($libName,Version)] } {
            return $sOpts($libName,Version)
        } else {
            return ""
        }
    }

    proc SetLibVersion { libName version } {
        variable sOpts

        set sOpts($libName,Version) $version
    }

    proc GetLibHomepage { libName } {
        variable sOpts

        if { [info exists sOpts($libName,Homepage)] } {
            return $sOpts($libName,Homepage)
        } else {
            return ""
        }
    }

    proc SetLibHomepage { libName url } {
        variable sOpts

        set sOpts($libName,Homepage) $url
    }
    
    proc GetLibDependencies { libName } {
        variable sOpts

        if { [info exists sOpts($libName,Dependencies)] } {
            if { $sOpts($libName,Dependencies) eq "None" } {
                return [list]
            } else {
                return $sOpts($libName,Dependencies)
            }
        } else {
            return [list]
        }
    }

    proc SetLibDependencies { libName args } {
        variable sOpts

        set sOpts($libName,Dependencies) [list]
        foreach arg $args {
            if { $arg ne "" } {
                lappend sOpts($libName,Dependencies) $arg
            }
        }
    }

    proc GetPlatforms { libName } {
        variable sOpts

        if { [info exists sOpts($libName,Platforms)] } {
            return $sOpts($libName,Platforms)
        } else {
            return [list]
        }
    }

    proc GetValidPlatforms {} {
        return [list "Windows" "Linux" "Darwin"]
    }

    proc SetPlatforms { libName args } {
        variable sOpts

        foreach arg $args {
            if { [string equal -nocase "All" $arg] } {
                set sOpts($libName,Platforms) [GetValidPlatforms]
                break
            }
            switch -exact -nocase -- $arg {
                "Windows" { set platform "Windows" }
                "Linux"   { set platform "Linux" }
                "Darwin"  { set platform "Darwin" }
                default   { ErrorAppend "Unknown platform $arg" "FATAL" }
            }
            lappend sOpts($libName,Platforms) $arg
        }
    }

    proc IsSupportedPlatform { libName } {
        if { [lsearch -exact [GetPlatforms $libName] [GetPlatformName]] >= 0 } {
            return true
        }
        return false
    }

    proc GetWinCompilers { libName } {
        variable sOpts

        set libName [string tolower $libName]
        if { [info exists sOpts($libName,WinCompilers)] } {
            return $sOpts($libName,WinCompilers)
        } else {
            return [list]
        }
    }

    proc SetWinCompilers { libName args } {
        variable sOpts

        set libName [string tolower $libName]
        if { ! [IsWindows] } {
            set sOpts($libName,WinCompilers) [list "gcc"]
            SetWinCompiler $libName "gcc"
            return
        }
        foreach arg $args {
            switch -exact -nocase -- $arg {
                "gcc"   { set compiler "gcc" }
                "vs"    { set compiler "vs" }
                default { ErrorAppend "Unknown Windows compiler $arg" "FATAL" }
            }
            lappend sOpts($libName,WinCompilers) $arg
        }
        set numWinCompilersSupported [llength $sOpts($libName,WinCompilers)]
        set numWinCompilersGlobal    [llength [GetCompilerVersions]]
        if { $numWinCompilersSupported > 0 && \
             $numWinCompilersGlobal > 0 && \
             [GetWinCompiler $libName] eq "" } {
            # Build script has specified supported Windows compiler(s) in the Init procedure.
            # Currently supported Windows compiler are: "vs" or "gcc".
            # Check the Windows compilers to be used globally (as specified with option "--compiler")
            # and determine the compiler to be used for this library:
            #   - Build script supports only gcc.
            #   - Build script supports only vs.
            #   - Build script supports both gcc and vs.
            #
            # Command line option   |        SetWinCompilers               |
            #                       | gcc         | vs          | gcc vs   |
            # --------------------------------------------------------------
            # --compiler gcc        | (1) gcc     |  (2) Exclude | (5) gcc |
            # --compiler vs20XX     | (3) Exclude |  (4) vs      | (6) vs  |
            # --compiler gcc+vs20XX | (9) gcc     | (10) vs      | (7) gcc |
            # --compiler vs20XX+gcc | (9) gcc     | (10) vs      | (8) vs  |

            if { $numWinCompilersGlobal == 1 } {
                set globalCompiler [lindex [GetCompilerVersions] 0]
                if { $numWinCompilersSupported == 1 } {
                    set scriptCompiler [lindex $sOpts($libName,WinCompilers) 0]
                    if { $globalCompiler eq "gcc" && $scriptCompiler eq "gcc" } {
                        SetWinCompiler $libName "gcc"                    ; # (1)
                    }
                    if { $globalCompiler eq "gcc" && [string match "vs*" $scriptCompiler] } {
                        SetExcludeCompiler $libName "gcc not supported"  ; # (2)
                    }
                    if { [string match "vs*" $globalCompiler] && $scriptCompiler eq "gcc" } {
                        SetExcludeCompiler $libName "vs not supported"   ; # (3)
                    }
                    if { [string match "vs*" $globalCompiler] && [string match "vs*" $scriptCompiler] } {
                        SetWinCompiler $libName "vs"                     ; # (4)
                    }
                } else {
                    if { $globalCompiler eq "gcc" } {
                        SetWinCompiler $libName "gcc"                    ; # (5)
                    } else {
                        SetWinCompiler $libName "vs"                     ; # (6)
                    }
                }
            } else {
                if { $numWinCompilersSupported == 1 } {
                    set scriptCompiler [lindex $sOpts($libName,WinCompilers) 0]
                    if { $scriptCompiler eq "gcc" } {
                        SetWinCompiler $libName "gcc"                    ; # (7)
                    } else {
                        SetWinCompiler $libName "vs"                     ; # (8)
                    }
                } else {
                    set globalCompiler [lindex [GetCompilerVersions] 0]
                    if { $globalCompiler eq "gcc" } {
                        SetWinCompiler $libName "gcc"                    ; # (9)
                    } else {
                        SetWinCompiler $libName "vs"                     ; # (10)
                    }
                }
            }
        }
    }

    proc GetSdkVersion { libName } {
        variable sOpts

        set libName [string tolower $libName]
        if { [info exists sOpts($libName,SdkVersion)] } {
            return $sOpts($libName,SdkVersion)
        } elseif { [info exists sOpts(all,SdkVersion)] } {
            return $sOpts(all,SdkVersion)
        } else {
            return ""
        }
    }

    proc SetSdkVersion { libName version } {
        variable sOpts

        set libName [string tolower $libName]
        set sOpts($libName,SdkVersion) $version
    }

    proc GetScriptAuthorName { libName } {
        variable sOpts

        if { [info exists sOpts($libName,Author,Name)] } {
            return $sOpts($libName,Author,Name)
        } else {
            return "Unknown"
        }
    }

    proc GetScriptAuthorMail { libName } {
        variable sOpts

        if { [info exists sOpts($libName,Author,Mail)] } {
            return $sOpts($libName,Author,Mail)
        } else {
            return "Unknown"
        }
    }

    proc SetScriptAuthor { libName name mail } {
        variable sOpts

        set sOpts($libName,Author,Name) $name
        set sOpts($libName,Author,Mail) $mail
    }

    proc CreateImportLibs { { onOff "" } } {
        variable sOpts

        if { $onOff eq "" } {
            return $sOpts(CreateImportLibs)
        } else {
            set sOpts(CreateImportLibs) $onOff
        }
    }

    proc CopyRuntimeLibs { { onOff "" } } {
        variable sOpts

        if { $onOff eq "" } {
            return $sOpts(CopyRuntimeLibs)
        } else {
            set sOpts(CopyRuntimeLibs) $onOff
        }
    }

    proc StripLibs { { onOff "" } } {
        variable sOpts

        if { $onOff eq "" } {
            return $sOpts(StripLibs)
        } else {
            set sOpts(StripLibs) $onOff
        }
    }

    proc UseOnlineRepository { { onOff "" } } {
        variable sOpts

        if { $onOff eq "" } {
            return $sOpts(UseOnlineRepository)
        } else {
            set sOpts(UseOnlineRepository) $onOff
        }
    }

    proc UseUserBuildFiles { { onOff "" } } {
        variable sOpts

        if { $onOff eq "" } {
            return $sOpts(UseUserBuildFiles)
        } else {
            set sOpts(UseUserBuildFiles) $onOff
        }
    }

    proc SetUserBuildFile { libName userBuildFile } {
        variable sUserBuildFiles

        set fileFound false
        set fileName $userBuildFile
        if { ! [file exists $fileName] } {
            if { [file pathtype $fileName] ne "absolute" } {
                foreach dir [GetInputLibsDirs] {
                    set fileName [file join $dir $userBuildFile]
                    if { [file exists $fileName] } {
                        set fileFound true
                        break
                    }
                }
            }
        } else {
            set fileName [file normalize $userBuildFile]
            set fileFound true
        }
        if { ! $fileFound } {
            ErrorAppend "SetUserBuildFile: User build file $userBuildFile does not exist" "FATAL"
        }

        set libName [string tolower $libName]
        set sUserBuildFiles($libName) $fileName
    }

    proc GetUserBuildFile { libName } {
        variable sUserBuildFiles

        set libName [string tolower $libName]
        if { ! [info exists sUserBuildFiles] || ! [info exists sUserBuildFiles($libName)] } {
            return ""
        }
        return $sUserBuildFiles($libName)
    }

    proc SetEnvVar { varName varValue } {
        variable sOpts

        Log "Environment : $varName=$varValue" 2 false
        set sOpts(EnvVars,$varName) $varValue
    }

    proc AddEnvVar { varName varValue } {
        variable sOpts

        lappend sOpts(EnvVars,$varName) $varValue
    }

    proc AddToPathEnv { varValue } {
        variable sOpts

        if { [lsearch -exact $sOpts(EnvVarPath) $varValue] < 0 } {
            Log "AddToPathEnv : $varValue" 2 false
            lappend sOpts(EnvVarPath) $varValue
        }
    }

    proc GetEnvVars {} {
        variable sOpts

        set msg ""
        foreach key [array names sOpts "EnvVars,*"] {
            set envVar [lindex [split $key ","] 1]
            if { [IsWindows] } {
                append msg "SETX $envVar \"$sOpts($key)\"\n"
            } else {
                append msg "export $envVar=\"$sOpts($key)\"\n"
            }
        }
        append msg "\n"
        if { [IsWindows] } {
            append msg "SETX BAWT_PATH \""
        } else {
            append msg "export BAWT_PATH=\""
        }
        foreach val $sOpts(EnvVarPath) {
            if { [IsWindows] } {
                append msg "$val;"
            } else {
                append msg "$val:"
            }
        }
        append msg "\"\n"
        if { [IsUnix] } {
            append msg "\n"
            append msg "export LD_LIBRARY_PATH=\"\$LD_LIBRARY_PATH:[GetOutputDevDir]/lib\""
            append msg "\n"
            append msg "export PATH=\"\$PATH:\$BAWT_PATH\""
        }
        return $msg
    }

    proc UseEnvVar { varName varValue } {
        variable sOpts

        set sOpts(UseEnvVars,$varName) $varValue
        set ::env($varName) $varValue
    }

    proc GetUseEnvVars {} {
        variable sOpts

        set envList [list]
        foreach key [array names sOpts "UseEnvVars,*"] {
            set envVar [lindex [split $key ","] 1]
            lappend envList $envVar $sOpts($key)
        }
        return $envList
    }

    proc ClearBuildType { libName } {
        variable sOpts

        set sOpts(BuildTypes,$libName) [list]
    }

    proc AppendBuildType { libName buildType } {
        variable sOpts

        if { $buildType eq "Release" || $buildType eq "Debug" } {
            if { ! [info exists sOpts(BuildTypes,$libName)] || \
                 [lsearch -exact $sOpts(BuildTypes,$libName) $buildType] < 0 } {
                lappend sOpts(BuildTypes,$libName) $buildType
            }
        } else {
            ErrorAppend "Unknown build type $buildType" "FATAL"
        }
    }

    proc GetBuildTypes { libName } {
        variable sOpts

        return $sOpts(BuildTypes,$libName)
    }

    proc SetExcludeOption { libName option } {
        variable sOpts

        set libName [string tolower $libName]
        set sOpts(ExcludeOption,$libName) $option
    }

    proc GetExcludeOption { libName } {
        variable sOpts

        set libName [string tolower $libName]
        if { [info exists sOpts(ExcludeOption,$libName)] } {
            return $sOpts(ExcludeOption,$libName)
        } else {
            return ""
        }
    }

    proc SetExcludeCompiler { libName compiler } {
        variable sOpts

        set libName [string tolower $libName]
        set sOpts(ExcludeCompiler,$libName) $compiler
    }

    proc GetExcludeCompiler { libName } {
        variable sOpts

        set libName [string tolower $libName]
        if { [info exists sOpts(ExcludeCompiler,$libName)] } {
            return $sOpts(ExcludeCompiler,$libName)
        } else {
            return ""
        }
    }

    proc SetWinCompiler { libName winCompiler } {
        variable sOpts

        set libName [string tolower $libName]
        set sOpts(WinCompiler,$libName) $winCompiler
    }

    proc GetWinCompiler { libName } {
        variable sOpts

        set libName [string tolower $libName]
        set retVal ""
        if { [info exists sOpts(WinCompiler,$libName)] } {
            set winCompiler $sOpts(WinCompiler,$libName)
            if { [lsearch $sOpts($libName,WinCompilers) $winCompiler] < 0 } {
                set retVal "Unsupported"
            }
            set retVal $winCompiler
        }
        return $retVal
    }

    proc UseWinCompiler { libName winCompiler } {
        if { $winCompiler ne "gcc" && $winCompiler ne "vs" } {
            ErrorAppend "Unknown Windows compiler $winCompiler" "FATAL"
            return
        }
        set libName [string tolower $libName]
        if { [IsWindows] && ( [GetWinCompiler $libName] eq $winCompiler ) } {
            return true
        } else {
            return false
        }
    }

    proc SetInputRootDir { dir } {
        variable sOpts

        set sOpts(BawtRootDir) [file normalize $dir]
    }

    proc GetInputRootDir {} {
        variable sOpts

        return $sOpts(BawtRootDir)
    }

    proc SetInputResourceDir { dir } {
        variable sOpts

        set sOpts(BawtResourceDir) [file normalize $dir]
    }

    proc GetInputResourceDir {} {
        variable sOpts

        return $sOpts(BawtResourceDir)
    }

    proc SetOutputRootDir { dir } {
        variable sOpts

        set sOpts(BawtBuildDir) [file normalize $dir]
    }

    proc GetOutputRootDir {} {
        variable sOpts

        return $sOpts(BawtBuildDir)
    }

    proc SetOutputToolsDir { dir } {
        variable sOpts

        set sOpts(BawtToolsDir) [file normalize $dir]
    }

    proc GetOutputToolsDir {} {
        variable sOpts

        if { ! [info exists sOpts(BawtToolsDir)] } {
            return [file join [GetOutputRootDir] "Tools"]
        } else {
            return $sOpts(BawtToolsDir)
        }
    }

    proc GetBootstrapDir {} {
        return [file join [GetInputRootDir] "Bootstrap-[GetPlatformName]"]
    }

    proc ExtractLibrary { libName targetDir } {
        if { ! [HaveLibZipFile $libName] } {
            ErrorAppend "ExtractLibrary: No directory or ZIP file specified for library $libName" "FATAL"
            return
        }
        set zipFileOrDir [file join [GetInputRootDir] [GetLibZipDir $libName] [GetLibZipFile $libName]]
        set haveDir false
        if { [file isdirectory $zipFileOrDir] } {
            set haveDir true
        } elseif { ! [file exists $zipFileOrDir] } {
            ErrorAppend "ExtractLibrary: Directory or ZIP file $zipFileOrDir does not exist" "FATAL"
            return
        }

        Log "ExtractLibrary" 2
        if { [file isdirectory $targetDir] } {
            file delete -force $targetDir
        }
        if { $haveDir } {
            Log "Directory       : $zipFileOrDir"   4 false
        } else {
            Log "ZIP file        : $zipFileOrDir"   4 false
        }
        Log "Target directory: $targetDir" 4 false

        # Target directory has library name and version as last path component.
        # The ZIP file may have either just the library name or the library name
        # and version as root directory.
        # So we extract the ZIP file in the directory above targetDir and rename
        # the extracted directory to the library name, if it contains the version.
        if { $haveDir } {
            MultiFileCopy $zipFileOrDir $targetDir "*" true
        } else {
            set rootDir [file dirname $targetDir]
            Unzip $zipFileOrDir $rootDir
            if { ! [file isdirectory $targetDir] } {
                set dirName [file rootname [file tail $zipFileOrDir]]
                FileRename [file join $rootDir $dirName] [file join $rootDir $libName]
            }
        }
        SetFilePermissions $targetDir "u+rwx" true
        file mtime $targetDir [clock seconds]
    }

    proc AddPath { path } {
        variable sOpts

        Log "AddPath $path" 2 false
        lappend sOpts(Path) $path
    }

    proc GetPathes { type } {
        variable sOpts

        if { $type eq "unix" } {
            set sep ":"
        } else {
            set sep ";"
        }
        set pathString ""
        foreach path $sOpts(Path) {
            if { $type eq "unix" } {
                set path [MSysPath $path]
            }
            set pathString [format "%s%s%s" $path $sep $pathString]
        }
        return $pathString
    }

    proc SetPathes {} {
        Log "SetPathes"
        AddPath [Get7ZipDistDir]
        AddPath [GetCMakeDistDir]
        AddPath [GetSWIGDistDir]
        AddPath [file join [GetOutputDevDir] "bin"]
        AddPath [file join [GetOutputDevDir] "lib"]
        AddPath [file join [GetOutputDevDir] [GetTclBinDir]]
    }

    proc ModificationTime { libName fileName modTime } {
        variable sRepository

        set sRepository($fileName,modTime) [clock scan $modTime -format "%Y-%m-%d_%H:%M:%S"]
    }

    proc GetModificationTime { libName fileName } {
        variable sRepository

        set modTime 0
        if { [info exists sRepository($fileName,modTime)] } {
            set modTime $sRepository($fileName,modTime)
        }
        return $modTime
    }

    proc HashKey { libName fileName hashKey } {
        variable sRepository

        set sRepository($fileName,hashKey) $hashKey
    }

    proc GetHashKey { libName fileName } {
        variable sRepository

        set hashKey ""
        if { [info exists sRepository($fileName,hashKey)] } {
            set hashKey $sRepository($fileName,hashKey)
        }
        return $hashKey
    }

    proc GetVersionFromFileName { fileName } {
        set fileIsDir false
        if { [file isdirectory $fileName] } {
            set fileIsDir true
        }
        set pureName [file tail $fileName]
        set versionStart [string first "-" $pureName]
        if { $fileIsDir } {
            # Directories don't have an extension
            set versionEnd [string length $pureName]
        } else {
            # Files have .7z or .zip as extension
            set versionEnd [string last  "." $pureName]
        }
        set version ""
        if { $versionStart >= 0 && $versionEnd >= 0 && $versionEnd > $versionStart } {
            set version [string range $pureName [expr $versionStart + 1] [expr $versionEnd - 1]]
        }
        return $version
    }

    proc AddIncludePath { path { useLog true } } {
        variable sIncludePathes

        if { [file isdirectory $path] } {
            if { ! [info exists sIncludePathes] || \
                [lsearch -exact $sIncludePathes $path] < 0 } {
                lappend sIncludePathes $path
                if { $useLog } {
                    Log "AddIncludePath $path"
                }
            }
        } else {
            ErrorAppend "AddIncludePath: Path $path does not exist" "Warning"
        }
    }

    proc Include { setupFile } {
        variable sIncludeFiles
        variable sIncludePathes

        set fileFound false
        set fileName $setupFile
        if { ! [file exists $fileName] } {
            if { [file pathtype $fileName] ne "absolute" } {
                foreach dir $sIncludePathes {
                    set fileName [file join $dir $setupFile]
                    if { [file exists $fileName] } {
                        set fileFound true
                        break
                    }
                }
            }
        }
        if { ! $fileFound } {
            ErrorAppend "Include: Setup file $setupFile does not exist" "FATAL"
        }
        if { ! [info exists sIncludeFiles] || [lsearch -exact $sIncludeFiles $setupFile] < 0 } {
            lappend sIncludeFiles $setupFile
            uplevel #0 source $fileName
        }
    }

    proc Setup { libName zipFile buildFile args } {
        # Check for existence of the library source code (either as a 7z file or directory)
        # as well as the according build file. If these do not exist in the library directory
        # (--libdir) and online update is enabled (--noonline not specified), they are downloaded
        # from the BAWT website.
        # If this fails, a fatal error is thrown and the build process is stopped.
        # The version number of the library is extracted from the file name of the library.
        # If build action is set to "Update", the necessary build stages are determined according
        # to the existence of the library source and build files as well as to the modification
        # times of the corresponding build and install directories.

        Log "Setup $libName" 2

        foreach libZipDir [GetInputLibsDirs] {
            Log "Looking for $zipFile in $libZipDir" 6 false
            # Note, that if zipFile is an absolute path,
            # zipFullPath gets the same value as zipFile.
            set zipFullPath [file join $libZipDir $zipFile]
            if { [file exists $zipFullPath] } {
                break
            }
        }
        Log "ZIP file   : $zipFullPath" 4 false
        if { ! [file exists $zipFullPath] } {
            if { [UseOnlineRepository] } {
                DownloadFile $libName "InputLibs" $zipFile $zipFullPath
                if { [UseStage "Update"] } {
                    UpdateLib $libName "Download/Build (Source distribution not available)"
                }
            } else {
                ErrorAppend "Setup: Directory or ZIP file $zipFullPath does not exist" "FATAL"
            }
        } else {
            set modTime 0
            if { [UseOnlineRepository] } {
                set modTime [GetModificationTime $libName [file tail $zipFile]]
            }
            if { $modTime > [file mtime $zipFullPath] } {
                if { ! [IsSimulationMode] } {
                    DownloadFile $libName "InputLibs" $zipFile $zipFullPath
                }
                if { [UseStage "Update"] } {
                    UpdateLib $libName "Remote source file newer than local"
                }
            }
        }
        foreach libDir [GetInputLibsDirs] {
            Log "Looking for $buildFile in $libDir" 6 false
            set buildFullPath [file join $libDir $buildFile]
            if { [file exists $buildFullPath] } {
                break
            }
        }
        foreach libDir [GetInputLibsDirs] {
            set userBuildExt [file extension $buildFile]
            set userBuildFile [format "%s_User%s" [file rootname [file tail $buildFile]] $userBuildExt]
            Log "Looking for user supplied $userBuildFile in $libDir" 6 false
            set userBuildFullPath [file join $libDir $userBuildFile]
            if { [file exists $userBuildFullPath] } {
                break
            }
        }
        Log "Build file : $buildFullPath" 4 false
        if { ! [file exists $buildFullPath] } {
            if { [UseOnlineRepository] } {
                DownloadFile $libName "InputLibs" $buildFile $buildFullPath
                if { [UseStage "Update"] } {
                    UpdateLib $libName "Download/Build (Build file not available)"
                }
            } else {
                ErrorAppend "Setup: Build file $buildFullPath does not exist" "FATAL"
            }
        } else {
            set modTime 0
            if { [UseOnlineRepository] } {
                set modTime [GetModificationTime $libName [file tail $buildFile]]
            }
            if { $modTime > [file mtime $buildFullPath] } {
                if { ! [IsSimulationMode] } {
                    DownloadFile $libName "InputLibs" $buildFile $buildFullPath
                }
                if { [UseStage "Update"] } {
                    UpdateLib $libName "Remote build file newer than local"
                }
            }
        }
        if { [file exists $buildFullPath] } {
            uplevel #0 source $buildFullPath
        }
        
        set libSpecificBuildFile [GetUserBuildFile $libName]
        if { ( [UseUserBuildFiles] && [file exists $userBuildFullPath] ) || \
               $libSpecificBuildFile ne "" } {
            if { $libSpecificBuildFile ne "" } {
                set userBuildFullPath $libSpecificBuildFile
            }
            Log "User file  : $userBuildFullPath" 4 false
            uplevel #0 source $userBuildFullPath
        }

        set version [GetVersionFromFileName $zipFullPath]

        if { [GetLibIndex $libName] >= 0 } {
            # Library was specified already. Print out a warning and
            # overwrite older values.
            set oldZipFile   [GetLibZipFile $libName]
            set oldBuildFile [file tail [GetLibBuildFile $libName]]
        }

        SetLibZipDir    $libName $libZipDir
        SetLibZipFile   $libName $zipFile
        SetLibBuildFile $libName $buildFullPath
        SetLibVersion   $libName $version
        set buildMsg ""
        AppendBuildType  $libName "Release"
        append buildMsg "Release "
        # Parse optional arguments.
        foreach arg $args {
            switch -exact -- $arg {
                "Release" -
                "Debug" {
                    # Additional build types
                    AppendBuildType $libName $arg
                    append buildMsg "$arg "
                }
                "NoWindows" -
                "NoLinux" -
                "NoDarwin" {
                    # Exclude library from building on specific OS.
                    if { [GetPlatformName] eq [string range $arg 2 end] } {
                        SetExcludeOption $libName $arg
                    }
                }
                default {
                    if { [string match "Version=*" $arg] } {
                        # Override library version number.
                        set version [lindex [split $arg "="] 1]
                        SetLibVersion $libName $version
                    } elseif { [string match "WinCompiler=*" $arg] } {
                        # Override default Windows compiler.
                        set winCompiler [lindex [split $arg "="] 1]
                        SetWinCompiler $libName $winCompiler
                    } elseif { [string match "MaxParallel=*" $arg] } {
                        # Use parallel build for specified platforms separated by commas.
                        set platforms [lindex [split $arg "="] 1]
                        foreach platformStr [split $platforms ","] {
                            set compiler ""
                            lassign [split $platformStr ":"] platform numJobs
                            if { [string first "-" $platform] > 0 } {
                                lassign [split $platform "-"] platform compiler 
                            }
                            if { [string tolower [GetPlatformName]] eq [string tolower $platform] } {
                                SetNumJobs $numJobs $libName $compiler
                            } elseif { [lsearch -nocase -exact [GetValidPlatforms] $platform] < 0 } {
                                ErrorAppend "Setup: Unknown platform name \"$platform\" specified for MaxParallel option" "FATAL"
                            }
                        }
                    } elseif { [string match "NoParallel=*" $arg] } {
                        # Do not use parallel build for specified platforms separated by commas.
                        ErrorAppend "Option NoParallel is obsolete. Use MaxParallel= instead." "Warning"
                        set platforms [lindex [split $arg "="] 1]
                        foreach platform [split $platforms ","] {
                            if { [string tolower [GetPlatformName]] eq [string tolower $platform] } {
                                SetNumJobs 1 $libName
                            } elseif { [lsearch -nocase -exact [GetValidPlatforms] $platform] < 0 } {
                                ErrorAppend "Setup: Unknown platform name \"$platform\" specified for NoParallel option" "FATAL"
                            }
                        }
                    } else {
                        # All other strings are interpreted as user configurations.
                        AddUserConfig $libName $arg
                    }
                }
            }
        }
        Log "Version    : $version"  4 false
        Log "Build types: $buildMsg" 4 false
        if { [GetLibIndex $libName] >= 0 } {
            if { $oldZipFile ne $zipFile || $oldBuildFile ne $buildFile } {
                ErrorAppend "Setup: Library $libName already specified:\n \
                             Old setup: $oldZipFile $oldBuildFile\n \
                             New setup: $zipFile $buildFile" "Warning"
            }
        } else {
            AppendLib $libName
        }
    }

    proc _PrintErrorsAndWarnings {} {
        set msg ""
        if { [llength [GetWarningList]] > 0 } {
            append msg "\nWarning list:\n"
            foreach warnMsg [GetWarningList] {
                append msg "  $warnMsg\n"
            }
        }
        if { [llength [GetErrorList]] > 0 } {
            append msg "\nError list:\n"
            foreach errorMsg [GetErrorList] {
                append msg "  $errorMsg\n"
            }
        }
        if { [GetLogLevel] > 0 } {
            Log $msg 0 false
        } else {
            puts $msg
        }
    }

    proc PrintSummary {} {
        Log ""
        Log "Summary"
        Log "Setup file     : [GetSetupFile]"        0 false
        Log "Build directory: [GetOutputBuildDir]"   0 false
        Log "Architecture   : [GetArchitecture]"     0 false
        Log "Compilers      : [GetCompilerVersions]" 0 false
        Log "Global stages  : [GetUsedStages]"       0 false
        if { [llength [GetWorkingSet]] > 0 } {
            set stageTitle ""
            if { [UseStage "Update"] } {
                set stageTitle "Stages"
            }
            if { ! [IsSimulationMode] } {
                Log [format "#  : %-20s %-10s %-15s %s" "Library Name" "Version" "Build time" $stageTitle] 0 false
            } else {
                Log [format "#  : %-20s %-10s %-15s %s" "Library Name" "Version" "Build action" "Build cause"] 0 false
            }
            Log [string repeat "-" 70] 0 false
            foreach libName [GetWorkingSet] {
                set libVersion [GetLibVersion $libName]
                set libNumber  [GetLibNumber  $libName]
                set buildTime  [GetBuildTime  $libName]
                set buildError [GetBuildError $libName]
                if { ! [IsSimulationMode] } {
                    if { $buildTime >= 0.0 || $buildTime == -2.0 } {
                        set stages ""
                        if { [UseStage "Update"] } {
                            set stages [GetUsedStages $libName]
                        }
                        if { $buildTime >= 0.0 } {
                            Log [format "%3d: %-20s %-10s %3.2f minutes    %s" $libNumber $libName $libVersion $buildTime $stages] 0 false
                        } else {
                            Log [format "%3d: %-20s %-10s %-15s %s" $libNumber $libName $libVersion "Simulation" $stages] 0 false
                        }
                    } else {
                        Log [format "%3d: %-20s %-10s %-15s %s" $libNumber $libName $libVersion "Excluded" $buildError] 0 false
                    }
                } else {
                    if { $buildTime >= 0.0 || $buildTime == -2.0 } {
                        set stages ""
                        if { [UseStage "Update"] } {
                            set stages [GetUsedStages $libName]
                        }
                        if { $stages eq "None" } {
                            Log [format "%3d: %-20s %-10s %-15s %s" $libNumber $libName $libVersion "None" ""] 0 false
                        } else {
                            Log [format "%3d: %-20s %-10s %-15s %s" $libNumber $libName $libVersion "Update" [GetLibUpdateCause $libName]] 0 false
                        }
                    } else {
                        Log [format "%3d: %-20s %-10s %-15s %s" $libNumber $libName $libVersion "None" $buildError] 0 false
                    }
                }
            }
            Log [string repeat "-" 70] 0 false
            Log [format "Total: %.2f minutes" [expr [GetTotalTime] / 1000.0 / 60.0]] 0 false
        }

        _PrintErrorsAndWarnings
    }
}

#
# Start of main program.
#

namespace import BawtLog::*
namespace import BawtZip::*
namespace import BawtFile::*
namespace import BawtBuild::*
namespace import BawtMain::*

BawtMain::_Init

if { $argc == 0 } {
    PrintUsage "No build options or libraries specified"
    exit 1
}

set curArg 0
set targetList  [list]

set optPrintUsage    false
set optPrintProcs    false
set optPrintProc     ""
set optPrintVersion  false
set optPrintDepends  false
set optHaveSetupFile false
set optShowLogViewer false

set optHaveListOpt   false
set optHaveActionOpt false

set optLogLevel -1
set optNumJobs  -1
set optSortMode [lindex [GetValidSortModes] 0]
set optWinCompiler [list]
set optUserConfigs [list]
set optSdkVersions [list]

while { $curArg < $argc } {
    set curParam [lindex $argv $curArg]
    if { [string compare -length 1 $curParam "-"]  == 0 || \
         [string compare -length 2 $curParam "--"] == 0 } {
        set curOpt [string tolower [string trimleft $curParam "-"]]
        if { $curOpt eq "loglevel" } {
            incr curArg
            if { ! [string is integer -strict [lindex $argv $curArg]] } {
                PrintUsage "Invalid $curParam value: \"[lindex $argv $curArg]\""
                exit 1
            }
            set optLogLevel [lindex $argv $curArg]
        } elseif { $curOpt eq "nologtime" } {
            SetLogTiming false
        } elseif { $curOpt eq "logviewer" } {
            set optShowLogViewer true
        } elseif { $curOpt eq "help" } {
            set optPrintUsage true
        } elseif { $curOpt eq "procs" } {
            set optPrintProcs true
        } elseif { $curOpt eq "proc" } {
            incr curArg
            set optPrintProc [lindex $argv $curArg]
        } elseif { $curOpt eq "version" } {
            set optPrintVersion true
        } elseif { $curOpt eq "list" } {
            set optHaveListOpt true
        } elseif { $curOpt eq "platforms" } {
            set optHaveListOpt true
            AddCheckOption "Platforms"
        } elseif { $curOpt eq "wincompilers" } {
            set optHaveListOpt true
            AddCheckOption "Compilers"
        } elseif { $curOpt eq "dependencies" } {
            set optHaveListOpt true
            AddCheckOption "Dependencies"
        } elseif { $curOpt eq "dependency" } {
            set optPrintDepends true
            set optHaveListOpt true
        } elseif { $curOpt eq "authors" } {
            set optHaveListOpt true
            AddCheckOption "ScriptAuthor"
        } elseif { $curOpt eq "homepages" } {
            set optHaveListOpt true
            AddCheckOption "Homepage"
        } elseif { $curOpt eq "sort" } {
            incr curArg
            if { [lsearch -exact -nocase [GetValidSortModes] [lindex $argv $curArg]] < 0 } {
                PrintUsage "Invalid $curParam value: \"[lindex $argv $curArg]\""
                exit 1
            }
            set optSortMode [lindex $argv $curArg]
        } elseif { $curOpt eq "clean" } {
            set optHaveActionOpt true
            EnableStage "Clean"
        } elseif { $curOpt eq "extract" } {
            set optHaveActionOpt true
            EnableStage "Extract"
        } elseif { $curOpt eq "configure" } {
            set optHaveActionOpt true
            EnableStage "Configure"
        } elseif { $curOpt eq "compile" } {
            set optHaveActionOpt true
            EnableStage "Compile"
        } elseif { $curOpt eq "distribute" } {
            set optHaveActionOpt true
            EnableStage "Distribute"
        } elseif { $curOpt eq "finalize" } {
            set optHaveActionOpt true
            EnableStage "Finalize"
        } elseif { $curOpt eq "complete" } {
            set optHaveActionOpt true
            EnableAllStages
        } elseif { $curOpt eq "update" } {
            set optHaveActionOpt true
            DisableAllStages
            EnableStage "Update"
            EnableStage "Finalize"
        } elseif { $curOpt eq "simulate" } {
            set optHaveActionOpt true
            DisableAllStages
            EnableStage "Update"
            AddCheckOption "Stages"
        } elseif { $curOpt eq "touch" } {
            set optHaveActionOpt true
            DisableAllStages
            EnableStage "Touch"
        } elseif { $curOpt eq "numjobs" } {
            incr curArg
            if { ! [string is integer -strict [lindex $argv $curArg]] || [lindex $argv $curArg] < 1 } {
                PrintUsage "Invalid $curParam value: \"[lindex $argv $curArg]\""
                exit 1
            }
            set optNumJobs [lindex $argv $curArg]
        } elseif { $curOpt eq "timeout" } {
            incr curArg
            if { ! [string is double -strict [lindex $argv $curArg]] || [lindex $argv $curArg] < 0.0 } {
                PrintUsage "Invalid $curParam value: \"[lindex $argv $curArg]\""
                exit 1
            }
            SetTimeout [lindex $argv $curArg]
        } elseif { $curOpt eq "architecture" } {
            incr curArg
            if { [lsearch -exact [GetValidArchitectures] [lindex $argv $curArg]] < 0 } {
                PrintUsage "Invalid $curParam value: \"[lindex $argv $curArg]\""
                exit 1
            }
            SetArchitecture [lindex $argv $curArg]
        } elseif { $curOpt eq "compiler" } {
            incr curArg
            set compilerStr  [lindex $argv $curArg]
            set compilerList [split $compilerStr "+"]
            foreach compiler $compilerList {
                if { [lsearch -exact [GetValidCompilerVersions] $compiler] < 0 } {
                    PrintUsage "Invalid $curParam value: \"$compilerStr\""
                    exit 1
                }
            }
            SetCompilerVersions {*}$compilerList
        } elseif { $curOpt eq "forcevs" } {
            incr curArg
            ErrorAppend "Option --forcevs is obsolete. Use --wincc instead." "Warning"
            lappend optWinCompiler [lindex $argv $curArg] "vs"
        } elseif { $curOpt eq "wincc" } {
            incr curArg
            set winOptLibName [lindex $argv $curArg]
            incr curArg
            set winOptValue [lindex $argv $curArg]
            lappend optWinCompiler $winOptLibName $winOptValue
        } elseif { $curOpt eq "exclude" } {
            incr curArg
            SetExcludeOption [lindex $argv $curArg] "--exclude" 
        } elseif { $curOpt eq "gcc" || $curOpt eq "gccversion" } {
            incr curArg
            SetMingwGccVersion [lindex $argv $curArg]
        } elseif { $curOpt eq "msysversion" } {
            incr curArg
            SetMSysVersion [lindex $argv $curArg]
        } elseif { $curOpt eq "tclversion" } {
            incr curArg
            SetTclVersion [lindex $argv $curArg]
        } elseif { $curOpt eq "tkversion" } {
            incr curArg
            SetTkVersion [lindex $argv $curArg]
        } elseif { $curOpt eq "imgversion" } {
            incr curArg
            SetImgVersion [lindex $argv $curArg]
        } elseif { $curOpt eq "osgversion" } {
            incr curArg
            SetOsgVersion [lindex $argv $curArg]
        } elseif { $curOpt eq "buildtype" } {
            incr curArg
            if { [lsearch -exact [GetValidBuildTypes] [lindex $argv $curArg]] < 0 } {
                PrintUsage "Invalid $curParam value: \"[lindex $argv $curArg]\""
                exit 1
            }
            AppendBuildType ForceBuildType [lindex $argv $curArg]
        } elseif { $curOpt eq "url" } {
            incr curArg
            SetBawtUrl [lindex $argv $curArg]
        } elseif { $curOpt eq "rootdir" } {
            incr curArg
            SetOutputRootDir [lindex $argv $curArg]
        } elseif { $curOpt eq "builddir" } {
            incr curArg
            ErrorAppend "Option --builddir is obsolete. Use --rootdir instead." "Warning"
            SetOutputRootDir [lindex $argv $curArg]
        } elseif { $curOpt eq "toolsdir" } {
            incr curArg
            SetOutputToolsDir [lindex $argv $curArg]
        } elseif { $curOpt eq "distdir" } {
            incr curArg
            SetOutputDistDir [lindex $argv $curArg]
        } elseif { $curOpt eq "libdir" } {
            incr curArg
            AddInputLibsDir [lindex $argv $curArg]
        } elseif { $curOpt eq "finalizefile" } {
            incr curArg
            SetFinalizeFile [lindex $argv $curArg]
        } elseif { $curOpt eq "noexit" } {
            ExitOnFatalError false
        } elseif { $curOpt eq "noversion" } {
            UseTclPkgVersion false
        } elseif { $curOpt eq "noimportlibs" } {
            CreateImportLibs false
        } elseif { $curOpt eq "noruntimelibs" } {
            CopyRuntimeLibs false
        } elseif { $curOpt eq "nostrip" } {
            StripLibs false
        } elseif { $curOpt eq "noonline" } {
            UseOnlineRepository false
        } elseif { $curOpt eq "norecursive" } {
            UseRecursiveDependencies false
        } elseif { $curOpt eq "nosubdirs" } {
            SetShortRootDir true
        } elseif { $curOpt eq "nouserbuilds" } {
            UseUserBuildFiles false
        } elseif { $curOpt eq "iconfile" } {
            incr curArg
            SetTclkitIconFile "All" [lindex $argv $curArg]
        } elseif { $curOpt eq "resourcefile" } {
            incr curArg
            SetTclkitResourceFile "All" [lindex $argv $curArg]
        } elseif { $curOpt eq "html" } {
            GenerateHtml true
        } elseif { $curOpt eq "copt" } {
            incr curArg
            set configOptLibName [lindex $argv $curArg]
            incr curArg
            set configOptData [lindex $argv $curArg]
            lappend optUserConfigs $configOptLibName $configOptData
        } elseif { $curOpt eq "user" } {
            incr curArg
            set userOptLibName [lindex $argv $curArg]
            incr curArg
            set userOptFileName [lindex $argv $curArg]
            SetUserBuildFile $userOptLibName $userOptFileName
        } elseif { $curOpt eq "sdk" } {
            incr curArg
            set sdkOptLibName [lindex $argv $curArg]
            incr curArg
            set sdkOptVersion [lindex $argv $curArg]
            lappend optSdkVersions $sdkOptLibName $sdkOptVersion
        } else {
            PrintUsage "Invalid option \"$curParam\""
            exit 1
        }
    } else {
        if { ! $optHaveSetupFile } {
            SetSetupFile $curParam
            AddIncludePath [file dirname $curParam] false
            set optHaveSetupFile true
        } else {
            lappend targetList $curParam
        }
    }
    incr curArg
}

if { $optPrintUsage } {
    PrintUsage
    exit 0
}

if { $optPrintProcs } {
    set procList [BawtHelp::GetProcList]
    if { $optSortMode eq "dictionary" } {
        set procList [lsort -dictionary $procList]
    }
    foreach fullName $procList {
        puts [BawtHelp::GetProcShortName $fullName]
    }
    exit 0
}

if { $optPrintProc ne "" } {
    set procList [BawtHelp::GetProcList]
    set found false
    foreach fullName $procList {
        set shortName [BawtHelp::GetProcShortName $fullName]
        if { [string match -nocase "$optPrintProc*" $shortName] } {
            puts "$shortName [info args $fullName]"
            set procBody [info body $fullName]
            set bodyLines [split $procBody "\n"]
            foreach line $bodyLines {
                set trimmedLine [string trim $line]
                if { $trimmedLine eq "" || [string first "#" $trimmedLine] == 0 } {
                    puts "[string trimright [string trimleft $trimmedLine "#"]]"
                } else {
                    break
                }
            }
            set found true
        }
    }
    if { ! $found } {
        puts "No procedure $optPrintProc available"
    }
    exit 0
}

if { $optPrintVersion } {
    PrintVersion [expr $optLogLevel == 0]
    exit 0
}

if { $optHaveListOpt } {
    DisableAllStages
    EnableStage "Check"
    SetLogLevel 0
}

if { $optLogLevel >= 0 } {
    SetLogLevel $optLogLevel
} else {
    SetLogLevel [GetLogLevel]
}

if { ! [file exists [GetSetupFile]] } {
    PrintUsage "No valid setup file specified."
    exit 1
}

if { ! $optHaveListOpt && ! $optHaveActionOpt } {
    PrintUsage "No list or build action specified."
    exit 1
}

if { [llength $targetList] == 0 && ! [UseStage "Check"] } {
    PrintUsage "No library specified."
    exit 1
}

if { $optNumJobs >= 0 } {
    SetNumJobs $optNumJobs
}

if { $optShowLogViewer && [GetLogLevel] > 1 } {
    StartBawtLogViewerProg [GetLogFile]
}

if { ! [UseStage "Check"] } {
    Bootstrap
}

if { [UseVisualStudio] } {
    Log "VisualStudio environment: [GetVcvarsProg]"
}

if { [UseOnlineRepository] && ! [UseStage "Check"] } {
    Log ""
    Log "Check online repository"
    set configFileList [list "ModificationTimes.txt" "HashKeys.txt"]
    set buildDir [GetOutputRootDir]
    foreach configFile $configFileList {
        set configFileFullPath [file join $buildDir $configFile]
        DownloadFile "ConfigFile" "" $configFile $configFileFullPath "Warning"
        if { [file readable $configFileFullPath] } {
            source $configFileFullPath
        }
    }
}

Log "Setup (File [GetSetupFile]) "
source [GetSetupFile]

foreach libName [GetLibs] {
    if { [info commands Init_$libName] eq "" } {
        ErrorAppend "Library $libName: No Init_$libName command defined." "Warning"
    } else {
        Init_$libName $libName [GetLibVersion $libName]
    }
}

# Overwrite optional Setup parameters WinCompiler, UserConfiguration and SDK version.
foreach { libName value } $optWinCompiler {
    SetWinCompiler $libName $value
}
foreach { libName value } $optUserConfigs {
    AddUserConfig $libName $value
}
foreach { libName value } $optSdkVersions {
    SetSdkVersion $libName $value
}

if { $optSortMode eq "none" } {
    ; # No sorting necessary
} elseif { $optSortMode eq "dictionary" } {
    SortLibsByDictionary
} else {
    SortLibsByDependencies
}

if { $optPrintDepends } {
    foreach libName $targetList {
        PrintLibDependency $libName
    }
    exit 0
}

if { [UseStage "Check"] } {
    SetWorkingSet [GetLibs]
    DisableAllStages
} else {
    if { [lsearch -exact -nocase $targetList "all"] >= 0 } {
        SetWorkingSet [GetLibs]
    } else {
        foreach libNameOrNum $targetList {
            set libIndex [GetLibIndex $libNameOrNum]
            if { $libIndex >= 0 } {
                AppendToWorkingSet [GetLibName [GetLibNumber $libNameOrNum]]
            } elseif { [string is integer $libNameOrNum] } {
                if { $libNameOrNum >= 1 && $libNameOrNum <= [GetNumLibs] } {
                    AppendToWorkingSet [GetLibName $libNameOrNum]
                } else {
                    PrintUsage "Invalid library number \"$libNameOrNum\" specified."
                    exit 1
                }
            } elseif { [string match "*-*" $libNameOrNum] } {
                if { 2 == [scan $libNameOrNum "%d-%d" minNumber maxNumber] } {
                    for { set i $minNumber } { $i <= $maxNumber } { incr i } {
                        if { $i >= 1 && $i <= [GetNumLibs] } {
                            AppendToWorkingSet [GetLibName $i]
                        } else {
                            PrintUsage "Invalid library number \"$i\" specified."
                            exit 1
                        }
                    }
                } else {
                    PrintUsage "Invalid library \"$libNameOrNum\" specified."
                    exit 1
                }
            } else {
                PrintUsage "Invalid library \"$libNameOrNum\" specified."
                exit 1
            }
        }
    }
}

Log ""
foreach libName [GetWorkingSet] {
    Log [format "WorkingSet %3d: %s \"%s\" \"%s\"" \
                [GetLibNumber $libName] \
                $libName \
                [GetLibVersion $libName] \
                [GetCompilerVersion -lib $libName]] 1 false
}
Log ""
Log "SetCompilerVersions [GetCompilerVersions]" 1 false
Log ""

AddToPathEnv "[GetOutputDevDir]/bin"
AddToPathEnv "[GetOutputDevDir]/lib"

SetPathes

SetStartTime

foreach libName [GetWorkingSet] {
    if { [llength [GetBuildTypes ForceBuildType]] > 0 } {
        set buildTypeList [GetBuildTypes ForceBuildType]
    } else {
        set buildTypeList [GetBuildTypes $libName]
    }
    if { ! [UseStage "Check"] } {
        Log ""
        Log "Start $libName [GetLibVersion $libName] (Library #[GetLibNumber $libName] of [GetNumLibs])"
        Log "Build types : $buildTypeList" 2 false
    }
    set buildTime [BuildLib $libName [GetLibVersion $libName] $buildTypeList]
    SetBuildTime $libName $buildTime
}

if { [UseStage "Finalize"] && ! [IsSimulationMode] } {
    Log ""
    Log "Start FinalizeStage"

    # Write out environment file.
    set outFileName [format "SetEnv-%s-%s%s" \
                    [GetCompilerVersion -platform] [GetArchitecture] [GetBatchSuffix]]
    set outDir [file join [GetOutputDevDir] "bin"]
    if { ! [file isdirectory $outDir] } {
        file mkdir $outDir
    }
    set outFilePath [file join $outDir $outFileName]
    Log "Environment file: $outFilePath" 2 false
    set retVal [catch {open $outFilePath w} outFp]
    if { $retVal != 0 } {
        ErrorAppend "Cannot write environment file $outFilePath" "FATAL"
    } else {
        puts $outFp [GetEnvVars]
        close $outFp
    }

    if { [IsWindows] && [UseVisualStudio] && [CopyRuntimeLibs] } {
        Log "VisualStudio runtime files" 2 false
        if { [GetVSRuntimeLibDir] ne "" } {
            MultiFileCopy [GetVSRuntimeLibDir]  [file join [GetOutputDevDir] [GetTclBinDir]]  "*.dll"
            MultiFileCopy [GetVSRuntimeLibDir]  [file join [GetOutputDistDir] [GetTclBinDir]]  "*.dll"
        }
    }

    if { [GetFinalizeFile] ne "" } {
        source [GetFinalizeFile]
    }
    if { [info commands "Finalize"] ne "" } {
        Finalize
    }
    Log "End FinalizeStage"
}

if { [UseStage "Check"] } {
    PrintLibNames
    exit 0
}

PrintSummary

exit 0
