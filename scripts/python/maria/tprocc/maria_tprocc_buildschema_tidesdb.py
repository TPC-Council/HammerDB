#!/bin/tclsh
# maintainer: TidesDB

print("SETTING CONFIGURATION")
dbset('db','maria')
dbset('bm','TPC-C')

diset('connection','maria_host','localhost')
diset('connection','maria_port','3306')
diset('connection','maria_socket','/tmp/mariadb.sock')

vu = tclpy.eval('numberOfCPUs')
warehouse = int(vu) * 5
diset('tpcc','maria_count_ware',warehouse)
diset('tpcc','maria_num_vu',vu)
diset('tpcc','maria_user','root')
diset('tpcc','maria_pass','maria')
diset('tpcc','maria_dbase','tpcc')
diset('tpcc','maria_storage_engine','tidesdb')
diset('tpcc','maria_tidesdb_compression','lz4')
diset('tpcc','maria_tidesdb_sync_mode','full')
diset('tpcc','maria_tidesdb_write_buffer_size','134217728')
diset('tpcc','maria_tidesdb_bloom_filter','true')
diset('tpcc','maria_tidesdb_use_btree','false')
diset('tpcc','maria_tidesdb_isolation_level','repeatable_read')
diset('tpcc','maria_tidesdb_bloom_fpr','100')
diset('tpcc','maria_tidesdb_sync_interval_us','500000')
diset('tpcc','maria_tidesdb_level_size_ratio','10')
diset('tpcc','maria_tidesdb_min_levels','5')
diset('tpcc','maria_tidesdb_skip_list_max_level','12')
diset('tpcc','maria_tidesdb_skip_list_probability','25')
diset('tpcc','maria_tidesdb_l1_file_count_trigger','4')
diset('tpcc','maria_tidesdb_ttl','0')
diset('tpcc','maria_tidesdb_encrypted','no')
diset('tpcc','maria_tidesdb_encryption_key_id','1')
if (warehouse >= 200): 
    diset('tpcc','maria_partition','true') 
else:
    diset('tpcc','maria_partition','false') 

print("SCHEMA BUILD STARTED")
buildschema()
print("SCHEMA BUILD COMPLETED")
exit()
