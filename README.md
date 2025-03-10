# Mixed Workload Benchmark Runner [Emumba's Automation Flow]

## Overview
This repository provides a 2 scripts (`pg_tproccv_diskann_run.py`) & (`pg_tproccv_hnsw_run.py`) to execute the benchmark tests for DiskAnn and HNSW, HNSW-BQ respectively . The script reads configuration details from `config.json` and runs multiple benchmark cases to evaluate the performance of various indexing parameters or OLTP/Vector virtual users ratio. This builds upon the CLI functionality provided to VectorDBBench & HammerDB to automate testing.

## Features
- Reads benchmark configuration from `config.json`
- Sets up, runs, and tears down database instances
- Logs detailed benchmark execution progress
- Generates metadata for each benchmark run

### Database Requirements
- PostgreSQL with `pgvector` and/or `pg_diskann` extensions enabled

## Configuration
The `config.json` file defines the benchmarking setup. Here is a breakdown of the structure:

### Database Configuration
```json
"database": {
    "host": "localhost",
    "username": "postgres",
    "password": "***",
    "db_name": "ann",
    "instance_type": "Standard_D8ds_v5",
    "provider": "azure",
    "enable_seqscan": "off"
}
```
- Defines the database connection details.



### Benchmark Configuration Options 
Each case contains parameters for benchmarking specific configurations. The following is a sample for *HNSW Full Vector*. For other samples please see config.json.

### HammerDB Schema Configuration
```json
"hammerdb": {
    "db": "pg",
    "bm": "TPC-C",
    "build_schema": false,
    "pg_driver": "timed",
    "pg_total_iterations": "10000000",
    "pg_count_ware": "200",
    "pg_num_vu": "8",
    "pg_rampup": "2",
    "pg_duration": "5",
    "pg_allwarehouse": "false",
    "pg_timeprofile": "true",
    "pg_vacuum": "false",
    "keepalive_margin": "90"
  },
```
- **`pg_count_ware`**: Specifies the number of warehouses in the TPROC-C schema. This number also acts as a scaling factor for the database schema.
- **`pg_num_vu`**: Indicates the number of virtual users that will concurrently create the TPROC-C database schema.
- **`pg_rampup`**: Sets the duration for the ramp-up period of the benchmark test.
- **`pg_duration`**: Defines how long the benchmark test will run.


### Benchmark Configuration
```json
"cases": [
     {
      "db-label": "hnsw-mixed-test-13vu-oltp-200wh",  
      "vindex": "hnsw",
      "vector_table_name": "public.pg_vector_collection",
      "drop_old": true,
      "load": true,
      "search-serial": false,
      "search-concurrent": false,
      "case-type": "Performance1536D50K",
      "maintenance-work-mem": "8GB",
      "max-parallel-workers": 7,
      "ef-search": [200],
      "ef-construction": 64,
      "m": 16,
      "num-concurrency": ["13", "16", "19", "22", "25", "28", "31", "34", "37"],
      "k": 10,
      "mw_oltp_vu": "13",
      "run_count": 3
    }
]
```
- **`db-label`**: A descriptive label for the database configuration or experiment, also added in results directory path.
- **`vindex`**: Specifies the vector algorithm for testing, expected values are `pgdiskann`, `hnsw`, and `hnsw_bq`, `"hnsw"` refers to using the HNSW (Hierarchical Navigable Small World) algorithm with `pgvector`. This is passed to HammerDB CLI to set parameters in appropriate dict.
- **`vector_table_name`**: Defines the vector table name that contains vector embeddings, needs to be the same value as defined in VectorDBBench extension's client code. The index was created using VectorDBBench, HammerDb has no knowledge of the index or table name in postgres. This value is passed to HammerDB CLI and is used to query the table. 
- **`case-type`**: Denotes the benchmark case or dataset to be used. `"Performance1536D500K"` refers to a dataset with 1,536 dimensions and 500,000 vectors. These are directly passed on to VectorDBBench and other options can be found in the VDB README. 

### Data Handling Flags

- **`drop-old`**: A boolean flag indicating whether to drop existing data before running the benchmark.  
- **`load`**: A boolean flag specifying whether to load data into the database.  

### Search Options

- **`search-serial`**: A boolean flag indicating whether to perform single-threaded search operations in VectorDBBench. In mixed workload, keep it false. We only want VectorDBBench to create the index. We perform the search from HammerDB.
- **`search-concurrent`**: A boolean flag indicating whether to perform concurrent (multi-threaded) search operations in VectorDBBench. In mixed workload, keep it false. VectorDBBench is only used to create the index. Perform the search from HammerDB.

### Index and Search Parameters
These params will vary based on the extension being used. Following two are common params 
- **`maintenance-work-mem`**: Specifies the memory allocated for maintenance operations, such as index creation. `"8GB"` allocates 8 gigabytes for these operations.  
- **`max-parallel-workers`**: Sets the maximum number of parallel workers for index construction, which can speed up the process. 

## For pgvector - HNSW 
- **`m`**: Controls the number of bi-directional links created for each new element during index construction. A higher value increases recall but also increases memory usage and indexing time.  
- **`ef-construction`**: Defines the size of the dynamic list for the nearest neighbors during index construction. Larger values can improve recall but may slow down the indexing process.  
- **`quantization-type`**: Define the quantization method. `bit` for binary quantization. Remove for Full Vector.
- **`ef-search`**: A list of values for the size of the dynamic list for the nearest neighbors during search. Larger values can improve recall but may increase search time.
 
## For pgvector - HNSW - BQ
- **`m`**: Controls the number of bi-directional links created for each new element during index construction. A higher value increases recall but also increases memory usage and indexing time.  
- **`ef-construction`**: Defines the size of the dynamic list for the nearest neighbors during index construction. Larger values can improve recall but may slow down the indexing process.  
- **`ef-search`**: A list of values for the size of the dynamic list for the nearest neighbors during search. Larger values can improve recall but may increase search time.
- **`quantization-type`**: Define the quantization method. `bit` for binary quantization. Remove for Full Vector.
- **`dim`**: Specifies the number of dimensions for the vector embeddings used in search queries.
- **`reranking`**: A boolean flag indicating whether to rerank the search results.
- **`quantized-fetch-limit`**: Sets a limit on the number of quantized vector results to fetch during rerank search. This is constrained by `ef-search` and is used only when `reranking` is `true`.
- **`rerank-distance-op`**: Defines the distance metric to use during the quantized vector search.
 
## For pg_diskann 
  - **`max-neighbors`**	The maximum number of edges (neighbors) each node in the graph can have. Higher values improve recall at the cost of increased memory usage and indexing time.
  - **`l-value-ib`**	The parameter is used during index building, which controls the candidate list size for inserting new elements. A larger value improves recall but increases indexing time.
  - **`l-value-is`**: The L parameter used during search, which defines the size of the candidate neighbor list for retrieving nearest neighbors. Higher values improve recall but increase search latency.

### Other HammerDB Options
  - **`mw-oltp-vu`**: Specifies number of OLTP virtual users (handles OLTP workload), value should be less then or equal to `num-concurrency`.
  - **`num-concurrency`**: Specifies the levels of concurrency to test during concurrent search using HammerDB, represented as a comma-separated list.  
  - **`k`**: Specifies the number of nearest neighbors to retrieve during search operations.  

### Benchmark Execution

- **`run-count`**: Indicates the number of times to repeat the benchmark to ensure consistent results.  

## Usage
### Running the Benchmark
To execute the benchmark, run:
```sh
nohup ./hammerdbcli py auto pg_tproccv_hnsw_run.py > out.log 2>&1 &
```

## Benchmark Execution Flow
1. **Load Configuration:** Reads benchmark settings from `config.json`.
2. **Setup Database:** Initializes the database with necessary extensions.
3. **Run Benchmark Cases:** Executes multiple benchmark runs based on the configuration.
4. **Teardown Database:** Cleans up the database after execution.
5. **Generate Metadata:** Stores benchmark results in an output directory.

## Output
Benchmark results are stored in an automatically generated directory. The script logs execution details and stores:
- Raw command execution logs
- Performance metrics
- Metadata for the run

# HammerDB

HammerDB is the leading benchmarking and load testing software for the worlds most popular databases supporting Oracle Database, Microsoft SQL Server, IBM Db2, PostgreSQL, MySQL and MariaDB.

## Credits

- Steve Shaw
- [All Contributors](https://github.com/TPC-Council/HammerDB/contributors)

## License

GNU General Public License v3.0. Please see [License File](LICENSE) for more information.

## Support

- [Contact information](http://www.hammerdb.com)
- [Documentation](https://www.hammerdb.com/docs)
