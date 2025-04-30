import subprocess
import sys

def main():
    if len(sys.argv) != 5:
        print("Usage: script.py <CONFIG> <DATERUN> <typedata> <typemod>")
        sys.exit(1)

    config, daterun, typedata, typemod = sys.argv[1:5]

    # Determine srcdata and options
    if typedata in ["SST", "SLA", "profile", "aice"]:
        srcdata = "GODAE"
        options = "--fcst --zarr"
    elif typedata in ["SLA-L3"]:
        srcdata = "CMS"
        options = "--best --zarr"
    elif typedata in ["DRIFTER", "DRIFTER_filtr"]:
        srcdata = "CMEMS_013_048"
        options = "--SMOC --best --clim --bathy --stokes --tides"
    else:
        print(f"{typedata} not known")
        sys.exit(1)

    loglevel = 7

    # Use installed CLI entry point instead of raw script path
    command = [
        "class4-zarr",
        f"--config={config}",
        f"--daterun={daterun}",
        f"--src={srcdata}",
        f"--data={typedata}",
        f"--typemod={typemod}",
        f"--loglevel={loglevel}",
    ] + options.split()

    # Print and run
    print("Running command:")
    print(" ".join(command))

    try:
        subprocess.run(command, check=True)
        print("Run submitted successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error running job: {e}")

if __name__ == "__main__":
    main()
