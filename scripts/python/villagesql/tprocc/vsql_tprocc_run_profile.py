#!/usr/bin/env python3
# maintainer: Pooja Jain
#
# Behaviour matches vsql_tprocc_run_profile.tcl:
#   PROFILEID=0   => single run at VUs=vcpu, jobs profileid 0
#   PROFILEID>1   => profile sweep, jobs profileid, adaptive VU steps based on CPU count
#   otherwise     => error
#
# Output:
#   TMP/vsql_tprocc_profile.<PROFILEID>

import os
import sys

def fatal(msg: str) -> None:
    print(msg)
    sys.exit(1)

# Ensure TMP exists
tmpdir = os.getenv("TMP")
if not tmpdir:
    tmpdir = os.path.join(os.getcwd(), "TMP")
    os.makedirs(tmpdir, exist_ok=True)
    os.environ["TMP"] = tmpdir
    print(f"TMP not set — defaulting to {tmpdir}")
else:
    tmpdir = os.path.abspath(tmpdir)
    os.environ["TMP"] = tmpdir

print("SETTING CONFIGURATION")

# PROFILEID must be explicitly set
if "PROFILEID" not in os.environ:
    fatal("ERROR: PROFILEID not set in environment (must be explicitly set to 0 or > 1)")

profileid_raw = os.environ.get("PROFILEID", "")
if profileid_raw == "":
    fatal("ERROR: PROFILEID is empty (must be explicitly set to 0 or > 1)")

try:
    profileid = int(profileid_raw)
except ValueError:
    fatal(f"ERROR: PROFILEID must be an integer, got: '{profileid_raw}'")

print(f"Using PROFILEID = {profileid}")

if profileid < 0 or profileid == 1:
    fatal(f"ERROR: PROFILEID must be 0 (non-profile single) or > 1 (profile). Got: {profileid}")

# UAW
uaw = 0
uaw_env = os.getenv("UAW", "").strip().lower()
if uaw_env in {"1", "true", "yes", "on"}:
    uaw = 1

# HammerDB config
dbset("db", "mysql")
dbset("bm", "TPC-C")

# Set jobs profileid for both single runs (0) and profile runs (>1)
try:
    jobs("profileid", str(profileid))
except Exception as e:
    fatal(f"ERROR: jobs profileid failed: {e}")

giset("commandline", "keepalive_margin", 1200)
giset("timeprofile", "xt_gather_timeout", 1200)

diset("connection", "vsql_host", "localhost")
diset("connection", "vsql_port", 3306)
diset("connection", "vsql_socket", "/tmp/villagesql.sock")

diset("tpcc", "vsql_user", "root")
diset("tpcc", "vsql_pass", "mysql")
diset("tpcc", "vsql_dbase", "tpcc")
diset("tpcc", "vsql_driver", "timed")
diset("tpcc", "vsql_rampup", 2)
diset("tpcc", "vsql_duration", 5)
diset("tpcc", "vsql_allwarehouse", "false")
if uaw:
    diset("tpcc", "vsql_allwarehouse", "true")
diset("tpcc", "vsql_timeprofile", "true")

print("TEST STARTED")

outfile = os.path.join(tmpdir, f"vsql_tprocc_profile.{profileid}")

# PROFILEID=0 => single run at vcpu, overwrite file
if profileid == 0:
    loadscript()
    vuset("vu", "vcpu")
    vuset("logtotemp", 1)
    vucreate()
    metstart()
    tcstart()
    tcstatus()
    jobid = vurun()
    metstop()
    tcstop()
    vudestroy()

    print(f"Writing to {outfile}")
    with open(outfile, "w", encoding="utf-8") as f:
        f.write(str(jobid) + "\n")

    print("TEST COMPLETE")
    sys.exit(0)

# PROFILEID > 1 => sweep, append jobids
cpus = int(tclpy.eval('numberOfCPUs'))
if cpus <= 64:
    vu_step = 4
elif cpus <= 128:
    vu_step = 8
elif cpus <= 256:
    vu_step = 16
else:
    vu_step = 24

end_vu = cpus + vu_step
vu_list = [1] + list(range(vu_step, end_vu + 1, vu_step))

metstart()
tcstart()

for z in vu_list:
    loadscript()
    vuset("vu", str(z))
    vuset("logtotemp", 1)
    vucreate()
    metstatus()
    tcstatus()
    jobid = vurun()
    vudestroy()

    print(f"Writing to {outfile}")
    with open(outfile, "a", encoding="utf-8") as f:
        f.write(str(jobid) + "\n")

tcstop()
metstop()

print("TEST COMPLETE")
sys.exit(0)
