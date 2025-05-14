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

    loglevel = 7
    #python_bin = "/opt/conda/envs/myenv_class4/bin/python"
    python_bin = "python"
    script_path = "../src/tep_class4/cli/class4_recomb.py"

    command = [
        python_bin,
        script_path,
        f"--config={config}",
        f"--date1={date1}",
        f"--date2={date2}",
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
