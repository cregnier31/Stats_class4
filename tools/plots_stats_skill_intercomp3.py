import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator

DISPLAY_NAMES = {'glow': 'GLONET3', 'GLOW': 'GLONET3'}

def plot_forecast_scores(scores, observation, dateval, label= '°C'):
    """
    Plot RMSD and Bias forecast scores for multiple models.

    Each model can have a different number of leadtimes.

    Parameters
    ----------
    scores : dict
        Dictionary containing the scores for each model.

        Example:
        {
            "gloens": {
                "x": ...,
                "rmsd_p05": ...,
                "rmsd_p25": ...,
                "rmsd_p50": ...,
                "rmsd_p75": ...,
                "rmsd_p95": ...,
                "rmsd": ...,
                "bias_p05": ...,
                "bias_p25": ...,
                "bias_p50": ...,
                "bias_p75": ...,
                "bias_p95": ...,
                "bias": ...,
            },
            ...
        }

    observation : str
        Name of the observation dataset.

    dateval : str
        Date displayed in the title.

    Returns
    -------
    fig : matplotlib.figure.Figure
        Figure object.

    ax : matplotlib.axes.Axes
        Axes object.
    """

    fig, ax = plt.subplots(figsize=(11, 6.5))

    # -------------------------
    # Colors for each model
    # -------------------------

    #colors = plt.cm.tab10(np.linspace(0, 1, len(scores)))
    colors = ["tab:blue", "tab:green", "tab:red", "tab:orange"]
    max_lead = 0

    for color, (model, data) in zip(colors, scores.items()):

        x = data["x"]

        if x[-1] > max_lead:
            max_lead = x[-1]
        # -------------------------
        # RMSD
        # -------------------------

        # Overall RMSD
        ax.plot(
            x,
            data["rmsd"],
            color=color,
            marker="o",
            #s=30,
            label=f"{DISPLAY_NAMES.get(model, model)} RMSD",
            linewidth=2,
            markersize=4,
            zorder=6,
        )

        # -------------------------
        # BIAS
        # -------------------------
        # Overall Bias
        ax.plot(
            x,
            data["bias"],
            color=color,
            marker="s",
            linestyle=":",
            linewidth=2,
            markersize=3,
            #s=30,
            label=f"{DISPLAY_NAMES.get(model, model)} Bias",
            zorder=6,
        )

    # ==========================================================
    # MODEL LEGEND
    # ==========================================================

    model_handles = []

    for color, (model, data) in zip(colors, scores.items()):

        model_handles.append(
            plt.Line2D(
                [0],
                [0],
                color=color,
                linewidth=3,
                label=DISPLAY_NAMES.get(model, model),
            )
        )

    fig.legend(
        handles=model_handles,
        title="Models",
        loc="lower center",
        fontsize=12,
        bbox_to_anchor=(0.57, 0.015),
        ncol=len(scores),
        frameon=True,
        title_fontsize=13,
        facecolor="#f0f0f0",
        edgecolor="#bcbcbc",
    )

    #ax.add_artist(legend_models)

    # -------------------------
    # Statistic legend
    # -------------------------

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
            linestyle=":",
            marker="s",
            linewidth=2,
            markersize=6,
            label="Bias",
        ),
    ]

    fig.legend(
        handles=stat_handles,
        title="Statistics",
        loc="lower left",
        bbox_to_anchor=(0.12, 0.015),
        fontsize=12,
        title_fontsize=13,
        ncol=2,
        frameon=True,
        facecolor="#f0f0f0",
        edgecolor="#bcbcbc",
    )


    # -------------------------
    # Plot settings
    # -------------------------

    ax.set_xlabel(
            "Forecast lead time (days)",
            fontsize=17,
            labelpad=10,
    )
    ax.set_ylabel(
            f"{label}",
            fontsize=17,
            labelpad=10,
    )
    ax.tick_params(
        axis="both",
        labelsize=15,
        width=1.3,
        length=6,
    )

    fig.suptitle(
        f"{observation} - Forecast scores intercomparison",
        fontsize=19,
        y=0.975,
    )
    fig.text(0.5, 0.925, f"Date: {dateval}",
             ha="center", va="center", fontsize=13)

    ax.grid(
        True,
        alpha=0.3,
        linestyle="--"
    )

    ax.axhline(
        y=0,
        color="black",
        alpha=0.6,
        linestyle="--",
        linewidth=1.5,
    )
    ax.set_xlim(
        0.5,
        max_lead + 0.5
    )

    ax.yaxis.set_major_locator(MultipleLocator(0.1))
    ax.xaxis.set_major_locator(MultipleLocator(1))

   # plt.tight_layout(rect=[0, 0.08, 1, 1])
    fig.subplots_adjust(bottom=0.23, top=0.84, left=0.12, right=0.97)

    saveimg = (f"imgs/results_scores_"
               f"class4_profile_TS_DB_intercomp_forecast_{dateval}_rmsd_bias2.png"
    )
    print(saveimg)
    plt.savefig(saveimg, dpi=300, bbox_inches="tight")

    return fig, ax


# Load scores

dirin = "/data/rd_exchange/cregnier/CLASS4/"
dateval = '20240101_20241231'
list_model = ["glo4-ens50-mean", "glonet", "glow", "GLO12"]
observation="SST_TS_DB"
scores = {}
label= "°C"
for model in list_model:

    filename = (
            f"{dirin}results_scores_class4_profile_TS_DB_{model}_"
            f"forecast_{dateval}.nc"
            )
    with xr.open_dataset(filename) as ds:

        leadtime = ds["leadtime"].values
        x = np.arange(1, len(leadtime)+1)

        # -------------------------
        # Overall statistics
        # -------------------------

        cumul_squared_diff = ds["cumul_squared_diff"].values
        print(cumul_squared_diff)

        cumul_bias = ds["cumul_bias"].values
        print(cumul_bias)

        n_obs = ds["n_obs"].values
        print(n_obs)

        with np.errstate(divide="ignore", invalid="ignore"):
            rmsd = np.sqrt(cumul_squared_diff / n_obs)
            bias = cumul_bias / n_obs

        # -------------------------
        # Daily statistics
        # -------------------------

        rmsd_daily = ds["rmsd_daily"].values.copy()
        bias_daily = ds["bias_daily"].values.copy()
        n_obs_daily = ds["n_obs_daily"].values

        # -------------------------
        # Percentiles of daily scores
        # -------------------------

        rmsd_p05 = np.nanpercentile(rmsd_daily, 5, axis=1)
        rmsd_p25 = np.nanpercentile(rmsd_daily, 25, axis=1)
        rmsd_p50 = np.nanpercentile(rmsd_daily, 50, axis=1)
        rmsd_p75 = np.nanpercentile(rmsd_daily, 75, axis=1)
        rmsd_p95 = np.nanpercentile(rmsd_daily, 95, axis=1)

        bias_p05 = np.nanpercentile(bias_daily, 5, axis=1)
        bias_p25 = np.nanpercentile(bias_daily, 25, axis=1)
        bias_p50 = np.nanpercentile(bias_daily, 50, axis=1)
        bias_p75 = np.nanpercentile(bias_daily, 75, axis=1)
        bias_p95 = np.nanpercentile(bias_daily, 95, axis=1)

        # -------------------------
        # Store model scores
        # -------------------------

        scores[model] = {
            "x": x,
            # Overall statistics
            "rmsd": rmsd,
            "bias": bias,
            "leadtime": leadtime,
            # RMSD daily percentiles
            "rmsd_p05": rmsd_p05,
            "rmsd_p25": rmsd_p25,
            "rmsd_p50": rmsd_p50,
            "rmsd_p75": rmsd_p75,
            "rmsd_p95": rmsd_p95,

            # Bias daily percentiles
            "bias_p05": bias_p05,
            "bias_p25": bias_p25,
            "bias_p50": bias_p50,
            "bias_p75": bias_p75,
            "bias_p95": bias_p95,
        }


fig, ax = plot_forecast_scores(
    scores,
    observation,
    dateval,
    label=label
)
