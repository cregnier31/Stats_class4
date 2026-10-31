#!/usr/bin/env python3
"""Plot regional CLASS4 profile forecast scores, one figure per region.

Each figure has one panel per depth layer, with every model overlaid.
Solid lines: RMSD. Dotted lines: mean bias.
Scores are aggregated from cumulative squared differences / biases / counts.
"""
import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np
import xarray as xr


def safe_name(s):
    return re.sub(r'[^a-zA-Z0-9_-]+', '_', str(s)).strip('_')


def as_labels(values):
    return [str(v.decode() if isinstance(v, bytes) else v) for v in values]


def load_scores(path):
    with xr.open_dataset(path) as ds:
        required = {'regions', 'depth', 'leadtime', 'cumul_sq_diff', 'cumul_bias', 'n_obs'}
        missing = required - set(ds.variables)
        if missing:
            raise ValueError(f'{path}: missing variables {sorted(missing)}')
        for name in ('cumul_sq_diff', 'cumul_bias', 'n_obs'):
            if set(ds[name].dims) != {'regions', 'depth', 'leadtime'}:
                raise ValueError(f'{path}: unexpected dimensions for {name}: {ds[name].dims}')
        sq = ds['cumul_sq_diff'].transpose('regions', 'depth', 'leadtime').values
        total_bias = ds['cumul_bias'].transpose('regions', 'depth', 'leadtime').values
        count = ds['n_obs'].transpose('regions', 'depth', 'leadtime').values
        with np.errstate(divide='ignore', invalid='ignore'):
            rmsd = np.where(count > 0, np.sqrt(np.maximum(sq / count, 0)), np.nan)
            bias = np.where(count > 0, total_bias / count, np.nan)
        # Display forecast steps as 1, 2, ..., N (not zero-based indices).
        # Keep the score arrays in their original order.
        x = np.arange(1, count.shape[2] + 1, dtype=int)
        return {
            'regions': as_labels(ds['regions'].values),
            'depths': as_labels(ds['depth'].values),
            'x': x,
            'rmsd': rmsd,
            'bias': bias,
            'nobs': count,
        }


def plot_all(models, output, variable, date_range, min_obs=1, dpi=180):
    data = {name: load_scores(path) for name, path in models.items()}
    regions = list(dict.fromkeys(r for d in data.values() for r in d['regions']))
    depths = list(dict.fromkeys(z for d in data.values() for z in d['depths']))[:4]
    output.mkdir(parents=True, exist_ok=True)
    colors = plt.get_cmap('tab10').colors
    units = '°C' if variable == 'thetao' else 'PSU' if variable == 'so' else ''
    count_figures = 0

    all_leadtimes = sorted(set(int(v) for scores in data.values() for v in scores['x']))

    for region in regions:
        ncols = 2
        nrows = 2
        fig, axes = plt.subplots(nrows, ncols, figsize=(15, 10), squeeze=False, sharex=True)
        fig.subplots_adjust(left=0.09, right=0.98, top=0.88, bottom=0.22, hspace=0.42, wspace=0.24)
        for j, depth in enumerate(depths):
            ax = axes.flat[j]
            for i, (model, scores) in enumerate(data.items()):
                if region not in scores['regions'] or depth not in scores['depths']:
                    continue
                ir = scores['regions'].index(region)
                iz = scores['depths'].index(depth)
                x = scores['x']
                nobs = scores['nobs'][ir, iz, :]
                valid = nobs >= min_obs
                rmsd = np.where(valid, scores['rmsd'][ir, iz, :], np.nan)
                bias = np.where(valid, scores['bias'][ir, iz, :], np.nan)
                color = colors[i % len(colors)]
                ax.plot(x, rmsd, color=color, linestyle='-', marker='o', markersize=3.5, linewidth=1.8)
                ax.plot(x, bias, color=color, linestyle=':', marker='s', markersize=3.5, linewidth=1.8)
            ax.axhline(0, color='gray', linewidth=0.8)
            ax.set_title(str(depth), fontsize=12, fontweight='bold')
            ax.set_xlabel('Forecast lead time (days)', fontsize=12)
            ax.set_ylabel(f'RMSD / mean bias ({units})' if units else 'RMSD / mean bias', fontsize=12)
            ax.tick_params(axis='both', which='major', labelsize=12)
            ax.tick_params(axis='both', which='minor', labelsize=12)
            ax.set_xticks(all_leadtimes)
            ax.set_xlim(0.5, max(all_leadtimes) + 0.5)
            ax.tick_params(axis='x', labelbottom=True, pad=7)
            for tick in ax.get_xticklabels():
                tick.set_rotation(45)
                tick.set_horizontalalignment('right')
            ax.grid(True, alpha=0.25, linestyle=':')
        for ax in axes.flat[len(depths):]:
            ax.set_visible(False)

        model_handles = [Line2D([0], [0], color=colors[i % len(colors)], lw=2.2, label=model)
                         for i, model in enumerate(models)]
        metric_handles = [
            Line2D([0], [0], color='black', lw=2, ls='-', marker='o', label='RMSD'),
            Line2D([0], [0], color='black', lw=2, ls=':', marker='s', label='Mean bias'),
        ]
        # Separate legends: models below panels, line styles in lower-left.
        fig.legend(handles=model_handles, loc='lower center', ncol=len(model_handles),
                   bbox_to_anchor=(0.62, 0.065), fontsize=12, frameon=True,
                   facecolor='#f0f0f0', edgecolor='#bcbcbc', framealpha=1, borderpad=0.8)
        fig.legend(handles=metric_handles, loc='lower left', ncol=1,
                   bbox_to_anchor=(0.08, 0.035), fontsize=12, frameon=True,
                   facecolor='#f0f0f0', edgecolor='#bcbcbc', framealpha=1, borderpad=0.8)
        fig.suptitle(f'CLASS4 regional profile scores — {variable} — {region}\\n{date_range}',
                     fontsize=16, fontweight='bold')
        outfile = output / f'class4_{variable}_{safe_name(region)}_{safe_name(date_range)}_4plots.png'
        fig.savefig(outfile, dpi=dpi, bbox_inches='tight')
        plt.close(fig)
        print(f'Saved {outfile}')
        count_figures += 1
    print(f'Generated {count_figures} figures in {output}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model', action='append', required=True, metavar='NAME=FILE',
                        help='Repeat for each system; e.g. --model glow=/path/results.nc')
    parser.add_argument('--variable', choices=['thetao', 'so'], required=True)
    parser.add_argument('--date-range', default='20240101_20241231')
    parser.add_argument('--output', type=Path, default=Path('imgs/regional_profiles'))
    parser.add_argument('--min-obs', type=int, default=1, help='Minimum observations per leadtime (default: 1)')
    parser.add_argument('--dpi', type=int, default=180)
    args = parser.parse_args()
    models = {}
    for item in args.model:
        if '=' not in item:
            parser.error(f'Expected NAME=FILE, got {item!r}')
        name, path = item.split('=', 1)
        if not name or not path or name in models:
            parser.error(f'Invalid or duplicate model: {item!r}')
        if not Path(path).is_file():
            parser.error(f'Input file not found: {path}')
        models[name] = Path(path)
    plot_all(models, args.output, args.variable, args.date_range, args.min_obs, args.dpi)


if __name__ == '__main__':
    main()
