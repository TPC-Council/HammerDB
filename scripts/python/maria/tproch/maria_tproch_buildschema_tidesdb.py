#!/bin/tclsh
# maintainer: TidesDB

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-H')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

vu = tclpy.eval('numberOfCPUs')
diset('tpch','maria_scale_fact','1')
diset('tpch','maria_num_tpch_threads',vu)
diset('tpch','maria_tpch_user','root')
diset('tpch','maria_tpch_pass','maria')
diset('tpch','maria_tpch_dbase','tpch')
diset('tpch','maria_tpch_storage_engine','tidesdb')
diset('tpch','maria_tpch_tidesdb_compression','lz4')
diset('tpch','maria_tpch_tidesdb_sync_mode','full')
diset('tpch','maria_tpch_tidesdb_write_buffer_size','134217728')
diset('tpch','maria_tpch_tidesdb_bloom_filter','true')
diset('tpch','maria_tpch_tidesdb_use_btree','false')
diset('tpch','maria_tpch_tidesdb_isolation_level','repeatable_read')
diset('tpch','maria_tpch_tidesdb_flush_threads','2')
diset('tpch','maria_tpch_tidesdb_compaction_threads','2')
diset('tpch','maria_tpch_tidesdb_block_cache_size','268435456')

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
