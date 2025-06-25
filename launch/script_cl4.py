import subprocess
from datetime import datetime, timedelta

start_date = datetime.strptime("20240103", "%Y%m%d").date()
#start_date = datetime.strptime("20241030", "%Y%m%d").date()
end_date = datetime.strptime("20240103", "%Y%m%d").date()
#end_date = datetime.strptime("20240110", "%Y%m%d").date()
#end_date = datetime.strptime("20240430", "%Y%m%d").date()
#start_date = datetime.strptime("20240703", "%Y%m%d").date()
#start_date = datetime.strptime("20240724", "%Y%m%d").date()
#start_date = datetime.strptime("20240103", "%Y%m%d").date()
#start_date = datetime.strptime("20240828", "%Y%m%d").date()
#end_date = datetime.strptime("20240131", "%Y%m%d").date()

current = start_date
#system = "WENHAI"
system = "GLO12"
system = "GLONET14"
#system = "XIHE"
#variable = "SST"
variable = "SLA"
#variable = "DRIFTER_filtr"
#liste_variables = ['SLA', 'SST', 'DRIFTER_filtr', 'profile']
#variable = "profile"
while current <= end_date:
    date_str = current.strftime("%Y%m%d")
    cmd = ["python", "launch_class4_zarr.py", f"{system}", date_str, f"{variable}", "pgs_ai"]
#    cmd = ["python", "launch_class4_zarr2.py", f"{system}", date_str, f"{variable}", "pgs_ai"]
    #cmd = ["python", "launch_class4_stats.py", f"{system}", date_str, f"{list_variables}", "start_date", "end_date", "pgs_ai"]
    subprocess.run(cmd)
    current += timedelta(days=7)  # advance to next Wednesday
