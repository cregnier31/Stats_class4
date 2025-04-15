import xarray as xr
import numpy as np

SYSTEM="GLONET14"
# Open the existing NetCDF file
input_file = f'/data/rd_exchange/cregnier/SORT/GLONET_14//fcst0/{SYSTEM}_2024-01-04_all.nc'
output_file = f'/data/rd_exchange/cregnier/static/{SYSTEM}_mask.nc'

# Open the dataset using xarray
ds = xr.open_dataset(input_file)

# Extract relevant variables: lat, lon, depth, and thetao
lat = ds['lat']
lon = ds['lon']
depth = ds['depth']
thetao = ds['thetao']

# Create a mask: 1 where thetao is not NaN, 0 where it is NaN
mask = xr.where(np.isnan(thetao), 0, 1)
# Set attributes for the mask variable
mask.name = 'mask'
mask.attrs['_FillValue'] = 0
mask = mask[0, :, :, :]
# Create a mask with the same shape as thetao, and set all values to 0
mask = xr.DataArray(
    mask,
    dims=['depth', 'lat', 'lon'],
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

