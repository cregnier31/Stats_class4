import subprocess
from datetime import datetime, timedelta

start_date = datetime.strptime("20240911", "%Y%m%d").date()
end_date = datetime.strptime("20241231", "%Y%m%d").date()

current = start_date
while current <= end_date:
    date_str = current.strftime("%Y%m%d")
    cmd = ["python", "launch_class4_zarr.py", "GLONET14", date_str, "SLA", "pgs_ai"]
    subprocess.run(cmd)
    current += timedelta(days=7)  # advance to next Wednesday
