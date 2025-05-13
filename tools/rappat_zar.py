import s3fs
import xarray as xr
import os

# Actual bucket name
#bucket_name = "project-glonet"
bucket_name = "project-oceanbench"
#prefix = "public/glonet_full_2024/"
prefix = "public/WENHAI/"

# S3 endpoint (MinIO)
endpoint_url = "https://minio.dive.edito.eu"

# Setup S3 filesystem with the correct MinIO endpoint
fs = s3fs.S3FileSystem(
    anon=True,
    client_kwargs={"endpoint_url": "https://minio.dive.edito.eu"}
)

# List Zarr stores
zarr_paths = fs.ls(f"{bucket_name}/{prefix}")
zarr_paths = [p for p in zarr_paths if p.endswith(".zarr")]
print(zarr_paths)

# Output directory for NetCDFs
output_dir = "./netcdf_outputs"
os.makedirs(output_dir, exist_ok=True)

# Convert each Zarr to NetCDF
for zarr_path in zarr_paths:
    print(f"Opening Zarr store: {zarr_path}")
    
    # Construct full S3 path
    store_url = f"s3://{zarr_path}"
    ds = xr.open_zarr(store_url, storage_options={
        "anon": True,
        "client_kwargs": {"endpoint_url": endpoint_url}
    })

    # Save as NetCDF
    base_name = os.path.basename(zarr_path).replace(".zarr", ".nc")
    nc_path = os.path.join(output_dir, base_name)
    ds.to_netcdf(nc_path)
    print(f"Saved to: {nc_path}")
