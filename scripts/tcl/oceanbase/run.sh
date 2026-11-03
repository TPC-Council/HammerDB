#!/bin/sh
# Run from any directory. "all" retains the database; deletion is explicit.
set -eu
if [ "$#" -gt 3 ]; then
    echo "Usage: $0 [tcl|python] [tprocc|tproch] [build|check|run|delete|result|all]" >&2
    exit 2
fi
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
hammerdb_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd)
language=${1:-tcl}
benchmark=${2:-tprocc}
phase=${3:-all}
case "$language" in tcl|python) ;; *) echo "Language must be tcl or python" >&2; exit 2 ;; esac
case "$benchmark" in tprocc) workload=TPROC-C ;; tproch) workload=TPROC-H ;; *) echo "Benchmark must be tprocc or tproch" >&2; exit 2 ;; esac
case "$phase" in all) phases="build check run result" ;; build|check|run|delete|result) phases=$phase ;; *) echo "Phase must be build, check, run, delete, result or all" >&2; exit 2 ;; esac
cd "$hammerdb_root"
TMP=${TMP:-${TMPDIR:-"$hammerdb_root/TMP"}}
TMPDIR=$TMP
export TMP TMPDIR
mkdir -p "$TMP"
for phase in $phases; do
    case "$phase" in build|check|delete) suffix=${phase}schema ;; *) suffix=$phase ;; esac
    logfile=$(mktemp "$TMP/ob_${benchmark}_${phase}.XXXXXX")
    if [ "$language" = python ]; then
        ./hammerdbcli py auto "scripts/python/oceanbase/$benchmark/ob_${benchmark}_${suffix}.py" 2>&1 | tee "$logfile"
    else
        ./hammerdbcli auto "scripts/tcl/oceanbase/$benchmark/ob_${benchmark}_${suffix}.tcl" 2>&1 | tee "$logfile"
    fi
    # Python auto mode can print an exception yet return a successful launcher
    # status. Only advance when the example confirms successful VU completion.
    if ! tr -d '\r' < "$logfile" | grep -Fqx "OCEANBASE_EXAMPLE_SUCCESS $workload $phase"; then
        echo "OceanBase $phase did not complete successfully; see $logfile" >&2
        exit 1
    fi
done
