"""Standalone OceanBase examples for hammerdbcli py (run from the HammerDB root)."""
import os
from pathlib import Path

import tclpy


def call(command, *args):
    # hammerdb.py joins arguments with spaces. Encode each argument as one Tcl
    # word so empty strings, quotes, newlines and Tcl metacharacters survive.
    def word(value):
        data = str(value).encode("utf-8").hex()
        return "[encoding convertfrom utf-8 [binary decode hex {" + data + "}]]"

    return tclpy.eval(" ".join([command, *(word(arg) for arg in args)]))


def dbset(*args):
    return call("dbset", *args)


def diset(*args):
    return call("diset", *args)


def required(name):
    value = os.environ.get(name, "")
    if not value:
        raise ValueError("Set " + name + " before running this example")
    return value


def number(name, fallback, minimum=1):
    value = int(os.environ.get(name, fallback))
    if value < minimum:
        raise ValueError(name + " must be an integer of at least " + str(minimum))
    return value


def configure(workload):
    dbset("db", "ob")
    dbset("bm", workload)
    diset("connection", "ob_compatibility_mode", "mysql")
    diset("connection", "ob_host", required("OB_HOST"))
    diset("connection", "ob_port", number("OB_PORT", 2881))
    diset("connection", "ob_tenant", os.environ.get("OB_TENANT", ""))
    diset("connection", "ob_cluster", os.environ.get("OB_CLUSTER", ""))
    diset("connection", "ob_query_timeout", number("OB_QUERY_TIMEOUT", 120))
    user, password, database = required("OB_USER"), os.environ.get("OB_PASSWORD", ""), required("OB_DATABASE")
    if workload == "TPROC-C":
        values = {
            "ob_user": user, "ob_pass": password, "ob_dbase": database,
            "ob_count_ware": number("OB_WAREHOUSES", 1),
            "ob_num_vu": number("OB_BUILD_USERS", 1),
            "ob_distributed_schema": "false", "ob_prepared": "false",
            "ob_no_stored_procs": "false", "ob_connect_pool": "false",
            "ob_async_scale": "false", "ob_driver": "timed",
            "ob_total_iterations": 10000000, "ob_keyandthink": "false",
            "ob_rampup": number("OB_RAMPUP", 1, 0), "ob_duration": number("OB_DURATION", 1),
            "ob_timeprofile": "true", "ob_raiseerror": "true",
        }
        section = "tpcc"
    else:
        values = {
            "ob_tpch_user": user, "ob_tpch_pass": password, "ob_tpch_dbase": database,
            "ob_scale_fact": number("OB_SCALE_FACTOR", 1),
            "ob_num_tpch_threads": number("OB_BUILD_USERS", 1),
            "ob_tpch_optimized_schema": "false", "ob_total_querysets": number("OB_QUERYSETS", 1),
            "ob_refresh_on": "false", "ob_cloud_query": "false", "ob_raise_query_error": "true",
        }
        section = "tpch"
    for key, value in values.items():
        diset(section, key, value)


def main(workload, phase):
    # Share status and Jobs handling with the Tcl examples; database operations
    # below still run through the real Python-to-Tcl command bridge.
    call("source", Path.cwd() / "scripts/tcl/oceanbase/common.tcl")
    if phase == "result":
        call("::ob_examples::result", workload)
    else:
        configure(workload)
        try:
            if phase in ("build", "check", "delete"):
                call({"build": "buildschema", "check": "checkschema", "delete": "deleteschema"}[phase])
                call("::ob_examples::assert_success", phase)
            elif phase == "run":
                call("::ob_examples::require_jobs")
                call("loadscript")
                default_users = 2 if workload == "TPROC-C" else 1
                call("vuset", "vu", number("OB_USERS", default_users))
                call("vucreate")
                if workload == "TPROC-C":
                    call("tcstart")
                run_result = call("vurun")
                call("::ob_examples::assert_success", "Run")
                call("::ob_examples::save_job", workload, run_result)
            else:
                raise ValueError("Unknown OceanBase example phase: " + phase)
        finally:
            if phase == "run" and workload == "TPROC-C":
                tclpy.eval("catch {tcstop}")
            tclpy.eval("catch {vudestroy}")
    print("OCEANBASE_EXAMPLE_SUCCESS " + workload + " " + phase, flush=True)
