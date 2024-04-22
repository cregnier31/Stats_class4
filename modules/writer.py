# coding: utf8
# toutes les chaines sont en unicode (même les docstrings)
#from __future__ import unicode_literals
import netCDF4
from netCDF4 import Dataset
import numpy as np
import datetime
import json
import fcntl
import errno

def write_cl4_files_2(filename, latitude, longitude, observations,\
        observation_filt, best, forecast, persistence, time, u_qc, v_qc, depth_qc,\
        position_qc, time_qc,nb_fcst, model):
    variables=['eastward_velocity ','northward_velocity']
    lead_time=[0, 24, 48, 72, 96, 120, 144, 168, 192, 216]
    fillvalue=-9999
    fillvalue_b=-128
    fillvalue_s=-32767
    nb_obs, nb_vars, nb_depths = np.shape(observations)

    nc_fid = netCDF4.Dataset(filename, 'w')
    nc_dims=['numobs','numvars','numdeps','numfcsts','string_length']
    nc_fid.createDimension('numobs', None)
    #nc_fid.createDimension('numobs', nb_obs)
    nc_fid.createDimension('numvars', nb_vars)
    nc_fid.createDimension('numdeps', nb_depths)
    nc_fid.createDimension('numfcsts', nb_fcst)
    nc_fid.createDimension('string_length', 18)
    nc_fid.createDimension('string32', 32)
    nc_lon = nc_fid.createVariable('longitude','f4',('numobs'))
    nc_lon.setncatts({'long_name': u"Longitudes",\
                                'units': u"degrees_east"})
    nc_lat = nc_fid.createVariable('latitude', 'f4',('numobs'))
    nc_lat.setncatts({'long_name': u"Latitudes",\
                                'units': u"degrees_north"})
    nc_time = nc_fid.createVariable('obs_time', 'f4',('numobs'))
    nc_time.setncatts({'long_name': u"data inversion time",\
            'units': u"hours since 1950-01-01T00:00:00Z"})
    nc_time.standard_name = 'time'
    nc_time.calendar = 'gregorian'
    nc_time.axis = 'T'
    nc_time.valid_min = np.nanmin(time)
    nc_time.valid_max = np.nanmax(time)
    nc_depth_qc  = nc_fid.createVariable('depth_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_depth_qc.long_name =  "Depth quality flag"
    nc_depth_qc.valid_min = 0
    nc_depth_qc.valid_max = 9
    nc_depth_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_depth_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_time_qc  = nc_fid.createVariable('time_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_time_qc.long_name =  "Time quality flag"
    nc_time_qc.valid_min = 0
    nc_time_qc.valid_max = 9
    nc_time_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_time_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_position_qc  = nc_fid.createVariable('position_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_position_qc.long_name =  "Position quality flag"
    nc_position_qc.valid_min = 0
    nc_position_qc.valid_max = 9
    nc_position_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_position_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_lead= nc_fid.createVariable('leadtime', 'f4',('numfcsts'))
    nc_lead.setncatts({'long_name': u"Model forecast day offset",\
                                'units': u"Hours"})
    nc_var = nc_fid.createVariable('varname', 'S1',('numvars','string_length'))
    nc_var.setncatts({'long_name': u"name of variables"})
    nc_obs = nc_fid.createVariable('observation','f4',('numobs','numvars', 'numdeps'),fill_value=fillvalue)
    nc_obs = nc_fid.createVariable('observation_filt','f4',('numobs','numvars', 'numdeps'),fill_value=fillvalue)
    nc_obs.setncatts({'long_name': u"currents from in situ drifters",\
                                'units': u"m s-1"})#,\
    nc_obs_filt = nc_fid.createVariable('observation_filt','f4',('numobs','numvars', 'numdeps'),fill_value=fillvalue)
    nc_obs_filt.setncatts({'long_name': u"currents from in situ drifters filtered over 3 days",\
                                'units': u"m s-1"})#,\
    nc_best = nc_fid.createVariable('best_estimate','f4',('numobs','numvars','numdeps'),fill_value=fillvalue)
    nc_best.setncatts({'long_name': u"Model best_estimate counterpart of obs. value"})
    nc_best.setncatts({'long_name': u"Model best_estimate counterpart of obs. value",'units': u"m s-1"})
    nc_fcst = nc_fid.createVariable('forecast','f4',('numobs','numvars','numfcsts','numdeps'),fill_value=fillvalue)
    nc_fcst.setncatts({'long_name': u"Model forecast counterpart of obs. value",'units': u"m s-1"})
    nc_pers = nc_fid.createVariable('persistence','f4',('numobs','numvars','numfcsts','numdeps'),fill_value=fillvalue)
    nc_pers.setncatts({'long_name': u"Model persistence counterpart of obs. value",'units': u"m s-1"})

    nc_fid.variables['latitude'][:] = latitude
    nc_fid.variables['longitude'][:] = longitude
    nc_fid.variables['obs_time'][:] = time[:]
    observations[np.isnan(observations)] = fillvalue
    nc_fid.variables['observation'][:,:,:] = observations
    nc_fid.variables['observation_filt'][:,:,:] = observations
    nc_fid.variables['leadtime'][:] = lead_time[:]
    nc_fid.variables['varname'][:] = netCDF4.stringtochar(np.array(variables))
    best[np.isnan(best)] = fillvalue
    nc_fid.variables['best_estimate'][:,:,:] = best[:,:,:]
    forecast[np.isnan(forecast)] = fillvalue
    nc_fid.variables['forecast'][:,:,:,:] = forecast[:,:,:,:]
    persistence[np.isnan(persistence)] = fillvalue
    nc_fid.variables['persistence'][:,:,:,:] = forecast[:,:,:,:]
    depth_qc[np.isnan(depth_qc)] = fillvalue_b
    nc_fid.variables['depth_qc'][:] = depth_qc[:]
    time_qc[np.isnan(time_qc)] = fillvalue_b
    nc_fid.variables['time_qc'][:] = time_qc[:]
    u_qc[np.isnan(u_qc)] = fillvalue_b
    v_qc[np.isnan(v_qc)] = fillvalue_b
    nc_fid.variables['obs_qc'][:,0]= u_qc[:]
    nc_fid.variables['obs_qc'][:,1]= v_qc[:]
    position_qc[np.isnan(position_qc)] = fillvalue_b
    nc_fid.variables['position_qc'][:]= position_qc[:]
    ## Add global attributs
    nc_fid.institution= 'MERCATOR OCEAN'
    nc_fid.contact= 'cregnier@mercator-ocean.fr'
    nc_fid.obs_type='Drifting buoys drogued at 15m depth'
    nc_fid.time_interp = "daily average fields" ;
    nc_fid.description = "Drifting buoys from CMEMS product INSITU_GLO_NRT_OBSERVATIONS_013_030"

def write_cl4_files(filename, latitude, longitude, id_drift, observations,\
        best, forecast, persistence, stokes, tides, smoc,\
        time, u_qc, v_qc, depth, depth_qc,\
        current_test, current_test_qc, position_qc, time_qc,\
        dc_reference, u_wind, v_wind, clim, nb_fcst, model, cmems_prod):

    variables=['eastward_velocity ','northward_velocity']
    lead_time=[0, 24, 48, 72, 96, 120, 144, 168, 192, 216]
    fillvalue=-9999
    fillvalue_b=-128
    fillvalue_s=-32767
    nb_obs, nb_vars, nb_depths = np.shape(observations)
    nc_fid = None
    nc_fid = netCDF4.Dataset(filename, 'w')
    #nc_dims=['numobs','numvars','numdeps','numfcsts','string_length']
    nc_fid.createDimension('numobs', None)
    #nc_fid.createDimension('numobs', nb_obs)
    nc_fid.createDimension('numvars', nb_vars)
    nc_fid.createDimension('numdeps', nb_depths)
    nc_fid.createDimension('numfcsts', nb_fcst)
    nc_fid.createDimension('string_length', 18)
    nc_fid.createDimension('string35', 35)
    nc_lon = nc_fid.createVariable('longitude','f4',('numobs'))
    nc_lon.setncatts({'long_name': u"Longitudes",\
                                'units': u"degrees_east"})
    nc_lat = nc_fid.createVariable('latitude', 'f4',('numobs'))
    nc_lat.setncatts({'long_name': u"Latitudes",\
                                'units': u"degrees_north"})
    nc_time = nc_fid.createVariable('obs_time', 'f4',('numobs'))
    nc_time.setncatts({'long_name': u"data inversion time",\
            'units': u"hours since 1950-01-01T00:00:00Z"})
    nc_time.standard_name = 'time'
    nc_time.calendar = 'gregorian'
    nc_time.axis = 'T'
    nc_time.valid_min = np.nanmin(time)
    nc_time.valid_max = np.nanmax(time)
    nc_depth  = nc_fid.createVariable('depth', 'f4',('numobs','numdeps'),fill_value=fillvalue)
    nc_depth.long_name =  "Depth"
    nc_depth.standard_name = "depth"
    nc_depth.valid_min = -12000.
    nc_depth.valid_max = 12000
    nc_depth.axis = "Z"
    nc_depth.positive = "down"
    nc_depth_qc  = nc_fid.createVariable('depth_qc', 'i1',('numobs','numdeps'),fill_value=fillvalue_b)
    nc_depth_qc.long_name =  "Depth quality flag"
    nc_depth_qc.valid_min = 0
    nc_depth_qc.valid_max = 9
    nc_depth_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_depth_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_time_qc  = nc_fid.createVariable('time_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_time_qc.long_name =  "Time quality flag"
    nc_time_qc.valid_min = 0
    nc_time_qc.valid_max = 9
    nc_time_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_time_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_position_qc  = nc_fid.createVariable('position_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_position_qc.long_name =  "Position quality flag"
    nc_position_qc.valid_min = 0
    nc_position_qc.valid_max = 9
    nc_position_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_position_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_current_test_qc =  nc_fid.createVariable('current_test_qc','i1',('numobs', 'numdeps'),fill_value=fillvalue_b)
    nc_current_test_qc.long_name = "quality flag of current test"
    nc_current_test_qc.valid_min = 0
    nc_current_test_qc.valid_max = 9
    nc_current_test_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_current_test_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_current_qc  = nc_fid.createVariable('obs_qc', 'i1',('numobs', 'numvars'), fill_value=fillvalue_b)
    nc_current_qc.long_name =  "Observation current quality flag"
    nc_current_qc.valid_min = 0
    nc_current_qc.valid_max = 9
    nc_current_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_current_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_dcref = nc_fid.createVariable('dc_reference','c',('numobs','string35'))
    nc_dcref.long_name = "Station/Location unique identifier in data centre"
    nc_dcref.conventions = "Data centre convention"
    nc_wind = nc_fid.createVariable('wdst_model','f4',('numobs', 'numvars'),fill_value=fillvalue)
    nc_wind.long_name = "6-hour integrated wind stress from ECMWF model interpolated at the drifter's position"
    nc_wind.units = "newton/m2"
    nc_current_test = nc_fid.createVariable('current_test','i2',('numobs','numdeps'),fill_value=fillvalue_s)
    nc_current_test.long_name = "Flag tests of drogue loss results"
    nc_current_test.description ="3 flags for 3 tests : Submersion Acceleration_buoy Wind-current-corr"
    nc_current_test.flag_values = "0, 1, 2, 3"
    nc_current_test.flag_meanings = "Drogue_probably_missing Test_not_performed Weak_probability_of_drogue_presence Strong_probability_of_drogue_presence"
    nc_lead= nc_fid.createVariable('leadtime', 'f4',('numfcsts'))
    nc_lead.setncatts({'long_name': u"Model forecast day offset",\
                                'units': u"Hours"})
    nc_indice = nc_fid.createVariable('id_drifter', 'i4',('numobs'))
    nc_indice.setncatts({'long_name': u"Id of the drifter",\
                                'units': u"None"})
    nc_var = nc_fid.createVariable('varname', 'S1',('numvars','string_length'))
    nc_var.setncatts({'long_name': u"name of variables"})
    nc_obs = nc_fid.createVariable('observation','f4',('numobs','numvars','numdeps'),fill_value=fillvalue)
    nc_obs.setncatts({'long_name': u"currents from in situ drifters",\
                                'units': u"m s-1"})#,\
    nc_best = nc_fid.createVariable('best_estimate','f4',('numobs','numvars','numdeps'),fill_value=fillvalue)
    nc_best.setncatts({'long_name': u"Model best_estimate counterpart of obs. value",'units': u"m s-1"})
    nc_fcst = nc_fid.createVariable('forecast','f4',('numobs','numvars','numfcsts','numdeps'),fill_value=fillvalue)
    nc_fcst.setncatts({'long_name': u"Model forecast counterpart of obs. value",'units': u"m s-1"})
    nc_pers = nc_fid.createVariable('persistence','f4',('numobs','numvars','numfcsts','numdeps'),fill_value=fillvalue)
    nc_pers.setncatts({'long_name': u"Model persistence counterpart of obs. value",'units': u"m s-1"})
    nc_clim = nc_fid.createVariable('climatology','f4',('numobs','numvars','numdeps'),fill_value=fillvalue)
    nc_clim.setncatts({'long_name': u"Climatology Lumpkin V3.05",'units': u"m s-1"})
    nc_clim.setncatts({'comment': u"Monthly Means of Drifter Data"})

    nc_stokes = nc_fid.createVariable('stokes_drift','f4',('numobs','numvars'),fill_value=fillvalue)
    nc_stokes.setncatts({'long_name': u"Eastward and Northward wave-induced velocity (Stokes drift)",'units': u"m s-1"})
    nc_stokes.description = "MFWAM waves model for Stokes drift - GLOBAL_ANALYSIS_FORECAST_WAV_001_027 CMEMS dataset"

    nc_tides = nc_fid.createVariable('tide_current','f4',('numobs','numvars'),fill_value=fillvalue)
    nc_tides.setncatts({'long_name': u"Eastward and tide-induced velocity (Tide current)",'units': u"m s-1"})
    nc_tides.description = "FES2014 model at 1/12 for tides"

    nc_smoc = nc_fid.createVariable('smoc_drift','f4',('numobs','numvars'),fill_value=fillvalue)
    nc_smoc.setncatts({'long_name': u"Eastward and Northward total velocity (Eulerian + Waves + Tide) (smoc drift)",'units': u"m s-1"})
    nc_smoc.description = "GLOBAL_ANALYSIS_FORECAST_PHY_001_024 hourly mean merged surface currents from oceanic circulation, tides and waves"

    nc_fid.variables['latitude'][:] = latitude
    nc_fid.variables['longitude'][:] = longitude
    nc_fid.variables['obs_time'][:] = time[:]
    nc_fid.variables['depth'][:,:] = depth[:,:]
    observations[np.isnan(observations)] = fillvalue
    nc_fid.variables['observation'][:,:,:] = observations
    nc_fid.variables['id_drifter'][:] = id_drift[:]
    nc_fid.variables['leadtime'][:] = lead_time[:]
    nc_var[:] = netCDF4.stringtochar(np.array(variables, 'S'))
    best[np.isnan(best)] = fillvalue
    nc_fid.variables['best_estimate'][:,:,:] = best[:,:,:]
    forecast[np.isnan(forecast)] = fillvalue
    nc_fid.variables['forecast'][:,:,:,:] = forecast[:,:,:,:]
    persistence[np.isnan(persistence)] = fillvalue
    nc_fid.variables['persistence'][:,:,:,:] = forecast[:,:,:,:]
    clim[np.isnan(clim)] = fillvalue
    nc_fid.variables['climatology'][:,:,:] = clim[:,:,:]
    stokes[np.isnan(stokes)] = fillvalue
    nc_fid.variables['stokes_drift'][:,:] = stokes[:,:]
    tides[np.isnan(tides)] = fillvalue
    nc_fid.variables['tide_current'][:,:] = tides[:,:]
    smoc[np.isnan(smoc)] = fillvalue
    nc_fid.variables['smoc_drift'][:,:] = smoc[:,:]
    depth_qc[np.isnan(depth_qc)] = fillvalue_b
    nc_fid.variables['depth_qc'][:,:] = depth_qc[:,:]
    time_qc[np.isnan(time_qc)] = fillvalue_b
    nc_fid.variables['time_qc'][:] = time_qc[:]
    u_qc[np.isnan(u_qc)] = fillvalue_b
    v_qc[np.isnan(v_qc)] = fillvalue_b
    nc_fid.variables['obs_qc'][:,0]= u_qc[:]
    nc_fid.variables['obs_qc'][:,1]= v_qc[:]
    position_qc[np.isnan(position_qc)] = fillvalue_b
    nc_fid.variables['position_qc'][:]= position_qc[:]
    current_test_qc[np.isnan(current_test_qc)] = fillvalue_b
    nc_fid.variables['current_test_qc'][:]= current_test_qc[:]
    current_test[np.isnan(current_test)] = fillvalue_s
    nc_fid.variables['current_test'][:]= current_test[:]
    u_wind[np.isnan(u_wind)] = fillvalue
    v_wind[np.isnan(v_wind)] = fillvalue
    nc_fid.variables['wdst_model'][:,0] = u_wind[:]
    nc_fid.variables['wdst_model'][:,1] = v_wind[:]
    list_ref=[ref for ref in dc_reference]
    nc_fid.variables['dc_reference'][:] = netCDF4.stringtochar(np.array(list_ref))
    ## Add global attributs
    nc_fid.institution= 'MERCATOR OCEAN'
    nc_fid.contact= 'cregnier@mercator-ocean.fr'
    nc_fid.obs_type='Drifting buoys drogued at 15m depth'
    nc_fid.time_interp = "daily average fields" ;
    nc_fid.description = "Drifting buoys from CMEMS product INSITU_GLO_NRT_OBSERVATIONS_"+cmems_prod
    nc_fid.creation_date=str(datetime.date.today())
    nc_fid.system=model
    nc_fid.Conventions = 'CF-1.6'
    nc_fid.netcdf_version = '4'
    #print '-------------------------------'
    #print 'Creation OK %s ' %(filename)
    #print '-------------------------------'
    nc_fid.close()  # close the new file


####
def write_cl4_files_clim(filename, latitude, longitude, id_drift, observations,\
        time, u_qc, v_qc, depth, depth_qc,\
        current_test, current_test_qc, position_qc, time_qc,\
        dc_reference, u_wind, v_wind, clim, nb_fcst, model, cmems_prod):

    variables=['eastward_velocity ','northward_velocity']
    lead_time=[0, 24, 48, 72, 96, 120, 144, 168, 192, 216]
    fillvalue=-9999
    fillvalue_b=-128
    fillvalue_s=-32767
    nb_obs, nb_vars, nb_depths = np.shape(observations)
    nc_fid = None
    nc_fid = netCDF4.Dataset(filename, 'w')
    #nc_dims=['numobs','numvars','numdeps','numfcsts','string_length']
    nc_fid.createDimension('numobs', None)
    #nc_fid.createDimension('numobs', nb_obs)
    nc_fid.createDimension('numvars', nb_vars)
    nc_fid.createDimension('numdeps', nb_depths)
    nc_fid.createDimension('numfcsts', nb_fcst)
    nc_fid.createDimension('string_length', 18)
    nc_fid.createDimension('string32', 32)
    nc_lon = nc_fid.createVariable('longitude','f4',('numobs'))
    nc_lon.setncatts({'long_name': u"Longitudes",\
                                'units': u"degrees_east"})
    nc_lat = nc_fid.createVariable('latitude', 'f4',('numobs'))
    nc_lat.setncatts({'long_name': u"Latitudes",\
                                'units': u"degrees_north"})
    nc_time = nc_fid.createVariable('obs_time', 'f4',('numobs'))
    nc_time.setncatts({'long_name': u"data inversion time",\
            'units': u"hours since 1950-01-01T00:00:00Z"})
    nc_time.standard_name = 'time'
    nc_time.calendar = 'gregorian'
    nc_time.axis = 'T'
    nc_time.valid_min = np.nanmin(time)
    nc_time.valid_max = np.nanmax(time)
    nc_depth  = nc_fid.createVariable('depth', 'f4',('numobs','numdeps'),fill_value=fillvalue)
    nc_depth.long_name =  "Depth"
    nc_depth.standard_name = "depth"
    nc_depth.valid_min = -12000.
    nc_depth.valid_max = 12000
    nc_depth.axis = "Z"
    nc_depth.positive = "down"
    nc_depth_qc  = nc_fid.createVariable('depth_qc', 'i1',('numobs','numdeps'),fill_value=fillvalue_b)
    nc_depth_qc.long_name =  "Depth quality flag"
    nc_depth_qc.valid_min = 0
    nc_depth_qc.valid_max = 9
    nc_depth_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_depth_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_time_qc  = nc_fid.createVariable('time_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_time_qc.long_name =  "Time quality flag"
    nc_time_qc.valid_min = 0
    nc_time_qc.valid_max = 9
    nc_time_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_time_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_position_qc  = nc_fid.createVariable('position_qc', 'i1',('numobs'),fill_value=fillvalue_b)
    nc_position_qc.long_name =  "Position quality flag"
    nc_position_qc.valid_min = 0
    nc_position_qc.valid_max = 9
    nc_position_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_position_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_current_test_qc =  nc_fid.createVariable('current_test_qc','i1',('numobs', 'numdeps'),fill_value=fillvalue_b)
    nc_current_test_qc.long_name = "quality flag of current test"
    nc_current_test_qc.valid_min = 0
    nc_current_test_qc.valid_max = 9
    nc_current_test_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_current_test_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_current_qc  = nc_fid.createVariable('obs_qc', 'i1',('numobs', 'numvars'), fill_value=fillvalue_b)
    nc_current_qc.long_name =  "Observation current quality flag"
    nc_current_qc.valid_min = 0
    nc_current_qc.valid_max = 9
    nc_current_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
    nc_current_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
    nc_dcref = nc_fid.createVariable('dc_reference','c',('numobs','string32'))
    nc_dcref.long_name = "Station/Location unique identifier in data centre"
    nc_dcref.conventions = "Data centre convention"
    nc_wind = nc_fid.createVariable('wdst_model','f4',('numobs', 'numvars'),fill_value=fillvalue)
    nc_wind.long_name = "6-hour integrated wind stress from ECMWF model interpolated at the drifter's position"
    nc_wind.units = "newton/m2"
    nc_current_test = nc_fid.createVariable('current_test','i2',('numobs','numdeps'),fill_value=fillvalue_s)
    nc_current_test.long_name = "Flag tests of drogue loss results"
    nc_current_test.description ="3 flags for 3 tests : Submersion Acceleration_buoy Wind-current-corr"
    nc_current_test.flag_values = "0, 1, 2, 3"
    nc_current_test.flag_meanings = "Drogue_probably_missing Test_not_performed Weak_probability_of_drogue_presence Strong_probability_of_drogue_presence"
    nc_lead= nc_fid.createVariable('leadtime', 'f4',('numfcsts'))
    nc_lead.setncatts({'long_name': u"Model forecast day offset",\
                                'units': u"Hours"})
    nc_indice = nc_fid.createVariable('id_drifter', 'i4',('numobs'))
    nc_indice.setncatts({'long_name': u"Id of the drifter",\
                                'units': u"None"})
    nc_var = nc_fid.createVariable('varname', 'S1',('numvars','string_length'))
    nc_var.setncatts({'long_name': u"name of variables"})
    nc_obs = nc_fid.createVariable('observation','f4',('numobs','numvars','numdeps'),fill_value=fillvalue)
    nc_obs.setncatts({'long_name': u"currents from in situ drifters",\
                                'units': u"m s-1"})#,\
    nc_clim = nc_fid.createVariable('climatology','f4',('numobs','numvars','numdeps'),fill_value=fillvalue)
    nc_clim.setncatts({'long_name': u"Climatology Lumpkin V3.05",'units': u"m s-1"})
    nc_clim.setncatts({'comment': u"Monthly Means of Drifter Data"})

    nc_fid.variables['latitude'][:] = latitude
    nc_fid.variables['longitude'][:] = longitude
    nc_fid.variables['obs_time'][:] = time[:]
    nc_fid.variables['depth'][:,:] = depth[:,:]
    observations[np.isnan(observations)] = fillvalue
    nc_fid.variables['observation'][:,:,:] = observations
    nc_fid.variables['id_drifter'][:] = id_drift[:]
    nc_fid.variables['leadtime'][:] = lead_time[:]
    nc_fid.variables['varname'][:] = netCDF4.stringtochar(np.array(variables))
    clim[np.isnan(clim)] = fillvalue
    nc_fid.variables['climatology'][:,:,:] = clim[:,:,:]
    nc_fid.variables['depth_qc'][:,:] = depth_qc[:,:]
    time_qc[np.isnan(time_qc)] = fillvalue_b
    nc_fid.variables['time_qc'][:] = time_qc[:]
    u_qc[np.isnan(u_qc)] = fillvalue_b
    v_qc[np.isnan(v_qc)] = fillvalue_b
    nc_fid.variables['obs_qc'][:,0]= u_qc[:]
    nc_fid.variables['obs_qc'][:,1]= v_qc[:]
    position_qc[np.isnan(position_qc)] = fillvalue_b
    nc_fid.variables['position_qc'][:]= position_qc[:]
    current_test_qc[np.isnan(current_test_qc)] = fillvalue_b
    nc_fid.variables['current_test_qc'][:]= current_test_qc[:]
    current_test[np.isnan(current_test)] = fillvalue_s
    nc_fid.variables['current_test'][:]= current_test[:]
    u_wind[np.isnan(u_wind)] = fillvalue
    v_wind[np.isnan(v_wind)] = fillvalue
    nc_fid.variables['wdst_model'][:,0] = u_wind[:]
    nc_fid.variables['wdst_model'][:,1] = v_wind[:]
    list_ref=[ref for ref in dc_reference]
    nc_fid.variables['dc_reference'][:] = netCDF4.stringtochar(np.array(list_ref))
    ## Add global attributs
    nc_fid.institution= 'MERCATOR OCEAN'
    nc_fid.contact= 'cregnier@mercator-ocean.fr'
    nc_fid.obs_type='Drifting buoys drogued at 15m depth'
    nc_fid.time_interp = "daily average fields" ;
    nc_fid.description = "Drifting buoys from CMEMS product INSITU_GLO_NRT_OBSERVATIONS_"+cmems_prod
    nc_fid.creation_date=str(datetime.date.today())
    nc_fid.system=model
    nc_fid.Conventions = 'CF-1.6'
    nc_fid.netcdf_version = '4'
    #print '-------------------------------'
    #print 'Creation OK %s ' %(filename)
    #print '-------------------------------'
    nc_fid.close()  # close the new file


def write_data_colloc_files_daily(filename, latitude, longitude, var_mod, vtime, stt_date, end_date, d_moor, d_mod, mvalue, ech_fcst=[0]):
    

    nc = netCDF4.Dataset(filename, 'w')

    #  ********************** Add dimensions ************************
    nc.createDimension('forecasts', len(ech_fcst))   
    nc.createDimension('depth',1) 
    nc.createDimension('time', None)


    #  ********************** Add variables ************************

    nc_fcst = nc.createVariable('forecasts','double',('forecasts'))
    nc_fcst.long_name = 'forecast lead time'
    nc_fcst.units = 'hours'
    nc.variables['forecasts'][:] = ech_fcst

    nc_dpt = nc.createVariable('depth','double',('depth'))
    nc_dpt.axis = 'Z'
    nc_dpt._CoordinateAxisType = 'Height'
    nc_dpt._CoordinateZisPositive = 'down'
    nc_dpt.long_name = 'Depth'
    nc_dpt.standard_name = 'depth'
    nc_dpt.units = 'm'
    nc_dpt.unit_long = 'Meters'
    nc.variables['depth'] = float(d_moor)

    nc_time = nc.createVariable('time','double', ('time'))
    nc_time.axis = 'T'
    nc_time.calendar = 'gregorian'
    nc_time.standard_name = 'time'
    nc_time.units = 'hours since 1950-01-01 00:00:00'
    nc_time._CoordinateAxisType = 'Time'
    nc_time.long_name = 'time'
    nc.variables['time'][:] = vtime  

    nc_model = nc.createVariable('thetao', 'f', ('time','depth','forecasts'), fill_value=mvalue)
    nc_model._Fill_value = -32767.
    nc_model.long_name = 'Temperature'
    nc_model.standard_name = 'sea_water_potential_temperature'
    nc_model.units = 'degrees_C'
    nc_model.valid_min = -2. ;
    nc_model.valid_max = 32. ;
    nc_model.comment = "closer model grid point" ;
    nc.variables['thetao'][:] = var_mod


    #  ********************** Add global attributes ************************

    nc.contact = 'qualif@mercator-ocean.fr'
    nc.product = 'GLOBAL_ANALYSIS_FORECAST_PHY_001_024'
    nc.start_date = stt_date
    nc.end_date = end_date
    nc.longitude_east = str(longitude)
    nc.latitude_north = str(latitude)
    nc.forecasts_units = 'hours' 
    nc.field_type = 'mean'
    nc.forecasts_value_0 = 'Analysis-SAM'
    nc.close()

def convert_to_list(item):
    if isinstance(item, np.ndarray):
        return item.tolist()
    elif isinstance(item, np.float32):
        return float(item)
    return item

def convert_numpy_to_list(d):
    for key, value in d.items():
        if isinstance(value, dict):
            d[key] = convert_numpy_to_list(value)
        elif isinstance(value, list):
            d[key] = value
        else:
            d[key] = convert_to_list(value)
    return d

def write_data_json_file(filename, latitude, longitude, depth_moor, var_mod, \
                         vtime, depth, obs_values, var_qc, variable, ech_fcst=[0]):
    # Convert NetCDF variables to a dictionary
    variables = {}
    variables["time"] = vtime.tolist()
    variables[f'Observed_{variable}'] = obs_values.tolist()
    variables["Analysis-mod"] = var_mod[:, 0].tolist()
    variables["Forecast_12"] = var_mod[:, 1].tolist()
    variables["Forecast_60"] = var_mod[:, 2].tolist()
    variables["Forecast_204"] = var_mod[:, 3].tolist()
    variables["longitude"] = float(longitude)
    variables["latitude"] = float(latitude)
    variables[f"{variable}_qc"] = var_qc.tolist()
    if isinstance(depth_moor, np.ndarray):
        print(f'DEPTH array {depth_moor}')
        variables["depth"] = depth_moor.tolist()
    else:
        variables["depth"] = depth_moor
        print(f'DEPTH List {variables["depth"]}')

    try:
        variables = convert_numpy_to_list(variables)
    except Exception as e:
        print(f"Error conversion JSON file: {e} {filename} {depth_moor} {type(depth_moor)}")

    # Write the dictionary to a JSON file
    try:
        with open(filename, 'w') as json_file:
            json.dump(variables, json_file, indent=2)
    except Exception as e:
        print(f"Error saving JSON file: {e} {filename} {depth_moor} {type(depth_moor)}")


def open_netcdf_with_lock(filename, mode):
    while True:
        try:
            # Attempt to open the file with exclusive locking
            with open(filename, mode) as file:
                fcntl.flock(file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                nc = netCDF4.Dataset(filename, mode)
                return nc
        except IOError as e:
            #If file is locked, wait and retry
            if e.errno == errno.EWOULDBLOCK:
                time.sleep(0.1)
                continue
            else:
                raise

def close_netcdf_with_lock(nc):
    # Release the lock and close the NetCDF dataset
    nc.close()

def write_data_colloc_files(filename, latitude, longitude, var_mod, vtime, stt_date, end_date, depth, mvalue, ech_fcst=[0]):


    #nc = netCDF4.Dataset(filename, 'w')
    nc = open_netcdf_with_lock(filename, 'w')

    #  ********************** Add dimensions ************************

    nc.createDimension('forecasts', len(ech_fcst))   
    nc.createDimension('depth',1) 
    nc.createDimension('time', None)


    #  ********************** Add variables ************************

    nc_fcst = nc.createVariable('forecasts','double',('forecasts'))
    nc_fcst.long_name = 'forecast lead time'
    nc_fcst.units = 'hours'
    nc.variables['forecasts'][:] = ech_fcst

    #nc_dpt = nc.createVariable('depth','double',('depth'))
    nc_dpt = nc.createVariable('depth','float',('depth'))
    nc_dpt.axis = 'Z'
    nc_dpt._CoordinateAxisType = 'Height'
    nc_dpt._CoordinateZisPositive = 'down'
    nc_dpt.long_name = 'Depth'
    nc_dpt.standard_name = 'depth'
    nc_dpt.units = 'm'
    nc_dpt.unit_long = 'Meters'
    print(f'Write moor file {filename} at depth { np.array(depth)}')
    #nc.variables['depth'] = float(depth[0])
    if isinstance(depth, list):
        nc.variables['depth'] = np.array(depth)
    elif isinstance(depth, np.ndarray):
        nc.variables['depth'] = depth[0]

    nc_time = nc.createVariable('time','double', ('time'))
    nc_time.axis = 'T'
    nc_time.calendar = 'gregorian'
    nc_time.standard_name = 'time'
    nc_time.units = 'hours since 1950-01-01 00:00:00'
    nc_time._CoordinateAxisType = 'Time'
    nc_time.long_name = 'time'
    nc.variables['time'][:] = vtime

    nc_model = nc.createVariable('thetao', 'f', ('time','depth','forecasts'), fill_value=mvalue)
    nc_model._Fill_value = -32767.
    nc_model.long_name = 'Temperature'
    nc_model.standard_name = 'sea_water_potential_temperature'
    nc_model.units = 'degrees_C'
    nc_model.valid_min = np.nanmin(var_mod)
    nc_model.valid_max = np.nanmax(var_mod)
    nc_model.comment = "closer model grid point" ;
    nc.variables['thetao'][:] = var_mod

    #  ********************** Add global attributes ************************

    nc.contact = 'qualif@mercator-ocean.fr'
    nc.product = 'GLOBAL_ANALYSIS_FORECAST_PHY_001_024'
    nc.start_date = stt_date
    nc.end_date = end_date
    nc.longitude_east = str(longitude)
    nc.latitude_north = str(latitude)
    nc.forecasts_units = 'hours' 
    nc.field_type = 'mean'
    nc.forecasts_value_0 = 'Analysis-SAM'
    nc.forecasts_value_12 = 'FC01-FREE'
    nc.forecasts_value_60 = 'FC03-FREE'
    nc.forecasts_value_204 = 'FC09-FREE'
    #nc = open_netcdf_with_lock(filename, mode)
    close_netcdf_with_lock(nc)
