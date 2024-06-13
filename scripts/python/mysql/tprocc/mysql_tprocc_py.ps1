Write-Output "BUILD HAMMERDB SCHEMA"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli py auto ./scripts/python/mysql/tprocc/mysql_tprocc_buildschema.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "CHECK HAMMERDB SCHEMA"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli py auto ./scripts/python/mysql/tprocc/mysql_tprocc_checkschema.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "RUN HAMMERDB TEST"
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
.\hammerdbcli py auto ./scripts/python/mysql/tprocc/mysql_tprocc_run.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "DROP HAMMERDB SCHEMA"
.\hammerdbcli py auto ./scripts/python/mysql/tprocc/mysql_tprocc_deleteschema.py
Write-Output "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
Write-Output "HAMMERDB RESULT"
.\hammerdbcli py auto ./scripts/python/mysql/tprocc/mysql_tprocc_result.py
