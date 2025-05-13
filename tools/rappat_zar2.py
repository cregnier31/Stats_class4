import subprocess
import xarray as xr
import os

# Updated system paths
SYSTEM_PATHS = {
    "GLO-NET_FULL": "project-glonet/public/glonet_full_2024",
    "XIHE": "project-oceanbench/public/XIHE",
    "WENHAI": "project-oceanbench/public/WENHAI",
    "GLO12": "project-glonet/public/GLO12",
}

ENDPOINT_URL = "https://minio.dive.edito.eu"
OUTPUT_DIR = "./netcdf_outputs"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def list_zarr_datasets(s3_path):
    cmd = [
        "aws", "--endpoint-url", ENDPOINT_URL,
        "s3", "ls", f"s3://{s3_path}/"
    ]

    try:
        output = subprocess.check_output(cmd).decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error listing datasets for {s3_path}: {e}")
        return []

    datasets = [
        line.split()[-1].rstrip('/').replace('.zarr', '')
        for line in output.strip().split('\n')
        if line.endswith('.zarr/')
    ]
    return datasets

def download_zarr_as_netcdf(system, s3_path, datasets):
    for dataset in datasets:
        zarr_url = f"s3://{s3_path}/{dataset}.zarr"
        print(f"[{system}] Reading: {zarr_url}")

        try:
            ds = xr.open_zarr(
                zarr_url,
                storage_options={
                    "anon": True,
                    "client_kwargs": {"endpoint_url": ENDPOINT_URL}
                }
            )
        except Exception as e:
            print(f"[{system}] Failed to open {zarr_url}: {e}")
            continue

        out_file = os.path.join(OUTPUT_DIR, f"{system}_{dataset}.nc")
        try:
            ds.to_netcdf(out_file)
            print(f"[{system}] Saved to: {out_file}")
        except Exception as e:
            print(f"[{system}] Failed to save NetCDF for {zarr_url}: {e}")

def main():
    for system, s3_path in SYSTEM_PATHS.items():
        print(f"--- Processing system: {system} ---")
        datasets = list_zarr_datasets(s3_path)
        if not datasets:
            print(f"[{system}] No Zarr datasets found.")
            continue
        download_zarr_as_netcdf(system, s3_path, datasets)

if __name__ == "__main__":
    main()
