import json
import time
from contextlib import redirect_stdout
import random
import subprocess
import psycopg2
from psycopg2 import sql
import os
import shutil

os.environ["LOG_LEVEL"] = "DEBUG"

def load_config(json_file):
    with open(json_file, 'r') as file:
        config = json.load(file)
    return config

def setup_database(config):
    try:
        conn = psycopg2.connect(
            dbname='postgres',
            user=config['database']['username'],
            password=config['database']['password'],
            host=config['database']['host']
        )
        conn.autocommit = True
        cursor = conn.cursor()
        # Create the database if it doesn't exist
        cursor.execute(sql.SQL("SELECT 1 FROM pg_database WHERE datname = %s"), [config['database']['db_name']])
        if not cursor.fetchone():
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(config['database']['db_name'])))
        conn.close()

        # Connect to the new database to create the extension
        conn = psycopg2.connect(
            dbname=config['database']['db_name'],
            user=config['database']['username'],
            password=config['database']['password'],
            host=config['database']['host']
        )
        cursor = conn.cursor()
        cursor.execute("CREATE EXTENSION IF NOT EXISTS vector;")
        cursor.execute("CREATE EXTENSION IF NOT EXISTS pg_diskann;")
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Setup failed: {e}")

def teardown_database(config):
    # Optionally drop the database after the test
    pass

def query_configurations(config):
    # List of configuration parameters to query
    config_queries = [
        "SHOW checkpoint_timeout;",
        "SHOW effective_cache_size;",
        "SHOW jit;",
        "SHOW maintenance_work_mem;",
        "SHOW max_parallel_maintenance_workers;",
        "SHOW max_parallel_workers;",
        "SHOW max_parallel_workers_per_gather;",
        "SHOW max_wal_size;",
        "SHOW max_worker_processes;",
        "SHOW shared_buffers;",
        "SHOW wal_compression;",
        "SHOW work_mem;"
    ]

    try:
        conn = psycopg2.connect(
            dbname=config['db_name'],
            user=config['username'],
            password=config['password'],
            host=config['host']
        )
        cursor = conn.cursor()
        results = []

        # Execute each query and collect the result
        for query in config_queries:
            cursor.execute(query)
            result = cursor.fetchone()
            results.append(result[0] if result else None)

        # Print the raw output to debug
        print("Raw query results:", results)

        config_dict = {
            "checkpoint_timeout": results[0],
            "effective_cache_size": results[1],
            "jit": results[2],
            "maintenance_work_mem": results[3],
            "max_parallel_maintenance_workers": results[4],
            "max_parallel_workers": results[5],
            "max_parallel_workers_per_gather": results[6],
            "max_wal_size": results[7],
            "max_worker_processes": results[8],
            "shared_buffers": results[9],
            "wal_compression": results[10],
            "work_mem": results[11]
        }

        conn.close()
        return config_dict
    except Exception as e:
        print(f"Failed to query configurations: {e}")
        return {}

def get_stats(config):
    with open('queries.json', 'r') as file:
        queries = json.load(file)
    try:
        conn = psycopg2.connect(
            dbname=config['db_name'],
            user=config['username'],
            password=config['password'],
            host=config['host']
        )
        cur = conn.cursor()
        for item in queries:
            query = item['query']
            description = item['description']
            print(f"\nRunning query: {description}")
            try:
                cur.execute(query)
                rows = cur.fetchall()
                headers = [desc[0] for desc in cur.description]
                print(f"{' | '.join(headers)}")
                for row in rows:
                    print(f"{' | '.join(map(str, row))}")
            except Exception as e:
                print(f"Failed to run query: {e}")
        conn.close()
    except Exception as e:
        print(f"Setup failed: {e}")
    finally:
        conn.close()

def configure_hammerdb(db_config: dict, hammerdb_config: dict, case: dict):
    dbset('db', hammerdb_config['db'])
    dbset('bm', hammerdb_config['bm'])
    dbset( 'vindex', case['vindex'])

    diset('connection','pg_host', db_config['host'])
    diset('connection','pg_port', '5432')
    diset('connection','pg_sslmode','prefer')

    diset('tpcc','pg_superuser', db_config['username'])
    diset('tpcc','pg_superuserpass', db_config['password'])
    diset('tpcc','pg_defaultdbase', db_config['db_name'])
    diset('tpcc','pg_user', db_config['username'])
    diset('tpcc','pg_pass', db_config['password'])
    diset('tpcc','pg_dbase', db_config['db_name'])
    diset('tpcc','pg_driver',hammerdb_config['pg_driver'])
    diset('tpcc','pg_total_iterations', hammerdb_config['pg_total_iterations'])
    diset('tpcc','pg_count_ware', hammerdb_config['pg_count_ware'])
    diset('tpcc','pg_num_vu', hammerdb_config['pg_num_vu'])
    diset('tpcc','pg_rampup', hammerdb_config['pg_rampup'])
    diset('tpcc','pg_duration', hammerdb_config['pg_duration'])
    diset('tpcc','pg_allwarehouse', hammerdb_config['pg_allwarehouse'])
    diset('tpcc','pg_timeprofile', hammerdb_config['pg_timeprofile'])
    diset('tpcc','pg_vacuum', hammerdb_config['pg_vacuum'])
    giset("commandline", "keepalive_margin", hammerdb_config['keepalive_margin'])
    dvset("mixed_workload", "vector_table_name", case["vector_table_name"])


def configure_vectordb(l_value_is: str, index: str, case: dict):
    dvset(index, "ss_diskann.l_value_is", l_value_is)
    dvset(index, "se_k", case["k"])
    dvset(index, "se_distance", "cosine")
    dvset(index, "in_max_parallel_workers", case["max-parallel-workers"])
    dvset(index, "in_maintenance_work_mem", case["maintenance-work-mem"])
    dvset(index, "ino_max_neighbors", case["max-neighbors"])
    dvset(index, "ino_l_value_ib", case["l-value-ib"])
    dvset("mixed_workload", "mw_oltp_vu", case["mw_oltp_vu"])
    dvset("mixed_workload", "mw_vector_vu", case["mw_vector_vu"])

def drop_tpcc_schema(db_config: dict):
    conn = psycopg2.connect(
        dbname=db_config['db_name'],
        user=db_config['username'],
        password=db_config['password'],
        host=db_config['host']
    )
    cursor = conn.cursor()

    tpcc_tables = [
        "customer", "district", "history", "item", "warehouse", "stock", "new_order", "orders", "order_line"
    ]
    for table in tpcc_tables:
        print(f"Dropping table: {table}")
        cursor.execute(sql.SQL("DROP TABLE IF EXISTS {};").format(sql.Identifier(table)))
    conn.commit()
    cursor.close()
    conn.close()

def run_tpccv(vu, output_dir: str):
    loadscript()
    vuset('vu', vu)
    vucreate()
    # tcstart()
    # tcstatus()
    jobid = tclpy.eval('vurun')
    vudestroy()
    # tcstop()
    print("TEST COMPLETE")
    file_path = os.path.join(output_dir, "tpccv_results.log")
    fd = open(file_path, "w")
    fd.write(jobid)
    fd.close()

def calculate_recall(output_dir: str):
    vudestroy()
    diset('tpcc','pg_driver','test')
    customscript("recall_calculation.tcl")
    vuset("vu", "1")
    vucreate()
    # tcstart()
    tcstatus()
    jobid = tclpy.eval('vurun')
    vudestroy()
    # tcstop()
    print("TEST COMPLETE")
    # TODO: Fix - logs are not being written to file
    file_path = os.path.join(output_dir, "tpccv_results.log")
    fd = open(file_path, "w")
    fd.write(jobid)
    fd.close()

def copy_log_and_config(output_directories: list):
    for output_dir in output_directories:
        try:
            shutil.copy("out.log", output_dir)
            print(f"Copied out.log to {output_dir}")
            shutil.copy("config.json", output_dir)
            print(f"Copied config.json to {output_dir}")
        except Exception as e:
            print(f"Failed to copy out.log to {output_dir}: {e}")

def run_benchmark(
    case: dict, db_config: dict, hammerdb_config: dict, build_schema: bool
):
    base_command = [
        "vectordbbench", "pgdiskann",
        "--user-name", db_config['username'],
        "--password", db_config['password'],
        "--host", db_config['host'],
        "--db-name", db_config['db_name']
    ]

    # Handle initial flags (no skip for the first ef_search)
    if case.get("drop_old", True):
        base_command.append("--drop-old")
    else:
        base_command.append("--skip-drop-old")

    if case.get("load", True):
        base_command.append("--load")
    else:
        base_command.append("--skip-load")

    # Only build index from VDB
    base_command.append("--skip-search-serial")
    base_command.append("--skip-search-concurrent")

    base_command.extend([
        "--case-type", case["case-type"],
        "--maintenance-work-mem", case["maintenance-work-mem"],
        "--max-parallel-workers", str(case["max-parallel-workers"]),
        "--l-value-ib", str(case["l-value-ib"]),
        "--max-neighbors", str(case["max-neighbors"]),
        "--k", str(case["k"]),
        "--concurrency-duration", str(case["concurrency-duration"])
    ])

    output_directories = []
    run_count = case.get("run_count", 1)  # Default to 1 if not specified
    for run in range(run_count):
        print(f"Starting run {run + 1} of {run_count} for case: {case['db-label']}")
        for i, l_value_is in enumerate(case["l-value-is"]):
            configure_hammerdb(db_config, hammerdb_config, case)
            configure_vectordb(l_value_is, case["vindex"], case)
            command = base_command + ["--l-value-is", str(l_value_is)]

            if i > 0 or run > 0:
                # Remove conflicting --drop-old and --load flags
                command = [arg for arg in command if arg not in ["--drop-old", "--load"]]
                # Add skip flags if they are not already in the command
                if "--skip-drop-old" not in command:
                    command.append("--skip-drop-old")
                if "--skip-load" not in command:
                    command.append("--skip-load")

            try:
                random_number = random.randint(1, 100000)
                print(f"Running command: {' '.join(command)}")
                output_dir = f"results/pgdiskann/diskann/{case['db-label']}/{db_config['provider']}/{db_config['instance_type']}-{str(case['max-neighbors'])}-{str(case['l-value-ib'])}-{l_value_is}-{case['case-type']}-{run}-{random_number}"
                os.environ["RESULTS_LOCAL_DIR"] = output_dir
                os.makedirs(output_dir, exist_ok=True)
                output_directories.append(output_dir)

                with open(f"{output_dir}/log.txt", 'w') as f:
                    with redirect_stdout(f):
                        print(f"DB Instance Type: {db_config['instance_type']}")
                        print(f"DB Instance Provider: {db_config['provider']}")
                        print(f"DB enable_seqscan: {db_config['enable_seqscan']}")
                        for key, value in case.items():
                            if key == "l_value_is":
                                print(f"{key}: {l_value_is}")
                            print(f"{key}: {value}")
                        print("Current PostgreSQL configurations:")
                        current_configs = query_configurations(db_config)
                        for key, value in current_configs.items():
                            print(f"{key}: {value}")
                        print("HammerDB configurations:")
                        for key, value in hammerdb_config.items():
                            print(f"{key}: {value}")
                        print(f"Running command: {' '.join(command)}")
                        f.flush()

                    print("***********START***********")
                    start_time = time.time()
                    # Capture both stdout and stderr and write them to the log file
                    subprocess.run(command, check=True, stdout=f, stderr=f)
                    end_time = time.time()
                    execution_time = end_time - start_time
                    print(f"total_duration={execution_time}")
                    print("***********END***********")
                    f.flush()

                    print("*************STARTING HAMMERDB SEARCH*************")
                    if build_schema:
                        drop_tpcc_schema(db_config)
                        buildschema()
                        vudestroy()
                    
                    for idx, vu in enumerate(case["num-concurrency"]):
                        if idx == 1:
                            # TODO: Remove
                            diset("tpcc", "pg_rampup", "10")
                        else:
                            diset("tpcc", "pg_rampup", hammerdb_config["pg_rampup"])

                        get_stats(db_config)
                        f.flush()
                        print(f"Running HammerDB TPC-CV with {vu} VUs")
                        run_tpccv(vu, output_dir)
                        get_stats(db_config)
                        f.flush()
                        time.sleep(30)
                    
                    print("*************CALCULATING RECALL*************")
                    # calculate_recall(output_dir)
                    print("*************END*************")
            except subprocess.CalledProcessError as e:
                print(f"Benchmark failed: {e}")
            print("Sleeping for 30 sec")
            time.sleep(60)

    return output_directories

def main():
    config = load_config("config.json")
    build_schema = True
    start_time = time.time()
    for i, case in enumerate(config['cases']):
        if i > 0:
            build_schema = False
        # BYPASS schema builds
        build_schema = True
        print(f"Running case: {case['db-label']}")
        setup_database(config)
        output_directories = run_benchmark(case, config['database'], config['hammerdb'], build_schema)
        copy_log_and_config(output_directories)
        teardown_database(config)
        time.sleep(120)
    end_time = time.time()
    execution_time = end_time - start_time
    print(f"COMPLETED ALL EXECUTIONS. total_duration={execution_time}")

if __name__ == "__main__":
    main()

