export TMP=`pwd`/TMP
mkdir -p $TMP
echo "BUILD HAMMERDB SCHEMA"
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
./hammerdbcli py auto ./scripts/python/oracle/tprocc/ora_tprocc_buildschema.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "CHECK HAMMERDB SCHEMA"
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
./hammerdbcli py auto ./scripts/python/oracle/tprocc/ora_tprocc_checkschema.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "RUN HAMMERDB TEST"
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
./hammerdbcli py auto ./scripts/python/oracle/tprocc/ora_tprocc_run.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "DROP HAMMERDB SCHEMA"
./hammerdbcli py auto ./scripts/python/oracle/tprocc/ora_tprocc_deleteschema.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "HAMMERDB RESULT"
./hammerdbcli py auto ./scripts/python/oracle/tprocc/ora_tprocc_result.py
