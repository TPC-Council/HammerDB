# Quack driver for sqlxtc

This directory adds HammerDB support for **sqlxtc**, the networked,
threaded SQL engine shipped as the `06_sqlxtc` example of the
[libxtc](https://codeberg.org/gregburd/libxtc) project.  sqlxtc speaks a
tiny newline-delimited-JSON wire protocol called **Quack** over plain
TCP (default port `15432`); see the sqlxtc `PROTOCOL.md`.

## Files

| File | Purpose |
|------|---------|
| `../../modules/quacktcl-1.0.tm` | Pure-Tcl Quack client package (no external deps): `quackconnect`, `quackexec`, `quacksel`, `quackcommit`, `quackrollback`, `quackclose`, `quackping`, `quackescape`. Includes a minimal flat-JSON encoder/decoder for the Quack framing. |
| `quackoltp.tcl` | TPROC-C schema build (`build_quacktpcc`) and driver (`loadquacktpcc` / `loadtimedquacktpcc`). |
| `quackolap.tcl` | TPROC-H placeholder - not offered for Quack (see Limitations). |
| `quackotc.tcl`  | Transaction-counter thread (reads a client-side commit counter). |
| `quackopt.tcl`  | GUI configuration dialogs. |
| `quackmet.tcl`  | Metrics-screen stub (no server-side stats views in sqlxtc). |
| `quackci.tcl`   | CI stubs (sqlxtc is an example binary, not a managed server). |
| `../../config/quack.xml` | Default configuration. |

## Using it

```sh
# 1. Build and start sqlxtc (from the libxtc tree):
cd libxtc/examples/06_sqlxtc && XTC_BUILD=/path/to/build make
./sqlxtc-server -p 15432 -d /path/to/tpcc.db      # durable file

# 2. Drive it from HammerDB CLI:
dbset db quack
dbset bm TPROC-C
diset connection quack_host 127.0.0.1
diset connection quack_port 15432
diset tpcc quack_count_ware 1
diset tpcc quack_num_vu 1
buildschema
# then load/run the driver
```

The connection target is just host + port - sqlxtc has no users,
passwords, databases or tablespaces.

## What sqlxtc supports (verified against the live server)

Fully working and used by this driver:

* `CREATE TABLE` (incl. composite `PRIMARY KEY`), `INSERT` (incl.
  multi-row `VALUES`), `UPDATE` (with arithmetic), `DELETE`;
* `BEGIN` / `COMMIT` / `ROLLBACK` transactions;
* `SELECT` with `WHERE`, `ORDER BY`, `LIMIT`, `BETWEEN`, `IN (subquery)`;
* aggregates (`COUNT`, `SUM`, `AVG`, `MAX`, `COUNT(DISTINCT ...)`) and
  `GROUP BY` **on a single table**;
* explicit `JOIN ... ON` for **projection** (non-aggregate) queries,
  when the projected columns are **table-qualified**.

## sqlxtc limitations (the honest gap list)

These are engine limitations discovered while building the driver; the
driver works *around* the first three and is blocked by the rest:

1. **No `CREATE INDEX`.** sqlxtc has no secondary-index DDL, so this
   driver omits all indexes.  The schema is correct and all queries
   return correct results, but every non-primary-key lookup is a table
   scan.  This is the dominant performance limit (see below).
2. **No comma-joins.** `FROM a, b WHERE ...` is rejected; the driver
   uses explicit `JOIN ... ON` instead.
3. **Join projections must be table-qualified.** `SELECT a.x, b.y ...`
   works; unqualified `SELECT x, y ...` across a join is rejected.
4. **No `JOIN` combined with aggregation.** `SELECT SUM(...) ... a JOIN
   b ...` / join + `GROUP BY` returns `unsupported SQL (native
   engine)`.  The stock-level transaction is therefore expressed as a
   single-table `COUNT(DISTINCT ...)` with an `IN` subquery (equivalent
   result).
5. **No `SELECT ... FOR UPDATE`, no `START TRANSACTION`** (use `BEGIN`),
   no server-side commit statistics, no catalog / performance views.

Because nearly every TPC-H query is a multi-table join *with*
aggregation (limitation 4), and several reference queries also need
server-side functions sqlxtc lacks (`pgmedian`, `pgpercentile_cont`,
`array_agg`), **TPROC-H is not offered for Quack** - only TPROC-C.

## Metrics

* **NOPM** is derived exactly as the other drivers do, from
  `sum(d_next_o_id)` over the district table (single-table aggregate,
  supported).
* **TPM** is counted client-side (each committed business transaction
  increments the shared tsv counter `application quack_txn`), because
  sqlxtc exposes no server-side commit counter.

## Verified result (libxtc 06_sqlxtc example, c6id.4xlarge, local NVMe)

* 1-warehouse TPROC-C schema built cleanly and durably: 1 warehouse,
  10 districts, 30000 customers, 100000 items, 100000 stock, 30000
  orders, 300557 order_lines, 9000 new_orders, 30000 history rows.
* Full transaction mix ran clean: 298/300 transactions committed with
  zero SQL errors (the 2 non-commits are the spec-mandated 1% New-Order
  rollbacks).
* Throughput is low (~15 NOPM single-connection) and does not scale with
  concurrency on a single warehouse - a direct consequence of the
  missing secondary indexes (limitation 1): each customer/stock/order
  lookup is a full table scan.  When sqlxtc gains `CREATE INDEX`, this
  is expected to improve by orders of magnitude with no driver change.
