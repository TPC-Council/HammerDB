# OceanBase

Select **OceanBase** in Benchmark Options, or use `dbset db ob` in
the CLI. This category reuses HammerDB's MySQL TPROC-C and TPROC-H workloads.
OceanBase-specific settings and behavior have been removed from the MySQL category.
Users of the former MySQL option must select OceanBase and enter their connection
and credentials again; those settings are not copied automatically. This does not
move or delete existing schema data. Select the existing database and matching
warehouse count or scale factor when checking an existing schema.
Oracle-compatible tenants are not supported by this category yet.

OceanBase is treated as an independently deployed database. This contribution
does not add an OceanBase engine source-build pipeline or a HammerDB-maintained
OceanBase Docker image. Functional testing against an available installation is
supported. Desktop database metrics read OceanBase's native Active Session
History (ASH) and tenant plan cache. Generic host CPU metrics remain available.

## Connection

Install the client library as described below, then connect directly to an
OBServer or through OBProxy. The example uses a direct business-tenant
connection; replace the host and tenant with those of your installation.

Use the business tenant's credentials. Set `ob_user` (TPROC-C) or `ob_tpch_user`
(TPROC-H) to the unqualified user, and set the connection fields separately:

```tcl
dbset db ob
dbset bm TPROC-C
diset connection ob_compatibility_mode mysql
diset connection ob_host 127.0.0.1
diset connection ob_port 2881
diset connection ob_tenant hammerdb
diset connection ob_cluster {}
diset connection ob_query_timeout 120
diset tpcc ob_user root
diset tpcc ob_pass $::env(OB_PASSWORD)
diset tpcc ob_dbase tpcc_ob
```

Direct connections use the OBServer port (normally 2881), an empty `ob_cluster`,
and the login `user@tenant`. For OBProxy, set its port (normally 2883) and
`ob_cluster`; the login becomes `user@tenant#cluster`. A sys tenant account,
shared administrative password, SQL extension, and cluster parameter changes
are not required. TLS settings are available in the connection configuration
on Linux. With `ob_ssl=true`, the OB binding requires TLS and validates the
server certificate and hostname. Configure trust with the CA file/directory
settings (`ob_ssl_ca` and `ob_ssl_linux_capath`). An untrusted certificate,
hostname mismatch or server without TLS is an error rather than a plaintext
fallback. This contribution currently builds
the OceanBase binding for Linux; a Windows OceanBase binding is not supplied.

OBProxy Service Name connections (`user@SERVICE:service_name`) are not supported
by this category. The user fields accept only an unqualified username; tenant
and cluster routing must use the separate connection fields above. For example,
for user `a`, tenant `b`, cluster `c`, and service `d`, set the user to `a`,
`ob_tenant` to `b`, and `ob_cluster` to `c`. This connects to the specified tenant
and cluster, without Service Name routing or automatic routing to a new primary
tenant after a tenant switchover.

OB Cloud (oceanbase.cloud) endpoints do not expose a cluster or tenant name, so
leave `ob_tenant` and `ob_cluster` empty there. The login is then the bare
username, and the endpoint itself selects the tenant:

```tcl
diset connection ob_host privatelink-example.aws-ap-southeast-1.oceanbase.cloud
diset connection ob_port 3306
diset connection ob_tenant {}
diset connection ob_cluster {}
```

`ob_query_timeout` is in seconds and only changes the current database session.
The default is 120 seconds, including schema statistics collection. It does not
change the tenant's global timeout or SQL mode.

### Install OceanBase Connector/C (libobclient)

Use a HammerDB build containing this contribution's **obmysqltcl** binding.
The unmodified HammerDB 6.1.1 distribution does not contain it. The binding is
compiled and included by the HammerDB build; ordinary users do not compile it.
The OceanBase backend uses `obmysqltcl`, while MySQL and VillageSQL continue to
use `mysqltcl`. Existing saved OceanBase registry entries are migrated when the
new build starts; native MySQL entries are preserved.

Install [OceanBase Connector/C (LibobClient)](https://github.com/oceanbase/obconnector-c/releases/tag/v2.2.14)
from OceanBase's official release. The vendor library is **not bundled** with
HammerDB or copied into this source repository. It is an open-source LGPL
library supporting OceanBase MySQL and Oracle compatibility modes; this
HammerDB category still supports only MySQL tenants. Community Edition provides
MySQL mode, while Enterprise Edition provides both modes.

For the verified Ubuntu 24.04 x86-64 configuration, download
`libobclient-2.2.14-2.el7.x86_64.rpm` from the linked official release and extract
it into a private directory. Extraction does not install an RPM into Ubuntu:

```sh
sudo apt-get install libarchive-tools
printf '%s  %s\n' \
  707338260d5d9c14556407b45c99844c5ac7bed4de68da793d33c0483225630d \
  libobclient-2.2.14-2.el7.x86_64.rpm | sha256sum --check
mkdir -p "$HOME/.local/oceanbase-client"
bsdtar -xf libobclient-2.2.14-2.el7.x86_64.rpm \
  -C "$HOME/.local/oceanbase-client"
export LD_LIBRARY_PATH="$HOME/.local/oceanbase-client/u01/obclient/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
cd /path/to/HammerDB
./hammerdbcli
```

Use the same environment to start `./hammerdb`, `./hammerdbcli py` or
`./hammerdbws`. The library in this release is named `libobclnt.so.2`, despite
the product/package name LibobClient. On another Linux installation, use its
matching architecture/OS package and add the installed library directory to
`LD_LIBRARY_PATH`. The Linux ARM64 build recipe is provided, but the validation
record below is for x86-64. Do not use an x86-64 library on ARM64.

In the CLI, run:

```tcl
librarycheck
puts [obmysql::baseinfo clientversion]
```

The OceanBase result should be `Success ... loaded library obmysqltcl for
OceanBase`. Other databases may report missing libraries if their separate
clients are not installed. The OB 2.2.14 client API identifies itself as
`10.5.5`; this compatibility string is not the downloaded package version.
Library loading checks dependencies, not the database login; configure the
business-tenant connection above and run schema check/build next.

No `TCLLIBPATH` override, MySQL client installation or manually obtained
`mysql_native_password` plugin is needed for this OceanBase driver. Do not
rename `libobclnt` to `libmysqlclient`: the stock MySQL binding requires different
versioned symbols and prepared-statement layouts. If the error says
`can't find package obmysqltcl`, install a HammerDB build containing this
binding. If it names `libobclnt.so.2` or another shared library, check the client
installation, CPU architecture and loader path. Authentication errors still
require valid credentials and tenant access.

### Building the binding (HammerDB maintainers)

The in-tree source and license are in `Build/obmysqltcl`. Linux BAWT builds the
package against its own Tcl runtime, copies the resulting binding into the
normal application library tree, and embeds it in the GUI, CLI and Web Service
executables. `OBCLIENT_ROOT` must point to an externally installed Connector/C
SDK containing `include/mysql.h` and `lib/libobclnt.so` (or
`lib64/libobclnt.so`). For example:

```sh
export OBCLIENT_ROOT=/path/to/oceanbase-client/u01/obclient
cd Build/Bawt-2.1.0
./Build-Linux.sh x64 Setup/HammerDB-Linux.bawt update
```

The other database SDK prerequisites in the
[HammerDB source-build guide](https://www.hammerdb.com/docs/ch01s19.html)
still apply. For native Linux ARM64 use the `arm64` architecture and
`Setup/HammerDB-LinuxArm64.bawt` with a matching SDK. Windows builds retain the
other database bindings but do not include `obmysqltcl` in this contribution.
A missing OB SDK is a build error on an enabled Linux build; it never silently
substitutes the MySQL client. See `Build/obmysqltcl/README.md` for the isolated
binding build command and provenance. Neither the SDK nor the vendor runtime
is copied into the HammerDB distribution.

### OBProxy connection notes

OBProxy remains an optional routing endpoint. Earlier tests of the MySQL client
reported numeric character-set diagnostics on direct OBServer connections,
while OBProxy removed the problematic tracking item. The current OceanBase
backend uses its own Connector/C binding, so a proxy is not required solely to
avoid those MySQL-client diagnostics. The historical client comparisons are
recorded below; they do not establish a server protocol fix.

In the earlier OBProxy 4.3.5.0-3 / CE 4.4.2.1 deployment, C schema checking with
temporary tables required `client_session_id_version=2` and a unique `proxy_id`
(`1` for the single test proxy). The Docker image accepts these as
`ODP_CLIENT_SESSION_ID_VERSION=2` and `ODP_PROXY_ID=1`. If a proxy reports
`obproxy version is too old or config not right, create temporary table not supported`,
check these proxy settings and establish new connections. These are proxy
settings, not HammerDB `diset` options.

## Database metrics (ASH)

Select OceanBase, configure the connection and credentials for the selected
TPROC-C or TPROC-H workload, and open **Metrics > Options**. Leave **CPU Metrics
Only** unchecked, then select **Metrics > Display**. ASH uses that workload's
business-tenant connection, including tenant/cluster routing, TLS and session
timeout settings. The agent settings in the options dialog apply to host CPU
metrics. The existing CLI `metstart` command remains a host CPU metrics command.

The monitor reads `oceanbase.GV$OB_ACTIVE_SESSION_HISTORY` across the current
tenant's OBServer nodes. It includes foreground CPU activity and non-idle waits
from all workloads in that tenant, not only the configured benchmark database.
It refuses the sys tenant. The account must be able to read this view; an absent
view or insufficient permission is reported without creating a sampling schema,
installing an event, or changing global database parameters.

The activity chart uses completed 15-second buckets and native sample weights
to calculate average active sessions. Empty retained intervals contribute zero
activity. On initial load, the chart starts at the earliest retained sample's
bucket rather than presenting older missing history as idle activity.
SQL and wait-event breakdowns use the selected interval. Session identities
include the OBServer address and port so equal session IDs on different nodes
are not merged. Sampling can miss short operations and is not an exact execution
count or a transaction-performance result.

SQL text and execution statistics come from
`oceanbase.GV$OB_PLAN_CACHE_PLAN_STAT`. Statistics are labelled as plan-cache
lifetime totals, not totals for the selected ASH interval. Cached-plan details
read `oceanbase.GV$OB_PLAN_CACHE_PLAN_EXPLAIN` for a matching node and plan ID.
When multiple plans exist for an SQL ID, the display selects one currently
cached plan; it is not a reconstruction of the plan at a historical sample.
Missing permissions or aged-out cache entries produce an unavailable message,
while ASH monitoring continues. The monitor does not execute the sampled SQL
or run `EXPLAIN` against it.

## Workloads and results

The independent OceanBase dialogs use MySQL's **Connection / Settings** layout,
control types and option dependencies. OceanBase credentials and workload
settings are saved separately from MySQL. Driver Options generates the selected
driver when OK is clicked; Cancel discards edits.

TPROC-C supports schema creation/checking/deletion, stored procedure test and
timed drivers, prepared procedure calls, client SQL, Cluster Connect Pool,
asynchronous client scaling, Time Profile and an invisible history primary key.
The legacy MySQL `Partition` checkbox is not exposed here;
OceanBase schema distribution is controlled by `Distributed schema` and
`Partition count`. Enable the distributed TPROC-C layout with:

```tcl
diset tpcc ob_distributed_schema true
diset tpcc ob_partition_count 24
```

Warehouse-related tables are hash-partitioned by warehouse ID in a tablegroup
using `SHARDING='PARTITION'`; the item table uses
`DUPLICATE_SCOPE='CLUSTER'`. This option affects new schema creation only.
The distributed layout was exercised on OceanBase 4.4.2.1 with three replicas.

### Optional TPROC-C client features

`ob_prepared` selects prepared procedure calls; `ob_no_stored_procs` selects
client SQL. Cluster Connect Pool (`ob_connect_pool`) requires prepared stored
procedures. Configure its endpoints and per-transaction routing policies in
`config/connectpool/obcpool.xml`, independently of MySQL's pool configuration.
Each endpoint has separate `ob_user`, `ob_tenant`, `ob_cluster`, `ob_pass` and
`ob_dbase` fields, plus host, port and TLS options. All endpoints must reach the
same business tenant and dataset. This is HammerDB's multiple-endpoint
transaction routing pool; no sys tenant connection is needed.

Asynchronous Scaling (`ob_async_scale`) uses the native client scheduling and
requires the Timed Driver Script and Keying and Thinking Time. The dialog sets
the required dependencies. `ob_async_client`, `ob_async_delay` and
`ob_async_verbose` control clients per active VU, login delay in milliseconds
and output. The timed driver also creates a monitor VU, which does not run
asynchronous clients. These are multiple client sessions scheduled by HammerDB;
this option does not change the server's SQL execution model.

`ob_history_pk` adds the native invisible AUTO_INCREMENT history ID without
using MySQL's version-number gate. For distributed history, the primary key is
`(h_w_id,id)` and `h_w_id` is NOT NULL to satisfy OceanBase's partitioned primary
key requirements. Enable this before building a fresh schema. It requires an
OceanBase version supporting invisible columns and was tested on 4.4.2.1.

Time Profile (`ob_timeprofile`) and Use All Warehouses (`ob_allwarehouse`) are
timed-driver options. Selecting the Test Driver Script clears timed-only
options in the dialog.

TPROC-H uses abbreviated-month parsing consistently for load and refresh data,
case-insensitive table discovery, and regular MySQL `ANALYZE TABLE`. Its single
user refresh driver runs RF1, the 22 queries, then RF2. Keep verbose result output
off for ordinary validation; some queries return many values.
Cloud Analytic Queries (`ob_cloud_query`) selects the native MySQL cloud query
workload. It does not enable HeatWave server features on OceanBase.

### Optional OceanBase distributed TPROC-H schema

Enable `Distributed schema` in the TPROC-H Schema Options **Settings** tab and
set `Partition count`, or configure:

```tcl
diset tpch ob_tpch_optimized_schema true
diset tpch ob_tpch_partition_count 24
```

This opt-in layout adds OceanBase distribution and storage options to HammerDB's
original MySQL TPROC-H table definitions. Column names, string lengths, nullability,
primary keys, secondary indexes and foreign keys are retained from the native
builder; a separate set of column definitions is not maintained. Selected numeric
types are adapted: part/customer keys use BIGINT, analytical amounts generally use
DECIMAL(15,2), supplier account balance uses DECIMAL(12,2), and LINEITEM quantity
and PARTSUPP supply cost use DECIMAL(15,2).

Six large tables use KEY partitioning, and all eight tables explicitly use
`WITH COLUMN GROUP(each column)` and `ROW_FORMAT=CONDENSED`.
LINEITEM/ORDERS share one tablegroup by order key; PART/PARTSUPP share another by
part key. The tablegroups use modern `SHARDING='PARTITION'` syntax.
LINEITEM retains its primary key `(L_ORDERKEY,L_LINENUMBER)`, and ORDERS retains
`(O_ORDERKEY)`. Customer and supplier comments retain HammerDB's 118/102-character
capacities, matching its existing data generator.

The layout also adds a local covering index on LINEITEM
`(L_SHIPDATE,L_PARTKEY,L_SUPPKEY,L_DISCOUNT,L_QUANTITY,L_EXTENDEDPRICE)`.
It provides a date-range access path for Q6, Q14 and Q15 while preserving the
order-key primary key and the existing secondary indexes. The additional index
uses storage and must also be maintained during data loading and refreshes.
For Q7, `scripts/sql/oceanbase/tproch-tuning.sql` includes a commented optional
outline example to use this index after verifying the benefit on your workload.

The default remains false for existing configurations. This option only affects
new schema builds; it does not migrate existing tables. Use a fresh database and
regenerate the build script. The partition count is independent of loader threads
and query parallelism. Apply `scripts/sql/oceanbase/tproch-tuning.sql` separately
for runtime tuning. The optimized DDL requires an OceanBase version supporting
column groups; the layout is validated on OceanBase 4.4.2.1. It retains HammerDB's query text
and does not establish a certified TPC-H result.

Timed TPROC-C and its transaction chart both read the business tenant's
`trans commit count` and `trans rollback count` from `oceanbase.GV$SYSSTAT`, summed
across the tenant's OBServers. The user needs permission to read this view.
These are OceanBase server transaction counters, not MySQL `Com_*` statement
counters. NOPM continues to use the change in `district.d_next_o_id`; the report
identifies TPM as OceanBase. Do not silently substitute a missing counter with
zero or assume that a different database's TPM has identical accounting. Other
activity in the same tenant, including monitoring, can contribute to these counters.

The H transaction chart uses the tenant's cumulative `sql select count`, excluding
its own polling requests from the delta. It is a tenant SQL activity indicator,
not the number of completed benchmark query sets. SQL Audit/ASH database metrics
are not exposed by this category yet; generic host CPU metrics remain available.

Transaction Counter Options has independent OceanBase connection fields and a
Settings tab for refresh interval (1–59 seconds), logging, unique log names and
timestamps. These preferences persist in HammerDB's generic counter settings,
as they do for MySQL. Counter startup, polling and shutdown use the OceanBase
tenant counters above.

## Reproducible CLI runs

The Tcl and Python examples each provide build, check, run, delete and result
phases under `scripts/{tcl,python}/oceanbase/{tprocc,tproch}/`. Every database
operation selects the standalone `ob` category. The old `mysql/` combined examples
and the older MySQL-category H examples have been retired.

From the HammerDB root, supply a **new** database name for a build:

```sh
export OB_HOST=127.0.0.1 OB_PORT=2883 OB_TENANT=test OB_CLUSTER=obcluster OB_USER=root
export OB_PASSWORD='' OB_DATABASE=tpch_ob_trial
export OB_SCALE_FACTOR=1 OB_BUILD_USERS=1 OB_QUERY_TIMEOUT=120
./scripts/tcl/oceanbase/run.sh tcl tproch all
```

`OB_HOST`, `OB_USER` and `OB_DATABASE` must be nonempty. `OB_PASSWORD`, `OB_TENANT`
and `OB_CLUSTER` may be empty or omitted; an empty tenant and cluster select the
bare-username login used by the documented Cloud connection. Enter environment
values literally, without Tcl escaping. Both languages preserve empty passwords,
spaces, quotes and Tcl metacharacters.

The runner accepts `tcl` or `python`, `tprocc` or `tproch`, and one phase or `all`.
For example, reuse the schema above through the real Python CLI:

```sh
./scripts/tcl/oceanbase/run.sh python tproch check
./scripts/tcl/oceanbase/run.sh python tproch run
./scripts/tcl/oceanbase/run.sh python tproch result
```

`all` runs build, check, run and result in separate CLI processes. It stops if a
phase fails and **retains the database**. Neither the runner nor a build deletes
an existing schema automatically. Deletion is a separate, explicit invocation:

```sh
./scripts/tcl/oceanbase/run.sh tcl tproch delete
```

The individual files follow the existing HammerDB example names:

| Phase | TPROC-H filename (replace `tproch` with `tprocc` for C) |
| --- | --- |
| Build | `ob_tproch_buildschema.tcl` / `ob_tproch_buildschema.py` |
| Check | `ob_tproch_checkschema.tcl` / `ob_tproch_checkschema.py` |
| Run | `ob_tproch_run.tcl` / `ob_tproch_run.py` |
| Delete | `ob_tproch_deleteschema.tcl` / `ob_tproch_deleteschema.py` |
| Result | `ob_tproch_result.tcl` / `ob_tproch_result.py` |

For direct execution, run `./hammerdbcli auto scripts/tcl/oceanbase/tproch/ob_tproch_buildschema.tcl`
or `./hammerdbcli py auto scripts/python/oceanbase/tproch/ob_tproch_buildschema.py`
from the HammerDB root. Python requires the interpreter version supported by the
HammerDB package; the reference Ubuntu 24.04 run used Python 3.12. The current
OceanBase backend cannot run on Windows until a matching `obmysqltcl` binding is
provided. The example shell runner is for Unix-like systems.

These examples use ordinary schemas, stored-procedure C and the standard H
queries. C defaults to one warehouse, one build VU, and a timed run with one
minute of ramp-up and one minute of measurement. Its default `OB_USERS=2` runs two workload VUs; HammerDB adds a separate monitor
VU. H defaults to SF1, one loader, one query VU and
one query set, with refresh functions disabled. Optional numeric overrides are
`OB_PORT`, `OB_QUERY_TIMEOUT`, `OB_BUILD_USERS`, `OB_WAREHOUSES`, `OB_USERS`,
`OB_RAMPUP`, `OB_DURATION`, `OB_SCALE_FACTOR` and `OB_QUERYSETS`. The examples do
not override saved TLS settings; configure the appropriate `ob_ssl_*` settings
when TLS is required. Use the CLI directly for distributed layouts and other
advanced workload options described above.

The Jobs repository must be enabled before `run`; if disabled, issue
`jobs disable 0` and restart HammerDB. The runner uses `TMP` (or `TMPDIR`, then
`<HammerDB>/TMP`) consistently across phases. Keep the same temporary directory
and Jobs repository for result retrieval. A successful run saves its job ID in
`ob_tprocc.jobid` or `ob_tproch.jobid` there. The result phase reads the latest
successful job, or `OB_JOB_ID` if supplied, prints the framework's result data
and saves the same labeled text output as the existing generic examples in
`ob_tprocc_<jobid>.out` or `ob_tproch_<jobid>.out`. Result retrieval does not
need database credentials. Phase logs are also retained in the temporary
directory.

### Independent binding and packaged runtime validation (2026-11-03)

The independent `obmysqltcl` binding was compiled through the native BAWT
component build on Ubuntu 24.04 x86-64 against official LibobClient 2.2.14.
CLI and Web Service test executables were assembled from the official HammerDB
6.1.1 runtime with the current contribution's source and compiled binding.
This verified embedded package discovery, but was not a full native rebuild of
all HammerDB dependencies. Both executables loaded the embedded binding with
`TCLLIBPATH` unset; removing the external vendor library produced an explicit
dependency error without falling back to the MySQL driver.

The documented `bsdtar` installation procedure was used to extract the official
client RPM. With that external library and the assembled CLI, direct connections
to CE 4.4.2.1 completed a fresh one-warehouse C build and statistics, schema
checks before and after 1,000 prepared stored-procedure iterations covering all
five transaction types, and transaction-counter polling. The retained SF1 H
schema completed check, statistics and all 22 queries in 165 seconds with the
120-second session timeout unchanged. These C/H runs emitted no character-set
diagnostics. The Python CLI H schema check also passed. The temporary C schema
was deleted; the existing H dataset was preserved. This run did not rebuild the
complete H dataset or repeat H refresh functions, and is not a performance
comparison.

Both binding load orders passed 50 isolation checks in total, including
nonempty-password authentication, Unicode, independent handles and error state,
and interpreter cleanup. In the same interpreter, the original MySQL binding
passed queries and SQL PREPARE/EXECUTE against native MySQL 8.4.13 while the OB
binding connected to OceanBase. Real OceanBase TLS checks accepted a matching
certificate signed by the configured CA and rejected an untrusted CA, a
nonexistent CA file and a hostname mismatch. Requesting TLS against a server
without TLS was rejected rather than silently using plaintext.

The revised source passed 118 external regression assertions and 55 ASH provider
checks. Another 33 real Tk/ASH checks exercised SQL, cached plans/statistics,
aged-out entries, VU lifecycle and reconnection using the independent binding.
These GUI checks loaded the source into the official runtime; acceptance of a
newly packaged GUI executable remains unverified. The Linux ARM64 recipe is
untested, and this contribution does not supply a Windows OB binding.

The following records describe earlier revisions and client arrangements; their
remaining character-set warnings do not describe the independent-binding runs
above.

### Reference Docker configuration and pre-review validation (2026-11-03)

The reference installation used the official
`oceanbase/oceanbase-ce:4.4.2.1-101000022026050611` image with `MODE=mini`,
`--ulimit nofile=65536:65536` and port 2881 bound to loopback. The Ubuntu 24.04
host had 8 vCPUs and 32 GiB memory; the mini business tenant used its default
3 GiB allocation. The database-engine image is supplied by OceanBase, not built
by this contribution.

With `ob_scale_fact=1`, `ob_num_tpch_threads=1`,
`ob_tpch_optimized_schema=false` and `ob_query_timeout=120`, pre-review revision
`89d33fe7` completed H build and check, followed by a Python CLI check and
all 22 queries. Build took 1,628 seconds and the query set 165 seconds in that
environment; these are functional-test observations, not performance targets.
The H build emitted one character-set `45` warning during statistics collection.

C build/check, 1,000 stored-procedure test iterations and post-run check also
completed. Python CLI check/run/postcheck completed separately. Repeated
character-set `255` warnings were reproduced even in a fresh CLI process whose
first operation was a workload run.

A separate four-loader H test, in a tenant retaining the preceding C schema,
completed PART and PARTSUPP (200,000 and 800,000 rows). Sampled statements had no
timeout; the longest sampled PARTSUPP insert was 18.862 seconds. Subsequent
LINEITEM inserts experienced `memstore memory page alloc wait`, with a sampled
maximum of 79.371 seconds. That run was stopped deliberately before ORDERS and
LINEITEM finished; it is **not** a complete four-loader validation and did not
reproduce the reported 120-second PART/PARTSUPP timeout. The original reported
failure remains under investigation. Start mini installations with one loader
and inspect tenant resources and waits before increasing concurrency; increasing
the timeout alone does not establish the cause of a slow build.

### Review follow-up validation (2026-11-03)

The revised Tcl and Python C examples each completed build, check, timed run,
result retrieval and explicit deletion on a fresh one-warehouse ordinary schema.
These runs connected directly to OBServer.
The runs used two active VUs plus the monitor, zero ramp-up and one minute of
measurement. Both saved job reports contained nonempty transaction timings,
transaction-counter samples and NOPM/TPM results. The Tcl run used an empty
password; the Python run used a dedicated username containing a dollar sign and
a password containing spaces, quotes, dollar signs, brackets and braces. The
Python credentials were read back in a new CLI process and used for a successful
schema check without reconfiguration. Both temporary schemas and the dedicated
user were removed after validation. The character-set warnings described above
still occurred; these results establish functionality, not warning-free operation
or benchmark performance.

The revised H examples were checked against the same installation. The Tcl
check and all 22 queries used the existing SF1 dataset; the query set completed
in 180 seconds. Python check and both languages' result phases exited normally.
Both result files contained all 22 query records from the saved job. A separate
fresh-schema test executed the revised eight-table DDL, loaded 1,000 PART and
4,000 PARTSUPP rows, and deleted that test schema. This follow-up did not rebuild
the complete SF1 dataset.

A separate native MySQL 8.4.13 smoke test passed a one-warehouse C build, check,
100 stored-procedure test iterations and post-check. Its H test exercised the
native eight-table DDL, a partial dataset with 20 PART and 80 PARTSUPP rows,
ANALYZE, RF1 and RF2. It did not perform a full native MySQL H SF1 build or all
22 analytical queries. Windows execution remains unverified.

### Native ASH validation (2026-11-03)

The native ASH provider was tested with current source loaded into the official
HammerDB 6.1.1 Ubuntu 24.04 x86-64 runtime against the same CE 4.4.2.1 tenant.
The 46 provider checks cover weighted averages, empty intervals, midnight
boundaries, SQL time-series gaps, node-qualified sessions, special credentials
and query validation. Six real Tk/dispatch checks cover provider switching and
metrics options. The existing 116 external regression checks also passed.

Live checks displayed workload samples, Top SQL, sessions, events, SQL text,
actual plan-cache statistics and a cached execution plan. VU creation, execution
and destruction left the ASH collector running and excluded from the VU count.
Stopping and reconnecting released and recreated the collector correctly; an
authentication failure also released its thread. An aged-out/missing SQL ID
displayed an unavailable message without stopping ASH. The live environment had
one OBServer; multi-node identity aggregation was checked with fixtures rather
than a new multi-node deployment.

### LibobClient direct-connection validation (2026-11-03)

Before the independent `obmysqltcl` binding, source revision `9f598829` was
tested with an isolated rebuild of `mysqltcl` against LibobClient 2.2.14,
connecting directly to the same CE 4.4.2.1 tenant. A fresh one-warehouse C schema completed
build/statistics, check, 1,000 prepared stored-procedure test iterations covering
all five transaction types, counter polling and postcheck. The retained SF1 H
schema completed check, statistics and all 22 queries in 172 seconds, with the
120-second session timeout unchanged. These workloads emitted no character-set
diagnostics. The C schema was temporary; the existing H data was preserved.

Additional checks covered native C API prepared parameter/result bindings, a
57-byte UTF-8 string containing Chinese, emoji, quotes and a newline through both
the C API and `mysqltcl`, and nonempty-password authentication without loading an
external authentication plugin. A controlled comparison explicitly selected
`utf8mb4`/`utf8mb4_bin` for both clients: the same direct SLEV calls still emitted
diagnostics with libmysqlclient 8.4.5 and none with LibobClient 2.2.14. The process
library mappings confirmed that workload VUs and the counter used the rebuilt
binding and OB library. This did not rebuild the complete H dataset, test H
refresh functions, validate Enterprise Edition/Oracle tenants, or revalidate TLS.

### OBProxy follow-up validation (2026-11-03)

PR source revision `62d4449f` was loaded into the same official HammerDB 6.1.1
Ubuntu 24.04 x86-64 runtime, with the same external libmysqlclient 8.4.5 and
OceanBase CE 4.4.2.1 installation. The proxy image was
`oceanbase/obproxy-ce:4.3.5.0-3`, digest
`sha256:c173d61281b1658e9cd8fe031c7216f036a5850658009c2484f2fd039c017564`.
Three identical `CALL SLEV(1,1,10,@x)` calls per route used the same tenant and
schema: all three direct calls returned numeric character-set tracking and a
`255` warning; all three proxy calls returned no such tracking item or warning.

Through the proxy, a fresh one-warehouse C schema completed build and statistics.
After enabling the V2 session-ID setting described above, schema check, 1,000
stored-procedure test iterations covering all five transaction types, post-run
check, counter polling and deletion passed. H schema check, statistics collection
and all 22 queries passed on the retained SF1 dataset; the query set completed
in 169 seconds with the unchanged 120-second session timeout. None of these
proxy workloads emitted character-set warnings. Raw logs were retained without
filtering; later C invocations also contain startup notices from the official
runtime's embedded source before the initializer loads this PR's source.

This establishes a proxy workaround for the tested combination, not a fix for
direct OBServer connections or a newly built PR package. This follow-up did not
repeat the complete H data load, refresh functions, prepared calls or TLS checks,
and does not establish a performance comparison.

## Validation status (2026-09-14)

Validated on Linux x86-64 against OceanBase Enterprise 4.3.5.6, a MySQL tenant,
and OBProxy 4.4.1.0: two-warehouse C build/check, direct and proxy procedure calls,
prepared calls, non-procedure calls, timed results, and post-run consistency;
H SF1 build/check, all 22 queries, RF1/queries/RF2 through the proxy, and final
consistency. Counter polling, rejected credentials, existing configuration
migration, and 29 helper/generated-driver assertions passed. The original
MySQL installation and earlier test databases were retained.

This is compatibility validation, not a performance result or certification.
At that date, Windows execution, TLS connections and native MySQL server
regression remained unverified. The earlier Linux GUI startup blocker was resolved during subsequent
validation. The bundled Linux MySQL client emitted a non-fatal character-set 45
warning during the earlier statistics collection; schema checks still passed.

### Additional validation (2026-10-07)

Linux x86-64 GUI testing exercised schema creation and the TPROC-C/TPROC-H
workflows on the AWS OceanBase 4.4.2.1 lab. TPROC-C was exercised with 240
warehouses and one- and three-replica tenant configurations. The three-replica
TPROC-H layout placed eight leaders from each 24-partition large table on each
OBServer, with corresponding tablegroup partitions colocated.

The Ubuntu 24.04 and RHEL9-runtime release packages each passed 39 helper tests
and 13 generated-driver tests, plus isolated GUI startup and extracted-package
CLI checks on Ubuntu 24.04. Native RHEL9 execution has not been tested. After
installing the release, the tester also reported successful manual CLI TPROC-C
and TPROC-H workflows; this is a functional confirmation, not a separately
collected performance result.

Both executable tuning SQL profiles were applied successfully to the dedicated
business tenant, with original values retained for restoration. The TPROC-H
profile uses global scope for `ob_sql_work_area_percentage` and
`parallel_servers_target`, which do not accept `SET SESSION` on the tested
OceanBase version. Tuning profiles are optional benchmark candidates and do not
establish performance gains.

### Client feature validation (2026-10-12)

The Ubuntu 24.04 x86-64 package was exercised on the three-replica OceanBase
4.4.2.1 AWS lab using fresh, isolated schemas and business-tenant credentials:

- TPROC-C native and distributed four-warehouse builds with History Primary
  Key enabled, followed by consistency checks.
- Stored procedures, prepared procedures, client SQL and a two-endpoint
  Cluster Connect Pool (OBProxy plus a direct OBServer connection).
- Timed asynchronous stored procedures, client SQL and pool drivers, each with
  three active VUs, two asynchronous clients per VU, plus the monitor VU.
- SF1 distributed TPROC-H build/check, RF1/all 22 queries/RF2/check and the
  Cloud Analytic Queries workload.
- Time Profile and counter lifecycle/logging tests. Every requested workload
  VU must finish successfully for these tests to pass.

The packaged helper, generated-driver, feature-validation and real Tk dialog
suites passed 100 assertions (60 + 19 + 8 + 13). A counter regression test also
checks that one activity burst after an idle sample is reported for both C and
H; the corresponding real-server tests observed nonzero TPM/QPH and confirmed
timestamped unique logs and removal of the worker thread after shutdown.

TLS-requested connections succeeded through both OBProxy and a direct OBServer.
This connection test did not establish mutual TLS or certificate verification.
At that date, Windows execution and native MySQL server regression remained
unverified. These tests establish functional compatibility on the stated environment, not a
performance improvement or a certified benchmark result.

## Tenant-mode extension boundary

`ob_compatibility_mode` selects a registered backend. Missing mode fields in old
OceanBase configurations are migrated to `mysql`. Only `mysql` is currently
registered; `oracle` and unknown values fail before workload generation or
connection, rather than falling back to MySQL.

The category entry points in `src/oceanbase/oboltp.tcl`, `obolap.tcl`, and
`obotc.tcl` dispatch semantic operations. They do not name MySQL generators.
`src/oceanbase/mysql/adapter.tcl` owns MySQL configuration mapping, username
construction, TLS options, schema/workload generation, session initialization,
and counter integration. `mysqlcommon` is used only by this MySQL path.

To implement Oracle tenants, add and explicitly register a separate backend
(e.g. `src/oceanbase/oracle/adapter.tcl`, namespace `oceanbase::oracle`) with:

- `generate workload action`: C build/test/timed/check/delete; H build/test/check/delete.
- `counter benchmark interval masterthread`: the Oracle connection/library and OB statistics implementation.
- `options group option` and `validate configuration`: Oracle-specific configuration, validation and UI.
- `data_format workload`: the format used by offline C/H data-file generation (`mysql` for the MySQL backend).

The Oracle backend can reuse the existing Oracle generators with isolated
configuration, as the MySQL backend does for MySQL. It must own Oracle login
rules, tablespaces/schema fields, SQL and driver initialization; it must not
route through the MySQL configuration mapper or expose MySQL engine/TLS fields.
Preserve each mode's settings when introducing Oracle-specific config groups;
the existing MySQL `ob_*` fields remain the compatibility contract. Register the
Oracle backend only after its implementation and tests are available. The
registry is an internal extension boundary, not a user-loadable plugin system.

After introducing the mode dispatcher, Linux regression also passed 4,000
non-procedure C calls, all 22 H queries, C/H counter polling, migration of a
configuration missing the mode field, and rejection of `oracle` through the
actual CLI. A test-only second backend verified that generation, counters,
options and validation dispatch independently of the MySQL implementation.

Empty optional values are supplied by `oceanbaseconfig::normalize` after loading
OceanBase XML or saved SQLite configuration. Existing values, including explicit
empty strings, are preserved. The shared XML parser is unchanged. MySQL password
defaults are only applied to the MySQL tenant mode.

Offline data generation resolves native database formats in one shared helper.
Additional categories supply a `<prefix>_data_generation_format` callback;
OceanBase delegates this to its selected backend's `data_format` operation.
Unsupported tenant modes fail before creating data-generation virtual users or
files. Adding an Oracle backend does not require changing the C/H data generators.

Offline generation was also validated on AWS Linux: one C warehouse produced all
nine files, and H SF1 produced all eight files with the expected fixed table
cardinalities and approximately six million line items. Customer timestamps in
the C files use the MySQL date-time format. Fresh and persisted OceanBase
configuration defaults and rejection of Oracle data generation passed as well.
