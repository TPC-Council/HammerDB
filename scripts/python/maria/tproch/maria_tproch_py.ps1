Write-Output "BUILD HAMMERDB SCHEMA"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli py auto ./scripts/python/maria/tproch/maria_tproch_buildschema.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "CHECK HAMMERDB SCHEMA"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli py auto ./scripts/python/maria/tproch/maria_tproch_checkschema.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "RUN HAMMERDB TEST"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli py auto ./scripts/python/maria/tproch/maria_tproch_run.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "DROP HAMMERDB SCHEMA"
.\hammerdbcli py auto ./scripts/python/maria/tproch/maria_tproch_deleteschema.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "HAMMERDB RESULT"
.\hammerdbcli py auto ./scripts/python/maria/tproch/maria_tproch_result.py
