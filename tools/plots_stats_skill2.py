import numpy as np
import xarray as xr
import matplotlib.pyplot as plt

dirin = "/data/rd_exchange/cregnier/CLASS4/"
dateval = '20240101_20241231'
#dateval = '20260101_20260630'
model = "glo4-ens50-mean"
model = "glow"
observation="SST_TS_DB"
filename = (
        f"{dirin}results_scores_class4_profile_TS_DB_{model}_"
        f"forecast_{dateval}.nc"
        )
ds = xr.open_dataset(filename)

leadtime = ds["leadtime"].values
x = np.arange(1, len(leadtime)+1)

# Overall statistics
cumul_squared_diff = ds["cumul_squared_diff"].values
print(cumul_squared_diff)
cumul_bias = ds["cumul_bias"].values
print(cumul_bias)
n_obs = ds["n_obs"].values
print(n_obs)

with np.errstate(divide="ignore", invalid="ignore"):
    rmsd = np.sqrt(cumul_squared_diff / n_obs)
    bias = cumul_bias / n_obs

# Daily statistics
rmsd_daily = ds["rmsd_daily"].values.copy()
bias_daily = ds["bias_daily"].values.copy()
n_obs_daily = ds["n_obs_daily"].values

print(rmsd_daily)
print(bias_daily)
print(n_obs_daily)

rmsd_daily[n_obs_daily <= 0] = np.nan
bias_daily[n_obs_daily <= 0] = np.nan

# Percentiles
rmsd_p05, rmsd_p25, rmsd_p50, rmsd_p75, rmsd_p95 = [
        np.nanpercentile(rmsd_daily, p, axis=1)
        for p in [5, 25, 50, 75, 95]
    ]

bias_p05, bias_p25, bias_p50, bias_p75, bias_p95 = [
        np.nanpercentile(bias_daily, p, axis=1)
        for p in [5, 25, 50, 75, 95]
    ]


# =========================================================
# ONE SINGLE PLOT / ONE SINGLE Y AXIS
# =========================================================

fig, ax = plt.subplots(figsize=(14, 8))


# -------------------------
# RMSD
# -------------------------

# P5-P95
ax.vlines(
        x,
        rmsd_p05,
        rmsd_p95,
        color="red",
        linewidth=1.5,
    )

# P25-P75
ax.vlines(
        x,
        rmsd_p25,
        rmsd_p75,
        color="red",
        linewidth=5,
    )

# Daily median
ax.scatter(
        x,
        rmsd_p50,
        color="red",
        marker="x",
        s=90,
        linewidths=2.5,
        label="RMSD daily median",
        zorder=5,
    )

# Overall RMSD
ax.scatter(
        x,
        rmsd,
        color="black",
        marker="o",
        s=70,
        label="RMSD",
        zorder=6,
    )


# -------------------------
# BIAS
# -------------------------

# P5-P95
ax.vlines(
        x,
        bias_p05,
        bias_p95,
        color="blue",
        linewidth=1.5,
    )

# P25-P75
ax.vlines(
        x,
        bias_p25,
        bias_p75,
        color="blue",
        linewidth=5,
    )

# Daily median
ax.scatter(
        x,
        bias_p50,
        color="blue",
        marker="x",
        s=90,
        linewidths=2.5,
        label="Bias daily median",
        zorder=5,
    )

# Overall bias
ax.scatter(
        x,
        bias,
        color="black",
        marker="s",
        s=60,
        label="Bias",
        zorder=6,
    )


# Zero line
ax.axhline(
        0,
        color="black",
        linestyle="--",
        linewidth=1,
    )


# =========================================================
# AXES
# =========================================================

ax.set_xticks(x)
ax.set_xticklabels(
        x,
        rotation=45,
        ha="right"
    )

ax.set_xlabel("Forecast leadtime")
ax.set_ylabel("RMSD / Bias")

ax.set_title(
    f"{model} -{observation} RMSD and Bias versus leadtime\n"
    f"Period: {dateval}"
)
ax.grid(
        True,
        linestyle="--",
        alpha=0.4
    )

ax.legend(loc="upper left")

plt.tight_layout()
saveimg = f"imgs/results_scores_class4_profile_TS_DB_{model}_forecast_{dateval}_rmsd_bias.png"
print(saveimg)
plt.savefig(saveimg, dpi=300, bbox_inches="tight")
