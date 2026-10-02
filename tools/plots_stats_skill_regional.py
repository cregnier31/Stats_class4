import os
import sys
import math

import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator


# ==========================================================
# PLOT FUNCTION
# ==========================================================

def plot_regional_scores(
    input_files,
    model_names,
    title,
    global_region="Global_60S_60N",
    output_file=None,
    ncols=3,
    ytick_step=0.1,
    xtick_step=2,
    units="",
    data=None,
    maxlead=10,
):
    """
    Plot RMSD and Bias for several models.

    Color identifies the model.
    Solid line + circle identifies RMSD.
    Dashed line + square identifies Bias.

    One subplot is created for each region.
    The global region is placed last.
    """

    if len(input_files) != len(model_names):
        raise ValueError(
            "input_files and model_names must have the same length"
        )

    # ======================================================
    # LOAD DATA
    # ======================================================

    scores = {}

    for model, input_file in zip(
        model_names,
        input_files,
    ):
        print(f"Read {input_file}")

        if not os.path.isfile(input_file):
            raise FileNotFoundError(
                f"Input file does not exist for {model}:\n"
                f"{input_file}"
            )

        print(f"Read {input_file}")

        ds = xr.open_dataset(input_file)

        regions = [
            str(region)
            for region in ds["regions"].values
        ]

        ds = ds.assign_coords(
            regions=regions
        )

        scores[model] = ds

    # ======================================================
    # CHECK REGIONS
    # ======================================================

    regions = list(
        scores[model_names[0]]["regions"].values
    )
    if data == "aice":
        regions = ['Full Domain', 'Arctic Ocean', 'Baltic Sea', 'Antarctic Circumpolar', 'North Pacific Ocean', 'North Atlantic Ocean']

    for model in model_names[1:]:

        model_regions = list(
            scores[model]["regions"].values
        )

        if model_regions != regions:
            raise ValueError(
                f"Region list/order differs for {model}"
            )

    # ======================================================
    # PUT GLOBAL REGION LAST
    # ======================================================

    if global_region in regions:

        regions.remove(global_region)
        regions.append(global_region)

    # ======================================================
    # FIGURE
    # ======================================================

    nregions = len(regions)

    nrows = math.ceil(
        nregions / ncols
    )

    fig, axes = plt.subplots(
        nrows,
        ncols,
        figsize=(
            5 * ncols,
            3.8 * nrows,
        ),
        squeeze=False,
    )

    axes = axes.flatten()

    # ==========================================================
    # FIGURE TITLE
    # ==========================================================

    if title is not None:
            fig.suptitle(
            title,
            fontsize=22,
            fontweight="bold",
            y=0.95,
        )
    # ======================================================
    # MODEL COLORS
    # ======================================================

    #colors = plt.cm.tab10(
    #    np.linspace(
    #        0,
    #        1,
    #        len(model_names),
    #    )
    #)
    colors = ["black", "blue", "green", "red"]

    # ======================================================
    # PLOT REGIONS
    # ======================================================

    for iregion, region in enumerate(regions):

        ax = axes[iregion]
        # Second axis for number of observations
        ax_nobs = ax.twinx()
        # --------------------------------------------------
        # Plot each model
        # --------------------------------------------------
        ind_mod = 0
        for color, model in zip(
            colors,
            model_names,
        ):
            print(f'{model=}')
            ds = scores[model]

            leadtime = np.asarray(
                ds["leadtime"].values,
                dtype=float,
            )
            x = np.arange(
                1,
                len(leadtime) + 1,
            )
            if ind_mod == 0:
                x_save = x.copy()

            rmsd = ds["rmsd"].sel(
                regions=region
            ).values
            # -------------------------
            # Overall statistics
            # -------------------------
            cumul_squared_diff = ds["cumul_sq_diff"].sel(
                    regions=region).values
            cumul_bias = ds["cumul_bias"].sel(
                    regions=region).values
            n_obs = ds["n_obs"].sel(
                    regions=region).values
            if np.nanmax(n_obs) < 10:
                print(f"Pb {n_obs} < 10")
                continue
            with np.errstate(divide="ignore", invalid="ignore"):
                rmsd = np.sqrt(cumul_squared_diff / n_obs)
                bias = cumul_bias / n_obs

            # ----------------------------------------------
            # RMSD
            # ----------------------------------------------
            print(x)
            print(rmsd)
            ax.plot(
                x,
                rmsd,
                color=color,
                linestyle="-",
                marker="o",
                linewidth=2,
                markersize=4,
            )

            # ----------------------------------------------
            # Bias
            # ----------------------------------------------

            ax.plot(
                x,
                bias,
                color=color,
                linestyle="--",
                marker="s",
                linewidth=2,
                markersize=4,
            )
            if ind_mod == 0:
                # Number of observations
                ax_nobs.bar(
                    x,
                    n_obs,
                    width=0.7,
                    color="gray",
                    alpha=0.25,
                    zorder=0,
                )
            ind_mod += 1

        # ==================================================
        # AXIS
        # ==================================================

        ax.set_title(
            region,
            fontsize=18,
        )

        ax.set_xlabel(
            "Lead time (days)",
            fontsize=16,
        )
        ax_nobs.set_ylabel(
            "Number of observations",
            color="gray",
        )


        ax.set_ylabel(
            units
        )
        ax.set_xlim(
            x.min() - 0.5,
            maxlead + 0.5,
        )

        ax.set_xticks(x_save[1::xtick_step])

        ax.set_xticklabels(
                x_save[1::xtick_step].astype(int)
        )

        ax.yaxis.set_major_locator(
            MultipleLocator(ytick_step)
        )

        ax.axhline(
            0.0,
            color="black",
            linestyle="-",
            linewidth=1.0,
            zorder=0,
        )

        ax.grid(
            True,
            alpha=0.3,
        )

        # ==================================================
        # STATISTIC LEGEND
        # ==================================================

        stat_handles = [

            plt.Line2D(
                [0],
                [0],
                color="black",
                linestyle="-",
                marker="o",
                linewidth=2,
                markersize=6,
                label="RMSD",
            ),

            plt.Line2D(
                [0],
                [0],
                color="black",
                linestyle="--",
                marker="s",
                linewidth=2,
                markersize=6,
                label="Bias",
            ),
        ]

        #ax.legend(
        #    handles=stat_handles,
        #    title="Statistics",
        #    loc="upper left",
        #    fontsize=10,
        #    title_fontsize=11,
        #    frameon=True,
        #)

    # ======================================================
    # REMOVE EMPTY SUBPLOTS
    # ======================================================

    for ax in axes[nregions:]:
        fig.delaxes(ax)

    # ======================================================
    # MODEL LEGEND
    # ======================================================

    model_handles = []

    for color, model in zip(
        colors,
        model_names,
    ):

        model_handles.append(
            plt.Line2D(
                [0],
                [0],
                color=color,
                linewidth=3,
                label=model,
            )
        )

    fig.legend(
        handles=model_handles,
        title="Models",
        loc="lower center",
        fontsize=14,
        bbox_to_anchor=(0.5, 0.015),
        ncol=len(model_names),
        frameon=True,
        title_fontsize=15,
    )
    fig.legend(
        handles=stat_handles,
        title="Statistics",
        loc="lower left",
        fontsize=14,
        frameon=True,
        title_fontsize=15,
    )

    # ======================================================
    # LAYOUT
    # ======================================================

    fig.tight_layout(
        rect=[0, 0.07, 1, 0.95]
    )

    # ======================================================
    # SAVE
    # ======================================================

    if output_file is not None:

        fig.savefig(
            output_file,
            dpi=300,
            bbox_inches="tight",
        )
        print(f"Save file {output_file}")

    # ======================================================
    # CLOSE DATASETS
    # ======================================================

    for ds in scores.values():
        ds.close()

    return fig, axes

# ==========================================================
# CONFIGURATION
# ==========================================================

input_path = "/sortref/calval/CLASS4_scores/"
output_path = "imgs/"
#results_regional_scores_class4_profile_TS_DB_glo4-ens50_forecast_20240101_20241231.nc
data = "profile_TS_DB"
#data = "aice"
units = "°C"
#units = "%"
dateval = "20240101_20241231"
maxlead = 28
models = [
    "glo4-ens50",
    "GLO12",
    "glonet",
    "glow",
]
#models = [
#    "glo4-ens50",
#]
listmod="glo4-ens50vsGLO12vsGLONETivsGLOW"
#listmod="glo4-ens50"
input_files = [
    os.path.join(
        input_path,
        f"results_regional_scores_class4_{data}_{model}_forecast_{dateval}.nc",
    )
    for model in models
]

output_file = os.path.join(
    output_path,
    f"regional_scores_rmsd_bias_{dateval}_{listmod}_class4_{data}.png",
)

title=(
        f"CLASS4 Regional RMSD and Bias - "
        f"{data} - {dateval}"
)
# ==========================================================
# PLOT
# ==========================================================

plot_regional_scores(
    input_files=input_files,
    model_names=models,
    title = title,
    global_region="Baltic Sea",
    output_file=output_file,
    ncols=3,
    ytick_step=0.1,
    units = units,
    data=data,
    maxlead = maxlead
)
