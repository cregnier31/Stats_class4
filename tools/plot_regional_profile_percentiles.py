#!/usr/bin/env python3
"""Regional CLASS4 depth-profile plots from stats_signed_error NetCDF files.

Example:
 python plot_regional_profile_percentiles.py --date1 20241001 --date2 20241231 \
   --systems GLO12 GLONET GLOENS --variables so thetao --leadtime 0

Percentile bands are of signed (model - observation) error.
"""
import argparse
from pathlib import Path
import re
import numpy as np
import xarray as xr
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

METRICS = {
    'bias': 'mean bias (model - obs)',
    'q99': 'percentile Q99', 'q1': 'percentile Q1',
    'q95': 'percentile Q95', 'q5': 'percentile Q5',
    'q75': 'percentile Q75', 'q25': 'percentile Q25',
}
UNITS = {'so': 'PSU', 'thetao': '°C'}
LABELS = {'so': 'Salinity', 'thetao': 'Temperature'}


def depth_midpoints(names):
    """Return midpoints of '0-5m' style bins, excluding the Total bin."""
    depths, indices = [], []
    for i, name in enumerate(names):
        value = str(name).strip()
        match = re.fullmatch(r'\s*([\d.]+)\s*-\s*([\d.]+)\s*m\s*', value, re.I)
        if not match:
            continue
        lo, hi = map(float, match.groups())
        depths.append((lo + hi) / 2)
        indices.append(i)
    return np.asarray(depths), np.asarray(indices, dtype=int)


def load_profile(path, region, leadtime):
    with xr.open_dataset(path) as ds:
        if 'stats_signed_error' not in ds:
            raise ValueError(f'{path}: missing stats_signed_error (rerun with percentiles enabled)')
        if region not in ds.regions.values:
            raise ValueError(f'{path}: unknown region {region!r}')
        leads = [str(x) for x in ds.leadtime.values]
        if str(leadtime) not in leads:
            raise ValueError(f'{path}: leadtime {leadtime!r} not in {leads}')
        profile = ds['stats_signed_error'].sel(regions=region).isel(leadtime=leads.index(str(leadtime)))
        depth, indices = depth_midpoints(ds.depth.values[:-1])
        if not len(indices):
            raise ValueError(f'{path}: no depth bins of the form 0-5m')
        names = [str(x) for x in ds.metric_names.values]
        missing = [name for name in METRICS.values() if name not in names]
        if missing:
            raise ValueError(f'{path}: missing metrics {missing}')
        matrix = np.asarray(profile.values)[indices, :]
        series = {key: matrix[:, names.index(label)] for key, label in METRICS.items()}
        counts = np.asarray(ds['n_obs'].sel(regions=region).isel(leadtime=leads.index(str(leadtime))).values)[indices]
    order = np.argsort(depth)
    return depth[order], {key: val[order] for key, val in series.items()}, counts[order]


def plot_region(args, region, var):
    systems = args.systems
    fig, axes = plt.subplots(1, len(systems), figsize=(5 * len(systems), 8), sharey=True, squeeze=False)
    axes = axes[0]
    all_handles = None
    plotted = 0
    for ax, system in zip(axes, systems):
        filename = (f'results_regional_scores_class4_{args.data}_{system}_{var}'
                    f'_forecast_{args.date1}_{args.date2}.nc')
        path = args.input_dir / filename
        if not path.is_file():
            ax.text(.5, .5, 'File not found', ha='center', va='center', transform=ax.transAxes)
            ax.set_title(system)
            print(f'WARNING: missing {path}')
            continue
        try:
            depth, data, counts = load_profile(path, region, args.leadtime)
        except (ValueError, KeyError) as exc:
            ax.text(.5, .5, 'No usable statistics', ha='center', va='center', transform=ax.transAxes)
            ax.set_title(system)
            print(f'WARNING: {exc}')
            continue
        valid = np.isfinite(data['bias']) & (counts > 0) & (depth <= args.max_depth)
        if not np.any(valid):
            ax.text(.5, .5, 'No valid observations', ha='center', va='center', transform=ax.transAxes)
            ax.set_title(system)
            continue
        d = depth[valid]
        v = {key: x[valid] for key, x in data.items()}
        ax.axvline(0, color='black', linewidth=1)
        h1, = ax.plot(v['bias'], d, color='darkturquoise', linewidth=2.3, label='Mean bias (model − obs)')
        h2, = ax.plot(v['q1'], d, color='goldenrod', linewidth=1.3, label='Q1–Q99 signed error')
        ax.plot(v['q99'], d, color='goldenrod', linewidth=1.3)
        h3 = ax.fill_betweenx(d, v['q5'], v['q95'], color='royalblue', alpha=.25, label='Q5–Q95 signed error')
        h4 = ax.fill_betweenx(d, v['q25'], v['q75'], color='royalblue', alpha=.5, label='Q25–Q75 signed error')
        ax.set_title(system, fontweight='bold')
        ax.set_xlabel(f"Model − observation error ({UNITS.get(var, var)})")
        ax.grid(linestyle='--', alpha=.35)
        ax.set_ylim(args.max_depth, 0)
        if args.xlim is not None:
            ax.set_xlim(-args.xlim, args.xlim)
        else:
            finite = np.concatenate([x[np.isfinite(x)] for x in v.values()])
            extent = np.max(np.abs(finite)) * 1.08 if finite.size else 1.0
            ax.set_xlim(-extent, extent) if extent > 0 else ax.set_xlim(-1, 1)
        all_handles = [h1, h2, h3, h4]
        plotted += 1
    axes[0].set_ylabel('Depth (m)')
    fig.suptitle(f"{LABELS.get(var, var)} — {region} — leadtime {args.leadtime}\n"
                 f"{args.date1}–{args.date2} | signed-error percentiles", fontweight='bold')
    if all_handles:
        fig.legend(handles=all_handles, loc='lower center', ncol=2, bbox_to_anchor=(.5, .015))
    fig.tight_layout(rect=(0, .09, 1, .91))
    safe_region = re.sub(r'[^A-Za-z0-9_-]+', '_', region).strip('_')
    out = args.output_dir / f'{safe_region}_profile_percentiles_LT{args.leadtime}_{var}_{args.date1}_{args.date2}.png'
    if plotted:
        fig.savefig(out, dpi=args.dpi, bbox_inches='tight')
        print(f'Saved {out}')
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input-dir', type=Path, default=Path('/sortref/calval/CLASS4_scores'))
    parser.add_argument('--output-dir', type=Path, default=Path('../imgs/Error_profiles'))
    parser.add_argument('--date1', default='20241001')
    parser.add_argument('--date2', default='20241231')
    parser.add_argument('--systems', nargs='+', default=['GLO12', 'GLONET', 'GLOENS'])
    parser.add_argument('--variables', nargs='+', default=['so', 'thetao'])
    parser.add_argument('--data', default='profile_PR_PF')
    parser.add_argument('--regions', nargs='+', help='Region names (default: all regions in first available file)')
    parser.add_argument('--leadtime', default='0', help='Exact NetCDF leadtime coordinate, e.g. 0')
    parser.add_argument('--max-depth', type=float, default=2000)
    parser.add_argument('--xlim', type=float, help='Symmetric x axis limit; default auto')
    parser.add_argument('--dpi', type=int, default=200)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    if args.regions:
        regions = args.regions
    else:
        regions = None
        for system in args.systems:
            for var in args.variables:
                path = args.input_dir / (f'results_regional_scores_class4_{args.data}_{system}_{var}'
                                         f'_forecast_{args.date1}_{args.date2}.nc')
                if path.exists():
                    with xr.open_dataset(path) as ds:
                        regions = [str(x) for x in ds.regions.values]
                    break
            if regions is not None:
                break
        if regions is None:
            parser.error('No input files found; check --input-dir, systems, variables, and dates')
    for region in regions:
        for var in args.variables:
            plot_region(args, region, var)


if __name__ == '__main__':
    main()