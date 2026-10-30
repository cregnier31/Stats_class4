import numpy as np
import xarray as xr
import matplotlib.pyplot as plt

dirin = "/data/rd_exchange/cregnier/CLASS4/"
filename = (
        f"{dirin}results_scores_class4_profile_TS_DB_glo4-ens50_"
        "forecast_20240401_20240630.nc"
    )

ds = xr.open_dataset(filename)

# ---------------------------------------------------------
# Leadtimes
# ---------------------------------------------------------
leadtime = ds["leadtime"].values

# ---------------------------------------------------------
# Overall RMSD and bias for each leadtime
# ---------------------------------------------------------
cumul_squared_diff = ds["cumul_squared_diff"].values
cumul_bias = ds["cumul_bias"].values
n_obs = ds["n_obs"].values

with np.errstate(divide="ignore", invalid="ignore"):
        rmsd = np.sqrt(cumul_squared_diff / n_obs)
            bias = cumul_bias / n_obs

            # ---------------------------------------------------------
            # Daily values
            # Shape = (leadtime, nbdays)
            # ---------------------------------------------------------
            rmsd_daily = ds["rmsd_daily"].values
            bias_daily = ds["bias_daily"].values
            n_obs_daily = ds["n_obs_daily"].values

            # Ignore daily values where there are no observations
            rmsd_daily[n_obs_daily <= 0] = np.nan
            bias_daily[n_obs_daily <= 0] = np.nan

            # ---------------------------------------------------------
            # Percentiles for each leadtime
            # ---------------------------------------------------------
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


            # =========================================================
            # PLOT RMSD
            # =========================================================

            fig, ax = plt.subplots(figsize=(14, 7))

            # 5-95 percentile
            ax.vlines(
                    leadtime,
                    rmsd_p05,
                    rmsd_p95,
                    color="red",
                    linewidth=1.5,
                    label="5–95 percentile"
                )

            # 25-75 percentile
            ax.vlines(
                    leadtime,
                    rmsd_p25,
                    rmsd_p75,
                    color="red",
                    linewidth=5,
                    label="25–75 percentile"
                )

            # Median = red cross
            ax.scatter(
                    leadtime,
                    rmsd_p50,
                    color="red",
                    marker="x",
                    s=80,
                    linewidths=2.5,
                    label="Median"
                )

            # Overall RMSD = black dot
            ax.scatter(
                    leadtime,
                    rmsd,
                    color="black",
                    marker="o",
                    s=70,
                    label="RMSD"
                )

            ax.set_xlabel("Leadtime", fontsize=13, fontweight="bold")
            ax.set_ylabel("RMSD", fontsize=13, fontweight="bold")

            ax.set_xticks(leadtime)

            ax.grid(
                    True,
                    linestyle="--",
                    color="gray",
                    alpha=0.5
                )

            ax.legend(fontsize=11)

            ax.set_title(
                    "RMSD as a function of leadtime",
                    fontsize=15,
                    fontweight="bold"
                )

            plt.tight_layout()

            plt.savefig(
                    "RMSD_vs_leadtime.png",
                    dpi=300,
                    bbox_inches="tight"
                )

            #plt.show()


            # =========================================================
            # PLOT BIAS
            # =========================================================

            fig, ax = plt.subplots(figsize=(14, 7))

            # 5-95 percentile
            ax.vlines(
                    leadtime,
                    bias_p05,
                    bias_p95,
                    color="red",
                    linewidth=1.5,
                    label="5–95 percentile"
                )

            # 25-75 percentile
            ax.vlines(
                    leadtime,
                    bias_p25,
                    bias_p75,
                    color="red",
                    linewidth=5,
                    label="25–75 percentile"
                )

            # Median = red cross
            ax.scatter(
                    leadtime,
                    bias_p50,
                    color="red",
                    marker="x",
                    s=80,
                    linewidths=2.5,
                    label="Median"
                )

            # Overall bias = black dot
            ax.scatter(
                    leadtime,
                    bias,
                    color="black",
                    marker="o",
                    s=70,
                    label="Mean bias"
                )

            ax.axhline(
                    0,
                    color="black",
                    linewidth=1,
                    linestyle="--"
                )

            ax.set_xlabel("Leadtime", fontsize=13, fontweight="bold")
            ax.set_ylabel("Bias", fontsize=13, fontweight="bold")

            ax.set_xticks(leadtime)

            ax.grid(
                    True,
                    linestyle="--",
                    color="gray",
                    alpha=0.5
                )

            ax.legend(fontsize=11)

            ax.set_title(
                    "Bias as a function of leadtime",
                    fontsize=15,
                    fontweight="bold"
                )

            plt.tight_layout()

            plt.savefig(
                    "Bias_vs_leadtime.png",
                    dpi=300,
                    bbox_inches="tight"
                )
