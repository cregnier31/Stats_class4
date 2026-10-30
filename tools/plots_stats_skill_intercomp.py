import numpy as np
import xarray as xr
import matplotlib.pyplot as plt

def plot_forecast_scores(scores, observation, dateval):
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

    fig, ax = plt.subplots(figsize=(14, 8))

    # -------------------------
    # Colors for each model
    # -------------------------

    #colors = plt.cm.tab10(np.linspace(0, 1, len(scores)))
    colors = ["black", "red", "blue", "dark green"]

    for color, (model, data) in zip(colors, scores.items()):

        x = data["x"]

        # -------------------------
        # RMSD
        # -------------------------

        # P5-P95
        ax.vlines(
            x,
            data["rmsd_p05"],
            data["rmsd_p95"],
            color=color,
            linewidth=1.5,
            alpha=0.7,
        )

        # P25-P75
        ax.vlines(
            x,
            data["rmsd_p25"],
            data["rmsd_p75"],
            color=color,
            linewidth=5,
            alpha=0.7,
        )

        # Daily median
        ax.scatter(
            x,
            data["rmsd_p50"],
            color=color,
            marker="x",
            s=90,
            linewidths=2.5,
            label=f"{model} RMSD daily median",
            zorder=5,
        )

        # Overall RMSD
        ax.scatter(
            x,
            data["rmsd"],
            color=color,
            marker="o",
            s=70,
            label=f"{model} RMSD",
            zorder=6,
        )

        # -------------------------
        # BIAS
        # -------------------------

        # P5-P95
        ax.vlines(
            x,
            data["bias_p05"],
            data["bias_p95"],
            color=color,
            linewidth=1.5,
            alpha=0.7,
        )

        # P25-P75
        ax.vlines(
            x,
            data["bias_p25"],
            data["bias_p75"],
            color=color,
            linewidth=5,
            alpha=0.7,
        )

        # Daily median
        ax.scatter(
            x,
            data["bias_p50"],
            color=color,
            marker="x",
            s=90,
            linewidths=2.5,
            label=f"{model} Bias daily median",
            zorder=5,
        )

        # Overall Bias
        ax.scatter(
            x,
            data["bias"],
            color=color,
            marker="s",
            s=60,
            label=f"{model} Bias",
            zorder=6,
        )

    # -------------------------
    # Plot settings
    # -------------------------

    ax.set_xlabel("Leadtime")
    ax.set_ylabel("Score")

    ax.set_title(
        f"{observation} - Forecast scores\n"
        f"Date: {dateval}"
    )

    ax.legend(loc="upper left")
    ax.grid(True, alpha=0.3, linestyle="--")

    ax.axhline(
        y=0,
        color="black",
        linestyle="-",
        linewidth=1.5,
    )
    plt.tight_layout()
    saveimg = (f"imgs/results_scores_"
               f"class4_profile_TS_DB_intercomp_forecast_{dateval}_rmsd_bias.png"
    )
    print(saveimg)
    plt.savefig(saveimg, dpi=300, bbox_inches="tight")

    return fig, ax


# Load scores

dirin = "/data/rd_exchange/cregnier/CLASS4/"
dateval = '20240101_20241231'
list_model = ["glo4-ens50-mean", "glonet", "glow"]
observation="SST_TS_DB"
scores = {}
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
)
