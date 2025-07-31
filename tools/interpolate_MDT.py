# for the plot
from lib_pyt.plot.class_plot_map import PlotMapCartopy as map2D
from lib_pyt.interp.interpolator import interpolator_2D
from datetime import datetime
from netCDF4 import Dataset
import numpy as np
import netCDF4
import xarray as xr

def create_netcdf(outnc, lon, lat, tab_var):

     # Define global attributes
     reference = 'http://marine.copernicus.eu'
     author = 'Mercator Ocean International'
     attrs = {'creation_date':str(datetime.now()),
              'author':author,
              'references':reference
             }
     missing_value = netCDF4.default_fillvals['f4']
     # Create netcdf
     dict_tab = {}
     dict_tab["mssh"] = (('lat', 'lon'), tab_var,
                          {'units':'m',
                           'long_name' : 'Mean dynamic topography',
                           'standard_name': 'sea_surface_height_above_geoid',
                           '_FillValue':missing_value})
     dict_coords = define_coords(lon, lat)
     ds = xr.Dataset(data_vars=dict_tab,
                     coords=dict_coords,
                     attrs=attrs)
     print (f'Create {outnc}')
     ds = ds.fillna(netCDF4.default_fillvals['f4'])
     ds.to_netcdf(outnc, encoding=None, unlimited_dims=None, format='NETCDF4')


def define_coords(lon, lat):
    # Define the time range and frequency
    # Create a monthly time coordinate for the middle of the month
    dict_coords = {}
    dict_coords = {'longitude':(["lat", "lon"], lon,
                       {'valid_min':np.nanmin(lon),
                        'valid_max':np.nanmax(lon),
                        '_FillValue': False,
                        'units':'degrees_east',
                        'unit_long': 'Degrees East',
                        'standard_name' : 'longitude',
                        'axis' : 'X'
                       }),
                       'latitude':(["lat", "lon"], lat,
                             {'valid_min':np.nanmin(lat),
                              'valid_max':np.nanmax(lat),
                              '_FillValue': False,
                              'units':'degrees_north',
                              'unit_long': 'Degrees North',
                              'standard_name' : 'latitude',
                              'axis' : 'Y'
                        })
                    }
    return dict_coords

SYSTEM = "GLONET14"
SYSTEM = "WENHAI"
#SYSTEM = "GLONET"
resol = "1deg"
resol = "025deg"
nbpts_interp = 1
file_in = "/data/rd_exchange/cregnier/static//MDT/HYBRID_MSSH_V5_ORCA12_r1.nc"
#file_in = "/data/rd_exchange/cregnier/static//MDT/GLO-MFC_001_030_mdt.nc"
#file_out = "/data/rd_exchange/cregnier/SORT/GLONET//fcst1/GLONET_2024-01-05_all.nc"
file_out = f"/data/rd_exchange/cregnier/SORT/GLONET_14//fcst1/{SYSTEM}_2024-01-05_all.nc"
path_weight = '/data/rd_exchange/cregnier/TMP/'
weight_file = f'{path_weight}{SYSTEM}_mdt_{resol}_nbpts{nbpts_interp}.p'
dir_out = "/data/rd_exchange/cregnier/static/"
variable = 'mssh'
# Interp options
x1 = 'longitude'
x2 = 'longitude'
y1 = 'latitude'
y2 = 'latitude'
ll_save = True
tab_out, lon, lat = interpolator_2D(x1, x2, y1, y2, file_in,\
                                    file_out, weight_file,
                                    nbpts_interp, variable, save=True)

print('ok')
sys.exit(1)
if ll_save:
    print(f'Save interp file')
    #outnc = f'{dir_out}GLO-MFC_001_030_mdt_{resol}.nc'
    outnc = f'{dir_out}GLO-MFC_{SYSTEM}_mdt_{resol}.nc'
    create_netcdf(outnc, lon, lat, tab_out)

