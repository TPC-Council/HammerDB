"""
Automated CSV Generation Script for Mixed Workload Benchmark Results
=====================================================================

PURPOSE:
    Extracts benchmark metrics from HammerDB mixed workload test results and 
    generates CSV files for analysis.

WHAT IT EXTRACTS:
    From hdbxtprofile.log:
        - Vector VU count (counted from SEMANTIC_SEARCH sections)
        - OLTP VU count (calculated: Total VU - Vector VU)
        - NOPM (New Orders Per Minute)
        - QPS (Queries Per Second)
    
    From result_*.json files:
        - Index type (hnsw, hnsw with quantization, diskann, etc)
        - All test parameters for accurate case identification
    
    From directory name:
        - Run count (e.g., 0, 1, 2 from folder name pattern: *-{run}-{random})
    
    From directory path:
        - db-label for grouping results

HOW IT WORKS:
    1. Walks through results/ directory recursively
    2. Optionally processes archive/ or latest/ subdirectories if present
    3. Finds folders containing BOTH: hdbxtprofile.log AND result_*.json
    4. Extracts ALL SUMMARY sections (one per num-concurrency value)
    5. Reads index type from result JSON 
    6. Groups results by db-label
    7. Generates combined CSV (or separate CSV per db-label if configured)

OUTPUT:
    CSV Format: OLTP VU, Vector VU, NOPM, QPS, Run Count, Extension
    
    Files Generated:
        - Default: mixed_workload_results_combined.csv (all results)
        - Separate mode: mixed_workload_results_{db-label}.csv (one per db-label)

    Configuration:
        - Set COMBINE_ALL = True for single combined CSV (default) or False for separate CSV per db-label 
        - Set SUBFOLDER = None or "latest" or "archive" for subdirectory processing

HANDLES:
    Multiple num-concurrency values per test (creates separate rows)
    Multiple run counts (run_count: 0, 1, 2, ...)
    Multiple test cases with same db-label
    Different vector index types (pgvector, pgvector-bq, pgdiskann, or custom)
    Different directory structures (local, azure, etc.)
    Result JSON in subdirectories or root folder
    Optional archive/latest subfolder processing
    Dynamic db-label extraction from various directory structures
    Error reporting for missing files and failed extractions
"""

import os
import re
import json
import csv
import glob
from pathlib import Path
from collections import defaultdict


def extract_index_to_extension(index_type, quantization_type=None, reranking=False):
    
    # Map index configuration to extension name
    # Handle None or empty index_type
    if not index_type:
        return "unknown"
    
    # Normalize index type to lowercase for comparison
    index_type_lower = str(index_type).lower()
    
    # DiskANN variants
    if "diskann" in index_type_lower:
        return "pgdiskann"
    
    # HNSW variants
    if index_type_lower == "hnsw":
        # Check for binary quantization with reranking
        if quantization_type == "bit" and reranking:
            return "pgvector-bq"
        else:
            return "pgvector"
    
    # For any unknown index type, return it as-is preserving original case
    return str(index_type)


def extract_db_label_from_path(path):

    # Looks for pattern: {database-type}/{index-type}/{db-label}/{provider}/
    parts = Path(path).parts
    
    # Known database types and index types that come before db-label
    db_types = ['pgvector', 'pgdiskann', 'pgvectorscale']
    index_types = ['hnsw', 'hnsw-bq', 'diskann', 'ivfflat']
    
    # Known provider types that come after db-label
    provider_types = ['local', 'azure', 'azure-vm', 'aws', 'gcp']
    
    # Scan through path to find the pattern
    for i in range(len(parts) - 3):  # Need at least 3 parts after current position
        current_part = parts[i].lower()
        
        # Check if current part is a database type
        if current_part in db_types:
            # Check if next part is an index type
            if i + 1 < len(parts) and parts[i + 1].lower() in index_types:
                # The part after index type should be the db-label
                if i + 2 < len(parts):
                    potential_db_label = parts[i + 2]
                    
                    # Verify it's not a provider type (sanity check)
                    if potential_db_label.lower() not in provider_types:
                        return potential_db_label
    
    # Fallback: If pattern not found, return "unknown"
    return "unknown"


def get_processing_directory(results_base_dir, subfolder_preference):
    """
    Determine which directory to process based on subfolder preference.
        results_base_dir: Base results directory (e.g., "results")
        subfolder_preference: "latest", "archive", or None
    """

    # Check if archive and latest folders exist
    latest_path = os.path.join(results_base_dir, 'latest')
    archive_path = os.path.join(results_base_dir, 'archive')
    
    has_latest = os.path.isdir(latest_path)
    has_archive = os.path.isdir(archive_path)
    
    # If subfolder preference is specified
    if subfolder_preference == "latest" and has_latest:
        return latest_path, "latest"
    
    if subfolder_preference == "archive" and has_archive:
        return archive_path, "archive"
    
    # If subfolder preference is specified but doesn't exist
    if subfolder_preference in ["latest", "archive"]:
        if not has_latest and not has_archive:
            print(f"ℹNote: Neither 'latest' nor 'archive' subfolders found.")
            print(f"         Processing entire '{results_base_dir}' directory.")
            return results_base_dir, None
        else:
            print(f"Warning: '{subfolder_preference}' subfolder not found.")
            if subfolder_preference == "latest" and has_archive:
                print(f"           'archive' subfolder is available. Consider using SUBFOLDER='archive'")
            elif subfolder_preference == "archive" and has_latest:
                print(f"           'latest' subfolder is available. Consider using SUBFOLDER='latest'")
            return results_base_dir, None
    
    # Default: process entire results directory
    return results_base_dir, None


def find_result_json(directory):

    # Search patterns in order of preference
    search_patterns = [
        os.path.join(directory, 'PgVector', 'result_*_pgvector.json'),
        os.path.join(directory, 'PgDiskANN', 'result_*_pgdiskann.json'),
        os.path.join(directory, 'result_*_pgvector.json'),
        os.path.join(directory, 'result_*_pgdiskann.json'),
        os.path.join(directory, 'result_*.json'),
    ]
    
    for pattern in search_patterns:
        matches = glob.glob(pattern)
        if matches:
            return matches[0]  # Return first match
    
    return None


def is_result_folder(directory, files):

    # Check if directory contains test-related files (not just result JSON)
    test_indicators = {
        'hdbxtprofile.log',
        'config.json',
        'out.log',
        'tpccv_results.log',
        'log.txt'
    }
    
    # If directory has any test indicator files, it's a result folder
    has_test_files = any(f in files for f in test_indicators)
    
    # Also check if this is NOT a known subdirectory
    dirname = os.path.basename(directory)
    is_subdirectory = dirname in ['PgVector', 'PgDiskANN', 'PgVectorScale']
    
    return has_test_files and not is_subdirectory


def extract_index_from_result_json(json_path):

    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        
        # Navigate to db_case_config
        results = data.get('results', [])
        if not results:
            return "unknown", False, "No 'results' array found in JSON"
        
        task_config = results[0].get('task_config', {})
        if not task_config:
            return "unknown", False, "No 'task_config' found in JSON"
        
        db_case_config = task_config.get('db_case_config', {})
        if not db_case_config:
            return "unknown", False, "No 'db_case_config' found in JSON"
        
        # Extract relevant fields
        index_type = db_case_config.get('index', 'hnsw')
        quantization_type = db_case_config.get('quantization_type')
        reranking = db_case_config.get('reranking', False)
        
        # Map to extension
        extension = extract_index_to_extension(index_type, quantization_type, reranking)
        
        return extension, True, None
    
    except FileNotFoundError:
        return "unknown", False, f"File not found: {json_path}"
    except json.JSONDecodeError as e:
        return "unknown", False, f"Invalid JSON format: {str(e)}"
    except KeyError as e:
        return "unknown", False, f"Missing key in JSON: {str(e)}"
    except Exception as e:
        return "unknown", False, f"Unexpected error: {str(e)}"


def extract_all_summaries_from_hdbxtprofile(file_path):

    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Find ALL SUMMARY sections using finditer
        summary_pattern = re.compile(
            r'>>>>> SUMMARY OF (\d+) ACTIVE VIRTUAL USERS.*?'
            r'TOTAL VECTOR QPS:\s*([\d.]+).*?'
            r'NOPM:\s*(\d+)',
            re.DOTALL
        )
        
        summaries = []
        
        for match in summary_pattern.finditer(content):
            total_vu = int(match.group(1))
            qps = float(match.group(2))
            nopm = int(match.group(3))
            
            # Get the position of this summary in the file
            summary_start = match.start()
            
            # Pattern for SEMANTIC_SEARCH sections
            vector_vu_pattern = r'>>>>> VIRTUAL USER \d+ :.*?>>>>> PROC: SEMANTIC_SEARCH'
            
            # Find previous summary's position to isolate current section
            previous_summaries = list(summary_pattern.finditer(content[:summary_start]))
            
            if previous_summaries:
                # Get content between previous and current summary
                previous_summary_end = previous_summaries[-1].end()
                current_section = content[previous_summary_end:summary_start]
            else:
                # This is the first summary, get content from start
                current_section = content[:summary_start]
            
            # Count SEMANTIC_SEARCH in current section only
            vector_vu_matches = re.findall(vector_vu_pattern, current_section, re.DOTALL)
            vector_vu = len(vector_vu_matches)
            
            # OLTP VU = Total VU - Vector VU
            oltp_vu = total_vu - vector_vu
            
            summaries.append({
                'oltp_vu': oltp_vu,
                'vector_vu': vector_vu,
                'nopm': nopm,
                'qps': qps
            })
        
        if not summaries:
            return None, False, "No SUMMARY sections found in file"
        
        return summaries, True, None
    
    except FileNotFoundError:
        return None, False, f"File not found: {file_path}"
    except Exception as e:
        return None, False, f"Error reading file: {str(e)}"


def extract_run_count_from_dirname(dirname):

    # Pattern: ...-{run_count}-{random_number}
    match = re.search(r'-(\d+)-\d+$', dirname)
    if match:
        return int(match.group(1)), True
    return 0, False


def process_results_directory(results_dir, subfolder_info=None):

    data_by_label = defaultdict(list)
    processed_count = 0
    skipped_count = 0
    error_details = []
    
    if subfolder_info:
        print(f"\nScanning directory: {results_dir} ({subfolder_info} subfolder)")
    else:
        print(f"\nScanning directory: {results_dir}")
    print("=" * 90)
    
    for root, dirs, files in os.walk(results_dir):
        dirname = os.path.basename(root)
        
        # Skip if this is not a test result folder 
        if not is_result_folder(root, files):
            continue
        
        # Check for BOTH required files
        has_hdbxtprofile = 'hdbxtprofile.log' in files
        has_result_json = find_result_json(root) is not None
        
        # Skip if missing either file 
        if not has_hdbxtprofile:
            skipped_count += 1
            error_details.append(f"{dirname:60s} → Missing hdbxtprofile.log")
            continue
        
        if not has_result_json:
            skipped_count += 1
            error_details.append(f"{dirname:60s} → Missing result_*.json file")
            continue
        
        # Both files present, proceed with extraction
        hdbxtprofile_path = os.path.join(root, 'hdbxtprofile.log')
        result_json_path = find_result_json(root)
        
        # Extract db-label from path
        db_label = extract_db_label_from_path(root)
        if db_label == "unknown":
            skipped_count += 1
            error_details.append(f"{dirname:60s} → Could not extract db-label from path")
            continue
        
        # Extract summaries from hdbxtprofile.log
        summaries, sum_success, sum_error = extract_all_summaries_from_hdbxtprofile(hdbxtprofile_path)
        if not sum_success:
            skipped_count += 1
            error_details.append(f"{dirname:60s} → {sum_error}")
            continue
        
        # Extract index type from result JSON
        extension, ext_success, ext_error = extract_index_from_result_json(result_json_path)
        if not ext_success:
            skipped_count += 1
            error_details.append(f"{dirname:60s} → {ext_error}")
            continue
        
        # Extract run count from directory name
        run_count, run_success = extract_run_count_from_dirname(dirname)
        if not run_success:
            error_details.append(f"{dirname:60s} → Run count not found (using 0)")
        
        # Create one row for EACH summary (each num-concurrency level)
        for idx, summary in enumerate(summaries):
            row = {
                'OLTP VU': summary['oltp_vu'],
                'Vector VU': summary['vector_vu'],
                'NOPM': summary['nopm'],
                'QPS': summary['qps'],
                'Run Count': run_count,
                'Extension': extension,
                'Concurrency Index': idx
            }
            
            data_by_label[db_label].append(row)
        
        processed_count += 1
        print(f"{dirname:60s} → {extension:15s} ({len(summaries)} summaries)")
    
    print("=" * 90)
    print(f"Summary: {processed_count} folders processed, {skipped_count} folders skipped")
    
    # Print error details if any
    if error_details:
        print(f"\nSkipped Folders Details:")
        print("-" * 90)
        for error in error_details:
            print(error)
        print("-" * 90)
    
    return data_by_label


def write_to_csv(data, output_file):

    if not data:
        print(f"No data to write for {output_file}")
        return
    
    fieldnames = ['OLTP VU', 'Vector VU', 'NOPM', 'QPS', 'Run Count', 'Extension']
    
    try:
        with open(output_file, 'w', newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(data)
        
        print(f"CSV created: {output_file} ({len(data)} rows)")
    
    except Exception as e:
        print(f"Error writing CSV {output_file}: {e}")


def main():
    
    # ==================== CONFIGURATION ====================
    
    results_base_dir = "results"
    
    # Set COMBINE_ALL to True to combine all db-labels into one CSV file (DEFAULT)
    # Set to False to create separate CSV files for each db-label 
    COMBINE_ALL = True
    
    # Set SUBFOLDER to process specific subdirectories:
    # - None: Process entire results directory (DEFAULT)
    # - "latest": Process only results/latest/ subdirectory
    # - "archive": Process only results/archive/ subdirectory
    SUBFOLDER = None  # ← Change to "latest" or "archive" if needed
    
    # =======================================================
    
    # Check if results directory exists
    if not os.path.exists(results_base_dir):
        print(f"\nError: Results directory '{results_base_dir}' not found!")
        print(f"   Please ensure you're running this script from the correct location.")
        return
    
    # Determine which directory to process
    processing_dir, subfolder_info = get_processing_directory(results_base_dir, SUBFOLDER)
    
    # Process directories grouped by db-label
    data_by_label = process_results_directory(processing_dir, subfolder_info)
    
    if not data_by_label:
        print("\nNo valid data found to process!")
        print("   Please check that your result folders contain both:")
        print("   1. hdbxtprofile.log")
        print("   2. result_*.json file")
        return
    
    print(f"\nFound {len(data_by_label)} db-label(s):")
    for label, rows in data_by_label.items():
        extensions = set(row['Extension'] for row in rows)
        print(f"   • {label} ({len(rows)} results, extensions: {', '.join(sorted(extensions))})")
    
    if COMBINE_ALL:
        # Combine all data into one CSV
        print("\nCombining all results into one file...")
        all_data = []
        for rows in data_by_label.values():
            all_data.extend(rows)
        
        # Sort combined data
        all_data.sort(key=lambda x: (
            x['Extension'],
            x['OLTP VU'],
            x['Vector VU'],
            x['Run Count'],
            x.get('Concurrency Index', 0)
        ))
        
        output_csv = "mixed_workload_results_combined.csv"
        write_to_csv(all_data, output_csv)
    
    else:
        # Create separate CSV for each db-label
        print("\nCreating separate CSV files for each db-label...")
        for db_label, rows in data_by_label.items():
            # Sort data for this db-label
            rows.sort(key=lambda x: (
                x['Extension'],
                x['OLTP VU'],
                x['Vector VU'],
                x['Run Count'],
                x.get('Concurrency Index', 0)
            ))
            
            # Create CSV filename from db-label
            output_csv = f"mixed_workload_results_{db_label}.csv"
            write_to_csv(rows, output_csv)
    
    print("\nProcessing complete!")


if __name__ == "__main__":
    main()