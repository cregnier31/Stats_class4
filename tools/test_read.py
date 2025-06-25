import xarray as xr

directory="https://minio.dive.edito.eu/project-glonet/public/glonet_full_2024/"
#directory="https://minio.dive.edito.eu/project-glonet/public/GLO12/"
file="20240103.zarr"
filename=f'{directory}{file}'
input_model = xr.open_dataset(filename, engine="zarr")
print(input_model)
