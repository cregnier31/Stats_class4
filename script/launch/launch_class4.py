import subprocess
import sys

def main():
    # Check for required input parameters
    if len(sys.argv) != 6:
        print("Usage: script.py <CONFIG> <DATE1> <DATE2> <typedata> <typemod>")
        sys.exit(1)

    config, date1, date2, typedata, typemod = sys.argv[1:6]

    # Determine srcdata and options
    if typedata in ["SST", "SLA", "profile", "aice"]:
        srcdata = "GODAE"
        options = "--best"
    elif typedata in ["SLA-L3"]:
        srcdata="CMS"
        options = "--best"
    elif typedata in ["DRIFTER", "DRIFTER_filtr"]:
        srcdata = "CMEMS_013_048"
        options = "--SMOC --best --clim --bathy --stokes --tides"
    else:
        print(f"{typedata} not known")
        sys.exit(1)

    loglevel = 7
    python_bin = "/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/python"
    script_path = "../TEP_CLASS4_kdtree_optim.py"

    command = [
        f"{python_bin} {script_path} --config={config} --date1={date1} --date2={date2} "
        f"--src={srcdata} --data={typedata} --typemod={typemod} --loglevel={loglevel} {options}"
    ]

    # Execute the sbatch command
    try:
        subprocess.run(sbatch_command, check=True)
        print("Run submitted successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error submitting job: {e}")
