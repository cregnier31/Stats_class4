import os
import sys
import re
from glob import glob
from datetime import datetime

def build_new_filename(file_name, prefix, suffix):
    base, ext = os.path.splitext(os.path.basename(file_name))  # '2024-01-04', '.nc'
    return f"{prefix}_{base}_{suffix}{ext}"

def extract_file_info(dirout, file_path, system, gridname):
    file_name = os.path.basename(file_path)
    folder_name = os.path.basename(os.path.dirname(file_path))
    daterun = folder_name[1:]  # Remove the 'R' and get '20240103'
    print("Extracted Date:", daterun)
    print(f"Extracted file:", file_name)
    # Define a regular expression pattern to extract information
    #pattern = r'(?P<start_date>\d{10}).nc'
    pattern = r'(?P<start_date>[^_]+).nc'
    # Match the pattern against the file name
    match = re.match(pattern, file_name)
    if match:
        # Extract information from the matched groups
        start_date = match.group('start_date')
        ## Convert start_date and daterun to datetime objects
        start_date_obj = datetime.strptime(start_date, '%Y-%m-%d')
        daterun_obj = datetime.strptime(folder_name, '%Y-%m-%d')

        # Calculate the number of days between start_date and daterun
        days_difference = (start_date_obj- daterun_obj).days -1
        # Determine the forecast type based on the number of days difference
        forecast_type = f'fcst{days_difference}'
        print(forecast_type)
        # Create a directory for the forecast type if it doesn't exist
        forecast_dir = os.path.join(dirout, forecast_type)
        if not os.path.exists(forecast_dir):
            os.makedirs(forecast_dir)
        
        file_new = build_new_filename(file_name, f"{system}", f"{gridname}")
        # Create a symlink to the file in the forecast directory
        new_file_path = os.path.join(forecast_dir, file_new)
        os.symlink(file_path, new_file_path)

        return {
            'start_date': start_date,
            'daterun': daterun_obj,
            'forecast_type': forecast_type
        }
    else:
        return None

# Example usage
system = 'GLONET14'
gridname = "all"
DIR_IN = f"/home/onyxia/work/CLASS4/TEP_CLASS4_creation/data/{system}/"
dirout = f"/home/onyxia/work/CLASS4/TEP_CLASS4_creation/data/SORT/{system}/"
for file_path in glob(f"{DIR_IN}*/*nc"):
    print(file_path)
    file_info = extract_file_info(dirout, file_path, system, gridname)
    print(file_info)
