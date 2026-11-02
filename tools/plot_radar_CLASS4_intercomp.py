#!/usr/bin/env python3
"""CLASS4 radar intercomparison: five metrics, four models, one plot per region.

Spokes show RMSD divided by the lowest valid model RMSD for that metric.
Thus 1.0 is best, and larger values indicate worse performance.
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
METRICS = (
    ("DRIFTER_filtr", "uo", "Drifter uo"),
    ("DRIFTER_filtr", "vo", "Drifter vo"),
    ("profile_PR_PF", "so", "PR_PF salinity"),
    ("profile_PR_PF", "thetao", "PR_PF temperature"),
    ("profile_TS_DB", "thetao", "TS_DB temperature"),
)


def string(value):
    return value.decode("utf-8") if isinstance(value, bytes) else str(value)


def safe_name(value):
    return re.sub(r"[^a-zA-Z0-9_-]+", "_", str(value)).strip("_")


def load_metric(path, lead_day, depth_layer, min_obs):
    with xr.open_dataset(path) as ds:
        sq_name = next((v for v in ("cumul_sq_diff", "cumul_squared_diff") if v in ds), None)
        if sq_name is None or "n_obs" not in ds:
            raise ValueError(f"{path}: expected cumul_sq_diff/cumul_squared_diff and n_obs")
        if "regions" not in ds.dims or "leadtime" not in ds.dims:
            raise ValueError(f"{path}: expected regions and leadtime dimensions")
        if lead_day > ds.sizes["leadtime"]:
            print(f"WARNING: {path.name}: day {lead_day} not available")
            return {string(v): np.nan for v in ds["regions"].values}
        sq = ds[sq_name].isel(leadtime=lead_day - 1)
        nobs = ds["n_obs"].isel(leadtime=lead_day - 1)
        if "depth" in sq.dims:
            if depth_layer > sq.sizes["depth"]:
                raise ValueError(f"{path}: depth layer {depth_layer} unavailable")
            sq = sq.isel(depth=depth_layer - 1)
            nobs = nobs.isel(depth=depth_layer - 1)
        elif "PR_PF" in path.name:
            raise ValueError(f"{path}: expected a depth dimension for PR_PF")
        if "regions" not in sq.dims or "regions" not in nobs.dims:
            raise ValueError(f"{path}: regions dimension missing in score arrays")
        extra = [d for d in sq.dims if d != "regions"]
        sq = sq.sum(dim=extra, skipna=True)
        nobs = nobs.sum(dim=[d for d in nobs.dims if d != "regions"], skipna=True)
        with np.errstate(divide="ignore", invalid="ignore"):
            rmsd = np.where(nobs.values >= min_obs,
                            np.sqrt(np.maximum(sq.values / nobs.values, 0)), np.nan)
        return dict(zip((string(v) for v in ds["regions"].values), rmsd))


def draw_radar(region, raw, metric_labels, output, lead_day, depth_layer, date_range, dpi):
    # raw has shape (4 models, 5 metrics). Ratios avoid mixing units.
    ratios = np.full_like(raw, np.nan, dtype=float)
    for j in range(raw.shape[1]):
        col = raw[:, j]
        good = np.isfinite(col) & (col >= 0)
        if not np.any(good):
            continue
        best = np.min(col[good])
        if best == 0:
            # An exact zero is a special case: other nonzero errors have
            # unbounded relative RMSD; leave them missing rather than inventing.
            ratios[good & (col == 0), j] = 1.0
        else:
            ratios[good, j] = col[good] / best

    angles = np.linspace(0, 2 * np.pi, len(metric_labels), endpoint=False)
    fig, ax = plt.subplots(figsize=(10, 9), subplot_kw={"projection": "polar"})
    ax.set_theta_offset(np.pi / 2)
    ax.set_theta_direction(-1)
    ax.set_xticks(angles)
    ax.set_xticklabels(metric_labels, fontsize=12)
    finite = ratios[np.isfinite(ratios)]
    upper = max(1.2, float(np.nanmax(finite)) * 1.08) if finite.size else 1.2
    ax.set_ylim(0, upper)
    ax.set_rlabel_position(20)
    ax.tick_params(axis="y", labelsize=9)
    ax.grid(alpha=0.35)

    for i, (name, color) in enumerate(zip(NAMES, COLORS)):
        series = ratios[i]
        # NaN values intentionally break the polygon, rather than connecting
        # across missing metrics or implying an observation exists.
        closed_angles = np.r_[angles, angles[0]]
        closed_values = np.r_[series, series[0]]
        ax.plot(closed_angles, closed_values, marker="o", lw=2.2,
                color=color, label=name)
        if np.all(np.isfinite(series)):
            ax.fill(closed_angles, closed_values, color=color, alpha=0.08)

    ax.set_title(f"CLASS4 relative RMSD — {region}\n"
                 f"Day {lead_day} | PR_PF layer {depth_layer} | {date_range}\n"
                 "1.0 = best for each variable (lower is better)",
                 fontsize=14, pad=28)
    fig.legend(loc="lower center", ncol=4, bbox_to_anchor=(0.5, 0.025),
               frameon=True, facecolor="#f0f0f0", fontsize=12)
    fig.subplots_adjust(left=0.16, right=0.84, top=0.80, bottom=0.16)
    outfile = output / (
        f"radar_CLASS4_{safe_name(region)}_day{lead_day}_"
        f"layer{depth_layer}_{date_range}.png")
    fig.savefig(outfile, dpi=dpi, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved {outfile}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path, default=Path("/sortref/calval/CLASS4_scores"))
    parser.add_argument("--output-dir", type=Path, default=Path("imgs/radar_CLASS4"))
    parser.add_argument("--date-range", default="20240101_20241231")
    parser.add_argument("--lead-day", type=int, default=10,
                        help="1-based forecast day (default: 10)")
    parser.add_argument("--depth-layer", type=int, default=2,
                        help="1-based PR_PF depth layer (default: 2, typically 5-100 m)")
    parser.add_argument("--min-obs", type=int, default=1)
    parser.add_argument("--dpi", type=int, default=250)
    args = parser.parse_args()
    if min(args.lead_day, args.depth_layer, args.min_obs) < 1:
        parser.error("--lead-day, --depth-layer and --min-obs must be positive")
    args.output_dir.mkdir(parents=True, exist_ok=True)

    metric_data = {}
    regions = []
    for metric_index, (product, variable, description) in enumerate(METRICS):
        for model_index, model in enumerate(MODELS):
            path = args.input_dir / (
                f"results_regional_scores_class4_{product}_{model}_{variable}_"
                f"forecast_{args.date_range}.nc")
            if not path.is_file():
                parser.error(f"Input file not found: {path}")
            scores = load_metric(path, args.lead_day, args.depth_layer, args.min_obs)
            metric_data[model_index, metric_index] = scores
            regions.extend(scores.keys())
    regions = list(dict.fromkeys(regions))
    for region in regions:
        raw = np.array([[metric_data[i, j].get(region, np.nan)
                         for j in range(len(METRICS))]
                        for i in range(len(MODELS))], dtype=float)
        if not np.any(np.isfinite(raw)):
            continue
        draw_radar(region, raw, [metric[2] for metric in METRICS],
                   args.output_dir, args.lead_day, args.depth_layer,
                   args.date_range, args.dpi)
    print(f"Finished: {len(regions)} regions examined; figures in {args.output_dir}")


if __name__ == "__main__":
    main()
