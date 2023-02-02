::if 0 {--*-tcl-*--
 @echo off
set path=..\.\bin;%PATH%
 if "%OS%" == "Windows_NT" goto WinNT
 tclsh86t "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
 goto :eof
 :WinNT
tclsh86t %0 %*
 if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto :eof
 if %errorlevel% == 9009 echo You do not have Tclsh in your PATH.
 if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
 goto :eof
 }
########################################################################
# HammerDB Metrics
#
#Simulation of Linux mpstat program for Windows using Twapi
#
# Copyright (C) 2003-2023 Steve Shaw
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.
#
# Author contact information: smshaw@users.sourceforge.net
######################################################################   
package require twapi
set hostname [twapi::get_computer_name]
set osversion [lindex [twapi::get_os_version] 0 ]
set osinfo [lindex [twapi::get_os_info] 7 ]
set cpu_count [twapi::get_processor_count]
set numa_nodes [ twapi::get_numa_config ]
set numa_node_count [ dict size $numa_nodes ]
set cpus_per_node [ expr $cpu_count / $numa_node_count ]
#Write Headers
puts "Mpstat for Windows $osinfo $osversion {$hostname}  [clock format [twapi::large_system_time_to_secs_since_1970 [twapi::get_system_time]] -format "%d/%m/%Y"] {$cpu_count CPU}\n"
puts "[clock format [twapi::large_system_time_to_secs_since_1970 [twapi::get_system_time]] -format "%I:%M:%S %p"]\tCPU\t%usr\t%nice\t%sys\t%iowait\t%irq\t%soft\t%steal\t%guest\t%idle"
#Define Query
set qh [ twapi::pdh_system_performance_query user_utilization_per_cpu privileged_utilization_per_cpu interrupt_utilization_per_cpu idle_utilization_per_cpu]
#Get Data
while {1} {
set cpu_number 0
catch { twapi::pdh_query_update $qh }
catch { set perf_data [ twapi::pdh_query_get $qh ] }
if { [ info exists perf_data ] } {
if { [ dict size $perf_data ] > 0 } {
for {set i 0} {$i < $numa_node_count} {incr i} {
for {set j 0} {$j < $cpus_per_node} {incr j} {
puts "[clock format [clock seconds] -format "%I:%M:%S %p"]\t$cpu_number\t[format "%.2f" [ dict get [ dict get $perf_data user_utilization_per_cpu ] $i,$j ]]\t0.00\t[format "%.2f" [dict get [ dict get $perf_data privileged_utilization_per_cpu ] $i,$j ]]\t0.00\t[format "%.2f" [dict get [ dict get $perf_data interrupt_utilization_per_cpu ] $i,$j ]]\t0.00\t0.00\t0.00\t[format "%.2f" [ dict get [ dict get $perf_data idle_utilization_per_cpu ] $i,$j ]]"
incr cpu_number
		}
	}
after 2000
unset -nocomplain $perf_data
	}
    }
}
