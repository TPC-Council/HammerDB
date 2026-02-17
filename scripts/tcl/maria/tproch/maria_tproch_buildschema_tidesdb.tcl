#!/bin/tclsh
# maintainer: TidesDB

puts "SETTING CONFIGURATION"
dbset db maria
dbset bm TPC-H

diset connection maria_host localhost
diset connection maria_port 3306
diset connection maria_socket /tmp/mariadb.sock

diset tpch maria_scale_fact 1
diset tpch maria_num_tpch_threads [ numberOfCPUs ]
diset tpch maria_tpch_user root
diset tpch maria_tpch_pass maria
diset tpch maria_tpch_dbase tpch
diset tpch maria_tpch_storage_engine tidesdb
diset tpch maria_tpch_tidesdb_compression lz4
diset tpch maria_tpch_tidesdb_sync_mode full
diset tpch maria_tpch_tidesdb_write_buffer_size 134217728
diset tpch maria_tpch_tidesdb_bloom_filter true
diset tpch maria_tpch_tidesdb_use_btree false
diset tpch maria_tpch_tidesdb_isolation_level repeatable_read
diset tpch maria_tpch_tidesdb_bloom_fpr 100
diset tpch maria_tpch_tidesdb_sync_interval_us 500000
diset tpch maria_tpch_tidesdb_level_size_ratio 10
diset tpch maria_tpch_tidesdb_min_levels 5
diset tpch maria_tpch_tidesdb_skip_list_max_level 12
diset tpch maria_tpch_tidesdb_skip_list_probability 25
diset tpch maria_tpch_tidesdb_l1_file_count_trigger 4
diset tpch maria_tpch_tidesdb_ttl 0
diset tpch maria_tpch_tidesdb_encrypted no
diset tpch maria_tpch_tidesdb_encryption_key_id 1
puts "SCHEMA BUILD STARTED"
buildschema
puts "SCHEMA BUILD COMPLETED"
