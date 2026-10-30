import subprocess
import sys

def main():
    if len(sys.argv) != 8:
        print("Usage: script.py <CONFIG> <DATE1> <DATE2> <typedata> <typemod> <conf> <loglevel>")
        sys.exit(1)

    config, date1, date2, typedata, typemod, conf, loglevel = sys.argv[1:8]

    print(config, date1, date2, typedata, typemod, conf )
    options = ""
    if typedata in ["SST", "SLA", "profile", "aice"]:
        srcdata = "GODAE"
    elif typedata in ["profile_TS_DB","profile_PR_PF"]:
        srcdata = "NC_CORIO"
    elif typedata in ["SLA-L3"]:
        srcdata = "CMS"
    elif typedata in ["DRIFTER", "DRIFTER_filtr"]:
        srcdata = "CMEMS_013_048"
    else:
        print(f"{typedata} not known")
        sys.exit(1)
    # Use installed CLI entry point instead of raw script path
    command = [
        "stats-class4file-reg",
        f"--config={config}",
        f"--cfg={conf}",
        f"--date1={date1}",
        f"--date2={date2}",
        f"--data={typedata}",
        f"--src={srcdata}",
        f"--typemod={typemod}",
        f"--loglevel={loglevel}"
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
