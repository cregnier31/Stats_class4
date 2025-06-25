import subprocess
import sys

def main():
    # Check for required input parameters
    if len(sys.argv) != 5:
        print("Usage: script.py <CONFIG> <DATERUN> <typedata> <typemod>")
        sys.exit(1)

    config, daterun, typedata, typemod = sys.argv[1:5]

    # Determine srcdata and options
    if typedata in ["SST", "SLA", "profile", "aice"]:
        srcdata = "GODAE"
        #ioptions = "--best"
        options = "--fcst --zarr"
    elif typedata in ["SLA-L3"]:
        srcdata="CMS"
        options = "--best"
    elif typedata in ["DRIFTER", "DRIFTER_filtr"]:
        srcdata = "CMEMS_013_048"
        #options = "--SMOC --best --clim --bathy --stokes --tides"
        options = "--fcst --zarr"
    else:
        print(f"{typedata} not known")
        sys.exit(1)

    loglevel = 6
    #python_bin = "/opt/conda/envs/myenv_class4/bin/python"
    python_bin = "python"
    script_path = "../src/tep_class4/cli/class4_zarr3.py"

    command = [
        python_bin,
        script_path,
        f"--config={config}",
        f"--daterun={daterun}",
        f"--src={srcdata}",
        f"--data={typedata}",
        f"--typemod={typemod}",
        f"--loglevel={loglevel}",
    ] + options.split()

    try:
        subprocess.run(command, check=True)
        print("Run submitted successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error submitting job: {e}")

if __name__ == "__main__":
    main()
