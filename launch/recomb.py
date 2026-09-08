import subprocess

start_date = "20240904"
end_date = "20241231"

system = "WENHAI"
variable = "SLA"
system = "GLONET14"
cmd = ["python", "launch_class4_recomb.py", f"{system}", start_date, end_date, f"{variable}", "pgs_ai"]
subprocess.run(cmd)
