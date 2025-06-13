from pathlib import Path
import pandas as pd
import sys
import os
import datetime

# FUNCTIONS
def filter_tab(directory, column1, value1, column2, value2):
    # Verificar si el archivo existe
    if not file_path.exists():
        print(f"File {file_path} doesn't exist.")
        return None
    
    # Read .tab file in a DataFrame
    df = pd.read_csv(file_path, sep='\t')
    df.columns = df.columns.str.strip().str.replace("'", "")
    
    # Remove the initial quote from the columns
    df[column1] = df[column1].astype(str).str.lstrip("'")
    df[column2] = df[column2].astype(str).str.lstrip("'")

    # Convert the columns to numeric, coercing errors to NaN
    df[column1] = pd.to_numeric(df[column1], errors='coerce')
    df[column2] = pd.to_numeric(df[column2], errors='coerce')

    # Filter the DataFrame depending the values of the columns
    filtered_df = df[(df[column1] > value1) & (df[column2] > value2)]
    
    return filtered_df

def save_filtered_data(filtered_df, output_path):
    filtered_df.to_csv(output_path, sep='\t', index=False)

def create_samples_txt(filtered_df, output_txt_path, value1, value2):
    # Select SampleID and LibraryID columns and delete the initial quote
    sample_library_df = filtered_df[['SampleID', 'LibraryID']].applymap(lambda x: str(x).lstrip("'"))
    
    # Save the selected columns in a .txt file
    sample_library_df.to_csv(output_txt_path, sep='\t', index=False, header=False, quoting=3) # quoting=3 is equivalent to csv.QUOTE_NONE

    # Write the values of Coverage mean and Coverage median used
    with open(output_txt_path, 'a') as f:
        f.write(f"\n# Used filters: Coverage mean > {value1}, Coverage median > {value2}\n")


# DATA
directory = sys.argv[1]
value1 = float(sys.argv[2])
value2 = float(sys.argv[3])
column1 = "(Any) Coverage mean"
column2 = "(Any) Coverage median"

# EXECUTION
file_path = Path(directory)/'Analysis/Statistics/Mapping_and_Variant_Statistics.tab'

filtered_data = filter_tab(file_path, column1, value1, column2, value2)

# Save the filtered data in a new file and create samples.txt file
output_path = Path(directory) / 'Analysis/Filtered_Statistics/Mapping_and_Variant_Statistics.tab'
os.makedirs(output_path.parent, exist_ok=True)  # Create the directory 
save_filtered_data(filtered_data, output_path)

output_txt_path = Path(directory) / 'Analysis/Filtered_Statistics/filtered_samples.txt'
create_samples_txt(filtered_data, output_txt_path, value1, value2)
    
current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
print(f"<INFO>  [{current_time}]   Filtered data has been saved in file 'Mapping_and_Variant_Statistics.tab' located in {output_path}")
print(f"<INFO>  [{current_time}]   SampleID and LibraryID columns have been saved in file 'filtered_samples.txt' located in {output_txt_path}")
