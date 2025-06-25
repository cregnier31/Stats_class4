import subprocess
from datetime import datetime, timedelta

start_date = datetime.strptime("20240103", "%Y%m%d").date()
end_date = datetime.strptime("20241231", "%Y%m%d").date()
system = "GLO12"
#system = "GLONET14"
#system = "WENHAI"
#system = "XIHE"
#list_variables = ['SLA', 'SST', 'DRIFTER_filtr', 'profile']
cmd = ["python", "launch_class4_stats.py", f"{system}", f'{start_date}', f'{end_date}', "pgs_ai"]
subprocess.run(cmd)
