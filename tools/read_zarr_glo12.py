# Open GLONET forecast sample with xarray
import xarray
from typing import List
import xarray as xr
import sys
import subprocess

from typing import Dict

# Base path per system
BASE_PATHS: Dict[str, str] = {
    "GLO-NET_FULL": "project-glonet/public/glonet_full_2024",
    "XIHE": "project-oceanbench/public/XIHE",
    "WENHAI": "project-oceanbench/public/WENHAI",
    "GLO12": "project-glonet/public/GLO12",
}

def list_zarr_datasets_sys(system):
    cmd = [
        "aws",
        "--endpoint-url", "https://minio.dive.edito.eu",
        "s3", "ls", f"s3://project-glonet/public/{system}/"
    ]
    output = subprocess.check_output(cmd).decode("utf-8")
    datasets = [
        line.split()[-1].rstrip('/')
        for line in output.strip().split('\n')
        if line.endswith('.zarr/')
    ]
    return datasets
system = "GLO12"
zarr_datasets = list_zarr_datasets_sys(system)
print(zarr_datasets)

sys.exit(1)

#challenger_datasets = {
#    "GLO12": xr.open_dataset(
#        "https://minio.dive.edito.eu/project-glonet/public/GLO12/20240810.zarr", engine="zarr"
#    ),
#}
#print(challenger_datasets["GLO12"].time)

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
