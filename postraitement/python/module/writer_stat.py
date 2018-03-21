import os,sys,string,shutil,glob,re
import numpy as np
import netCDF4
from netCDF4 import Dataset
from datetime import date


########################################################
#                C.SZCZYPTA NOV 2017
#     Class Writer to write output file in NetCDF
########################################################

class writer_stat():

    """ Class to write different type of file """

    def write_BIO_files(self,filename,contact, product, fmt, dstart, dend, resultsFileName,
                        institution, ref, areas, metric,start_jdate, end_jdate,
                        cla_areasattr, cla_metricname,fcst, layer,vtime, stat):
        
        nc_fid = netCDF4.Dataset(filename, 'w')

        #  Add dimensions
        # ----------------
        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(metric))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', 1)
        nc_fid.createDimension('time', None)

        #  Add variables
        # ---------------
        nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
        nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(cla_areasattr))
        nc_metric_name = nc_fid.createVariable('metric_names','c',('metrics','string_length'))
        nc_metric_name.long_name = 'metric names'
        nc_fid.variables['metric_names'][:] = netCDF4.stringtochar(np.array(cla_metricname))
        nc_fcst = nc_fid.createVariable('forecasts', 'f', ('forecasts'))
        nc_fcst.long_name = 'forecast lead time'
        nc_fcst.units = 'hours'
        nc_fid.variables['forecasts'][:] = fcst
        nc_depth = nc_fid.createVariable('depths','f', ('depths'))
        nc_depth.long_name = 'depths'
        nc_depth.positive = 'down'
        nc_depth.units = 'm'
        nc_depth.description = 'depth of the base of the vertical layer over which statistics are aggregated'
        nc_fid.variables['depths'][:] = layer[0:-1]
        nc_time = nc_fid.createVariable('time','f', ('time'))
        nc_time.valid_min = start_jdate 
        nc_time.valid_max = end_jdate
        nc_time.calendar = 'gregorian'
        nc_time.long_name = 'validity time'
        nc_time.standard_name = 'time'
        nc_time.units = 'hours since 1950-01-01 00:00:00'
        nc_time.axis = 'T'
        nc_fid.variables['time'][:] = vtime
        nc_CHL = nc_fid.createVariable('stats_chl-a','f', ('time','forecasts','surface','metrics','areas'), fill_value = 999999.)
        nc_CHL.parameter = 'log10-chlorophyll'
        nc_CHL.reference = 'Observations of ocean color from satellite-born instrument'
        nc_CHL.units = 'mg/m3'
        nc_CHL.long_name = 'Logarithm (base 10) of chlorophyll-a concentration'
        nc_fid.variables['stats_chl-a'][:] = stat[:,:,:,:,:,0]

        #  Add global attributes
        # ----------------------
        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.start_date = dstart
        nc_fid.end_date = dend
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()


    def write_PHYS_files(self,filename,contact, product, fmt, dstart, dend, resultsFileName, institution,
                         ref, areas, metric,start_jdate, end_jdate, cla_areasattr, cla_metricname,
                         fcst, layer, vtime, stat, surf_layer):


        nc_fid = netCDF4.Dataset(filename, 'w')

        #  Add dimensions
        # ----------------
        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(metric))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', len(surf_layer[0:-1]))
        nc_fid.createDimension('time', None)

        #  Add variables
        # ---------------
        nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
        nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(cla_areasattr))
        nc_metric_name = nc_fid.createVariable('metric_names','c',('metrics','string_length'))
        nc_metric_name.long_name = 'metric names'
        nc_fid.variables['metric_names'][:] = netCDF4.stringtochar(np.array(cla_metricname))
        nc_fcst = nc_fid.createVariable('forecasts', 'f', ('forecasts'))
        nc_fcst.long_name = 'forecast lead time'
        nc_fcst.units = 'hours'
        nc_fid.variables['forecasts'][:] = fcst
        nc_depth = nc_fid.createVariable('depths','f', ('depths'))
        nc_depth.long_name = 'depths'
        nc_depth.positive = 'down'
        nc_depth.units = 'm'
        nc_depth.description = 'depth of the base of the vertical layer over which statistics are aggregated'
        nc_fid.variables['depths'][:] = layer[1:]
        nc_time = nc_fid.createVariable('time','f', ('time'))
        nc_time.valid_min = start_jdate 
        nc_time.valid_max = end_jdate
        nc_time.calendar = 'gregorian'
        nc_time.long_name = 'validity time'
        nc_time.standard_name = 'time'
        nc_time.units = 'hours since 1950-01-01 00:00:00'
        nc_time.axis = 'T'
        nc_fid.variables['time'][:] = vtime
        nc_temp = nc_fid.createVariable('stats_temperature','f', ('time','forecasts','depths','metrics','areas'), fill_value = 999999.)
        nc_temp.parameter = 'Temperature'
        nc_temp.reference = 'Profile observations from in-situ TAC'
        nc_temp.units = 'Kelvin'
        nc_fid.variables['stats_temperature'][:] = stat[:,:,:,:,:,1]
        nc_sal = nc_fid.createVariable('stats_salinity','f', ('time','forecasts','depths','metrics','areas'), fill_value = 999999.)
        nc_sal.parameter = 'Salinity'
        nc_sal.reference = 'Profile observations from in-situ TAC'
        nc_sal.units = '1e-3'
        nc_fid.variables['stats_salinity'][:] = stat[:,:,:,:,:,0]
        nc_sla = nc_fid.createVariable('stats_sla','f', ('time','forecasts','surface','metrics','areas'), fill_value = 999999.)
        nc_sla.parameter = 'Sea Level Anomaly'
        nc_sla.reference = 'Profile observations from in-situ TAC'
        nc_sla.units = 'meters'
        nc_fid.variables['stats_sla'][:] = stat[:,:,0,:,:,2]
        nc_sst = nc_fid.createVariable('stats_sst','f', ('time','forecasts','surface','metrics','areas'), fill_value = 999999.)
        nc_sst.parameter = 'Sea Surface Temperature'
        nc_sst.reference = 'Profile observations from in-situ TAC'
        nc_sst.units = 'Kelvin'
        nc_fid.variables['stats_sst'][:] = stat[:,:,0,:,:,3]


        #  Add global attributes
        # ----------------------
        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.start_date = dstart
        nc_fid.end_date = dend
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()
