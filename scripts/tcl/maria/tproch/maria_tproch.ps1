Write-Output "BUILD HAMMERDB SCHEMA"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli auto ./scripts/tcl/maria/tproch/maria_tproch_buildschema.tcl 
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "CHECK HAMMERDB SCHEMA"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli auto ./scripts/tcl/maria/tproch/maria_tproch_checkschema.tcl
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "RUN HAMMERDB TEST"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli auto ./scripts/tcl/maria/tproch/maria_tproch_run.tcl 
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "DROP HAMMERDB SCHEMA"
.\hammerdbcli auto ./scripts/tcl/maria/tproch/maria_tproch_deleteschema.tcl
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "HAMMERDB RESULT"
.\hammerdbcli auto ./scripts/tcl/maria/tproch/maria_tproch_result.tcl 
