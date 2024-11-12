import sys
from os.path import dirname
sys.path.append(dirname(__file__)+'/../../modules/')
from utils import split_year_into_months
import os
import subprocess
from datetime import datetime

# Function to generate the SLURM script for a given month
def get_srcdata_and_options(typedata):
    if typedata in ["SST", "SLA", "profile", "aice"]:
        srcdata = "GODAE"
        # options = '--all'  # Commented out as in the original script
        options = '--best'
    elif typedata in ["DRIFTER", "DRIFTER_filtr"]:
        srcdata = "CMEMS_013_048"
        options = '--SMOC --best --clim --bathy --stokes --tides'
    elif typedata == "CORA5.2":
        srcdata = "NC_CORIO"
        options = '--all'  # '--clim' commented out as in the original script
    else:
        raise ValueError(f"'{typedata}' not known")

    return srcdata, options

def create_batch_script(date1,
                        date2,
                        CONFIG,
                        typedata,
                        typemod,
                        dirsrc,
                        dirlog,
                        output_dir):
    # Template for the SLURM batch script
    srcdata, options = get_srcdata_and_options(typedata)
    script_content = f"""#!/usr/bin/ksh
#SBATCH -J CLASS4_{typemod}_{CONFIG}_{date1}_{date2}
#SBATCH -p multi
#SBATCH -N 4
#SBATCH -q qosmulti
#SBATCH --exclusive
#SBATCH -e /kara/data1/cregnier/log/{CONFIG}_{typedata}_{typemod}_CLASS4_{date1}_{date2}_job%j.e
#SBATCH -o /kara/data1/cregnier/log/{CONFIG}_{typedata}_{typemod}_CLASS4_{date1}_{date2}_job%j.o
#SBATCH --ntasks-per-node=10
#SBATCH --time=06:00:00
options='--best'
loglevel=7
CONFIG="{CONFIG}"
DATE1="{date1}"
DATE2="{date2}"
typemod="{typemod}"
srcdata="{srcdata}"
typedata="{typedata}"
dirlog="{dirlog}"
src_dir="{dirsrc}"
DIR_BIN="/data/rd_exchange/qualif/anaconda3/envs/env_py311/bin/"
${{DIR_BIN}}mpirun -np 40 ${{DIR_BIN}}python ${{src_dir}}/TEP_CLASS4_kdtree_multiproc.py \\
                 --config=${{CONFIG}} --date1=${{DATE1}} --date2=${{DATE2}} \\
                 --src=${{srcdata}} --data=${{typedata}} --typemod=${{typemod}} \\
                 --loglevel=${{loglevel}} ${{options}} --dirlog=${{dirlog}}
"""

    # Write the script to a file
    script_filename = os.path.join(output_dir, f"CLASS4_PGS_GREP_{date1}_{date2}.sh")
    with open(script_filename, 'w') as script_file:
        script_file.write(script_content)
    print(f"Created {script_filename}")
    # Submit the script to SLURM using sbatch
    try:
        result = subprocess.run(['sbatch', script_filename], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(f"Submitted {script_filename} with Job ID: {result.stdout.decode().strip()}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to submit {script_filename}: {e.stderr.decode().strip()}")


def main():
    if len(sys.argv) != 5:
        print(sys.argv)
        print(f"Len {len(sys.argv)} /= 6")
        print("Usage: python launch_class4_multi.py <year><CONFIG><typedata><typemod>")
        print("Example launch_class4_multi.py 2024 GREP CORA5.2 pgs")
        sys.exit(1)
    try:
        year = int(sys.argv[1])
        CONFIG = sys.argv[2]
        typedata = sys.argv[3]
        typemod = sys.argv[4]
    except ValueError:
        print("Please provide valid values.")
        sys.exit(1)
    dirlog = "/kara/data1/cregnier/log/"
    output_dir = "/kara/data1/cregnier/sub/"
    dir_src = "/home/cregnier/Gitlab/TEP_CLASS4_creation/script/"
    print(year, CONFIG, typedata, typemod)
    months = split_year_into_months(year)
    for start, end in months:
        print(f"Month: {start} to {end}")
        create_batch_script(start,
                            end,
                            CONFIG,
                            typedata,
                            typemod,
                            dir_src,
                            dirlog,
                            output_dir)

if __name__ == "__main__":
    main()
