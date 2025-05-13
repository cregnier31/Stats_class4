import xarray as xr
import numpy as np

SYSTEM="GLONET14"
SYSTEM="WENHAI"
# Open the existing NetCDF file
output_file = f'/home/onyxia/work/CLASS4/TEP_CLASS4_creation/statics/'
input_filename = f"https://minio.dive.edito.eu/project-oceanbench/public/WENHAI/20240904.zarr"
# Open the dataset using xarray
ds = xr.open_dataset(input_filename, engine="zarr")

# Extract relevant variables: lat, lon, depth, and thetao
lat = ds['latitude']
lon = ds['longitude']
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

