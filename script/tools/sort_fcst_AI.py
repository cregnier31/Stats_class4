import os
import sys
import re
from glob import glob
from datetime import datetime

def extract_file_info(dirout, file_path):
    file_name = os.path.basename(file_path)
    folder_name = os.path.basename(os.path.dirname(file_path))
    daterun = folder_name[1:]  # Remove the 'R' and get '20240103'
    print("Extracted Date:", daterun)
    # Define a regular expression pattern to extract information
    pattern = r'(?P<system>[^_]+)_(?P<file_type>[^_]+)_(?P<start_date>\d{8})_(?P<variable>[^_]+).nc'
    # Match the pattern against the file name
    match = re.match(pattern, file_name)

    if match:
        # Extract information from the matched groups
        system = match.group('system')
        file_type = match.group('file_type')
        start_date = match.group('start_date')
        variable = match.group('variable')

        print(system, file_type, start_date, variable)
        ## Convert start_date and daterun to datetime objects
        start_date_obj = datetime.strptime(start_date, '%Y%m%d')
        daterun_obj = datetime.strptime(daterun, '%Y%m%d')

        # Calculate the number of days between start_date and daterun
        days_difference = (start_date_obj- daterun_obj).days

        # Determine the forecast type based on the number of days difference
        forecast_type = f'{days_difference}D'
        print(forecast_type)
        # Create a directory for the forecast type if it doesn't exist
        forecast_dir = os.path.join(dirout, forecast_type)
        if not os.path.exists(forecast_dir):
            os.makedirs(forecast_dir)

        # Create a symlink to the file in the forecast directory
        new_file_path = os.path.join(forecast_dir, file_name)
        os.symlink(file_path, new_file_path)

        return {
            'system': system,
            'file_type': file_type,
            'start_date': start_date,
            'variable': variable,
            'daterun': daterun,
            'forecast_type': forecast_type
        }
    else:
        return None

# Example usage
#DIR_IN = "/data/rd_exchange/aelaouni/XIHE_oper/"
#dirout = "/data/rd_exchange/cregnier/SORT/XIHE_oper/"
#DIR_IN = "/data/rd_exchange/aelaouni/GLONET/"
#dirout = "/data/rd_exchange/cregnier/SORT/GLONET/"
DIR_IN = "/data/rd_exchange/olegallou/IA_FORECAST/"
dirout = "/data/rd_exchange/cregnier/SORT/GLO12V4_PGS/"
for file_path in glob(f"{DIR_IN}*/*nc"):
    print(file_path)
    file_info = extract_file_info(dirout, file_path)
    print(file_info)
