import os
import re
from glob import glob
from datetime import datetime

def extract_file_info(dirout, file_path):
    file_name = os.path.basename(file_path)
    # Define a regular expression pattern to extract information
    pattern = r'(?P<system>[^_]+)_(?P<file_type>[^_]+)_(?P<schedule>[^_]+)_(?P<start_date>\d{8})-(?P<end_date>\d{8})_(?P<variable>[^_]+)_(?P<leadtime>[^_]+)_R(?P<daterun>\d{8})\.nc'

    # Match the pattern against the file name
    match = re.match(pattern, file_name)

    if match:
        # Extract information from the matched groups
        system = match.group('system')
        file_type = match.group('file_type')
        schedule = match.group('schedule')
        start_date = match.group('start_date')
        end_date = match.group('end_date')
        variable = match.group('variable')
        leadtime = match.group('leadtime')
        daterun = match.group('daterun')

        ## Convert start_date and daterun to datetime objects
        start_date_obj = datetime.strptime(start_date, '%Y%m%d')
        daterun_obj = datetime.strptime(daterun, '%Y%m%d')

        # Calculate the number of days between start_date and daterun
        days_difference = (start_date_obj- daterun_obj).days

        # Determine the forecast type based on the number of days difference
        forecast_type = f'fcst{days_difference}'

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
            'end_date': end_date,
            'variable': variable,
            'daterun': daterun,
            'forecast_type': forecast_type
        }
    else:
        return None

# Example usage
DIR_IN = "/scratch/work/elmoussaouia/BIO4GLO12/BGC_MODEL/FORECAST/"
dirout = "/scratch/work/regnierc/SORT/HEBDO/BIO4GLO12/"
for file_path in glob(f"{DIR_IN}*nc"):
    print(file_path)
    file_info = extract_file_info(dirout, file_path)
    print(file_info)
