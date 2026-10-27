-- OceanBase MySQL tenant: executable HammerDB TPROC-C benchmark tuning.
-- OceanBase tuning recommendations adapted for HammerDB TPROC-C.
-- These are benchmark candidates, not measured HammerDB improvements or
-- production defaults. Check parameter availability on your OceanBase version.
-- Sourcing this file records current settings, then applies the profile below.
-- Connect as an administrator of the BUSINESS tenant (e.g. root@hammerdb),
-- not root@sys. Do not apply this file to the OCP metadata tenant.
-- Save the output below before changing anything; restore the recorded values
-- after the experiment. Do not assume that product defaults are your baseline.
-- Example: obclient ... --batch < tprocc-tuning.sql > tuning-before.txt

SELECT VERSION(), CURRENT_USER();
SHOW GLOBAL VARIABLES WHERE Variable_name IN
  ('ob_query_timeout', 'ob_trx_timeout', 'max_allowed_packet',
   'auto_increment_cache_size', 'ob_sql_work_area_percentage',
   'parallel_servers_target');
SHOW SESSION VARIABLES WHERE Variable_name = 'ob_query_timeout';
SHOW PARAMETERS WHERE name IN
  ('freeze_trigger_percentage', 'cpu_quota_concurrency',
   'workers_per_cpu_quota', 'enable_early_lock_release',
   'default_auto_increment_mode', 'writing_throttling_trigger_percentage');

-- 1. BUILD / STATISTICS COLLECTION
-- Start with a bounded 600-second QUERY timeout for HammerDB builds/statistics;
-- this is a HammerDB example limit, not a performance knob.
-- SET GLOBAL affects new connections; SET SESSION affects this SQL connection.
-- HammerDB explicitly overrides ob_query_timeout in every connection, so also
-- set Connection > Query timeout to 600 seconds, then reload the build driver.
-- CLI equivalent BEFORE buildschema/loadscript:
--   diset connection ob_query_timeout 600
-- For larger builds, select a measured timeout limit.
SET GLOBAL ob_query_timeout = 600000000;
SET SESSION ob_query_timeout = 600000000;
-- Only extend transaction timeout if a single transaction actually needs it;
-- changing query timeout does not extend an already-open transaction.
-- SET GLOBAL ob_trx_timeout = 600000000;
-- SET SESSION ob_trx_timeout = 600000000;

-- Build tuning candidate: allow packets up to 64 MiB. Reconnect the loaders
-- after changing a global variable. This does not increase client-side limits.
SET GLOBAL max_allowed_packet = 67108864;

-- Existing TPROC-C data can have statistics retried without rebuilding it.
-- Replace tpcc with the configured database; run AFTER all loaders finish.
-- USE tpcc;
-- SET SESSION ob_query_timeout = 600000000;
-- ANALYZE TABLE customer, district, history, item, new_order,
--               orders, order_line, stock, warehouse;
-- Then run HammerDB Schema Check before starting a timed benchmark.

-- 2. TPROC-C MEASUREMENT PROFILE (business-tenant administrator)
-- Apply between runs, reconnect VUs, and compare the entire profile against
-- the recorded baseline with warehouse count/driver/duration held fixed.
-- Compare NOPM, response times, CPU, compaction and lock waits. To attribute
-- a change, restore the baseline and test individual settings separately.

-- MemStore freeze threshold candidate: 50 percent of the MemStore limit.
-- Relative to the recorded baseline, raising this value delays freezes and
-- lowering it triggers them sooner; memory pressure and background I/O change.
ALTER SYSTEM SET freeze_trigger_percentage = 50;

-- Concurrency candidate: 2 active workers per CPU quota. This may REDUCE concurrency.
-- Check the captured workers_per_cpu_quota and keep it greater than this value.
-- Confirm the benefit of this candidate with an A/B run.
ALTER SYSTEM SET cpu_quota_concurrency = 2;

-- Disable early lock release in this profile; throughput and lock waits may change.
ALTER SYSTEM SET enable_early_lock_release = false;

-- Auto-increment candidates: NOORDER and a 10,000,000-value cache.
-- Applies to auto-increment columns, not the explicit district.d_next_o_id
-- sequence used to calculate HammerDB NOPM. IDs can have gaps / lack ordering.
ALTER SYSTEM SET default_auto_increment_mode = 'NOORDER';
SET GLOBAL auto_increment_cache_size = 10000000;

-- A value of 100 defers write throttling until the MemStore threshold is
-- reached. Consider ONLY with adequate memory/I/O headroom; this can increase
-- the risk of exhausting MemStore. Keep throttling enabled for the baseline.
-- ALTER SYSTEM SET writing_throttling_trigger_percentage = 100;

-- 3. VALUES NOT INCLUDED IN THE EXECUTABLE PROFILE
-- Larger SQL work-area and PX queuing limits are not included because they
-- must be sized for the tenant. Choose SQL work-area memory and PX concurrency
-- from tenant resources, especially for TPROC-H parallel queries.
-- SQL Audit/performance-event/trace-log disabling, OBProxy logging/protocol/QoS
-- changes and private underscore parameters are deliberately omitted: retain
-- diagnostics and proxy metrics for node-load analysis, and validate version-specific internal
-- parameters separately. No durability, locality or replica changes here.

-- 4. RESTORE / REPRODUCE
-- Restore each changed parameter/variable using the values in tuning-before.txt
-- and the SAME scope (ALTER SYSTEM / SET GLOBAL / SET SESSION) used above.
-- Reconnect after restoring global variables; restore HammerDB's connection
-- timeout too and reload its driver. Global changes do not update existing VUs.
-- Record applied settings and topology alongside the HammerDB Job/Profile ID.
-- Use the same settings in single-node and three-node comparison groups.
-- Diagnostic references:
-- https://www.oceanbase.com/docs/common-oceanbase-database-standalone-1000000002701711
-- https://oceanbase.github.io/docs/user_manual/quick_starts/en-US/chapter_07_diagnosis_and_tuning/troubleshooting_sql_performance_issues

-- 5. OPTIONAL STOCK-LEVEL OUTLINE (DISABLED BY DEFAULT)
-- Apply only when the SLEV stock-level join regresses to a large STOCK scan.
-- First compare actual executions with identical warehouse/district/threshold
-- values and verify identical counts; EXPLAIN alone does not prove a benefit.
-- OceanBase 4.4.2.1 testing of the unmodified stored procedure on a fresh
-- four-warehouse, column-store copy found the nested-loop path faster than
-- default, hash and merge paths. On already-compacted data, merge can be faster;
-- recheck after changing data, storage, warehouse scale or OceanBase version.
-- This fixes the join order/method and primary-key access paths, not every
-- operator or physical storage condition. It does not change transaction SQL.
-- All statements below are commented: sourcing this file creates no outline.
-- Copy only the optional SQL statements you need, remove their leading "-- ",
-- and execute as the SAME benchmark user in EACH configured TPROC-C database,
-- before VU warm-up. Keep the explanatory prose commented.
-- An outline is database-scoped; a new benchmark database needs its own copy.
-- Replace tpcc below with the configured database. Do not source the whole file
-- just to apply this outline: the earlier sections change other tenant settings.
--
-- USE tpcc;
-- SHOW INDEX FROM order_line WHERE Key_name = 'PRIMARY';
-- SHOW INDEX FROM stock WHERE Key_name = 'PRIMARY';
-- The intended path scans the last 20 orders for one warehouse/district, then
-- gets each STOCK row by BOTH s_w_id and s_i_id, rather than scanning a warehouse.
-- Confirm order_line's primary-key prefix is (ol_w_id, ol_d_id, ol_o_id).
-- Run an unmodified SLEV call first, then confirm its INTERNAL SELECT SQL_ID:
-- CALL SLEV(1, 1, 10, @stock_count);
-- SELECT @stock_count;
-- SELECT DISTINCT p.SQL_ID, p.STATEMENT, p.PLAN_HASH
-- FROM oceanbase.GV$OB_PLAN_CACHE_PLAN_STAT p
-- WHERE p.DB_ID IN (SELECT DISTINCT DB_ID FROM oceanbase.GV$OB_SQL_AUDIT
--                   WHERE DB_NAME = DATABASE())
--   AND p.SQL_ID = '74AF455B28BEDB63AFA6CAFC08C54A2C';
-- This ID was verified for the current native HammerDB SLEV internal SELECT,
-- including Danny 943fc46 and OceanBase Preview 4 d5b642d2. Different SQL text,
-- whitespace or Client SQL drivers can require a different ID; never bind the
-- outer CALL's SQL_ID. Inspect existing outlines before adding one; SQL_ID
-- outlines override SQL hints. Do not replace an existing outline blindly.
-- SELECT OUTLINE_NAME, SQL_ID, OUTLINE_ID
-- FROM oceanbase.DBA_OB_OUTLINES
-- WHERE DATABASE_NAME = DATABASE();
-- CREATE OUTLINE hdb_tpcc_slev_plan
--   ON '74AF455B28BEDB63AFA6CAFC08C54A2C'
--   USING HINT /*+ LEADING(order_line stock) USE_NL(stock)
--                  INDEX(order_line PRIMARY) INDEX(stock PRIMARY) */;
--
-- Reconnect and run SLEV WITHOUT adding hints to the CALL or procedure body.
-- CALL SLEV(1, 1, 10, @stock_count);
-- SELECT @stock_count;
-- Verify actual execution: the internal SELECT must use this OUTLINE_ID and
-- a nested-loop join with a STOCK primary-key get, not a broad STOCK range scan.
-- SELECT p.SVR_IP, p.PLAN_ID, p.SQL_ID, p.PLAN_HASH,
--        p.OUTLINE_ID, p.OUTLINE_DATA, p.HINTS_ALL_WORKED
-- FROM oceanbase.GV$OB_PLAN_CACHE_PLAN_STAT p
-- JOIN oceanbase.DBA_OB_OUTLINES o
--   ON p.TENANT_ID = o.TENANT_ID AND p.DB_ID = o.DATABASE_ID
--  AND p.OUTLINE_ID = o.OUTLINE_ID
-- WHERE o.DATABASE_NAME = DATABASE()
--   AND o.OUTLINE_NAME = 'hdb_tpcc_slev_plan';
-- Inspect those PLAN_IDs in GV$OB_PLAN_CACHE_PLAN_EXPLAIN and compare server
-- ELAPSED_TIME in GV$OB_SQL_AUDIT for the internal SELECT on the same inputs.
-- Do this before the benchmark; keep VUs, seeds, timings and other settings fixed.
--
-- Rollback: remove only this optional outline from the configured database,
-- reconnect, rerun SLEV and verify the new plan is no longer outline-bound.
-- DROP OUTLINE hdb_tpcc_slev_plan;
-- References (OceanBase 4.4.2 outline binding and join/index hints):
-- https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000005287850
-- https://www.oceanbase.com/docs/common-oceanbase-database-cn-1000000005287286
