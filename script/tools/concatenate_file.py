import xarray as xr
import re
import sys
from glob import glob
import numpy as np
sys.path.append('./../../modules/')
from utils import generate_date_list

# Target date in format YYYYMMDD
date1="20250101"
date2="20250114"
#date1="20240101"
#date2="20241231"
dates = generate_date_list(date1, date2)
system = "GLO12V4"
#system = "PSY4V3R1"
dirout = f"/scratch/work/regnierc/data/CLASS4/{system}/sla_l3_corr/coarsed/"
dirout = f"/scratch/work/regnierc/data/CLASS4/GLO12V4/sla_l3_corr_with_shift/"
#dirout = f"/scratch/work/regnierc/data/CLASS4/GLO12V4/GODAE_withshift_new/"

print(dirout)
for target_date in dates:
    output_sys = f"{system}_orca12"
    # Use glob to find files that contain the target date
    frame = "nrt_global_"
    frame = "class4"
    frame2 = "_phy_l3_1hz"
    #input_files = glob(f"{dirout}{frame}*_{frame2}_{target_date}_*.nc")
    input_files = glob(f"{dirout}{frame}_{target_date}_*.nc")
    print(input_files)
    output_file = f"{dirout}class4_{target_date}_{output_sys}_SLA-L3.nc"
    ndim_int = 20  # Desired length of each string
    string_length20 = 20
    ndim_int = 8  # Desired length of each string
    string_length8 = 8
    numvars = 1
    # Prepare to hold individual datasets
    datasets = []
    # Variable to hold 'varname'
    varname_values = []  # Ensure this is a list
    ll_var = False
    for file in input_files:
        print(f"File {file}")
        # Load dataset
        ds = xr.open_dataset(file, decode_cf=False)
        # Check and fix any 'units' attributes that are integers
        for var in ds.variables:
            if 'units' in ds[var].attrs and isinstance(ds[var].attrs['units'], (int, float)):
                # Convert units to string if it's an integer or float
                ds[var].attrs['units'] = str(ds[var].attrs['units'])
        # If 'time' exists, create a 'juld' variable and drop 'time' dimension
        if 'time' in ds.variables:
            ds['juld'] = ds['time'].copy()  # Duplicate 'time' as 'juld'
            ds = ds.drop('time')  # Drop the 'time' dimension
        # Capture the 'varname' variable from the first dataset
        if 'varname' in ds.variables and ll_var == False:
            varname_value = ds['varname'].values  # Get the first value directly as bytes
            names = []
            for letters in varname_value:
                value = b''.join(letters).strip().decode("utf-8")
                names.append(value)
            varname_values.append(names[0])
            for i, name in enumerate(varname_values):
                padded_name = name.ljust(string_length8)  # Pad the name to the desired length
                varname_array = np.array([padded_name.ljust(20)], dtype="S20")  # Pad to 20 characters and set dtype to S20
            varname_save = xr.DataArray(varname_array,
                                   dims=('numvars',),
                                   coords={'numvars': range(numvars)})
            ll_var = True
        ds = ds.drop('varname')
        # Rename 'time' dimension to 'numobs' only for variables that have 'time' as their only dimension
        for var in ds.data_vars:
            print(f'Variable {var}')
            if ds[var].dims == ('time',):
                ds = ds.rename({var: f"{var}"})  # Rename variable to indicate numobs dimension
                ds[f"{var}"] = ds[f"{var}"].rename(time="numobs")  # Rename dimension in the variable
        # Extract satellite name from filename
        #satellite_name = re.split('_', file)[2]
        print(file)
        if system == 'GLO12V4':
            satellite_name = re.split('_', file)[6].split('-')[0]
        elif system == "PSY4V3R1":
            satellite_name = re.split('_', file)[5].split('-')[0]
        # Add satellite name as a new variable in the dataset
        ds = ds.assign(satellite_name=satellite_name)
        datasets.append(ds)
    # Concatenate along the 'numobs' dimension
    merged_ds = xr.concat(datasets, dim="numobs")
    ## Rename 'time' variable to 'timecounter' if it exists
    if 'juld' in merged_ds.variables:
        merged_ds = merged_ds.rename({'juld': 'time_counter'})
    # Ensure 'time_counter' retains its attributes
    if 'time_counter' in merged_ds.variables:
        merged_ds['time_counter'].attrs['long_name'] = "Time of measurement"  # Adjust the long_name as needed
        merged_ds['time_counter'].attrs['axis'] = "T"  # Retain the axis attribute if applicable
    if 'satellite_name' in merged_ds.variables: 
        merged_ds['satellite_name'].attrs['long_name'] = "name of satellite"  # Adjust the long_name as needed
    ## Add the varname variable back to the merged dataset
    if varname_save is not None:
        merged_ds['varname'] = varname_save
        merged_ds['varname'].attrs['long_name'] = "Variable name"  # Retain attributes from the original varname
    # Save to a new NetCDF file
    merged_ds.to_netcdf(output_file)
    print(f"Concatenated file saved as {output_file}")


