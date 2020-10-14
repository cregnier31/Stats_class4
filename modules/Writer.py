from __future__ import generators
import os
import sys
import string
import shutil
from glob import glob
import re
import numpy as np
import geojson
from geojson import MultiPoint
import shelve
import json
from Logger import Logger
from datetime import date
from netCDF4 import Dataset
import gzip

##############################################################
# C.REGNIER Juin 2014
# Class Writer to write output file in ASCII or Geojson
##############################################################


class Writer():

    """ Class to write different type of file """

    def __init__(self, log):
        self.log = log
        self.fillvalue = 1.e35
        self.type_data = {
            'profile': {'code': 'INSITU_profile', 'defaults': {'name': 'In Situ profiles from CMEMS'}},
            'SST': {'code': 'SST_DB', 'defaults': {'name': 'SST Drifting buoy'}},
            'SLA': {'code': 'SLA_L3S', 'defaults': {'name': 'SLA CMEMS L3S'}},
            'chloro': {'code': 'CHLORO-A_L3S', 'defaults': {'name': 'log10-chlorophyll A Satellite'}},
            'aice': {'code': 'SEA_CONC', 'defaults': {'name': 'Sea ice concentration from AMSR2 brightness temperature'}},
            'current': {'code': 'CURRENT_ZONAL_DB', 'defaults': {'name': 'Currents from CMEMS drifting buoys 001_048'}},
            'DRIFTER_filtr': {'code': 'CURRENT_ZONAL_DB', 'defaults': {'name': 'Filtered Currents from CMEMS drifting buoys 001_048'}},
            'default': {'code': 'Default_code', 'defaults': {'name': 'Data for validation'}},
       }

    def mkdir(self, path):
        "Create a directory, and parents if needed"
        if not os.path.exists(path):
            os.makedirs(path)

    def write_json_profile(self, filename, tab):
        with open(filename, 'w') as outfile:
                json.dump(tab, outfile,indent=4)

    def write_geojson(self, filename, position):
        try:
            #print 'Write Geojson file'
            liste_position = []
            for il_ind in range(len(position)):
                pos = position[il_ind]
                liste_position.append(tuple(pos))
            #print MultiPoint(liste_position)
            with open(filename, 'w') as outfile:
                json.dump(MultiPoint(liste_position), outfile)
        except:
            print ('Probleme d ecriture')
            sys.exit(1)

    def write_ASCII(self, filename, position):
        try:
            #print 'Write ASCII file'
            # Creation fichier
            length = position.size
            # if length < 2 :
            #     print "Empty Position array"
            # elif length == 2 :
            #     print "Only 1 position"
            #     np.savetxt(filename, position[None,:],fmt='%12.5f',delimiter='    ')
            # else :
            #     np.savetxt(filename, position,fmt='%12.5f',delimiter='    ')
            np.savetxt(filename, position, fmt='%12.5f', delimiter='    ')
        # print len(position)
        #print 'Write ASCII file OK'
        except:
            print ('Probleme d ecriture')
            sys.exit(1)

    def write_geojson_fromdb(self, type_f, file_out, file_db):
        # Open a shelve file if not exist
        if not(os.path.isfile(file_db)):
            print ("Pb persistent file doesn't exist")
            sys.exit(1)
        else:
            shelf = shelve.open(file_db)
            try:
                tab_fin = shelf[type_f]
                #tab_fin[0,:][tab_fin[0,:] <0] += 360.
                #print "Type exist %s " %(type_f)
                self.write_geojson(file_out, tab_fin)
            except:
                print ("Type doesn't exist %s " % (type_f))
            shelf.close()
#
    def write_GODAE_files_best(self, filename, hdct_tab, dateval, model, variable):
        nc_fid = Dataset(filename, 'r+') #, format='NETCDF3')
        nc_best = nc_fid.createVariable(
            'best_estimate', 'f4', ('numobs', 'numvars', 'numdeps'), fill_value=self.fillvalue)
        nc_best.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:, :, :] = hdct_tab[:, :, :]
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.contact = 'cregnier@mercator-ocean.fr'
        nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.time_interp = "daily average fields"
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.best_estimate_description = "analysis produced between 7 and 14 days behind real time"
        nc_fid.close()  # close the new file

    def write_BIOARGO_files(self, filename, hdct_tab, dateval, model, variable, fcst = None, pers = None):
        nc_fid = Dataset(filename, 'r+')
        nc_best = nc_fid.createVariable(
            'best_estimate', 'f4', ('time', 'N_PROF', 'N_LEVELS'), fill_value=self.fillvalue)
        nc_best.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:, :, :] = hdct_tab[:, :, :]
        if fcst:
            nc_fcst = nc_fid.createVariable(
                'forecast', 'f4', ('time', 'N_PROF', 'N_LEVELS'), fill_value=self.fillvalue)
            nc_fcst.setncatts(
                {'long_name': u"Model forecast counterpart of obs. value"})
            nc_fid.variables['forecast'][:, :, :] = fcst
        if pers:
            nc_pers = nc_fid.createVariable(
                'pers', 'f4', ('time', 'N_PROF', 'N_LEVELS'), fill_value=self.fillvalue)
            nc_pers.setncatts(
                {'long_name': u"Model persistence counterpart of obs. value"})
            nc_fid.variables['persistence'][:, :, :] = pers

        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.contact = 'cregnier@mercator-ocean.fr'
        nc_fid.obs_type = 'BIOARGO'
        nc_fid.time_interp = "daily average fields"
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.best_estimate_description = "analysis produced between 7 and 14 days behind real time"
        nc_fid.close()  # close the new file


    def write_CMEMS_files(self, filename, hdct_tab, fcst_tab, pers_tab, clim_tab, dateval, model, variable):
        nc_fid = Dataset(filename, 'r+')
        nb_obs, nb_vars, nb_fcst, nb_depths = np.shape(fcst_tab)
        nc_fid.createDimension('numobs', nb_obs)
        nc_fid.createDimension('numvars', nb_vars)
        nc_fid.createDimension('numfcsts', nb_fcst) 
        nc_fid.createDimension('numdeps', nb_depths)
        nc_best = nc_fid.createVariable(
            'best_estimate', 'f4', ('numobs', 'numvars', 'numdeps'), fill_value=self.fillvalue)
        nc_best.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_fcst = nc_fid.createVariable(
            'forecast', 'f4', ('numobs', 'numvars', 'numfcsts', 'numdeps'), fill_value=self.fillvalue)
        nc_fcst.setncatts(
            {'long_name': u"Model forecast counterpart of obs. value"})
        nc_pers = nc_fid.createVariable(
            'persistence', 'f4', ('numobs', 'numvars', 'numfcsts', 'numdeps'), fill_value=self.fillvalue)
        nc_pers.setncatts(
            {'long_name': u"Model persistence counterpart of obs. value"})
        nc_clim = nc_fid.createVariable(
            'climatology', 'f4', ('numobs', 'numvars', 'numdeps'), fill_value=self.fillvalue)
        nc_clim.setncatts(
            {'long_name': u"Surface climatology from Lumpkin counterpart of obs. value"})
        nc_clim.setncatts(
            {'version': u"V3.05"}) 
        nc_fid.variables['best_estimate'][:, :, :] = hdct_tab[:, :, :]
        nc_fid.variables['forecast'][:, :, :, :] = fcst_tab[:, :, :, :]
        nc_fid.variables['persistence'][:, :, :, :] = pers_tab[:, :, :, :]
        nc_fid.variables['climatology'][:, :, :] = clim_tab[:, :, :]
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.contact = 'cregnier@mercator-ocean.fr'
        nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.time_interp = "daily average fields"
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.best_estimate_description = "analysis produced between 7 and 14 days behind real time"
        nc_fid.close()  # close the new file

    def write_GODAE_files(self, filename, hdct_tab, fcst_tab, pers_tab, dateval, model, variable):
        nc_fid = Dataset(filename,'r+')
        nc_best = nc_fid.createVariable(
            'best_estimate', 'f4', ('numobs', 'numvars', 'numdeps'), fill_value=self.fillvalue)
        nc_best.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_fcst = nc_fid.createVariable(
            'forecast', 'f4', ('numobs', 'numvars', 'numfcsts', 'numdeps'), fill_value=self.fillvalue)
        nc_fcst.setncatts(
            {'long_name': u"Model forecast counterpart of obs. value"})
        nc_pers = nc_fid.createVariable(
            'persistence', 'f4', ('numobs', 'numvars', 'numfcsts', 'numdeps'), fill_value=self.fillvalue)
        nc_pers.setncatts(
            {'long_name': u"Model persistence counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:, :, :] = hdct_tab[:, :, :]
        nc_fid.variables['forecast'][:, :, :, :] = fcst_tab[:, :, :, :]
        nc_fid.variables['persistence'][:, :, :, :] = pers_tab[:, :, :, :]
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.contact = 'cregnier@mercator-ocean.fr'
        nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.time_interp = "daily average fields"
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.best_estimate_description = "analysis produced between 7 and 14 days behind real time"
        nc_fid.close()  # close the new file

    def write_GLOBCOLOR_files(self, filename, tab1, tab2, tab3, dateval, model, variable):
        nc_fid = Dataset(filename, 'r+') #, format='NETCDF3_CLASSIC')
        nc_file = nc_fid.createVariable(
            'best_estimate', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file2 = nc_fid.createVariable(
            'forecast', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file3 = nc_fid.createVariable(
            'climatology', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_file2.setncatts(
            {'long_name': u"Model forecast counterpart of obs. value"})
        nc_file3.setncatts(
            {'long_name': u"Satellite L4 climatology counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:] = tab1
        nc_fid.variables['forecast'][:] = tab2
        nc_fid.variables['climatology'][:] = tab3
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.contact = 'qualif@mercator-ocean.fr'
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        print ('-------------------------------')
        print ('Creation OK %s ')
        print ('-------------------------------')
        nc_fid.close()  # close the new file

    def write_GLOBCOLOR_files2(self, filename, tab, tab2, dateval, model, variable):
        nc_fid = Dataset(filename, 'r+', format='NETCDF3_CLASSIC')
        nc_file = nc_fid.createVariable(
            'best_estimate', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file2 = nc_fid.createVariable(
            'climatology', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_file2.setncatts(
            {'long_name': u"Satellite L4 climatology counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:] = tab
        nc_fid.variables['climatology'][:] = tab2
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.contact = 'qualif@mercator-ocean.fr'
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        print ('-------------------------------')
        print ('Creation OK %s ')
        print ('-------------------------------')
        nc_fid.close()  # close the new file

    def write_best_fcst(self, filename, tab1, tab2, dateval, model, variable):
        nc_fid = Dataset(filename, 'r+') #, format='NETCDF3_CLASSIC')
        nc_file = nc_fid.createVariable(
            'best_estimate', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file2 = nc_fid.createVariable(
            'forecast', 'f4', ('lat', 'lon'), fill_value=self.fillvalue)
        nc_file.setncatts(
            {'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_file2.setncatts(
            {'long_name': u"Model forecast counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:] = tab1[:, :]
        nc_fid.variables['forecast'][:] = tab2[:, :]
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.contact = 'qualif@mercator-ocean.fr'
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        nc_fid.close()  # close the new file

    def write_best(self, filename, tab1, dateval, model, dimension, variable, desc, variable2):
        nc_fid = Dataset(filename, 'r+') #, format='NETCDF3_CLASSIC')
        nc_file = nc_fid.createVariable(
            variable, 'f4', (dimension), fill_value=np.nan)
        nc_file.setncatts({'long_name': desc+" counterpart of obs. value"})
        nc_file.setncatts({'minvalue':  np.nanmin(tab1)})
        nc_file.setncatts({'maxvalue': np.nanmax(tab1)})
        nc_fid.variables[variable][:] = tab1[:]
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.obs_type = self.type_data.get(variable2, {}).get('defaults').get('name')
        nc_fid.contact = 'qualif@mercator-ocean.fr'
        today = date.today()
        yyyy = str(today)[0:4]
        yyyy2 = dateval[0:4]
        month = str(today)[5:7]
        month2 = dateval[4:6]
        day = str(today)[8:10]
        day2 = dateval[7:9]
        nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system = model
        nc_fid.close()  # close the new file

    def write_output(self, filename, tab_results, param_dict, dateval, ll_zip=True):
        dataorigin = param_dict['data_origin']
        self.mkdir(param_dict['diroutput'])
        if dataorigin == "GODAE":
            self.log.debug("Write inside GODAE file")
            if 'forecast'  not in tab_results.keys() and 'persistence' not in tab_results.keys() \
                    and 'best' in tab_results.keys():
                self.write_GODAE_files_best(
                    filename, tab_results['best'], dateval, param_dict['modele'], param_dict['data_type'])
            else:
                self.write_GODAE_files(
                    filename, tab_results['best'], tab_results['forecast'],
                    tab_results['persistence'], dateval, param_dict['modele'], param_dict['data_type'])
        elif dataorigin == "BIOARGO":
                self.write_BIOARGO_files(
                    filename, tab_results['best'], dateval, param_dict['modele'], param_dict['data_type'])

        elif dataorigin == "CMEMS" :
            self.write_CMEMS_files(
                 filename, tab_results['best'], tab_results['forecast'],
                 tab_results['persistence'], tab_results['clim'], dateval, param_dict['modele'], param_dict['data_type'])

        elif dataorigin == "GLOBCOLOUR" and param_dict['daily_pref'] == '7dAV':
            self.log.info("Write inside GLOBCOLOUR files")
            self.write_GLOBCOLOR_files(filename, tab_results['best'],
                                       tab_results['forecast'], tab_results['clim'],
                                       dateval, param_dict['cl_config'], param_dict['data_type'])
        elif dataorigin == "GLOBCOLOUR" and param_dict['daily_pref'] == '1dAV':
            self.log.info("Write inside GLOBCOLOUR files")
            self.write_GLOBCOLOR_files2(filename, tab_results['best'],
                                        tab_results['clim'],
                                        dateval, param_dict['cl_config'], param_dict['data_type'])
        elif dataorigin == "Microwat" or dataorigin == "SSS_ship":
            # Add missing value
            hdct_tab = np.where(
                np.array(tab_results['best']) > 9.e36, np.nan, np.array(tab_results['best']))
            self.write_best(filename, hdct_tab, dateval, param_dict['cl_config'],
                            param_dict['dimension'], 'best_estimate', param_dict['desc'], param_dict['data_type'])
            self.write_best(filename, tab_results['clim'], dateval, param_dict['cl_config'],
                            param_dict['dimension'], 'clim', param_dict['desc'], param_dict['data_type'])
        else:
            self.log.error("Origin Not Known : %s :" % (dataorigin))

        # Remove corresponding colloc file
        for file_coloc in glob(param_dict['coloc_rep'] + '*_'+dateval+'*.p'):
            if os.path.exists(file_coloc):
                os.remove(file_coloc)   

        self.log.info('Creation file %s' % (filename))
        if ll_zip:
            # Zipped files and move in output directory
            self.log.info(param_dict['dirwork'])
            #self.log.info(param_dict['dirwork']+"*"+param_dict['cl_conf'] +"*"+param_dict['varname']+"*.nc")
            #for filename in glob(param_dict['dirwork']+"*"+param_dict['cl_conf'] +
            #                     "*"+param_dict['varname']+"*.nc"):
            for filename in glob(param_dict['dirwork']+"*.nc"):
                self.log.info('ZIP and move file %s' % (filename))
                self.log.info('ZIP and move file %s' % (filename))
                f_in = open(filename, 'rb')
                f_out = gzip.open(filename+'.gz', 'wb')
                f_out.writelines(f_in)
                f_out.close()
                f_in.close()
                if param_dict['diroutput'] != param_dict['dirwork']:
                    if os.path.exists(param_dict['diroutput'] +
                                      os.path.basename(filename)+'.gz'):
                        os.remove(param_dict['diroutput'] +
                                  os.path.basename(filename)+'.gz')
                    shutil.move(filename+'.gz', param_dict['diroutput'])
                os.remove(filename)
                self.log.info('File ok %s' % (filename))
