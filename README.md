# Stats_class4 / TEP CLASS4

Python tools for creating ocean-model **CLASS4 model–observation collocation files** and computing verification statistics. The package is named `tep_class4`; the repository contains command-line programs, model and local configuration files, launch helpers, and processing utilities.

## What the code does

The workflow compares ocean-model fields with observations (for example, in-situ temperature/salinity profiles, SST, SLA, sea ice and drifter data, depending on configuration):

1. **Load configuration** for the model, observation source, date range, lead times and file paths.
2. **Discover and read observations**, including their positions, depths, values and quality-control information.
3. **Locate model grid points** near observations using KD-tree-based spatial matching and calculate interpolation weights.
4. **Interpolate model values** horizontally and, for 3-D profiles, vertically onto observed depths.
5. **Write CLASS4 collocation outputs** containing paired model/observation data.
6. **Compute verification statistics**, including bias and RMSD, optionally grouped by region and depth interval.

The available operations and supported datasets depend on the selected model configuration and accessible data files.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/tep_class4/cli/` | Command-line entry points for collocation, statistics and parallel workflows |
| `src/tep_class4/cli/cfg/` | Model-specific configuration files, such as `config_mod_GLO12V4.cfg` |
| `src/tep_class4/core/Loader.py` | Load and interpret configuration and input metadata |
| `src/tep_class4/core/Extractor.py` | Locate observation files |
| `src/tep_class4/core/inputdata_loader.py` | Read observations and handle missing/QC data |
| `src/tep_class4/core/Interpolator.py` | Horizontal and vertical model-to-observation interpolation |
| `src/tep_class4/core/Interp_kdtree.py` | KD-tree spatial search and interpolation weights |
| `src/tep_class4/core/Writer.py` | Write collocation and other outputs |
| `src/tep_class4/core/arithm.py` | Numerical statistics, including depth-binned RMSD |
| `src/tep_class4/core/utils.py` | Shared utilities |
| `cfg/config_local.cfg` | Example local input, output and static-data paths |
| `launch/` | Example launch wrappers and batch scripts |
| `environment.yaml`, `conda-env-dev.yml` | Conda environment definitions |
| `pyproject.toml` | Python package metadata and installed commands |

## Requirements and installation

- Python **3.11 or 3.12** (as specified in `pyproject.toml`).
- Access to the configured observation and model datasets, static grid files and writable output directories.
- The scientific Python dependencies declared in `pyproject.toml`, including NumPy, SciPy, xarray, netCDF4, pandas, pykdtree and joblib.

Clone the repository and check out the working branch:

```bash
git clone https://github.com/cregnier31/Stats_class4.git
cd Stats_class4
git switch github_branch
```

One installation option is Conda followed by an editable package install:

```bash
conda env create -f environment.yaml
conda activate py312_env
python -m pip install -e .
```

The environment YAML supplies the scientific dependencies; the editable install registers the command-line entry points. On an HPC system with an existing Python environment, you can instead activate that environment and run `python -m pip install -e .`.

Verify the installation:

```bash
class4-run --help
stats-class4 --help
stats-class4-reg --help
stats-class4file-reg --help
```

> The `pyproject.toml` also declares a `class4-zarr` command, but verify that its referenced module exists in your checkout before using it.

## Configure a run

Two configuration layers are used:

1. **Local configuration**: `cfg/config_local.cfg` defines site-specific paths to observations, model inputs, output directories and static files. The sample contains HPC-specific absolute paths and will usually need editing.
2. **Model configuration**: files under `src/tep_class4/cli/cfg/` describe a model and its variables, forecast lead times and data formats. The `--config` argument selects the model configuration through the application's loader.

Before running, check that all paths in your local configuration exist, that you have read permission on input datasets, and that the output location is writable.

## Launch CLASS4 collocation

The installed entry point for the main collocation workflow is `class4-run` (`tep_class4.cli.class4:main`).

Example, using an illustrative model name and dates (replace these and the local config path with values valid for your installation):

```bash
class4-run \
  --config=GLO12V4 \
  --cfg=cfg/config_local.cfg \
  --date1=20261101 \
  --date2=20261101 \
  --data=profile \
  --typemod=pgn \
  --loglevel=2
```

Key options:

| Option | Meaning |
| --- | --- |
| `--config` | Model configuration identifier |
| `--cfg` | Local configuration file |
| `--date1`, `--date2` | Start and end dates, normally `YYYYMMDD` |
| `--data` | Observation/data category, such as `profile`, `SST` or `SLA` |
| `--typemod` | Model grid type, e.g. `pgn` for native grid |
| `--loglevel` | Application logging verbosity; the CLI describes `2` as info and `1` as debug |
| `--no-recombine` | Skip the recombination stage |

The exact model names, data types and supported options depend on the selected configuration. Use `class4-run --help` to check the installed version.

A launcher wrapper is also available at `launch/launch_class4.py`. It accepts five positional arguments (`CONFIG DATE1 DATE2 typedata typemod`) and selects an observation source and some forecast options. It invokes a relative script path, so run it from the intended `launch/` working directory and review its settings before using it.

## Launch CLASS4 statistics

Installed statistics entry points include:

- `stats-class4`: general statistics (`tep_class4.cli.class4_stats:main`).
- `stats-class4-reg`: regional statistics (`tep_class4.cli.class4_stats_regional:main`).
- `stats-class4file-reg`: statistics from regional CLASS4 files (`tep_class4.cli.class4_file_stats_regional:main`).

For regional file statistics, the repository includes a wrapper that builds the CLI command from positional arguments:

```bash
python launch/launcher_stats-class4_cli.py \
  GLO12V4 20261101 20261101 profile pgn cfg/config_local.cfg 2
```

The wrapper selects the source from the data type and invokes `stats-class4file-reg` with `--config`, `--cfg`, `--date1`, `--date2`, `--data`, `--src`, `--typemod` and `--loglevel`. Adjust the example values to match available datasets. You can also run the underlying installed command directly:

```bash
stats-class4file-reg \
  --config=GLO12V4 \
  --cfg=cfg/config_local.cfg \
  --date1=20261101 --date2=20261101 \
  --data=profile --src=GODAE --typemod=pgn --loglevel=2
```

For other statistics programs, inspect their `--help` output and the associated CLI file: their required arguments are not necessarily identical.

## Interpolation and missing values

The main collocation program reads observations through `inputdata_loader.py`, uses `Interpolator.query_weight()` to obtain spatial weights, and calls interpolation methods to compute model values at observation locations.

For profiles, `Interpolator.interp_3D()`:

1. Interpolates the model field horizontally at model depth levels via `compute_3D_weight_origin()`.
2. Builds a model profile at each observation position.
3. Uses the `Column` vertical interpolator to evaluate that profile at observation depths.
4. Returns a model array aligned with the observation profiles.

**Missing-value caution:** The current `interp_3D()` implementation contains:

```python
tab_interp_tmp = np.array(results)
values_interp = fillvalue * np.zeros((nb_obs, nb_profs))
```

Multiplying a finite fill value by zeros initializes the output to **zero**, not to the fill value. If a profile/level is not subsequently assigned, an invalid model value may remain zero and contaminate salinity RMSD. A safer initialization is:

```python
values_interp = np.full((nb_obs, nb_profs), fillvalue, dtype=float)
```

This README documents the issue; it does **not** change the interpolation implementation. Also inspect masked values, NetCDF fill values and invalid grid points when investigating interpolation artifacts. Do not globally discard model zeros: zero degrees Celsius can be a valid temperature.

## RMSD diagnostics

`compute_rmsd_3d_by_depth_bins()` in `src/tep_class4/core/arithm.py` computes depth-binned bias and RMSD from model/observation pairs, observation depths and QC flags. Its optional debug mode reports pair counts, RMSD, bias, absolute-error percentiles, maximum error and large-error outliers.

To **enable** RMSD diagnostics for a run:

```bash
export CLASS4_DEBUG_RMSD=1
# Run your usual CLASS4 statistics command
```

To **disable** the diagnostics:

```bash
unset CLASS4_DEBUG_RMSD
# Run your usual CLASS4 statistics command
```

The function also accepts `debug=True` and an optional `log=` argument when called from Python. Environment-based debugging only affects executions that reach this function; it does not automatically enable logging for unrelated statistics paths. Console visibility depends on the application's logger configuration.

When interpreting RMSD, inspect outliers and the number of valid pairs. A small number of zero-valued model salinity points paired with normal observations can disproportionately increase RMSD because errors are squared.

## Typical troubleshooting

- **Command not found:** Activate the correct environment and reinstall with `python -m pip install -e .`.
- **Missing configuration or input files:** Check `--cfg`, `--config` and the paths in `cfg/config_local.cfg`.
- **No output:** Check the output directories and file permissions, input date range, and whether observation files were discovered.
- **Unexpected model zeros:** Inspect raw model values, horizontal interpolation output and `interp_3D()` initialization/vertical interpolation.
- **Unusually high RMSD:** Enable `CLASS4_DEBUG_RMSD`, inspect outlier pairs and QC flags, and verify missing values are excluded.
- **No debug messages on screen:** Pass the application's configured logger to the RMSD routine, or check logger handlers and INFO-level filtering.

## Additional launch examples

See `launch/README_LAUNCH` for historical commands and `launch/` for shell and Python wrappers. Some examples refer to older `TEP_CLASS4*.py` script names and are not guaranteed to work unchanged with the current packaged entry points.

## Development notes

The package uses a `src/` layout and declares its CLI entry points in `pyproject.toml`. After changing interpolation or statistics code, run a representative one-day collocation/statistics job and compare valid pair counts, depth-binned RMSD and logged outliers before deploying a longer run.
