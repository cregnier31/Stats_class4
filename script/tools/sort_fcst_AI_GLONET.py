import os
import sys
import re
from glob import glob
from datetime import datetime

def extract_file_info(dirout, file_path):
    file_name = os.path.basename(file_path)
    folder_name = os.path.basename(os.path.dirname(file_path))
    print("Extracted Date:", folder_name)
    # Define a regular expression pattern to extract information
    #pattern = r'(?P<start_date>\d{10}).nc'
    pattern = r'(?P<start_date>[^_]+).nc'
    # Match the pattern against the file name
    match = re.match(pattern, file_name)
    print(match)
    if match:
        # Extract information from the matched groups
        start_date = match.group('start_date')
        ## Convert start_date and daterun to datetime objects
        start_date_obj = datetime.strptime(start_date, '%Y-%m-%d')
        daterun_obj = datetime.strptime(folder_name, '%Y-%m-%d')
        # Calculate the number of days between start_date and daterun
        days_difference = (start_date_obj- daterun_obj).days
        # Determine the forecast type based on the number of days difference
        forecast_type = f'fcst{days_difference}'
        print(forecast_type)
        # Create a directory for the forecast type if it doesn't exist
        forecast_dir = os.path.join(dirout, forecast_type)
        if not os.path.exists(forecast_dir):
            os.makedirs(forecast_dir)

        # Create a symlink to the file in the forecast directory
        new_file_path = os.path.join(forecast_dir, file_name)
        os.symlink(file_path, new_file_path)

        return {
            'start_date': start_date,
            'daterun': daterun_obj,
            'forecast_type': forecast_type
        }
    else:
        return None

# Example usage
#DIR_IN = "/data/rd_exchange/aelaouni/XIHE_oper/"
#dirout = "/data/rd_exchange/cregnier/SORT/XIHE_oper/"
DIR_IN = "/data/rd_exchange/aelaouni/GLONET_14/"
dirout = "/data/rd_exchange/cregnier/SORT/GLONET_14/"
for file_path in glob(f"{DIR_IN}*/*nc"):
    print(file_path)
    file_info = extract_file_info(dirout, file_path)
    print(file_info)
