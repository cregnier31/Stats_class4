#!/usr/bin/env python3
"""Plot regional DRIFTER_filtr uo/vo CLASS4 RMSD and bias, comparing four models.

Generates one figure per region and velocity component, using the style of
plots_stats_skill_intercomp3.py. Scores are computed from cumulative totals.
"""
import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import MultipleLocator
import numpy as np
import xarray as xr

MODELS = ["glo4-ens50", "glonet", "glow", "GLO12"]
DISPLAY_NAMES = {"glo4-ens50": "GLOENS", "glonet": "GLONET",
                 "glow": "GLONET3", "GLO12": "GLO12"}
COLORS = ["tab:blue", "tab:green", "tab:red", "tab:orange"]


def labels(values):
    return [v.decode() if isinstance(v, bytes) else str(v) for v in values]


def safe_name(value):
    return re.sub(r"[^a-zA-Z0-9_-]+", "_", str(value)).strip("_")


def load_scores(path):
    with xr.open_dataset(path) as ds:
        sq_name = next((n for n in ("cumul_sq_diff", "cumul_squared_diff") if n in ds), None)
        if sq_name is None or "cumul_bias" not in ds or "n_obs" not in ds:
            raise ValueError(f"{path}: expected cumulative squared difference, cumul_bias and n_obs")
        if "regions" not in ds.dims or "leadtime" not in ds.dims:
            raise ValueError(f"{path}: expected 'regions' and 'leadtime' dimensions")
        arrays = []
        for name in (sq_name, "cumul_bias", "n_obs"):
            a = ds[name]
            if "regions" not in a.dims or "leadtime" not in a.dims:
                raise ValueError(f"{path}: {name} dimensions are {a.dims}")
            # Aggregate any extra dimensions using the cumulative totals, not
            # averages of already-normalized RMSDs or biases.
            extra = [dim for dim in a.dims if dim not in ("regions", "leadtime")]
            if extra:
                a = a.sum(dim=extra, skipna=True)
            arrays.append(a.transpose("regions", "leadtime").values)
        sq, total_bias, count = arrays
        with np.errstate(divide="ignore", invalid="ignore"):
            rmsd = np.where(count > 0, np.sqrt(np.maximum(sq / count, 0)), np.nan)
            bias = np.where(count > 0, total_bias / count, np.nan)
        return {"regions": labels(ds["regions"].values),
                "x": np.arange(1, ds.sizes["leadtime"] + 1),
                "rmsd": rmsd, "bias": bias}


def plot_region(data, region, variable, date_range, output, dpi):
    fig, ax = plt.subplots(figsize=(12.5, 8))
    max_lead = 0
    for model, color in zip(MODELS, COLORS):
        scores = data[model]
        if region not in scores["regions"]:
            continue
        index = scores["regions"].index(region)
        x = scores["x"]
        max_lead = max(max_lead, int(x[-1]))
        ax.plot(x, scores["rmsd"][index], color=color, marker="o",
                linewidth=2, markersize=4, zorder=6)
        ax.plot(x, scores["bias"][index], color=color, marker="s",
                linestyle=":", linewidth=2, markersize=3, zorder=6)

    model_handles = [Line2D([0], [0], color=color, lw=3,
                            label=DISPLAY_NAMES[model])
                     for model, color in zip(MODELS, COLORS)]
    stat_handles = [
        Line2D([0], [0], color="black", ls="-", marker="o", lw=2, label="RMSD"),
        Line2D([0], [0], color="black", ls=":", marker="s", lw=2, label="Bias"),
    ]
    fig.legend(handles=model_handles, title="Models", loc="lower center",
               bbox_to_anchor=(0.70, 0.025), ncol=len(MODELS), fontsize=10,
               title_fontsize=13, frameon=True,
               facecolor="#f0f0f0", edgecolor="#bcbcbc")
    fig.legend(handles=stat_handles, title="Statistics", loc="lower left",
               bbox_to_anchor=(0.12, 0.025), ncol=2, fontsize=12,
               title_fontsize=13, frameon=True,
               facecolor="#f0f0f0", edgecolor="#bcbcbc")

    ax.set_xlabel("Forecast lead time (days)", fontsize=17, labelpad=10)
    ax.set_ylabel("RMSD / Bias (m/s)", fontsize=17, labelpad=10)
    ax.tick_params(axis="both", labelsize=15, width=1.3, length=6)
    ax.set_xlim(0.5, max_lead + 0.5)
    ax.xaxis.set_major_locator(MultipleLocator(1))
    ax.grid(True, alpha=0.3, linestyle="--")
    ax.axhline(0, color="black", alpha=0.6, linestyle="--", linewidth=1.5)
    fig.suptitle(f"DRIFTER_filtr {variable} - {region} - Forecast scores intercomparison",
                 fontsize=16, y=0.985)
    fig.text(0.5, 0.948, f"Date: {date_range}",
             ha="center", va="center", fontsize=14)
    fig.subplots_adjust(bottom=0.19, top=0.91, left=0.12, right=0.97)
    outfile = output / (f"results_regional_scores_class4_DRIFTER_filtr_{variable}_"
                        f"{safe_name(region)}_forecast_{date_range}_rmsd_bias.png")
    fig.savefig(outfile, dpi=dpi, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved {outfile}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", type=Path,
                        default=Path("/sortref/calval/CLASS4_scores"))
    parser.add_argument("--output-dir", type=Path,
                        default=Path("imgs/regional_DRIFTER_filtr"))
    parser.add_argument("--date-range", default="20240101_20241231")
    parser.add_argument("--variable", choices=["uo", "vo", "both"], default="both")
    parser.add_argument("--dpi", type=int, default=300)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    for variable in (["uo", "vo"] if args.variable == "both" else [args.variable]):
        data = {}
        for model in MODELS:
            path = args.input_dir / (
                f"results_regional_scores_class4_DRIFTER_filtr_{model}_"
                f"{variable}_forecast_{args.date_range}.nc")
            if not path.is_file():
                parser.error(f"Missing input file: {path}")
            data[model] = load_scores(path)
        regions = list(dict.fromkeys(region for scores in data.values()
                                     for region in scores["regions"]))
        for region in regions:
            plot_region(data, region, variable, args.date_range,
                        args.output_dir, args.dpi)
    print(f"Done: figures saved in {args.output_dir}")


if __name__ == "__main__":
    main()
