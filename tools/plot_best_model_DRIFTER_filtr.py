#!/usr/bin/env python3
"""Heatmaps of the lowest-RMSD CLASS4 system by region and forecast lead time.

One PNG per velocity component (uo, vo). The winning system is determined
independently for each region/lead-time cell using the lowest valid RMSD.
"""
import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import BoundaryNorm, ListedColormap
from matplotlib.patches import Patch
import numpy as np
import xarray as xr

MODELS = ("glo4-ens50", "glonet", "glow", "GLO12")
NAMES = ("GLOENS", "GLONET", "GLONET3", "GLO12")
COLORS = ("tab:blue", "tab:green", "tab:red", "tab:orange")


def label(value):
    return value.decode("utf-8") if isinstance(value, bytes) else str(value)


def load_rmsd(path, min_obs):
    with xr.open_dataset(path) as ds:
        sq_name = next((n for n in ("cumul_sq_diff", "cumul_squared_diff") if n in ds), None)
        if sq_name is None or "n_obs" not in ds:
            raise ValueError(f"{path}: missing cumulative squared differences or n_obs")
        if "regions" not in ds.dims or "leadtime" not in ds.dims:
            raise ValueError(f"{path}: missing regions/leadtime dimensions")
        sq = ds[sq_name]
        count = ds["n_obs"]
        if not {"regions", "leadtime"}.issubset(sq.dims) or not {"regions", "leadtime"}.issubset(count.dims):
            raise ValueError(f"{path}: unexpected score dimensions")
        # Aggregate cumulative quantities over any additional dimensions.
        sq = sq.sum(dim=[d for d in sq.dims if d not in ("regions", "leadtime")], skipna=True)
        count = count.sum(dim=[d for d in count.dims if d not in ("regions", "leadtime")], skipna=True)
        sq = sq.transpose("regions", "leadtime").values
        count = count.transpose("regions", "leadtime").values
        with np.errstate(divide="ignore", invalid="ignore"):
            rmsd = np.where(count >= min_obs, np.sqrt(np.maximum(sq / count, 0)), np.nan)
        regions = [label(v) for v in ds["regions"].values]
        leadtimes = [label(v) for v in ds["leadtime"].values]
        return regions, leadtimes, rmsd


def plot_component(variable, input_dir, output_dir, date_range, min_obs, dpi):
    datasets = {}
    for model in MODELS:
        path = input_dir / (
            f"results_regional_scores_class4_DRIFTER_filtr_{model}_{variable}_"
            f"forecast_{date_range}.nc"
        )
        if not path.is_file():
            raise FileNotFoundError(f"Input file not found: {path}")
        datasets[model] = load_rmsd(path, min_obs)

    # Union of regions; use positional forecast days 1..N, consistent with
    # plots_stats_skill_intercomp_DRIFTER_filtr.py.
    regions = list(dict.fromkeys(region for r, _, _ in datasets.values() for region in r))
    n_leads = max(len(leads) for _, leads, _ in datasets.values())
    values = np.full((len(MODELS), len(regions), n_leads), np.nan)

    for imodel, model in enumerate(MODELS):
        model_regions, leads, rmsd = datasets[model]
        for ir, region in enumerate(model_regions):
            values[imodel, regions.index(region), :len(leads)] = rmsd[ir]

    valid = np.isfinite(values)
    any_valid = valid.any(axis=0)
    winner = np.full((len(regions), n_leads), np.nan)
    winner[any_valid] = np.argmin(np.where(valid, values, np.inf), axis=0)[any_valid]

    cmap = ListedColormap(COLORS)
    cmap.set_bad("#e0e0e0")
    norm = BoundaryNorm(np.arange(-0.5, len(MODELS) + 0.5), cmap.N)
    fig_height = max(5.5, 0.43 * len(regions) + 2.3)
    fig, ax = plt.subplots(figsize=(max(12, 0.48 * n_leads + 4), fig_height))
    ax.imshow(np.ma.masked_invalid(winner), cmap=cmap, norm=norm,
              interpolation="nearest", aspect="auto")
    ax.set_yticks(np.arange(len(regions)))
    ax.set_yticklabels(regions, fontsize=11)
    ax.set_xticks(np.arange(n_leads))
    ax.set_xticklabels(np.arange(1, n_leads + 1), fontsize=10)
    ax.set_xlabel("Forecast lead time (days)", fontsize=14)
    ax.set_ylabel("Region", fontsize=14)
    ax.set_title(f"DRIFTER_filtr {variable} — Best system (lowest RMSD)\n"
                 f"{date_range}", fontsize=16, pad=17)
    ax.set_xticks(np.arange(-0.5, n_leads, 1), minor=True)
    ax.set_yticks(np.arange(-0.5, len(regions), 1), minor=True)
    ax.grid(which="minor", color="white", linewidth=0.7)
    ax.tick_params(which="minor", bottom=False, left=False)

    legend = [Patch(facecolor=color, label=name) for color, name in zip(COLORS, NAMES)]
    legend.append(Patch(facecolor="#e0e0e0", label="No valid data"))
    fig.legend(handles=legend, loc="lower center", ncol=len(legend),
               bbox_to_anchor=(0.55, 0.015), frameon=True, fontsize=11)
    fig.subplots_adjust(left=0.18, right=0.98, top=0.88, bottom=0.15)

    outfile = output_dir / (
        f"best_model_DRIFTER_filtr_{variable}_forecast_{date_range}.png"
    )
    fig.savefig(outfile, dpi=dpi, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved {outfile}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=Path("/sortref/calval/CLASS4_scores"))
    parser.add_argument("--output-dir", type=Path, default=Path("imgs/best_model_DRIFTER_filtr"))
    parser.add_argument("--date-range", default="20240101_20241231")
    parser.add_argument("--variable", choices=("uo", "vo", "both"), default="both")
    parser.add_argument("--min-obs", type=int, default=1)
    parser.add_argument("--dpi", type=int, default=250)
    args = parser.parse_args()
    if args.min_obs < 1:
        parser.error("--min-obs must be at least 1")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for variable in ("uo", "vo") if args.variable == "both" else (args.variable,):
        plot_component(variable, args.input_dir, args.output_dir,
                       args.date_range, args.min_obs, args.dpi)


if __name__ == "__main__":
    main()
