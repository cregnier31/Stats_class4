import numpy as np
import sys
import datetime
from copy import deepcopy
import numpy.ma as ma

__author__      = "L.ZAWADZKI"
__version__ = 0.1

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
