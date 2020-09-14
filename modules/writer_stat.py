import sys, os
from glob import glob
import numpy as np
import netCDF4
from netCDF4 import Dataset
import cl4_reader
import datetime as dt
from numba import jit
from timeit import default_timer as timer

########################################################
#     Class Writer to write output file in NetCDF
########################################################
__version__ = 0.1
__date__  = "February 2019"
__author__ = "C.SZCZYPTA"

@jit
def _compute_percentile(nb_fcst, nb_layers, nb_vars, stat_bias, nb_obs, stat_percent, params_conf):

    for fcst in range(nb_fcst):
        for dep in range(nb_layers):
            for v in range(nb_vars):
                w = np.where(nb_obs[:,fcst,dep,v] == params_conf['missing_value'])
                nb_obs[w,fcst,dep,v] = np.nan 
                nb_obs_tot = np.nansum(nb_obs[:,fcst,dep,v])
                if nb_obs_tot == 0. or np.isnan(nb_obs_tot): continue
                mat_tmp = np.nan*np.zeros((int(nb_obs_tot)))
                ini=0
                for t in range(len(nb_obs[:,fcst,dep,v])):
                    if np.isnan(nb_obs[t,fcst,dep,v]): continue
                    for nbo in range(int(nb_obs[t,fcst,dep,v])):
                        mat_tmp[ini] = stat_bias[t,fcst,dep,v]
                        ini+=1

                stat_percent[fcst,dep,0, v] = np.nanmean(mat_tmp)
                stat_percent[fcst,dep,1, v] = np.percentile(mat_tmp, 99)
                stat_percent[fcst,dep,2, v] = np.percentile(mat_tmp, 1)
                stat_percent[fcst,dep,3, v] = np.percentile(mat_tmp, 95)
                stat_percent[fcst,dep,4, v] = np.percentile(mat_tmp, 5)
                stat_percent[fcst,dep,5, v] = np.percentile(mat_tmp, 75)
                stat_percent[fcst,dep,6, v] = np.percentile(mat_tmp, 25)

    return stat_percent


class writer_stat():

    """ Class to write different type of file """


    def compute_percentile(self, nb_fcst, nb_layers, nb_vars, stat_bias, nb_obs, stat_percent, params_conf):
        stat_percent = _compute_percentile(nb_fcst, nb_layers, nb_vars, stat_bias, nb_obs, stat_percent, params_conf)

        return stat_percent

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #             WRITE DAILY BIO STATS IN NETCDF FILE
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_BIO_files(self,filename,contact, product, fmt, dstart, dend, resultsFileName,
                        institution, ref, areas, start_jdate, end_jdate,
                        cla_metricname,fcst, layer,vtime, stat, CMEMS_area, cla_vars, params_conf):


        nc_fid = netCDF4.Dataset(filename, 'w')

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', 1)
        nc_fid.createDimension('time', None)

        #  ********************** Add variables ************************

        if CMEMS_area == True:
            nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_area_name = nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)

        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
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
        for ind, variable in enumerate(cla_vars):
            if variable ==  'CHL' or variable == 'chl':
                nc_CHL = nc_fid.createVariable('stats_chl-a','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_CHL.parameter = 'log10-chlorophyll'
                nc_CHL.reference = 'Observations of ocean color from satellite-born instrument'
                nc_CHL.units = 'mg/m3'
                nc_CHL.long_name = 'Logarithm (base 10) of chlorophyll-a concentration'
                nc_fid.variables['stats_chl-a'][:] = stat[:,:,:,:,:,ind]

        #  ********************** Add global attributes ************************

        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.start_date = dstart
        nc_fid.end_date = dend
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()


    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #      WRITE BIO STATS (computed over the whole considered period) IN NETCDF FILE
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_BIO_bilan(self,filename,contact, product, fmt, resultsFileName, institution, ref, areas,
                        cla_metricname,fcst, layer, stat, CMEMS_area, cla_vars, params_conf):

        nc_fid = netCDF4.Dataset(filename, 'w')

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', 1)

        #  ********************** Add variables ************************

        if CMEMS_area == True:
            nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_area_name = nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)

        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
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
        for ind, variable in enumerate(cla_vars):
            if variable ==  'CHL' or variable == 'chl':
                nc_CHL = nc_fid.createVariable('stats_chl-a','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_CHL.parameter = 'log10-chlorophyll'
                nc_CHL.reference = 'Observations of ocean color from satellite-born instrument'
                nc_CHL.units = 'mg/m3'
                nc_CHL.long_name = 'Logarithm (base 10) of chlorophyll-a concentration'
                nc_fid.variables['stats_chl-a'][:] = stat[:,:,:,:,ind]

        #  ********************** Add global attributes ************************

        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()


    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #               WRITE DAILY PHYS STATS IN NETCDF FILE
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_PHYS_files(self, filename, contact, product, fmt, dstart, dend, resultsFileName, institution,
                         ref, areas, start_jdate, end_jdate, cla_metricname,
                         fcst, layer, vtime, stat, surf_layer, CMEMS_area, cla_vars, params_conf):


        nc_fid = netCDF4.Dataset(filename, 'w')


        #  ********************** Add dimensions ************************

        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', len(surf_layer[0:-1]))
        nc_fid.createDimension('time', None)

        #  ********************** Add variables ************************


        if CMEMS_area == True:
            nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_area_name = nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)

        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
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
        nc_time.valid_min = str(start_jdate)
        nc_time.valid_max = str(end_jdate)
        nc_time.calendar = 'gregorian'
        nc_time.long_name = 'validity time'
        nc_time.standard_name = 'time'
        nc_time.units = 'hours since 1950-01-01 00:00:00'
        nc_time.axis = 'T'
        nc_fid.variables['time'][:] = vtime
        for ind, variable in enumerate(cla_vars):
            index = ind
            print ('Write variable {} '.format(variable))
            if variable ==  'TEMP':
                nc_temp = nc_fid.createVariable('stats_temperature','f', ('time','forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_temp.parameter = 'Temperature'
                nc_temp.reference = 'Profile observations from in-situ TAC'
                nc_temp.units = 'Kelvin'
                nc_fid.variables['stats_temperature'][:] = stat[:,:,:,:,:,index]
            if variable ==  'PSAL':
                nc_sal = nc_fid.createVariable('stats_salinity','f', ('time','forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sal.parameter = 'Salinity'
                nc_sal.reference = 'Profile observations from in-situ TAC'
                nc_sal.units = '1e-3'
                nc_fid.variables['stats_salinity'][:] = stat[:,:,:,:,:,index]
            if variable ==  'SLA':
                nc_sla = nc_fid.createVariable('stats_sla','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sla.parameter = 'Sea Level Anomaly'
                nc_sla.reference = 'Profile observations from in-situ TAC'
                nc_sla.units = 'meters'
                nc_fid.variables['stats_sla'][:] = stat[:,:,0,:,:,index]
            if variable ==  'SST':
                nc_sst = nc_fid.createVariable('stats_sst','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sst.parameter = 'Sea Surface Temperature'
                nc_sst.reference = 'Profile observations from in-situ TAC'
                nc_sst.units = 'Kelvin'
                nc_fid.variables['stats_sst'][:] = stat[:,:,0,:,:,index]
            if variable ==  'aice':
                nc_aice = nc_fid.createVariable('stats_seaice-concentration','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_aice.parameter = 'Sea ice concentration'
                nc_aice.reference = 'Observations from AMSR2 satellite'
                nc_aice.units = '1'
                nc_fid.variables['stats_seaice-concentration'][:] = stat[:,:,0,:,:,index]
            if variable ==  'UVEL':
                nc_uvel = nc_fid.createVariable('stats_zonal-velocity','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_uvel.parameter = 'Zonal velocity at 15m depth'
                nc_uvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_uvel.units = 'm s-1'
                nc_fid.variables['stats_zonal-velocity'][:] = stat[:,:,0,:,:,index]
            if variable ==  'VVEL':
                nc_vvel = nc_fid.createVariable('stats_meridional-velocity','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_vvel.parameter = 'Meridional velocity at 15m depth'
                nc_vvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_vvel.units = 'm s-1'
                nc_fid.variables['stats_meridional-velocity'][:] = stat[:,:,0,:,:,index]

        #  ********************** Add global attributes ************************

        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.start_date = dstart
        nc_fid.end_date = dend
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()


    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #      WRITE PHYS STATS (computed over the whole considered period) IN NETCDF FILE
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_PHYS_bilan(self,filename,contact, product, fmt, resultsFileName, institution,
                         ref, areas, cla_metricname,
                         fcst, layer, stat, surf_layer, CMEMS_area, cla_vars, params_conf):


        nc_fid = netCDF4.Dataset(filename, 'w')

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', len(surf_layer[0:-1]))

        #  ********************** Add variables ************************

        if CMEMS_area == True:
            nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_area_name = nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)

        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
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
        for ind, variable in enumerate(cla_vars):
            print ('Write variable {} '.format(variable))
            index = ind
            if variable ==  'PSAL':
                nc_sal = nc_fid.createVariable('stats_salinity','f', ('forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sal.parameter = 'Salinity'
                nc_sal.reference = 'Profile observations from in-situ TAC'
                nc_sal.units = '1e-3'
                nc_fid.variables['stats_salinity'][:] = stat[:,:,:,:,index]
            if variable ==  'TEMP':
                nc_temp = nc_fid.createVariable('stats_temperature','f', ('forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_temp.parameter = 'Temperature'
                nc_temp.reference = 'Profile observations from in-situ TAC'
                nc_temp.units = 'Kelvin'
                nc_fid.variables['stats_temperature'][:] = stat[:,:,:,:,index]
            if variable ==  'SLA':
                nc_sla = nc_fid.createVariable('stats_sla','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sla.parameter = 'Sea Level Anomaly'
                nc_sla.reference = 'Profile observations from in-situ TAC'
                nc_sla.units = 'meters'
                nc_fid.variables['stats_sla'][:] = stat[:,0,:,:,index]
            if variable ==  'SST':
                nc_sst = nc_fid.createVariable('stats_sst','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sst.parameter = 'Sea Surface Temperature'
                nc_sst.reference = 'Profile observations from in-situ TAC'
                nc_sst.units = 'Kelvin'
                nc_fid.variables['stats_sst'][:] = stat[:,0,:,:,index]
            if variable ==  'aice':
                nc_aice = nc_fid.createVariable('stats_seaice-concentration','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_aice.parameter = 'Sea ice concentration'
                nc_aice.reference = 'Observations from AMSR2 satellite'
                nc_aice.units = '1'
                nc_fid.variables['stats_seaice-concentration'][:] = stat[:,0,:,:,index]
            if variable ==  'UVEL':
                nc_uvel = nc_fid.createVariable('stats_zonal-velocity','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_uvel.parameter = 'Zonal velocity at 15m depth'
                nc_uvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_uvel.units = 'm s-1'
                nc_fid.variables['stats_zonal-velocity'][:] = stat[:,0,:,:,index]
            if variable ==  'VVEL':
                nc_vvel = nc_fid.createVariable('stats_meridional-velocity','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_vvel.parameter = 'Meridional velocity at 15m depth'
                nc_vvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_vvel.units = 'm s-1'
                nc_fid.variables['stats_meridional-velocity'][:] = stat[:,0,:,:,index]

        #  ********************** Add global attributes ************************

        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()


    def write_PHYS_bilan_skill(self,filename,contact, product, fmt, resultsFileName, institution,
                         ref, areas, fcst, layer, stat, surf_layer, CMEMS_area, cla_vars, params_conf):


        nc_fid = netCDF4.Dataset(filename, 'w')

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('string_length15', 15)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', 2)
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', len(surf_layer[0:-1]))

        #  ********************** Add variables ************************

        if CMEMS_area == True:
            nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_area_name = nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)

        tab_fcst={}
        tab_fcst["skill_1D"] = 12
        tab_fcst["skill_2D"] = 36
        tab_fcst["skill_3D"] = 60
        tab_fcst["skill_4D"] = 84
        tab_fcst["skill_5D"] = 108
        tab_fcst["skill_6D"] = 132
        tab_fcst["skill_7D"] = 156
        tab_fcst["skill_8D"] = 180
        tab_fcst["skill_9D"] = 208
        tab_fcst["skill_10D"] = 232
        rla_forecast_ref=[]
        for i in range(len(fcst)):
            rla_forecast_ref.append(tab_fcst[str(fcst[i])])
        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
        nc_metric_name = nc_fid.createVariable('metric_names','c',('metrics','string_length15'))
        nc_metric_name.long_name = 'metric names'
        cla_metricname = np.chararray(2, itemsize=15)
        cla_metricname[0]='PSS_skill_score'
        cla_metricname[1]='CSS_skill_score'
        nc_fid.variables['metric_names'][:] = netCDF4.stringtochar(np.array(cla_metricname))
        nc_fcst = nc_fid.createVariable('forecasts', 'f', ('forecasts'))
        nc_fcst.long_name = 'forecast lead time'
        nc_fcst.units = 'hours'
        nc_fid.variables['forecasts'][:] = rla_forecast_ref
        nc_depth = nc_fid.createVariable('depths','f', ('depths'))
        nc_depth.long_name = 'depths'
        nc_depth.positive = 'down'
        nc_depth.units = 'm'
        nc_depth.description = 'depth of the base of the vertical layer over which statistics are aggregated'
        nc_fid.variables['depths'][:] = layer[1:]
        for ind, variable in enumerate(cla_vars):
            index = ind
            print ('Write variable {} '.format(variable))
            if variable ==  'PSAL':
                nc_sal = nc_fid.createVariable('skill_salinity','f', ('forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sal.parameter = 'Salinity'
                nc_sal.reference = 'Profile observations from in-situ TAC'
                nc_sal.units = '1e-3'
                nc_fid.variables['skill_salinity'][:] = stat[:,:,:,:,index]
            if variable ==  'TEMP':
                nc_temp = nc_fid.createVariable('skill_temperature','f', ('forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_temp.parameter = 'Temperature'
                nc_temp.reference = 'Profile observations from in-situ TAC'
                nc_temp.units = 'Kelvin'
                nc_fid.variables['skill_temperature'][:] = stat[:,:,:,:,index]
            if variable ==  'SLA':
                nc_sla = nc_fid.createVariable('skill_sla','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sla.parameter = 'Sea Level Anomaly'
                nc_sla.reference = 'Profile observations from in-situ TAC'
                nc_sla.units = 'meters'
                nc_fid.variables['skill_sla'][:] = stat[:,0,:,:,index]
            if variable ==  'SST':
                nc_sst = nc_fid.createVariable('skill_sst','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sst.parameter = 'Sea Surface Temperature'
                nc_sst.reference = 'Profile observations from in-situ TAC'
                nc_sst.units = 'Kelvin'
                nc_fid.variables['skill_sst'][:] = stat[:,0,:,:,index]
            if variable ==  'aice':
                nc_aice = nc_fid.createVariable('skill_seaice-concentration','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_aice.parameter = 'Sea ice concentration'
                nc_aice.reference = 'Observations from AMSR2 satellite'
                nc_aice.units = '1'
                nc_fid.variables['skill_seaice-concentration'][:] = stat[:,0,:,:,index]
            if variable ==  'UVEL':
                nc_uvel = nc_fid.createVariable('stats_zonal-velocity','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_uvel.parameter = 'Zonal velocity at 15m depth'
                nc_uvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_uvel.units = 'm s-1'
                nc_fid.variables['stats_zonal-velocity'][:] = stat[:,0,:,:,index]
            if variable ==  'VVEL':
                nc_vvel = nc_fid.createVariable('stats_meridional-velocity','f', ('forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_vvel.parameter = 'Meridional velocity at 15m depth'
                nc_vvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_vvel.units = 'm s-1'
                nc_fid.variables['stats_meridional-velocity'][:] = stat[:,0,:,:,index]

        #  ********************** Add global attributes ************************

        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #                         WRITE DAILY STATS IN TMP FILES
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_daily_files(self, filename, areas, cla_metricname, fcst, layer, stat, CMEMS_area, lead_time, params_conf):

        nc_fid = netCDF4.Dataset(filename, 'w')


        #  ********************** Add dimensions ************************

        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('string_length14', 14)
        nc_fid.createDimension('leadtime', len(lead_time))


        #  ********************** Add variables ************************

        if CMEMS_area == True:
            nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)
        nc_fid.createVariable('metric_names','c',('metrics','string_length'))
        nc_fid.variables['metric_names'][:] = netCDF4.stringtochar(np.array(cla_metricname))
        nc_fid.createVariable('lead_time','c',('leadtime','string_length14'))
        nc_fid.variables['lead_time'][:] = netCDF4.stringtochar(np.array(lead_time))
        nc_fid.createVariable('forecast','f', ('forecasts'))
        nc_fid.variables['forecast'][:] = fcst
        nc_fid.createVariable('depths','f', ('depths'))
        nc_fid.variables['depths'][:] = layer[1:]
        nc_fid.createVariable('stat_var','f', ('forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
        nc_fid.variables['stat_var'][:] = stat
        nc_fid.close()

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #                         WRITE DAILY STATS IN TMP FILES
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_glob_files_area(self, filename, cla_metricname, fcst, layer, stat, lead_time, params_conf):

        nc_fid = netCDF4.Dataset(filename, 'w')

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('string_length14', 14)
        nc_fid.createDimension('leadtime', len(lead_time))


        #  ********************** Add variables ************************

        nc_fid.createVariable('metric_names','c',('metrics','string_length'))
        nc_fid.variables['metric_names'][:] = netCDF4.stringtochar(np.array(cla_metricname))
        nc_fid.createVariable('lead_time','c',('leadtime','string_length14'))
        nc_fid.variables['lead_time'][:] = netCDF4.stringtochar(np.array(lead_time))
        nc_fid.createVariable('forecast','f', ('forecasts'))
        nc_fid.variables['forecast'][:] = fcst
        nc_fid.createVariable('depths','f', ('depths'))
        nc_fid.variables['depths'][:] = layer[1:]
        nc_fid.createVariable('stat_var','f', ('forecasts','depths','metrics'), fill_value = params_conf['missing_value'])
        nc_fid.variables['stat_var'][:] = stat
        nc_fid.close()


    def write_glob_files_area_skill(self, filename, layer, PSS_stat, CSS_stat, params_conf):

        nc_fid = netCDF4.Dataset(filename, 'w')
        lead_time = ['skill_1D', 'skill_3D', 'skill_5D', 'skill_7D', 'skill_9D']

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('string_length8', 8)
        nc_fid.createDimension('leadtime', len(lead_time))


        #  ********************** Add variables ************************

        nc_fid.createVariable('lead_time','c',('leadtime','string_length8'))
        nc_fid.variables['lead_time'][:] = lead_time[:]
        nc_fid.createVariable('depths','f', ('depths'))
        nc_fid.variables['depths'][:] = layer[1:]
        nc_fid.createVariable('skill_PSS_var','f', ('leadtime','depths'), fill_value = params_conf['missing_value'])
        nc_fid.variables['skill_PSS_var'][:] = PSS_stat
        nc_fid.createVariable('skill_CSS_var','f', ('leadtime','depths'), fill_value = params_conf['missing_value'])
        nc_fid.variables['skill_CSS_var'][:] = CSS_stat
        nc_fid.close()

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #             WRITE STATS IN ASCII FORMAT FILE (DAILY TIME STEP)
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    def write_ASCII_files(self, dirout, modele, stat, tab_prof, areas, yout, vtime, cla_metricname, varname, cl_start_date, cl_end_date):

        for a, ar in enumerate(areas) :
            for dep, prof in enumerate(tab_prof[:-1]) :
                ASCII_tab = np.zeros((4+yout*4, len(vtime)))
                ASCII_tab[0,:] = vtime/24
                metric = np.where(np.array(cla_metricname) == 'number of data values')[0][0]
                ASCII_tab[1,:] = stat[:,0,dep,metric,a]
                metric = np.where(np.array(cla_metricname) == 'mean of reference')[0][0]
                ASCII_tab[2,:] = stat[:,0,dep,metric,a]
                metric = np.where(np.array(cla_metricname) == 'mean squared reference')[0][0]
                ASCII_tab[3,:] = stat[:,0,dep,metric,a]
                il_var = 4
                fmt_type = '%10.2f  %10.1f  %10.7f  %10.7f  '
                for dset in range(yout):
                    fmt_type = fmt_type + '%10.7f  %10.7f  %10.7f  %10.7f  '
                    metric = np.where(np.array(cla_metricname) == 'mean of product')[0][0]
                    ASCII_tab[il_var,:] = stat[:,dset,dep,metric,a]
                    il_var += 1
                    metric = np.where(np.array(cla_metricname) == 'mean squared product')[0][0]
                    ASCII_tab[il_var,:] = stat[:,dset,dep,metric,a]
                    il_var += 1
                    metric = np.where(np.array(cla_metricname) == 'mean squared error')[0][0]
                    ASCII_tab[il_var,:] = stat[:,dset,dep,metric,a]
                    il_var += 1
                    metric = np.where(np.array(cla_metricname) == 'anomaly correlation')[0][0]
                    ASCII_tab[il_var,:] = stat[:,dset,dep,metric,a]
                    il_var += 1

                ASCII_tab = ASCII_tab.transpose()
                cprof = '%i-%im'%(np.int(prof),np.int(tab_prof[dep+1]))
                filename = os.path.join(dirout, 'MYO2_product_quality_'+modele+'_'+ar+'_'+cl_start_date+'_'+cl_end_date+'_'+varname+'_'+cprof+'.txt')
                np.savetxt(filename,ASCII_tab,fmt=fmt_type)



    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #             WRITE STATS IN ASCII FORMAT FILE (WHOLE PERIOD)
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    def write_ASCII_bilan(self, dirout, modele, stat, tab_prof, areas, yout, cla_metricname, varname, cl_start_date, cl_end_date):


        for a, ar in enumerate(areas) :
            for dep, prof in enumerate(tab_prof[:-1]) :
                ASCII_tab = np.zeros((2+yout*4))
                metric = np.where(np.array(cla_metricname) == 'mean of reference')[0][0]
                ASCII_tab[0] = stat[0,dep,metric,a]
                metric = np.where(np.array(cla_metricname) == 'mean squared reference')[0][0]
                ASCII_tab[1] = stat[0,dep,metric,a]
                il_var = 2
                for dset in range(yout):
                    metric = np.where(np.array(cla_metricname) == 'mean of product')[0][0]
                    ASCII_tab[il_var] = stat[dset,dep,metric,a]
                    il_var += 1
                    metric = np.where(np.array(cla_metricname) == 'mean squared product')[0][0]
                    ASCII_tab[il_var] = stat[dset,dep,metric,a]
                    il_var += 1
                    metric = np.where(np.array(cla_metricname) == 'mean squared error')[0][0]
                    ASCII_tab[il_var] = stat[dset,dep,metric,a]
                    il_var += 1
                    metric = np.where(np.array(cla_metricname) == 'anomaly correlation')[0][0]
                    ASCII_tab[il_var] = stat[dset,dep,metric,a]
                    il_var += 1

                cprof = '%i-%im'%(np.int(prof),np.int(tab_prof[dep+1]))
                filename = os.path.join(dirout, 'Global_mean_quality_stats_'+modele+'_'+str(ar)+'_'+cl_start_date+'_'+cl_end_date+'_'+varname+'_'+cprof+'.txt')
                np.savetxt(filename,ASCII_tab,fmt='%10.7f')


    def write_percent_files(self, filename, cla_metricname, fcst, layer, stat, lead_time, cla_vars, params_conf):

        nc_fid = netCDF4.Dataset(filename, 'w')

        #  ********************** Add dimensions ************************

        nc_fid.createDimension('metrics', len(cla_metricname))
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('string_length14', 14)
        nc_fid.createDimension('leadtime', len(lead_time))


        #  ********************** Add variables ************************

        nc_fid.createVariable('metric_names','c',('metrics','string_length'))
        nc_fid.variables['metric_names'][:] = netCDF4.stringtochar(np.array(cla_metricname))
        nc_fid.createVariable('lead_time','c',('leadtime','string_length14'))
        nc_fid.variables['lead_time'][:] = netCDF4.stringtochar(np.array(lead_time))
        nc_fid.createVariable('forecast','f', ('forecasts'))
        nc_fid.variables['forecast'][:] = fcst
        nc_fid.createVariable('depths','f', ('depths'))
        nc_fid.variables['depths'][:] = layer[1:]
        for ind, variable in enumerate(cla_vars):
            index = ind
            print ('Write variable {} '.format(variable))
            if variable ==  'TEMP':
                nc_temp = nc_fid.createVariable('stats_temperature','f', ('forecasts','depths','metrics'), fill_value = params_conf['missing_value'])
                nc_temp.parameter = 'Temperature'
                nc_temp.units = 'Kelvin'
                nc_fid.variables['stats_temperature'][:] = stat[:,:,:,index]
            if variable ==  'PSAL':
                nc_sal = nc_fid.createVariable('stats_salinity','f', ('forecasts','depths','metrics'), fill_value = params_conf['missing_value'])
                nc_sal.parameter = 'Salinity'
                nc_sal.units = '1e-3'
                nc_fid.variables['stats_salinity'][:] = stat[:,:,:,index]
        nc_fid.close()


    def write_stats_daily(self, params_conf, \
                          cla_vars, rla_layers, rla_surface, log):
        """
            Output writer to save all the daily statistics for a period of time
            Arguments
            --------------------------------
            run_ini:
            params_conf: input params dictionnary
            cvar: input variable
            datex: input experience
            dirout: output directory
        """

        run_ini = True

        # ************************** Time vector **********************************

        dateCNESref   = dt.datetime.strptime('19500101','%Y%m%d').toordinal()
        ndays = len(params_conf['cla_dates'])
        vector_time = np.zeros((ndays))
        for il_ind, day in enumerate(params_conf['cla_dates']):
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref)*24

        log.info("SAVE RESULTS IN A SINGLE FILE")

        nb_fcst_max = 0

        #*  First loop to count the number of max leadtimes
        for numvar, cvar in enumerate(cla_vars):

            # *************** Listing fichiers CLASS4 ***************
            for datex in params_conf['cla_dates']:
                log.info(datex)
                cl_file = cvar+'_'+datex+'.nc'
                cla_filechck = glob(os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_file))
                if len(cla_filechck) != 1:
                    log.info("missing file %s" %(datex))
                    continue
                else: cl_cl4file = cla_filechck[0]
                stat_tmp, rla_forecast, aname, lead_time = cl4_reader.read_NC_tmp(cl_cl4file)
                if 'forecast' in lead_time:
                    tmp1 = np.where(rla_forecast == params_conf['missing_value'], 0, rla_forecast)
                    nb_fcst = len(np.where(np.array(tmp1) > 0)[0])
                    if nb_fcst > nb_fcst_max:
                        nb_fcst_max = nb_fcst
                        rla_forecast_tmp = rla_forecast[:]
                        nb_lead_max=len(rla_forecast_tmp)
                else:
                    rla_forecast_tmp = []
                    nb_lead_max =  len(rla_forecast)

        log.info('nb_lead_max  {}'.format(nb_lead_max))

        for numvar, cvar in enumerate(cla_vars):

            # *************** Listing fichiers CLASS4 ***************

            for datex in params_conf['cla_dates']:
                log.info(datex)
                cl_file = cvar+'_'+datex+'.nc'
                cla_filechck = glob(os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_file))
                if len(cla_filechck) != 1:
                    log.info("missing file %s" %(datex))
                    continue
                else: cl_cl4file = cla_filechck[0]
                stat_day = np.where(np.asarray(params_conf['cla_dates']) == datex)[0][0]
                stat_tmp, rla_forecast, aname, lead_time = cl4_reader.read_NC_tmp(cl_cl4file)

                if 'forecast' in lead_time:
                    tmp1 = np.where(rla_forecast == params_conf['missing_value'], 0, rla_forecast)
                    nb_fcst = len(np.where(np.array(tmp1) > 0)[0])

                if params_conf['CMEMS_area'] == True:
                    aname = params_conf['cla_area_names']
                    name_ascii = params_conf['cla_areaini']
                else:
                    name_ascii = aname

                if run_ini == True:
                    #stat_all = np.nan*np.zeros((len(params_conf['cla_dates']), len(rla_forecast), len(rla_layers[0:-1]),\
                    #                            len(params_conf['cla_metricname']), len(aname),\
                    #                            len(cla_vars)))
                    stat_all = np.nan*np.zeros((len(params_conf['cla_dates']), nb_lead_max, len(rla_layers[0:-1]),\
                                                len(params_conf['cla_metricname']), len(aname),\
                                                len(cla_vars)))
                    leadtime_ref = []
                    if 'best_estimate' in lead_time: leadtime_ref.append('best_estimate')
                    if 'forecast' in lead_time:
                       # for f in range(nb_fcst):
                        for f in range(nb_fcst_max):
                            leadtime_ref.append('forecast')
                    if 'persistence' in lead_time:
                      #  for f in range(nb_fcst):
                        for f in range(nb_fcst_max):
                            leadtime_ref.append('persistence')
                    if 'climatology' in lead_time: leadtime_ref.append('climatology')
                    rla_forecast_ref = rla_forecast_tmp
                    run_ini = False

                ## Log
                log.info('Len leadtime_ref {}'.format(len(leadtime_ref)))
                ##
                ldt_ref = np.chararray(len(leadtime_ref), itemsize=14)

                for l in range(len(leadtime_ref)):
                    ldt_ref[l] = str(leadtime_ref[l])

                if len(stat_tmp[0,:,0,0]) > 1:
                    if stat_all[stat_day,:,:,:,:,numvar].shape == stat_tmp.shape:
                        stat_all[stat_day,:,:,:,:,numvar] = stat_tmp
                    else:
                        for y, lt in enumerate(lead_time):
                            w = np.where(ldt_ref == lt)[0][0]
                            if lt not in ['forecast','persistence']:
                                stat_all[stat_day,w,:,:,:,numvar] = stat_tmp[y,:,:,:]
                            else:
                                stat_all[stat_day,w:w+nb_fcst,:,:,:,numvar] = stat_tmp[y:y+nb_fcst,:,:,:]
                    tab_prof = rla_layers
                else:
                    if stat_all[stat_day,:,0:1,:,:,numvar].shape == stat_tmp.shape:
                        stat_all[stat_day,:,0:1,:,:,numvar] = stat_tmp
                    else:
                        for y, lt in enumerate(lead_time):
                            w = np.where(ldt_ref == lt)[0][0]

                            if lt not in ['forecast','persistence']:
                                stat_all[stat_day,w,0:1,:,:,numvar] = stat_tmp[y,:,:,:]
                            else:
                                stat_all[stat_day,w:w+nb_fcst,0:1,:,:,numvar] = stat_tmp[y:y+nb_fcst,:,:,:]
                    tab_prof = rla_surface

                del stat_tmp

            if params_conf['fmt_ascii'] == 'on':
                writer_stat().write_ASCII_files(params_conf['dirASCIIout'], params_conf['config_model'], stat_all[:,:,:,:,:,numvar], \
                                                tab_prof, name_ascii, len(rla_forecast_ref), vector_time, \
                                                params_conf['cla_metricname'], cvar, params_conf['cl_start_date'],\
                                                cl_end_date)


        # **********************  Save stats in netCDF format  **********************

        w = np.where(np.isnan(stat_all) == True)
        stat_all[w] = params_conf['missing_value']
        w = np.where(stat_all > params_conf['missing_value'])
        stat_all[w] = params_conf['missing_value']

        if params_conf['percent'] == 'off':
            cl_resultsFileName = params_conf['prefix_fileout']+params_conf['cl_confres']+'_'+\
                params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'.nc'
            cl_resultsFile = os.path.join(params_conf['dirout'],cl_resultsFileName)


            # **************************  Write **********************************

            if params_conf['cexp'] == 'BIO':
                writer_stat().write_BIO_files(cl_resultsFile, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],\
                                              params_conf['cl_start_date'], params_conf['cl_end_date'],
                                              cl_resultsFileName, params_conf['cl_institution'], params_conf['cl_ref'], aname,
                                              params_conf['cl_start_jdate'], params_conf['cl_end_jdate'], params_conf['cla_metricname'], rla_forecast_ref,
                                              rla_surface, vector_time, stat_all, params_conf['CMEMS_area'], cla_vars, params_conf)
                del stat_all

            elif params_conf['cexp'] == 'PHYS':
                writer_stat().write_PHYS_files(cl_resultsFile, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],\
                                               params_conf['cl_start_date'], params_conf['cl_end_date'],\
                                               cl_resultsFileName, params_conf['cl_institution'], params_conf['cl_ref'], aname,
                                               params_conf['cl_start_jdate'], params_conf['cl_end_jdate'], params_conf['cla_metricname'], rla_forecast_ref,
                                               rla_layers, vector_time, stat_all, rla_surface, params_conf['CMEMS_area'], cla_vars, params_conf)
                del stat_all

        else:
            return stat_all, rla_forecast, aname, lead_time
        

    def write_stats_BOX(self, params_conf, cla_vars,\
                        rla_layers, rla_surface, rla_maskvalues):

        """
            Write stats for global bins
            input:
            run_ini: index run
            params_conf: params configuration
            cla_vars: input variables
            output:
        """
 
        run_ini = True

        for numvar, cvar in enumerate(cla_vars):

            # *************** Listing fichiers CLASS4 ***************

            for a, area_mask in enumerate(params_conf['cla_area']):
                cl_file = 'glob_mean_quality_stats_'+cvar+'_'+str(area_mask)+'_'+params_conf['cl_start_date']+\
                          '_'+params_conf['cl_end_date']+'.nc'
                cla_filechck = glob(os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_file))
                if len(cla_filechck) != 1: continue
                else: cl_cl4file = cla_filechck[0]

                stat_tmp, rla_forecast, aname, lead_time = cl4_reader.read_NC_tmp(cl_cl4file)

                if run_ini == True:
                    stat_bilan = np.nan*np.zeros((len(rla_forecast), len(rla_layers[0:-1]),\
                                                  len(params_conf['cla_metricname']), len(params_conf['cla_area']),\
                                                  len(cla_vars)))
                run_ini = False

                if len(stat_tmp[0,:,0]) > 1:
                    stat_bilan[:,:,:,a,numvar] = stat_tmp
                    tab_prof = rla_layers
                else:
                    stat_bilan[:,0:1,:,a,numvar] = stat_tmp
                    tab_prof = rla_surface

                del stat_tmp


            if params_conf['fmt_ascii'] == 'on':
                writer_stat().write_ASCII_bilan(params_conf['dirASCIIout'], params_conf['config_model'], stat_bilan[:,:,:,:,numvar], \
                                                tab_prof, params_conf['cla_area'], len(rla_forecast), \
                                                params_conf['cla_metricname'], cvar, params_conf['cl_start_date'],\
                                                param_conf['cl_end_date'])


        # **********************  Save stats in netCDF format  **********************

        w = np.where(np.isnan(stat_bilan) == True)
        stat_bilan[w] = params_conf['missing_value']
        w = np.where(stat_bilan > params_conf['missing_value'])
        stat_bilan[w] = params_conf['missing_value']

        cl_resultsFileName_bilan = 'glob_mean_quality_stats_'+params_conf['cl_confres']+'_'+\
                                    params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'.nc'
        if params_conf['ll_arc'] :
            cl_resultsFileName_bilan = 'glob_mean_quality_stats_NH_polar_' +\
            params_conf['cl_confres']+'_'+params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'.nc'
        if params_conf['ll_ant']:
            cl_resultsFileName_bilan = 'glob_mean_quality_stats_SH_polar_'+\
                                    params_conf['cl_confres']+'_'+params_conf['cl_start_date']+\
                                    '_'+params_conf['cl_end_date']+'.nc'
        cl_resultsFile_bilan = os.path.join(params_conf['dirout'],cl_resultsFileName_bilan)


        # **************************  Write **********************************

        if params_conf['CMEMS_area'] == True:
            aname = params_conf['cla_area_names']
        else:
            aname = np.arange((len(np.array(rla_maskvalues))))

        if params_conf['cexp'] == 'BIO':
            writer_stat().write_BIO_bilan(cl_resultsFile_bilan, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],
                                          cl_resultsFileName_bilan, params_conf['cl_institution'], params_conf['cl_ref'], aname,
                                          params_conf['cla_metricname'][:], rla_forecast, rla_surface,
                                          stat_bilan[:,:,:,:,:], params_conf['CMEMS_area'], cla_vars, params_conf)

        if params_conf['cexp'] == 'PHYS':
            writer_stat().write_PHYS_bilan(cl_resultsFile_bilan, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],
                                           cl_resultsFileName_bilan, params_conf['cl_institution'], params_conf['cl_ref'], aname,
                                           params_conf['cla_metricname'][:], rla_forecast, rla_layers,
                                           stat_bilan[:,:,:,:,:], rla_surface, params_conf['CMEMS_area'], cla_vars, params_conf)

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_stats_BOX_skill(self, params_conf, cla_vars,\
                        rla_layers, rla_surface, rla_maskvalues):

        """
            Write stats for global bins
            input:
            run_ini: index run
            params_conf: params configuration
            cla_vars: input variables
            output:
        """

        run_ini = True

        for numvar, cvar in enumerate(cla_vars):

            # *************** Listing fichiers CLASS4 ***************

            for a, area_mask in enumerate(params_conf['cla_area']):
                cl_file = 'glob_mean_quality_stats_'+cvar+'_'+str(area_mask)+'_'+params_conf['cl_start_date']+\
                          '_'+params_conf['cl_end_date']+'_skill.nc'
                cla_filechck = glob(os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_file))
                if len(cla_filechck) != 1: continue
                else: cl_cl4file = cla_filechck[0]

                stat_PSS_skill, stat_CSS_skill, area_names, leadtime = cl4_reader.read_NC_skill_tmp(cl_cl4file)

                if run_ini == True:
                    stat_bilan = np.nan*np.zeros((len(leadtime), len(rla_layers[0:-1]),\
                                                  2, len(params_conf['cla_area']),\
                                                  len(cla_vars)))
                run_ini = False

                if len(stat_PSS_skill[0,:]) > 1:
                    stat_bilan[:,:,0,a,numvar] = stat_PSS_skill
                    stat_bilan[:,:,1,a,numvar] = stat_CSS_skill
                    tab_prof = rla_layers
                else:
                    stat_bilan[:,0:1,0,a,numvar] = stat_PSS_skill
                    stat_bilan[:,0:1,1,a,numvar] = stat_CSS_skill
                    tab_prof = rla_surface

                del stat_PSS_skill, stat_CSS_skill

        # **********************  Save stats in netCDF format  **********************

        w = np.where(np.isnan(stat_bilan) == True)
        stat_bilan[w] = params_conf['missing_value']
        w = np.where(stat_bilan > params_conf['missing_value'])
        stat_bilan[w] = params_conf['missing_value']

        cl_resultsFileName_bilan = 'glob_mean_quality_stats_'+params_conf['cl_confres']+'_'+\
                                    params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'_skill.nc'
        cl_resultsFile_bilan = os.path.join(params_conf['dirout'],cl_resultsFileName_bilan)


        # **************************  Write **********************************

        if params_conf['CMEMS_area'] == True:
            aname = params_conf['cla_area_names']
        else:
            aname = np.arange((len(np.array(rla_maskvalues))))

        if params_conf['cexp'] == 'BIO':
            writer_stat().write_BIO_bilan(cl_resultsFile_bilan, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],
                                          cl_resultsFileName_bilan, params_conf['cl_institution'], params_conf['cl_ref'], aname,
                                          params_conf['cla_metricname'][:], rla_forecast, rla_surface,
                                          stat_bilan[:,:,:,:,:], params_conf['CMEMS_area'], cla_vars, params_conf)

        if params_conf['cexp'] == 'PHYS':
            writer_stat().write_PHYS_bilan_skill(cl_resultsFile_bilan, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],
                                           cl_resultsFileName_bilan, params_conf['cl_institution'], params_conf['cl_ref'], aname,
                                           leadtime, rla_layers, stat_bilan[:,:,:,:,:], rla_surface, params_conf['CMEMS_area'], cla_vars, params_conf)

     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_daily_skill(self, filename, layer, areas, tab_PSS_skill, tab_CSS_skill, CMEMS_area, nb_fcst, params_conf):
        """
            Write Skill scores files
        """
        nc_fid = netCDF4.Dataset(filename, 'w')

        lead_time_type = ['skill_1D', 'skill_3D', 'skill_5D', 'skill_7D', 'skill_9D']
        nfcst = nb_fcst//2
        lead_time = lead_time_type[0:nb_fcst]
        #  ********************** Add dimensions ***********************
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('string_length8', 8)
        nc_fid.createDimension('leadtime', len(lead_time))
        #  ********************** Add variables ************************
        if CMEMS_area == True:
            nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_fid.createVariable('area_names',int,('areas'))

        nc_fid.createVariable('lead_time','c',('leadtime','string_length8'))
        #nc_fid.variables['lead_time'][:] = lead_time[:]
        nc_fid.variables['lead_time'][0:len(lead_time)] = lead_time[:]
        nc_fid.createVariable('depths','f', ('depths'))
        nc_fid.variables['depths'][:] = layer[1:]
        nc_fid.createVariable('skill_PSS_var','f', ('leadtime','depths','areas'), fill_value = params_conf['missing_value'])
        #nc_fid.variables['skill_PSS_var'][:] = tab_PSS_skill
        nc_fid.variables['skill_PSS_var'][0:len(lead_time)] = tab_PSS_skill
        nc_fid.createVariable('skill_CSS_var','f', ('leadtime','depths','areas'), fill_value = params_conf['missing_value'])
        #nc_fid.variables['skill_CSS_var'][:] = tab_CSS_skill
        nc_fid.variables['skill_CSS_var'][0:len(lead_time)] = tab_CSS_skill
        nc_fid.close()

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_stats_daily_skill(self, params_conf, \
                          cla_vars, rla_layers, rla_surface, log):
        """
            Output writer to save all the daily statistics for a period of time
            Arguments
            --------------------------------
            run_ini:
            params_conf: input params dictionnary
        """
        run_ini = True

        # ************************** Time vector **********************************

        dateCNESref   = dt.datetime.strptime('19500101','%Y%m%d').toordinal()
        ndays = len(params_conf['cla_dates'])
        vector_time = np.zeros((ndays))
        for il_ind, day in enumerate(params_conf['cla_dates']):
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref)*24

        log.info("SAVE Skill RESULTS IN A SINGLE FILE")
        nb_lead_max = 0

        # Count the number of leadtime
        for numvar, cvar in enumerate(cla_vars):
            for datex in params_conf['cla_dates']:
                cl_file = cvar+'_skill_scores_'+datex+'.nc'

                cla_filechck = glob(os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_file))
                if len(cla_filechck) != 1: continue
                else: cl_cl4file = cla_filechck[0]

                stat_PSS_skill, stat_CSS_skill, area_names, leadtime = cl4_reader.read_NC_skill_tmp(cl_cl4file)
                if len(leadtime) > nb_lead_max:
                    leadtime_tmp = leadtime
                    nb_lead_max = len(leadtime)


        for numvar, cvar in enumerate(cla_vars):

            # *************** Listing fichiers CLASS4 ***************

            for datex in params_conf['cla_dates']:
                cl_file = cvar+'_skill_scores_'+datex+'.nc'

                cla_filechck = glob(os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_file))
                if len(cla_filechck) != 1: continue
                else: cl_cl4file = cla_filechck[0]

                stat_day = np.where(np.asarray(params_conf['cla_dates']) == datex)[0][0]
                stat_PSS_skill, stat_CSS_skill, area_names, leadtime = cl4_reader.read_NC_skill_tmp(cl_cl4file)

                if run_ini == True:
                    stat_all = np.nan*np.zeros((len(params_conf['cla_dates']), nb_lead_max, len(rla_layers[0:-1]),\
                                                2, len(area_names), len(cla_vars)))
                run_ini = False

                if params_conf['CMEMS_area'] == True:
                    area_names = params_conf['cla_area_names']
                if len(stat_PSS_skill[0,:,0]) > 1:
                    stat_all[stat_day,0:len(leadtime),:,0,:,numvar] = stat_PSS_skill
                    stat_all[stat_day,0:len(leadtime),:,1,:,numvar] = stat_CSS_skill
                    tab_prof = rla_layers
                else:
                    stat_all[stat_day,0:len(leadtime),0:1,0,:,numvar] = stat_PSS_skill
                    stat_all[stat_day,0:len(leadtime),0:1,1,:,numvar] = stat_CSS_skill
                    tab_prof = rla_surface
                del stat_PSS_skill, stat_CSS_skill

        # **********************  Save stats in netCDF format  **********************

        w = np.where(np.isnan(stat_all) == True)
        stat_all[w] = params_conf['missing_value']
        w = np.where(stat_all > params_conf['missing_value'])
        stat_all[w] = params_conf['missing_value']
        cl_resultsFileName = params_conf['prefix_fileout']+params_conf['cl_confres']+'_'+\
            params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'_skills.nc'
        cl_resultsFile = os.path.join(params_conf['dirout'],cl_resultsFileName)
        tab_fcst={}
        tab_fcst["skill_1D"] = 12
        tab_fcst["skill_2D"] = 36
        tab_fcst["skill_3D"] = 60
        tab_fcst["skill_4D"] = 84
        tab_fcst["skill_5D"] = 108
        tab_fcst["skill_6D"] = 132
        tab_fcst["skill_7D"] = 156
        tab_fcst["skill_8D"] = 180
        tab_fcst["skill_9D"] = 208
        tab_fcst["skill_10D"] = 232
        rla_forecast_ref=[]
        #for i in range(len(leadtime)):
        for i in range(len(leadtime_tmp)):
            rla_forecast_ref.append(tab_fcst[str(leadtime[i])])
        rla_forecast_ref = np.array(rla_forecast_ref)
        if params_conf['cexp'] == 'PHYS':
            writer_stat().write_PHYS_files_skill(cl_resultsFile, params_conf['cl_contact'], params_conf['cl_confres'], params_conf['cl_fmt'],\
                                           params_conf['cl_start_date'], params_conf['cl_end_date'],\
                                           cl_resultsFileName, params_conf['cl_institution'], params_conf['cl_ref'], area_names,
                                           params_conf['cl_start_jdate'], params_conf['cl_end_jdate'], params_conf['cla_metricname'], rla_forecast_ref,
                                           rla_layers, vector_time, stat_all, rla_surface, params_conf['CMEMS_area'], cla_vars, params_conf)
        del stat_all


    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_PHYS_files_skill(self,filename,contact, product, fmt, dstart, dend, resultsFileName, institution,
                         ref, areas, start_jdate, end_jdate, cla_metricname,
                         fcst, layer, vtime, stat, surf_layer, CMEMS_area, cla_vars, params_conf):


        nc_fid = netCDF4.Dataset(filename, 'w')


        #  ********************** Add dimensions ************************

        nc_fid.createDimension('string_length', 25)
        nc_fid.createDimension('string_length2', 15)
        nc_fid.createDimension('areas', len(areas))
        nc_fid.createDimension('metrics', 2)
        nc_fid.createDimension('forecasts', len(fcst))
        nc_fid.createDimension('depths', len(layer[0:-1]))
        nc_fid.createDimension('surface', len(surf_layer[0:-1]))
        nc_fid.createDimension('time', None)

        #  ********************** Add variables ************************

        if CMEMS_area == True:
            nc_area_name = nc_fid.createVariable('area_names','c',('areas','string_length'))
            nc_fid.variables['area_names'][:] = netCDF4.stringtochar(np.array(areas))
        else:
            nc_area_name = nc_fid.createVariable('area_names',int,('areas'))
            nc_fid.variables['area_names'][:] = np.array(areas)

        nc_area_name.long_name = 'area names'
        nc_area_name.description = 'region over which statistics are aggregated'
        nc_metric_name = nc_fid.createVariable('metric_names','c',('metrics','string_length2'))
        nc_metric_name.long_name = 'metric names'
        cla_metricname = ['PSS_skill_score','CSS_skill_score']
        cla_metricname = np.chararray(2, itemsize=15)
        cla_metricname[1]='CSS_skill_score'
        cla_metricname[0]='PSS_skill_score'
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
        nc_time.valid_min = str(start_jdate)
        nc_time.valid_max = str(end_jdate)
        nc_time.calendar = 'gregorian'
        nc_time.long_name = 'validity time'
        nc_time.standard_name = 'time'
        nc_time.units = 'hours since 1950-01-01 00:00:00'
        nc_time.axis = 'T'
        nc_fid.variables['time'][:] = vtime
        for ind, variable in enumerate(cla_vars):
            index = ind
            print ('Write variable {} '.format(variable))
            if variable ==  'TEMP':
                nc_temp = nc_fid.createVariable('skill_temperature','f', ('time','forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_temp.parameter = 'Temperature'
                nc_temp.reference = 'Profile observations from in-situ TAC'
                nc_temp.units = 'Kelvin'
                nc_fid.variables['skill_temperature'][:] = stat[:,:,:,:,:,index]
            if variable ==  'PSAL':
                nc_sal = nc_fid.createVariable('skill_salinity','f', ('time','forecasts','depths','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sal.parameter = 'Salinity'
                nc_sal.reference = 'Profile observations from in-situ TAC'
                nc_sal.units = '1e-3'
                nc_fid.variables['skill_salinity'][:] = stat[:,:,:,:,:,index]
            if variable ==  'SLA':
                nc_sla = nc_fid.createVariable('skill_sla','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sla.parameter = 'Sea Level Anomaly'
                nc_sla.reference = 'Profile observations from in-situ TAC'
                nc_sla.units = 'meters'
                nc_fid.variables['skill_sla'][:] = stat[:,:,0,:,:,index]
            if variable ==  'SST':
                nc_sst = nc_fid.createVariable('skill_sst','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_sst.parameter = 'Sea Surface Temperature'
                nc_sst.reference = 'Profile observations from in-situ TAC'
                nc_sst.units = 'Kelvin'
                nc_fid.variables['skill_sst'][:] = stat[:,:,0,:,:,index]
            if variable ==  'aice':
                nc_aice = nc_fid.createVariable('skill_seaice-concentration','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_aice.parameter = 'Sea ice concentration'
                nc_aice.reference = 'Observations from AMSR2 satellite'
                nc_aice.units = '1'
                nc_fid.variables['skill_seaice-concentration'][:] = stat[:,:,0,:,:,index]
            if variable ==  'UVEL':
                nc_uvel = nc_fid.createVariable('skill_zonal-velocity','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_uvel.parameter = 'Zonal velocity at 15m depth'
                nc_uvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_uvel.units = 'm s-1'
                nc_fid.variables['skill_zonal-velocity'][:] = stat[:,:,0,:,:,index]
            if variable ==  'VVEL':
                nc_vvel = nc_fid.createVariable('skill_meridional-velocity','f', ('time','forecasts','surface','metrics','areas'), fill_value = params_conf['missing_value'])
                nc_vvel.parameter = 'Meridional velocity at 15m depth'
                nc_vvel.reference = 'Observations from AOML, CMEMS hourly product INSITU_GLO_NRT_OBSERVATIONS_013_048'
                nc_vvel.units = 'm s-1'
                nc_fid.variables['skill_meridional-velocity'][:] = stat[:,:,0,:,:,index]

        #  ********************** Add global attributes ************************

        nc_fid.contact = contact
        nc_fid.product = product
        nc_fid.start_date = dstart
        nc_fid.end_date = dend
        nc_fid.filename = resultsFileName
        nc_fid.institution = institution
        nc_fid.references = ref
        nc_fid.format = fmt
        nc_fid.close()



