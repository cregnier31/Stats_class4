#!/usr/bin/env python
# coding: utf-8

import xarray as xr
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

def scores(ax, nc_files, model_names, varname, var_long_name, time_indices=None, show_row_labels=True, show_column_labels=True, var_unit=None):
    import xarray as xr
    import pandas as pd
    import numpy as np

    data = []
    for file in nc_files:
        ds = xr.open_dataset(file)
        var = ds[varname]
        if time_indices is not None:
            var = var.isel(time=time_indices)
        mean_var = var.mean(dim='member').values
        data.append(mean_var)
        ds.close()

    if time_indices is not None:
        column_labels = [f"{i+1}" for i in time_indices]
    else:
        column_labels = [f"lead {i+1}" for i in range(mean_var.shape[0])]

    col_labels = column_labels if show_column_labels else [""] * len(column_labels)
    df = pd.DataFrame(data, index=model_names, columns=column_labels)
    arr = df.values
    n_models, n_leads = arr.shape
    ax.axis('off')

    baseline = arr[0]
    diffs = arr - baseline
    max_diff = np.abs(diffs[1:]).max() if len(model_names) > 1 else 1

    # Cell colors
    cell_colors = []
    for i in range(n_models):
        row_colors = []
        for j in range(n_leads):
            if i == 0:
                row_colors.append((0.9, 0.9, 0.9, 1.0))  # baseline 
            else:
                delta = diffs[i, j]
                norm = abs(delta / max_diff) if max_diff != 0 else 0
                row_colors.append((1.0, 0.0, 0.0, norm) if delta > 0 else (0.0, 0.0, 1.0, norm))
        cell_colors.append(row_colors)

    cell_colors.append([(1, 1, 1, 0.0)] * n_leads)
    cell_text = [[f"{val:.3f}" for val in row] for row in arr]
    cell_text.append(col_labels)

    row_labels = model_names + [""] if show_row_labels else [""] * (len(model_names) + 1)

    table = ax.table(
        cellText=cell_text,
        rowLabels=row_labels,
        colLabels=[""] * n_leads,
        cellColours=cell_colors,
        loc='center',
        cellLoc='center'
    )

    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1.2, 1.7)

    for (row, col), cell in table.get_celld().items():
        cell.set_linewidth(1)
        cell.set_edgecolor("white")

        if col == -1:
            txt = str(cell.get_text().get_text())
            if txt == "GLO12":
                cell.set_facecolor((0.0, 1.0, 1.0))  # physics
            elif txt in model_names:
                cell.set_facecolor((0.7, 1.0, 0.7))  # AI models

    if var_unit:
        ax.text(0.4, 0.84, var_long_name, transform=ax.transAxes,
                ha='center', va='bottom', fontsize=10, weight='bold')

        ax.text(0.4, 0.82, f"{var_unit}", transform=ax.transAxes,
                ha='center', va='top', fontsize=9, weight='normal')
    else:
        ax.text(0.4, 0.80, var_long_name, transform=ax.transAxes,
                ha='center', va='bottom', fontsize=10, weight='bold')

    if show_column_labels:
        ax.text(0.5, 0.1, "Lead time [days]", transform=ax.transAxes,
                ha='center', va='top', fontsize=10)

    return df

def scores_grid(nc_files, model_names, varnames, var_long_names, time_indices, depth_indices, depth_labels, var_units=None, top_var=None):
    n_depths = len(depth_indices)
    n_vars = len(varnames)

    has_top = top_var is not None
    n_rows = n_depths + (1 if has_top else 0)

    fig, axs = plt.subplots(n_rows, n_vars, figsize=(4 * n_vars, 3 * n_rows))

    if n_rows == 1:
        axs = [axs]
    if n_vars == 1:
        axs = [[ax] for ax in axs]
    if has_top:
        for j, varname in enumerate(varnames):
            ax = axs[0][j]
            scores(
                ax=ax,
                nc_files=nc_files,
                model_names=model_names,
                varname=top_var["name"],
                var_long_name=top_var["long_name"],
                var_unit=top_var.get("unit"),
                time_indices=time_indices,
                show_column_labels=(j == n_vars - 1)
            )
    for i, depth_idx in enumerate(depth_indices):
        for j, varname in enumerate(varnames):
            ax = axs[i + (1 if has_top else 0)][j]
            scores(
                ax=ax,
                nc_files=nc_files,
                model_names=model_names,
                varname=varname + f"_depth{depth_idx}",
                var_long_name=f"{var_long_names[j]} [{depth_labels[i]}m]",
                var_unit=var_units[j] if var_units else None,
                time_indices=time_indices,
                show_row_labels=(j == 0),
                show_column_labels=(i == len(depth_indices) - 1)
            )
    plt.subplots_adjust(hspace=0.0, wspace=0.2)
    plt.tight_layout()
    plt.show()



scores_grid(
    nc_files=[
        f"results/{model}/glo12.nc",
        f"results/{model}/glonet.nc",
        f"results/{model}/wenhai.nc",
        f"results/{model}/xihe.nc"
    ],
    model_names=["GLO12", "GLONET", "WENHAI", "XIHE"],
    varnames=["uo", "vo", "so", "thetao"],
    var_long_names=["Zonal current", "Meridional current", "Salinity", "Temperature"],
    var_units=["RMSE (m/s)", "RMSE (m/s)", " RMSE (psu)", " RMSE(°C)"],  
    time_indices=[0, 2, 4, 6, 9],
    depth_indices=[0, 50, 92, 222, 318, 540],
    depth_labels=["0", "50", "100", "200", "300", "500"],
    top_var={
        "name": "zos",
        "long_name": "Sea Surface Height",
        "unit": " RMSE (m)"
    }
)

