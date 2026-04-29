#!/usr/bin/env python3
# maintainer: Pooja Jain
#
# Behaviour matches mysql_tprocc_run_profile.tcl:
#   PROFILEID=0   => single run at VUs=vcpu, no jobs profileid
#   PROFILEID>1   => profile sweep, jobs profileid, VU list: 1 then 4..(cpus+8) step 4
#   otherwise     => error
#
# Output:
#   TMP/mysql_tprocc_profile.<PROFILEID>

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

# Only set jobs profileid when PROFILEID > 1
if profileid > 1:
    try:
        jobs("profileid", str(profileid))
    except Exception as e:
        fatal(f"ERROR: jobs profileid failed: {e}")

giset("commandline", "keepalive_margin", 1200)
giset("timeprofile", "xt_gather_timeout", 1200)

diset("connection", "mysql_host", "localhost")
diset("connection", "mysql_port", 3306)
diset("connection", "mysql_socket", "/tmp/mysql.sock")

diset("tpcc", "mysql_user", "root")
diset("tpcc", "mysql_pass", "mysql")
diset("tpcc", "mysql_dbase", "tpcc")
diset("tpcc", "mysql_driver", "timed")
diset("tpcc", "mysql_rampup", 2)
diset("tpcc", "mysql_duration", 5)
diset("tpcc", "mysql_allwarehouse", "false")
if uaw:
    diset("tpcc", "mysql_allwarehouse", "true")
diset("tpcc", "mysql_timeprofile", "true")

print("TEST STARTED")

outfile = os.path.join(tmpdir, f"mysql_tprocc_profile.{profileid}")

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
end_vu = (os.cpu_count() or 1) + 8
vu_list = [1] + list(range(4, end_vu + 1, 4))

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
