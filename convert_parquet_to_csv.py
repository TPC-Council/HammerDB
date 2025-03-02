import pandas as pd
import sys
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

import pyarrow.parquet as pq
import pandas as pd

# Define the input Parquet file and output CSV file
parquet_file = 'openai_small_50k/test.parquet'
csv_file = 'output.csv'


def convert_parquet_to_csv(parquet_file, csv_file):
    try:
        logging.debug(f"Starting conversion of {parquet_file} to {csv_file}")
        
        # Read the parquet file
        logging.debug(f"Reading parquet file: {parquet_file}")
        # Read the Parquet file
        table = pq.read_table(parquet_file)

        # Convert to a pandas DataFrame
        df = table.to_pandas()
        # Flatten the 'emb' column
        df['emb'] = df['emb'].apply(lambda x: ','.join(map(str, x)))

        # Write to CSV
        df.to_csv(csv_file, index=False)
        logging.info(f"Successfully converted {parquet_file} to {csv_file}")
    except Exception as e:
        logging.error(f"Error during conversion: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        logging.error("Usage: python convert_parquet_to_csv.py <input_parquet_file> <output_csv_file>")
    else:
        input_parquet_file = sys.argv[1]
        output_csv_file = sys.argv[2]
        logging.debug(f"Input Parquet file: {input_parquet_file}")
        logging.debug(f"Output CSV file: {output_csv_file}")
        convert_parquet_to_csv(input_parquet_file, output_csv_file)