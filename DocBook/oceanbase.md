# OceanBase

Select **OceanBase** in Benchmark Options, or use `dbset db ob` in
the CLI. This category reuses HammerDB's MySQL TPROC-C and TPROC-H workloads.
The existing OceanBase option under MySQL remains available for compatibility.
Oracle-compatible tenants are not supported by this category yet.

## Connection

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

Direct connections use `user@tenant`. For OBProxy, set its port (normally 2883)
and `ob_cluster`; the login becomes `user@tenant#cluster`. A sys tenant account,
shared administrative password, SQL extension, and cluster parameter changes
are not required. TLS settings are available in the connection configuration
on Linux and Windows; enabling OceanBase does not disable TLS.

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

Set `OB_HOST`, `OB_TENANT`, `OB_USER`, `OB_PASSWORD`, and a **new** `OB_DATABASE` in
the environment, then run either script:

```sh
./hammerdbcli auto scripts/tcl/oceanbase/mysql/tprocc.tcl
./hammerdbcli auto scripts/tcl/oceanbase/mysql/tproch.tcl
```

On Windows use `hammerdbcli.bat` from a source/development installation (or the
packaged `hammerdbcli.exe`). The Tcl scripts use platform-neutral paths.
Optional environment settings include `OB_PORT`, `OB_CLUSTER`, `OB_QUERY_TIMEOUT`,
`OB_BUILD_USERS`, and the workload's `OB_WAREHOUSES`, `OB_USERS`, `OB_RAMPUP`,
`OB_DURATION`, or `OB_SCALE_FACTOR`. The scripts fail when a virtual user fails,
check data before and after execution, and retain the test database.

Runtime helper tests can be run with Tcl 8.6 or newer:

```sh
tclsh tests/oceanbase.tcl
```

Generated-driver regression tests run inside the CLI. The suite uses disposable
copies of the configuration databases and removes them on success or failure;
saved passwords and benchmark settings are retained.

```sh
./hammerdbcli auto tests/oceanbase-generated.tcl
./hammerdbcli auto tests/oceanbase-feature-validation.tcl
```

The real Tk dialog suite runs in the packaged CLI with a working X display and
the matching `hammerdb` GUI executable in the current directory. It uses
disposable configuration copies and retains saved credentials and preferences:

```sh
./hammerdbcli auto tests/oceanbase-options.tcl
```

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
Windows execution and native MySQL server regression remain unverified. These
tests establish functional compatibility on the stated environment, not a
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
