export TMP=`pwd`/TMP
mkdir -p $TMP
echo "BUILD HAMMERDB SCHEMA"
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
./hammerdbcli py auto ./scripts/python/mssqls/tproch/mssqls_tproch_buildschema.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "CHECK HAMMERDB SCHEMA"
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
./hammerdbcli py auto ./scripts/python/mssqls/tproch/mssqls_tproch_checkschema.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "RUN HAMMERDB TEST"
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
./hammerdbcli py auto ./scripts/python/mssqls/tproch/mssqls_tproch_run.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "DROP HAMMERDB SCHEMA"
./hammerdbcli py auto ./scripts/python/mssqls/tproch/mssqls_tproch_deleteschema.py
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
echo "HAMMERDB RESULT"
./hammerdbcli py auto ./scripts/python/mssqls/tproch/mssqls_tproch_result.py
