import numpy as np
import sys
import datetime
from copy import deepcopy
import numpy.ma as ma
import netCDF4
from scipy.stats import binned_statistic_2d

__author__      = "C.REGNIER"
__version__ = 0.1

import numpy as np


def init_array_1D(size):
    return np.full(size, netCDF4.default_fillvals['f4'], dtype=float, order='F')

def init_array_1D_null(size):
    return np.zeros(size, dtype=float, order='F')

def init_array_2D_null(nregion, nlead):
    return np.zeros(
        (nregion, nlead),
        dtype=float,
        order='F',
    )
def init_array_3D_null(nregion, ndepth, nlead):
    return np.zeros(
        (nregion, ndepth, nlead),
        dtype=float,
        order="F",
    )

def init_array_4D_null(nlat, nlon, ndepth, nlead,):
    return np.zeros(
        (nlat, nlon, ndepth, nlead),
        dtype=float,
        order="F",
    )

def init_array_2D(size, size2):
    return np.full((size, size2), netCDF4.default_fillvals['f4'], dtype=float, order='F')

def init_array_3D(size, size2, size3):
    return np.full((size, size2, size3), netCDF4.default_fillvals['f4'], dtype=float, order='F')

def compute_rmsd_3d_by_depth_bins(data1, data2, depth_array, data_qc, depth_bins, good_qc):
    """
    Compute RMSD and Bias between data1 and data2 over specified depth bins,
    aggregated across all profiles (not per-profile).

    Parameters:
    - data1, data2: masked arrays of shape (num_obs, num_depths)
    - depth_array: array of shape (num_obs, num_depths), giving the actual depth of each point
    - data_qc : ndarray (num_obs, num_depths)
                QC flags: only values with QC == 0 are used in the statistics
    - depth_bins: list of bin edges (e.g., [0, 5, 100, 300, 600])

    Returns:
    - rmsd_bin: list of RMSD per depth bin
    - cumul_sq_diff_bin: list of total squared diff per bin
    - n_obs_bin: list of valid observation counts per bin
    """

    data1 = ma.masked_where(
                np.abs(data1) > 1.0e30,
                    data1,
    )

    data2 = ma.masked_where(
                np.abs(data2) > 1.0e30,
                    data2,
    )
    data2 = ma.masked_where(
                np.abs(data1) > 1.0e30,
                    data2,
    )
    #data1 = ma.masked_where(
    #    np.isclose(data1, 99999.0),
    #    data1,
    #)
    #data2 = ma.masked_where(
    #    np.isclose(data2, 99999.0),
    #    data2,
    #)
    data1 = ma.masked_invalid(data1)
    data2 = ma.masked_invalid(data2)
    depth_array = ma.masked_invalid(depth_array)

    assert data1.shape == data2.shape == depth_array.shape, "Shapes of input arrays must match"

    # Create QC mask (True for valid values)
    qc_mask = (data_qc == good_qc)

    bias_bins = []
    cumul_bias_bins = []
    rmsd_bins = []
    cumul_sq_diff_bins = []
    n_obs_bins = []

    for i in range(len(depth_bins) - 1):

        bin_mask = (
            (depth_array >= depth_bins[i])
            & (depth_array < depth_bins[i + 1])
        )
        # Valid where bin_mask is True and both data1 and data2 are not masked
        #valid_mask = bin_mask & (~data1.mask) & (~data2.mask)
        #bin_mask_2d = np.broadcast_to(bin_mask, data1.shape)
        valid_mask = (
            bin_mask
            & (~ma.getmaskarray(data1))
            & (~ma.getmaskarray(data2))
            & (~ma.getmaskarray(depth_array))
            & qc_mask
        )
        #valid_mask = bin_mask_2d & (~data1.mask) & (~data2.mask) & qc_mask

        diff = data1 - data2
        valid_diff = ma.masked_where(
            ~valid_mask,
            diff,
        )
        #print(f'Max : {np.nanmax(valid_diff)}')
        #print(f'Min : {np.nanmin(valid_diff)}')
        #print(f'Mean : {np.nanmean(valid_diff)}')
        #print(f'Max abs : {np.max(np.abs(valid_diff))}')
        cumul_bias = valid_diff.sum()
        cumul_sq_diff = (valid_diff ** 2).sum()
        n_obs = valid_mask.sum()
        #print(f'Nb obs : {n_obs}')

        #print(valid_diff[0:10])

        if n_obs > 0:
            bias = (cumul_bias / n_obs)
            rmsd = np.sqrt(cumul_sq_diff / n_obs)
        else:
            bias = np.nan
            rmsd = np.nan
            cumul_bias = 0.0
            cumul_sq_diff = 0.0

        #print(f'{depth_bins[i]}-{depth_bins[i+1]}')
        #print(f'{bias=}')
        #print(f'{rmsd=}')
        #print(f'{n_obs=}')
        bias_bins.append(bias)
        cumul_bias_bins.append(float(cumul_bias))
        rmsd_bins.append(float(rmsd))
        cumul_sq_diff_bins.append(float(cumul_sq_diff))
        n_obs_bins.append(int(n_obs))

    # ---------------------------------------------------------
    # Total over all depth layers
    # ---------------------------------------------------------

    cumul_bias_total = sum(
        cumul_bias_bins
    )

    cumul_sq_diff_total = sum(
        cumul_sq_diff_bins
    )

    n_obs_total = sum(
        n_obs_bins
    )

    if n_obs_total > 0:

        bias_total = (
            cumul_bias_total
            / n_obs_total
        )

        rmsd_total = np.sqrt(
            cumul_sq_diff_total
            / n_obs_total
        )

    else:

        bias_total = np.nan
        rmsd_total = np.nan

    # Append total as the last output
    bias_bins.append(
        float(bias_total)
    )

    cumul_bias_bins.append(
        float(cumul_bias_total)
    )

    rmsd_bins.append(
        float(rmsd_total)
    )

    cumul_sq_diff_bins.append(
        float(cumul_sq_diff_total)
    )

    n_obs_bins.append(
        int(n_obs_total)
    )

    return (
        bias_bins,
        cumul_bias_bins,
        rmsd_bins,
        cumul_sq_diff_bins,
        n_obs_bins,
    )
       # sq_diff = ma.masked_where(~valid_mask, (data1 - data2)**2)
       # cum_sq_diff = sq_diff.sum()
       # n_obs = valid_mask.sum()
       # rmsd = np.sqrt(cum_sq_diff / n_obs) if n_obs > 0 else np.nan

       # rmsd_bins.append(rmsd)
       # cum_sq_diff_bins.append(cum_sq_diff)
       # n_obs_bins.append(n_obs)
       # #diff = data1.data - data2.data
       # #sq_diff = np.square(diff)
       # #cumul_sq_diff_bin[i] = np.sum(sq_diff[valid_mask])
       # #n_obs_bin[i] = np.sum(valid_mask)

    ## Total RMSD over all bins (0 to max(depth_bins))
    #dmin_total = depth_bins[0]
    #dmax_total = depth_bins[-1]
    #total_mask = (depth_array >= dmin_total) & (depth_array <= dmax_total)
    #total_mask_2d = np.broadcast_to(total_mask, data1.shape)

    #valid_mask_total = total_mask_2d & (~data1.mask) & (~data2.mask) & qc_mask

    #sq_diff_total = ma.masked_where(~valid_mask_total, (data1 - data2)**2)

    #cum_sq_diff_total = sq_diff_total.sum()
    #n_obs_total = valid_mask_total.sum()
    #rmsd_total = np.sqrt(cum_sq_diff_total / n_obs_total) if n_obs_total > 0 else np.nan
    #rmsd_bins.append(rmsd_total)
    #cum_sq_diff_bins.append(cum_sq_diff_total)
    #n_obs_bins.append(n_obs_total)
    ## Compute RMSD per bin
    ##rmsd_bin = [np.sqrt(cumul / n) if n > 0 else np.nan
    ##            for cumul, n in zip(cumul_sq_diff_bin, n_obs_bin)]

    #return rmsd_bins, cum_sq_diff_bins, n_obs_bins

def compute_rmsd(data1,
                 data2,
                 nbobs,
                 data_qc=None,
                 good_qc=0,
                 threshold=None):
    """
    Compute RMSD between two arrays, skipping invalid/masked values.
    and optionally filtering by QC flags (QC == 0 only).
    Parameters
    ----------
    data1, data2 : array-like
        Data to compare.
    data_qc : array-like, optional
        QC flags. Only values equal to good_qc are retained.
    good_qc : int, default=0
        QC value considered valid.
    threshold : float, optional
        Maximum allowed absolute difference between data1 and data2.
        Values with abs(data1 - data2) > threshold are excluded.

    Returns:
        rmsd: root mean square difference
        cumul_sq_diff: sum of squared differences
        n_obs: number of valid observations
    """
    # Convert to masked arrays if not already
    data1 = np.ma.masked_invalid(data1)
    data2 = np.ma.masked_invalid(data2)

    # Mask positions where either data1 or data2 is masked
    combined_mask = np.ma.mask_or(data1.mask, data2.mask)

    # If QC is provided, mask anything not QC == 0
    if data_qc is not None:
        qc_mask = (data_qc != good_qc)
        combined_mask = np.logical_or(combined_mask, qc_mask)

    # Difference
    diff = np.ma.masked_array(data1 - data2, mask=combined_mask)

    # Apply threshold
    if threshold is not None and nbobs > 2:
        threshold_mask = np.abs(diff) > threshold
        n_bad = np.count_nonzero(threshold_mask)
        diff = np.ma.masked_where(threshold_mask, diff)
    else:
         n_bad = 0

    # Count valid observations
    n_obs = diff.count()
    if n_obs == 0:
        return (
            np.nan,  # mean_diff
            0.0,     # cumul_diff
            np.nan,  # rmsd
            0.0,     # cumul_sq_diff
            0,       # n_obs
            n_bad,   # n_bad
        )

    # Statistics
    cumul_diff = np.ma.sum(diff)
    mean_diff = np.ma.mean(diff)

    cumul_sq_diff = np.ma.sum(diff**2)
    rmsd = np.sqrt(cumul_sq_diff / n_obs)

    return (
        mean_diff,
        cumul_diff,
        rmsd,
        cumul_sq_diff,
        n_obs,
        n_bad,
    )

def fillVal2nan(data,fillVal):
    return np.ma.filled(np.ma.masked_array(data,(data==fillVal)), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------

def nanmean(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).mean(**args), fill_value=np.nan)

def weighted_nanmean(data, weights, **kwargs):
   # Mask invalid values (NaNs)
   masked_data = ma.masked_invalid(data)
   # Apply weights
   weighted_data = ma.masked_array(masked_data, mask=masked_data.mask, fill_value=np.nan) * weights
   # Calculate the area-weighted mean
   weighted_mean = np.ma.average(weighted_data, **kwargs)
   return weighted_mean

#--------------------------------------------------------------------------------------------------
def nansum(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).sum(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanrms(data, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data),np.isnan(data)).mean(**args), fill_value=np.nan)
    return np.sqrt(out)

#--------------------------------------------------------------------------------------------------
def nanms(data, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data),np.isnan(data)).mean(**args), fill_value=np.nan)
    return out

def weighted_nanms(data, weights, **kwargs):
    # Mask invalid values (NaNs)
    masked_data = ma.masked_invalid(data)
    # Apply weights to squared values
    weighted_squared_data = ma.masked_array(masked_data ** 2, mask=masked_data.mask, fill_value=np.nan) * weights
    # Calculate the area-weighted mean of squared values
    weighted_mean_squared = np.ma.average(weighted_squared_data, **kwargs)
    return weighted_mean_squared

#--------------------------------------------------------------------------------------------------
def nansums(data, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data),np.isnan(data)).sum(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nanrmse(data1,data2, **args):
    data1 = np.array(data1)
    data2 = np.array(data2)
    out = np.ma.filled(np.ma.masked_array(np.square(data2-data1),np.isnan(data2-data1)).mean(**args), fill_value=np.nan)
    return np.sqrt(out)

def weighted_nanrmse(data1, data2, weights, **kwargs):
    data1 = np.array(data1)
    data2 = np.array(data2)
    # Mask invalid values (NaNs) in both datasets
    masked_diff = ma.masked_invalid(data2 - data1)
    # Apply weights to squared differences
    weighted_squared_diff = ma.masked_array(masked_diff ** 2, mask=masked_diff.mask, fill_value=np.nan) * weights
    # Calculate the area-weighted mean of squared differences
    weighted_mean_squared_diff = np.ma.average(weighted_squared_diff, **kwargs)
    # Calculate the RMSE and fill NaNs
    rmse = np.sqrt(np.ma.filled(weighted_mean_squared_diff, fill_value=np.nan))
    return rmse

#--------------------------------------------------------------------------------------------------
def nansummd(data1,data2, **args):
    data1 = np.array(data1)
    data2 = np.array(data2)
    out = np.ma.filled(np.ma.masked_array((data2-data1),np.isnan(data2-data1)).sum(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nansummad(data1,data2, **args):
    data1 = np.array(data1)
    data2 = np.array(data2)
    out = np.ma.filled(np.ma.masked_array((abs(data2-data1)),np.isnan(abs(data2-data1))).sum(**args), fill_value=np.nan)
    return out

def nanmeanMAE(data1,data2, **args):
    data1 = np.array(data1)
    data2 = np.array(data2)
    out = np.ma.filled(np.ma.masked_array((abs(data2-data1)),np.isnan(abs(data2-data1))).mean(**args), fill_value=np.nan)
    return out
#--------------------------------------------------------------------------------------------------
def nanmse(data1,data2, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data2-data1),np.isnan(data2-data1)).mean(**args), fill_value=np.nan)
    return out

def weighted_nanmse(data1, data2, weights, **kwargs):
    # Mask invalid values (NaNs) in both datasets
    masked_diff = ma.masked_invalid(data2 - data1)
    # Apply weights to squared differences
    weighted_squared_diff = ma.masked_array(masked_diff ** 2, mask=masked_diff.mask, fill_value=np.nan) * weights
    # Calculate the area-weighted mean of squared differences
    weighted_mean_squared_diff = np.ma.average(weighted_squared_diff, **kwargs)
    # Fill NaNs in the result
    mse = np.ma.filled(weighted_mean_squared_diff, fill_value=np.nan)
    return mse



#--------------------------------------------------------------------------------------------------
def nansumse(data1,data2, **args):
    out = np.ma.filled(np.ma.masked_array(np.square(data2-data1),np.isnan(data2-data1)).sum(**args), fill_value=np.nan)
    return out

#--------------------------------------------------------------------------------------------------
def nanstd(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).std(**args), fill_value=np.nan)

def weighted_nanstd(data, weights, **kwargs):
    # Mask invalid values (NaNs)
    masked_data = ma.masked_invalid(data)
    # Apply weights to the masked data
    weighted_data = ma.masked_array(masked_data, mask=masked_data.mask, fill_value=np.nan) * weights
    # Calculate the area-weighted standard deviation
    weighted_std = np.ma.sqrt(np.ma.average((weighted_data - np.ma.average(weighted_data, **kwargs))**2, weights=weights, **kwargs))
    # Fill NaNs in the result
    std = np.ma.filled(weighted_std, fill_value=np.nan)

    return std




#--------------------------------------------------------------------------------------------------
def nanmin(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).min(**args), fill_value=np.nan)

#--------------------------------------------------------------------------------------------------
def nanmax(data, **args):
    return np.ma.filled(np.ma.masked_array(data,np.isnan(data)).max(**args), fill_value=np.nan)

def weighted_nanpearson(data1, data2, weights):
    # Mask invalid values (NaNs) in both datasets
    masked_data1 = ma.masked_invalid(data1)
    masked_data2 = ma.masked_invalid(data2)

    # Apply weights to the masked data
    weighted_data1 = ma.masked_array(masked_data1, mask=masked_data1.mask, fill_value=np.nan) * weights
    weighted_data2 = ma.masked_array(masked_data2, mask=masked_data2.mask, fill_value=np.nan) * weights

    # Check if shapes are compatible for broadcasting
    try:
        np.broadcast(weighted_data1, weighted_data2, weights)
    except ValueError:
        raise ValueError("Shapes of data and weights are not compatible for broadcasting.")

    # Calculate means
    mean_data1 = np.ma.average(weighted_data1)
    mean_data2 = np.ma.average(weighted_data2)

    # Calculate covariance
    #print(np.shape(weighted_data1))
    #print(np.shape(mean_data1))
    #print(np.shape(weighted_data2))
    #print(np.shape(mean_data2))
    #print(np.shape(weights))

    cov12 = np.ma.average((weighted_data1 - mean_data1) * (weighted_data2 - mean_data2), weights=weights)

    # Calculate weighted standard deviations
    std1 = np.ma.sqrt(np.ma.average((weighted_data1 - mean_data1)**2, weights=weights))
    std2 = np.ma.sqrt(np.ma.average((weighted_data2 - mean_data2)**2, weights=weights))

    # Calculate the area-weighted Pearson correlation coefficient
    if std1 * std2 == 0:
       return 1  # Return 1 for perfect correlation if one of the standard deviations is zero

    return cov12 / (std1 * std2)

#--------------------------------------------------------------------------------------------------
def nanpearson(data1,data2):
    std1   = nanstd(data1)
    std2   = nanstd(data2)
    cov12  = nanmean((data1-nanmean(data1))*(data2 - nanmean(data2)))

    if cov12 == 0 : return 0
    if std1*std2 == 0 : return 1

    return cov12/(std1*std2)

def compute_grid_stats_2d(
    obs_lon,
    obs_lat,
    data1,
    data2,
    grid_resolution,
    threshold=None,
):
    """
    Compute statistics on a regular longitude/latitude grid.

    Parameters
    ----------
    obs_lon : ndarray
        Observation longitudes.
    obs_lat : ndarray
        Observation latitudes.
    data1 : ndarray
        Model values.
    data2 : ndarray
        Observation values.
    grid_resolution : float
        Grid resolution in degrees.
    threshold : float, optional
        Maximum allowed absolute difference.

    Returns
    -------
    bias : ndarray
        Mean bias per grid cell.
    cumul_bias : ndarray
        Sum of differences per grid cell.
    rmsd : ndarray
        RMSD per grid cell.
    cumul_sq_diff : ndarray
        Sum of squared differences per grid cell.
    n_obs : ndarray
        Number of observations per grid cell.
    lon_centers : ndarray
        Longitude grid centers.
    lat_centers : ndarray
        Latitude grid centers.
    """

    obs_lon = np.asarray(obs_lon)
    obs_lat = np.asarray(obs_lat)
    data1 = np.asarray(data1)
    data2 = np.asarray(data2)

    diff = data1 - data2

    valid = (
        np.isfinite(obs_lon)
        & np.isfinite(obs_lat)
        & np.isfinite(data1)
        & np.isfinite(data2)
    )

    if threshold is not None:
        valid &= np.abs(diff) <= threshold

    obs_lon = obs_lon[valid]
    obs_lat = obs_lat[valid]
    diff = diff[valid]

    lon_edges = np.arange(
        -180.0,
        180.0 + grid_resolution,
        grid_resolution,
    )

    lat_edges = np.arange(
        -90.0,
        90.0 + grid_resolution,
        grid_resolution,
    )

    lon_centers = (
        lon_edges[:-1]
        + grid_resolution / 2.0
    )

    lat_centers = (
        lat_edges[:-1]
        + grid_resolution / 2.0
    )

    # Number of observations
    n_obs, _, _ = binned_statistic_2d(
        obs_lat,
        obs_lon,
        values=None,
        statistic="count",
        bins=[lat_edges, lon_edges],
    )

    # Cumulative bias
    cumul_bias, _, _ = binned_statistic_2d(
        obs_lat,
        obs_lon,
        values=diff,
        statistic="sum",
        bins=[lat_edges, lon_edges],
    )

    # Cumulative squared difference
    cumul_sq_diff, _, _ = binned_statistic_2d(
        obs_lat,
        obs_lon,
        values=diff ** 2,
        statistic="sum",
        bins=[lat_edges, lon_edges],
    )

    # Empty bins from statistic="sum" are NaN
    cumul_bias = np.nan_to_num(
        cumul_bias,
        nan=0.0,
    )

    cumul_sq_diff = np.nan_to_num(
        cumul_sq_diff,
        nan=0.0,
    )

    # RMSD
    rmsd = np.full(
        n_obs.shape,
        np.nan,
        dtype=float,
    )

    bias = np.full(
        n_obs.shape,
        np.nan,
        dtype=float,
    )

    valid_grid = n_obs > 0

    rmsd[valid_grid] = np.sqrt(
        cumul_sq_diff[valid_grid]
        / n_obs[valid_grid]
    )

    bias[valid_grid] = (
        cumul_bias[valid_grid]
        / n_obs[valid_grid]
    )

    return (
        bias,
        cumul_bias,
        rmsd,
        cumul_sq_diff,
        n_obs,
        lon_centers,
        lat_centers,
    )

def compute_grid_stats_2d(
    obs_lon,
    obs_lat,
    data1,
    data2,
    grid_resolution,
    threshold=None,
):
    """
    Compute statistics on a regular longitude/latitude grid.

    Parameters
    ----------
    obs_lon : ndarray
        Observation longitudes.
    obs_lat : ndarray
        Observation latitudes.
    data1 : ndarray
        Model values.
    data2 : ndarray
        Observation values.
    grid_resolution : float
        Grid resolution in degrees.
    threshold : float, optional
        Maximum allowed absolute difference.

    Returns
    -------
    bias : ndarray
        Mean bias per grid cell.
    cumul_bias : ndarray
        Sum of differences per grid cell.
    rmsd : ndarray
        RMSD per grid cell.
    cumul_sq_diff : ndarray
        Sum of squared differences per grid cell.
    n_obs : ndarray
        Number of observations per grid cell.
    lon_centers : ndarray
        Longitude grid centers.
    lat_centers : ndarray
        Latitude grid centers.
    """

    obs_lon = np.asarray(obs_lon)
    obs_lat = np.asarray(obs_lat)
    data1 = np.asarray(data1)
    data2 = np.asarray(data2)

    diff = data1 - data2

    valid = (
        np.isfinite(obs_lon)
        & np.isfinite(obs_lat)
        & np.isfinite(data1)
        & np.isfinite(data2)
    )

    if threshold is not None:
        valid &= np.abs(diff) <= threshold

    obs_lon = obs_lon[valid]
    obs_lat = obs_lat[valid]
    diff = diff[valid]

    lon_edges = np.arange(
        -180.0,
        180.0 + grid_resolution,
        grid_resolution,
    )

    lat_edges = np.arange(
        -90.0,
        90.0 + grid_resolution,
        grid_resolution,
    )

    lon_centers = (
        lon_edges[:-1]
        + grid_resolution / 2.0
    )

    lat_centers = (
        lat_edges[:-1]
        + grid_resolution / 2.0
    )

    # Number of observations
    n_obs, _, _ = binned_statistic_2d(
        obs_lat,
        obs_lon,
        values=None,
        statistic="count",
        bins=[lat_edges, lon_edges],
    )

    # Cumulative bias
    cumul_bias, _, _ = binned_statistic_2d(
        obs_lat,
        obs_lon,
        values=diff,
        statistic="sum",
        bins=[lat_edges, lon_edges],
    )

    # Cumulative squared difference
    cumul_sq_diff, _, _ = binned_statistic_2d(
        obs_lat,
        obs_lon,
        values=diff ** 2,
        statistic="sum",
        bins=[lat_edges, lon_edges],
    )

    # Empty bins from statistic="sum" are NaN
    cumul_bias = np.nan_to_num(
        cumul_bias,
        nan=0.0,
    )

    cumul_sq_diff = np.nan_to_num(
        cumul_sq_diff,
        nan=0.0,
    )

    # RMSD
    rmsd = np.full(
        n_obs.shape,
        np.nan,
        dtype=float,
    )

    bias = np.full(
        n_obs.shape,
        np.nan,
        dtype=float,
    )

    valid_grid = n_obs > 0

    rmsd[valid_grid] = np.sqrt(
        cumul_sq_diff[valid_grid]
        / n_obs[valid_grid]
    )

    bias[valid_grid] = (
        cumul_bias[valid_grid]
        / n_obs[valid_grid]
    )

    return (
        bias,
        cumul_bias,
        rmsd,
        cumul_sq_diff,
        n_obs,
        lon_centers,
        lat_centers,
    )
