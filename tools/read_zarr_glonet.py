# Open GLONET forecast sample with xarray
import xarray
from typing import List
import xarray as xr
challenger_datasets = {
    "GLO-NET_FULL": xr.open_dataset(
        "https://minio.dive.edito.eu/project-glonet/public/glonet_full_2024/20240810.zarr", engine="zarr"
    ),
    "XIHE": xr.open_dataset(
        "https://minio.dive.edito.eu/project-oceanbench/public/XIHE/20240810.zarr", engine="zarr"
    ),
    "WENHAI": xr.open_dataset(
        "https://minio.dive.edito.eu/project-oceanbench/public/WENHAI/20240810.zarr", engine="zarr"
    ),
    "GLO12": xr.open_dataset(
        "https://minio.dive.edito.eu/project-glonet/public/GLO12/20240810.zarr", engine="zarr"
    ),
}
print(challenger_datasets["GLO12"].time)

#challenger_datasets: List[xarray.Dataset] = [
#        xr.open_dataset("https://minio.dive.edito.eu/project-glonet/public/glonet_full_2024/20240103.zarr",engine="zarr",),
#        xr.open_dataset("https://minio.dive.edito.eu/project-oceanbench/public/XIHE/20240103.zarr",engine="zarr",),
#        xr.open_dataset("https://minio.dive.edito.eu/project-oceanbench/public/WENHAI/20240103.zarr",engine="zarr",),
#        xr.open_dataset("https://minio.dive.edito.eu/project-glonet/public/GLO12/20240103.zarr",engine="zarr",),
#        ]

#challenger_datasets: List[xarray.Dataset] = [
#    xarray.open_dataset(
#        "https://minio.dive.edito.eu/project-glonet/public/glonet_full_2024/20240103.zarr",
#        engine="zarr",
#    ),
#    xarray.open_dataset(
#        "https://minio.dive.edito.eu/project-glonet/public/glonet_full_2024/20240110.zarr",
#        engine="zarr",
#    ),
#]
