import subprocess
from datetime import datetime, timedelta

start_date = "20240103"
start_date = "20241106"
#start_date = "20240703"
#start_date = "20240714"
end_date = "20241231"
end_date = "20240103"

system = "WENHAI"
system = "GLONET14"
system = "GLO12"
#system = "XIHE"
variable = "DRIFTER_filtr"
#variable = "SST"
#variable = "SLA"
variable = "profile"

cmd = ["python", "launch_class4_recomb.py", f"{system}", start_date, end_date, f"{variable}", "pgs_ai"]
subprocess.run(cmd)
