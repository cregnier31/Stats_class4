#!/usr/bin/env python3
"""Regional surface CLASS4 skill versus forecast lead time."""
import argparse
import re
from pathlib import Path
import warnings

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr

ALIASES = {"GLOENS": ("glo4-ens50", "GLOENS"),
           "GLONET": ("glonet", "GLONET"),
           "GLOW": ("glow", "GLOW"), "GLO12": ("GLO12",)}
VARIABLES = {"profile_TS_DB": ("thetao", "so"),
             "DRIFTER_filtr": ("uo", "vo"), "DRIFTER": ("uo", "vo")}
UNITS = {"thetao": "deg C", "so": "PSU", "uo": "m/s", "vo": "m/s"}


def find_file(args, system, variable):
    aliases = ALIASES.get(system.upper(), (system,))
    prefixes = {"auto": ("optim_", ""), "optim": ("optim_",),
                "original": ("",)}[args.source]
    for prefix in prefixes:
        for alias in aliases:
            path = args.input_dir / (
                f"results_regional_scores_class4_{prefix}{args.data}_{alias}_"
                f"{variable}_forecast_{args.date1}_{args.date2}.nc")
            if path.is_file():
                return path
    return None


def skill(ds, name):
    if "stats_skill" not in ds or "skill_metric_names" not in ds:
        return None
    names = [v.decode() if isinstance(v, bytes) else str(v)
             for v in ds.skill_metric_names.values]
    if name not in names:
        return None
    return ds.stats_skill.isel(skill_metrics=names.index(name))


def line(ax, da, region, label, color, style="-"):
    if da is None:
        return
    a = da.sel(regions=region).transpose("leadtime")
    ax.plot(a.leadtime.values, a.values, style, color=color,
            marker="o", markersize=3, label=label)


def plot_region(data, region, variable, args):
    drifter = args.data.startswith("DRIFTER")
    common = drifter and any("current_common_scores" in ds for ds in data.values())
    n = 3 + int(common) + int(drifter and args.acc)
    fig, axes = plt.subplots(n, 1, figsize=(10, 3*n), sharex=True,
                             constrained_layout=True)
    titles = [f"Period RMSD ({UNITS[variable]})",
              f"Mean daily RMSD ({UNITS[variable]})", "Pearson correlation"]
    if common:
        titles.append("Common-sample model / climatology RMSD and Pearson")
        # Separate axes for dimensional RMSD and dimensionless correlation.
        twin = axes[3].twinx()
        twin.set_ylabel("Pearson correlation")
        twin.set_ylim(-1, 1.05)
    if drifter and args.acc:
        titles.append("Anomaly correlation")
    for i, (system, ds) in enumerate(data.items()):
        if region not in ds.regions.values:
            continue
        color = f"C{i % 10}"
        sq = next((ds[k] for k in ("cumul_sq_diff", "cumul_squared_diff") if k in ds), None)
        rmsd = np.sqrt(sq / ds.n_obs.where(ds.n_obs > 0)) if sq is not None else ds.rmsd
        daily = ds.rmsd_daily
        if "n_obs_daily" in ds:
            daily = daily.where(ds.n_obs_daily > 0)
        line(axes[0], rmsd, region, system, color)
        line(axes[1], daily.mean("day", skipna=True), region, system, color)
        line(axes[2], skill(ds, "pearson correlation"), region, system, color)
        if common and "current_common_scores" in ds:
            scores = ds.current_common_scores
            for product, style in (("model", "-"), ("climatology", "--")):
                a = scores.sel(current_product=product)
                label = f"{system} {product}"
                line(axes[3], a.sel(current_metric="rmsd"), region, label, color, style)
                line(twin, a.sel(current_metric="pearson"), region, label, color,
                     ":" if product == "model" else "-.")
        if drifter and args.acc:
            line(axes[-1], skill(ds, "anomaly correlation"), region, system, color)
    axes[2].set_ylim(-1, 1.05)
    if drifter and args.acc:
        axes[-1].set_ylim(-1, 1.05)
    for ax, title in zip(axes, titles):
        ax.set_title(title)
        ax.grid(alpha=.25)
        handles, labels = ax.get_legend_handles_labels()
        if handles:
            ax.legend(fontsize=8, ncol=2)
        else:
            ax.text(.5, .5, "Statistic unavailable", transform=ax.transAxes,
                    ha="center", va="center")
    if common:
        axes[3].set_ylabel(f"RMSD ({UNITS[variable]})")
        handles, labels = twin.get_legend_handles_labels()
        if handles:
            twin.legend(handles, labels, fontsize=8, loc="lower right", title="Pearson")
    axes[-1].set_xlabel("Forecast lead time (days)")
    fig.suptitle(f"{args.data} | {variable} | {region} | {args.date1}-{args.date2}")
    safe = re.sub(r"[^a-zA-Z0-9_-]+", "_", str(region)).strip("_")
    path = args.output_dir / f"{args.data}_{variable}_{safe}_{args.date1}_{args.date2}_surface_skill.png"
    fig.savefig(path, dpi=args.dpi)
    plt.close(fig)
    print(f"Saved {path}")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input-dir", type=Path, default=Path("/sortref/calval/CLASS4_scores"))
    p.add_argument("--output-dir", type=Path, default=Path("imgs/regional_surface_skill"))
    p.add_argument("--data", choices=VARIABLES, required=True)
    p.add_argument("--date1", required=True)
    p.add_argument("--date2", required=True)
    p.add_argument("--systems", nargs="+", default=list(ALIASES))
    p.add_argument("--variables", nargs="+")
    p.add_argument("--regions", nargs="+")
    p.add_argument("--source", choices=["auto", "optim", "original"], default="auto")
    p.add_argument("--acc", action="store_true")
    p.add_argument("--dpi", type=int, default=200)
    args = p.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for variable in args.variables or VARIABLES[args.data]:
        if variable not in VARIABLES[args.data]:
            p.error(f"Unsupported variable {variable} for {args.data}")
        data = {}
        for system in args.systems:
            path = find_file(args, system, variable)
            if path is None:
                warnings.warn(f"No input for {system} {variable}")
                continue
            print(f"Reading {path}")
            with xr.open_dataset(path) as ds:
                data[system] = ds.load()
        if not data:
            p.error(f"No input files for {variable}")
        regions = list(dict.fromkeys(r for ds in data.values() for r in ds.regions.values))
        for region in args.regions or regions:
            if region not in regions:
                warnings.warn(f"Unknown region {region}")
                continue
            plot_region(data, region, variable, args)


if __name__ == "__main__":
    main()
