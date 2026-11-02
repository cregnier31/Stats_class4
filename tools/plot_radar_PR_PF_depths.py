#!/usr/bin/env python3
"""PR_PF depth-layer radar charts for thetao and so, one chart per region.

Each spoke is a PR_PF depth layer. Four model curves show RMSD relative
to the lowest valid RMSD at that region/depth/lead time (1.0 is best).
"""
import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr

MODELS = ("glo4-ens50", "glonet", "glow", "GLO12")
NAMES = ("GLOENS", "GLONET", "GLONET3", "GLO12")
COLORS = ("tab:blue", "tab:green", "tab:red", "tab:orange")


def label(v):
    return v.decode("utf-8") if isinstance(v, bytes) else str(v)


def safe_name(s):
    return re.sub(r"[^a-zA-Z0-9_-]+", "_", str(s)).strip("_")


def load(path, lead_day, min_obs):
    with xr.open_dataset(path) as ds:
        sq_name = next((n for n in ("cumul_sq_diff", "cumul_squared_diff") if n in ds), None)
        if sq_name is None or "n_obs" not in ds:
            raise ValueError(f"{path}: missing cumulative squared difference or n_obs")
        needed = {"regions", "depth", "leadtime"}
        if not needed.issubset(ds.dims):
            raise ValueError(f"{path}: expected dimensions {sorted(needed)}")
        if lead_day > ds.sizes["leadtime"]:
            raise ValueError(f"{path}: day {lead_day} exceeds {ds.sizes['leadtime']} lead times")
        sq = ds[sq_name].isel(leadtime=lead_day - 1)
        count = ds["n_obs"].isel(leadtime=lead_day - 1)
        for name, arr in ((sq_name, sq), ("n_obs", count)):
            if not {"regions", "depth"}.issubset(arr.dims):
                raise ValueError(f"{path}: unexpected dimensions for {name}: {arr.dims}")
        extra_sq = [d for d in sq.dims if d not in ("regions", "depth")]
        extra_count = [d for d in count.dims if d not in ("regions", "depth")]
        if extra_sq:
            sq = sq.sum(dim=extra_sq, skipna=True)
        if extra_count:
            count = count.sum(dim=extra_count, skipna=True)
        sq = sq.transpose("regions", "depth").values
        count = count.transpose("regions", "depth").values
        with np.errstate(divide="ignore", invalid="ignore"):
            rmsd = np.where(count >= min_obs, np.sqrt(np.maximum(sq / count, 0)), np.nan)
        return [label(v) for v in ds["regions"].values], [label(v) for v in ds["depth"].values], rmsd


def plot(region, variable, models_data, date_range, lead_day, output_dir, dpi, max_depth):
    depths = list(dict.fromkeys(d for _, depth_labels, _ in models_data.values()
                                for d in depth_labels))
    # Depth labels are typically intervals such as "5-100m". Keep layers
    # whose lower and upper bounds are both at or below max_depth.
    def within_depth(label_text):
        numbers = re.findall(r"\d+(?:\.\d+)?", label_text)
        if not numbers:
            raise ValueError(f"Cannot interpret depth label {label_text!r}; specify numeric depth intervals")
        return max(map(float, numbers)) <= max_depth

    depths = [d for d in depths if within_depth(d)]
    if len(depths) < 3:
        print(f"Skipping {variable} / {region}: radar needs at least 3 depth layers")
        return False
    raw = np.full((len(MODELS), len(depths)), np.nan)
    for i, model in enumerate(MODELS):
        regions, model_depths, rmsd = models_data[model]
        if region not in regions:
            continue
        ir = regions.index(region)
        for j, depth in enumerate(depths):
            if depth in model_depths:
                raw[i, j] = rmsd[ir, model_depths.index(depth)]

    relative = np.full_like(raw, np.nan)
    for j in range(len(depths)):
        column = raw[:, j]
        valid = np.isfinite(column) & (column >= 0)
        if not np.any(valid):
            continue
        best = column[valid].min()
        if best == 0:
            relative[valid & (column == 0), j] = 1.0
        else:
            relative[valid, j] = column[valid] / best

    if not np.any(np.isfinite(relative)):
        print(f"Skipping {variable} / {region}: no valid scores")
        return False

    angles = np.linspace(0, 2 * np.pi, len(depths), endpoint=False)
    closed_angles = np.r_[angles, angles[0]]
    fig, ax = plt.subplots(figsize=(10, 9), subplot_kw={"projection": "polar"})
    ax.set_theta_offset(np.pi / 2)
    ax.set_theta_direction(-1)
    ax.set_xticks(angles)
    ax.set_xticklabels(depths, fontsize=11)
    ax.tick_params(axis="x", pad=13)
    ax.set_rlabel_position(20)
    ax.tick_params(axis="y", labelsize=10)
    ax.grid(alpha=0.3)
    ax.set_ylim(0, max(1.2, float(np.nanmax(relative)) * 1.08))

    for i, (name, color) in enumerate(zip(NAMES, COLORS)):
        values = relative[i]
        ax.plot(closed_angles, np.r_[values, values[0]], color=color,
                marker="o", markersize=5, linewidth=2.3, label=name)
        if np.all(np.isfinite(values)):
            ax.fill(closed_angles, np.r_[values, values[0]], color=color, alpha=0.07)

    display_var = "Temperature (thetao)" if variable == "thetao" else "Salinity (so)"
    fig.suptitle(f"PR_PF {display_var} — {region}\n"
                 f"Day {lead_day} | {date_range}\n"
                 "Relative RMSD by depth layer (1.0 = best; lower is better)",
                 fontsize=15, y=0.99)
    fig.legend(loc="lower center", ncol=4, bbox_to_anchor=(0.5, 0.02),
               frameon=True, facecolor="#f0f0f0", fontsize=12)
    fig.subplots_adjust(left=0.15, right=0.85, top=0.82, bottom=0.16)
    outfile = output_dir / (
        f"radar_PR_PF_{variable}_{safe_name(region)}_day{lead_day}_{date_range}.png")
    fig.savefig(outfile, dpi=dpi, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved {outfile}")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path,
                        default=Path("/sortref/calval/CLASS4_scores"))
    parser.add_argument("--output-dir", type=Path,
                        default=Path("imgs/radar_PR_PF_depths"))
    parser.add_argument("--date-range", default="20240101_20241231")
    parser.add_argument("--lead-day", type=int, default=10,
                        help="1-based forecast day, default 10")
    parser.add_argument("--variable", choices=("thetao", "so", "both"), default="both")
    parser.add_argument("--max-depth", type=float, default=800,
                        help="Maximum depth in meters for radar spokes (default: 800)")
    parser.add_argument("--min-obs", type=int, default=1)
    parser.add_argument("--dpi", type=int, default=250)
    args = parser.parse_args()
    if min(args.lead_day, args.min_obs) < 1 or args.max_depth <= 0:
        parser.error("--lead-day and --min-obs must be >= 1; --max-depth must be positive")
    args.output_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    variables = ("thetao", "so") if args.variable == "both" else (args.variable,)
    for variable in variables:
        models_data = {}
        for model in MODELS:
            path = args.input_dir / (
                f"results_regional_scores_class4_profile_PR_PF_{model}_{variable}_"
                f"forecast_{args.date_range}.nc")
            if not path.is_file():
                parser.error(f"Input file not found: {path}")
            models_data[model] = load(path, args.lead_day, args.min_obs)
        regions = list(dict.fromkeys(r for rlabels, _, _ in models_data.values()
                                     for r in rlabels))
        for region in regions:
            count += plot(region, variable, models_data, args.date_range,
                          args.lead_day, args.output_dir, args.dpi, args.max_depth)
    print(f"Generated {count} radar plots in {args.output_dir}")


if __name__ == "__main__":
    main()
