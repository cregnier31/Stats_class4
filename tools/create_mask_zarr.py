import xarray as xr
import numpy as np
import sys

SYSTEM="GLONET14"
SYSTEM="WENHAI"
SYSTEM="XIHE"
SYSTEM="GLO12"
# Open the existing NetCDF file
output_file = f'/home/onyxia/work/TEP_CLASS4_creation/statics/{SYSTEM}_mask.nc'
#input_filename = f"https://minio.dive.edito.eu/project-oceanbench/public/{SYSTEM}/20240904.zarr"
input_filename = f"https://minio.dive.edito.eu/project-glonet/public/{SYSTEM}/20240103.zarr"
# Open the dataset using xarray
ds = xr.open_dataset(input_filename, engine="zarr")
# Extract relevant variables: lat, lon, depth, and thetao
lat = ds['latitude']
lon = ds['longitude']
depth = ds['depth']
thetao = ds['thetao'][0,:,:,:]

# Create a mask: 1 where thetao is not NaN, 0 where it is NaN
mask = xr.where(np.isnan(thetao), 0, 1)
# Set attributes for the mask variable
mask.name = 'mask'
mask.attrs['_FillValue'] = 0
mask = mask[:, :, :]
print(np.shape(mask))
print(np.shape(depth))
print(np.shape(lat))
print(np.shape(lon))
# Create a mask with the same shape as thetao, and set all values to 0
mask = xr.DataArray(
    mask,
    dims=['depth', 'latitude', 'longitude'],
    coords={'depth': depth, 'latitude': lat, 'longitude': lon},
    name='mask'
)

# Set the fill value for the mask
mask.attrs['_FillValue'] = 0

# Create a new dataset with the mask and the coordinates
mask_ds = xr.Dataset(
    {
        'mask': mask
    },
    coords={
        'latitude': lat,
        'longitude': lon,
        'depth': depth
    }
)

# Write the new mask dataset to a NetCDF file
mask_ds.to_netcdf(output_file, format='NETCDF4')

# Close the original dataset
ds.close()

