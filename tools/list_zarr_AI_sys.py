import subprocess
from typing import List

# Mapping system name to its S3 path
SYSTEM_PATHS = {
    "GLO-NET_FULL": "project-glonet/public/glonet_full_2024",
    "XIHE": "project-oceanbench/public/XIHE",
    "WENHAI": "project-oceanbench/public/WENHAI",
    "GLO12": "project-glonet/public/GLO12",
}

def list_zarr_datasets_for_system(system: str) -> List[str]:
    """
    List available Zarr datasets for a given system from MinIO S3.
    Returns a list of filenames (e.g. '20240810.zarr').
    """
    if system not in SYSTEM_PATHS:
        raise ValueError(f"Unknown system: {system}")
    
    s3_path = SYSTEM_PATHS[system]
    cmd = [
        "aws", "--endpoint-url", "https://minio.dive.edito.eu",
        "s3", "ls", f"s3://{s3_path}/"
    ]
    
    try:
        output = subprocess.check_output(cmd).decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error listing datasets for {system}: {e}")
        return []
    
    datasets = [
        line.split()[-1].rstrip('/').replace('.zarr', '')
        for line in output.strip().split('\n')
        if line.endswith('.zarr/')
    ]
    return datasets

# Example: list available Zarr datasets for GLO12
system = "GLO12"
system = "WENHAI"
#system = "XIHE"
#system = "GLO-NET_FULL"
available_zarrs = list_zarr_datasets_for_system(system)
print(available_zarrs)
