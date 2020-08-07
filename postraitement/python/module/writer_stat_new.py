import sys, os
import numpy as np
import netCDF4
from netCDF4 import Dataset


########################################################
#                C.SZCZYPTA NOV 2017
#     Class Writer to write output file in NetCDF
########################################################

class writer_stat():

    """ Class to write different type of file """

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #             WRITE DAILY BIO STATS IN NETCDF FILE
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_BIO_files(self,filename,contact, product, fmt, dstart, dend, resultsFileName,
                        institution, ref, areas, start_jdate, end_jdate,
                        cla_metricname,fcst, layer,vtime, stat, CMEMS_area):
        

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
        nc_CHL = nc_fid.createVariable('stats_chl-a','f', ('time','forecasts','surface','metrics','areas'), fill_value = 999999.)
        nc_CHL.parameter = 'log10-chlorophyll'
        nc_CHL.reference = 'Observations of ocean color from satellite-born instrument'
        nc_CHL.units = 'mg/m3'
        nc_CHL.long_name = 'Logarithm (base 10) of chlorophyll-a concentration'
        nc_fid.variables['stats_chl-a'][:] = stat[:,:,:,:,:,0]

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
                        cla_metricname,fcst, layer, stat, CMEMS_area):

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
        nc_CHL = nc_fid.createVariable('stats_chl-a','f', ('forecasts','surface','metrics','areas'), fill_value = 999999.)
        nc_CHL.parameter = 'log10-chlorophyll'
        nc_CHL.reference = 'Observations of ocean color from satellite-born instrument'
        nc_CHL.units = 'mg/m3'
        nc_CHL.long_name = 'Logarithm (base 10) of chlorophyll-a concentration'
        nc_fid.variables['stats_chl-a'][:] = stat[:,:,:,:,0]

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

    def write_PHYS_files(self,filename,contact, product, fmt, dstart, dend, resultsFileName, institution,
                         ref, areas, start_jdate, end_jdate, cla_metricname,
                         fcst, layer, vtime, stat, surf_layer, CMEMS_area, ll_ice):


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
        print ll_ice
        if ll_ice:
            nc_aice = nc_fid.createVariable('stats_seaice-concentration','f', ('time','forecasts','surface','metrics','areas'), fill_value = 999999.)
            nc_aice.parameter = 'Sea ice concentration'
            nc_aice.reference = 'Observations from AMSR2 satellite'
            nc_aice.units = '1'
            nc_fid.variables['stats_seaice-concentration'][:] = stat[:,:,0,:,:,4]

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
                         fcst, layer, stat, surf_layer, CMEMS_area, cla_vars):


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
            index = ind
            print 'Write variable %s '%(variable)
            print 'Write indice %i '%(ind)
           # index = 0
           # for numvar, cvar in enumerate(cla_vars):
           #     index = index_tmp
           #     if variable == 'profile':
           #         index_tmp += 2
           #     else:
           #         index_tmp += 1
            if variable ==  'PSAL':
                nc_sal = nc_fid.createVariable('stats_salinity','f', ('forecasts','depths','metrics','areas'), fill_value = 999999.)
                nc_sal.parameter = 'Salinity'
                nc_sal.reference = 'Profile observations from in-situ TAC'
                nc_sal.units = '1e-3'
                print "Write salinity %i " %(index)
                nc_fid.variables['stats_salinity'][:] = stat[:,:,:,:,index]
            if variable ==  'TEMP':
                nc_temp = nc_fid.createVariable('stats_temperature','f', ('forecasts','depths','metrics','areas'), fill_value = 999999.)
                nc_temp.parameter = 'Temperature'
                nc_temp.reference = 'Profile observations from in-situ TAC'
                nc_temp.units = 'Kelvin'
                nc_fid.variables['stats_temperature'][:] = stat[:,:,:,:,index+1]
                print "Write temperature %i " %(index+1)
            if variable ==  'SLA':
                nc_sla = nc_fid.createVariable('stats_sla','f', ('forecasts','surface','metrics','areas'), fill_value = 999999.)
                nc_sla.parameter = 'Sea Level Anomaly'
                nc_sla.reference = 'Profile observations from in-situ TAC'
                nc_sla.units = 'meters'
                nc_fid.variables['stats_sla'][:] = stat[:,0,:,:,index]
                print "Write sla %i " %(index)
            if variable ==  'SST':
                nc_sst = nc_fid.createVariable('stats_sst','f', ('forecasts','surface','metrics','areas'), fill_value = 999999.)
                nc_sst.parameter = 'Sea Surface Temperature'
                nc_sst.reference = 'Profile observations from in-situ TAC'
                nc_sst.units = 'Kelvin'
                nc_fid.variables['stats_sst'][:] = stat[:,0,:,:,index]
                print "Write sst %i " %(index)
            if variable ==  'aice':
                nc_aice = nc_fid.createVariable('stats_seaice-concentration','f', ('forecasts','surface','metrics','areas'), fill_value = 999999.)
                nc_aice.parameter = 'Sea ice concentration'
                nc_aice.reference = 'Observations from AMSR2 satellite'
                nc_aice.units = '1'
                nc_fid.variables['stats_seaice-concentration'][:] = stat[:,0,:,:,index]
                print "Write aice %i " %(index)

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

    def write_daily_files(self, filename, areas, cla_metricname,fcst, layer, stat, CMEMS_area, lead_time):

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
        nc_fid.createVariable('stat_var','f', ('forecasts','depths','metrics','areas'), fill_value = 999999.)
        nc_fid.variables['stat_var'][:] = stat
        nc_fid.close()



    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #                         WRITE DAILY STATS IN TMP FILES
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def write_glob_files_area(self, filename, cla_metricname, fcst, layer, stat, lead_time):
  
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
        nc_fid.createVariable('stat_var','f', ('forecasts','depths','metrics'), fill_value = 999999.)
        nc_fid.variables['stat_var'][:] = stat
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

