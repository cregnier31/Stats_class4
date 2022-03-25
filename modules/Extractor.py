from __future__ import generators
import os
import sys
import string
import shutil
from glob import glob
import re
import numpy as np
import logging
import tarfile
import netCDF4
#import custom as c
#from sydate import SyDate
from sytoolkit.sydate import SyDate
from Logger import Logger
from gz import ZipManipulator
from os.path import dirname
sys.path.append(dirname(__file__))
from nco.nco import Nco
import xarray as xr
from netCDF4 import Dataset
#from nco import Nco

##############################################################
# C.REGNIER Juin 2014
# Class Extractor to extract profile : the selection depends on date
##############################################################


class Extractor(object):

    def __init__(self, log):

        self.log = log


    """ Factory extract file depending on type """

    def factory(self, type):
        """
         Create an interface for different type of data
         Factory
        """
        if type == "CORA3": return Extract_cora3(self.log)
        if type == "cora4.0_merc": return Extract_cora4('.tgz',self.log)
        if type == "cora4.1_raw": return Extract_cora4_1(self.log)
        if type == "CORA4.1_MERC": return Extract_cora4('.tgz',self.log)
        if type == "cora5.0_raw": return Extract_cora4('.tar.gz',self.log)
        if type == "CORA5.0": return Extract_cora4('.tgz', self.log)
        if type == "CORA5.2": return Extract_cora5_2(self.log)
        if type == "CORIO_ASSIM": return Extract_corio_cmems(self.log)
        if type == "CORIOLIS": return Extract_corio(self.log)
        if type == "CORIOLIS_RAW": return Extract_corio_raw(self.log)
        if type == "ENS": return ExtractEns(self.log)
        if type == "ARMOR_CO" or type == "ARMOR_AR" or type == "AR_": return Extract_ARMOR(self.log)
        if type == "GODAE_UV": return Extract_UVDrifters(self.log)  
        if type == "GODAE_UV_filtr": return Extract_UVDrifters_filtr(self.log)  
        if type == "GODAE": return Extract_GODAE(self.log)
        if type == "ASCII": return Extract_ASCII(self.log)
        if type == "L3m": return Extract_genericData(self.log)
        if type.startswith("BGC_ARGO"): return Extract_BGC_ARGO(self.log)
        if type == "L3mCHL": return Extract_CHLORO(self.log)
        if type == "Microwat_Lband_Orbite_1day_Lband" or type == "Microwat_6.9GHz_Orbite_1day": return Extract_genericData(self.log)
        if type == "001_048" : return Extract_CMEMS_drifters(self.log)
        if type == "sssdata_netcdf_good_FNAV" or type == "sssdata_netcdf_all": return Extract_SSSData(self.log)
        if type == "Legos_SIT" : return Extract_Legos_SIT(self.log)

    def timelinespace(self, date1, date2):
        """
         Create a list for a defined time range
         Arguments
         -----------------------------
         date1 : init date
         date2 : end date
         Returns
         -----------------------------
         list_time : list of time values
        """
        liste_time = []
        valeurj = date1
        while valeurj.__ge__(date1) and valeurj.__le__(date2):
            dateval = SyDate.__str__(valeurj)
            liste_time.append(dateval)
            valeurj = valeurj.goforward(1)
        return liste_time

    def run_list(self, param_dict, dateval):
        """
         Create a list of data corresponding to a specific date
         Arguments
         -----------------------------
         param_dict : dictionnary with all the parameters
         dateval : date value
         Returns
         -----------------------------
         liste_tot : list of input data corresponding to a date
        """
        liste_tot = []
        YEAR = dateval[0:4]
        liste_file = glob(param_dict['dirdata']+'/'+YEAR+'/*'+dateval+'*.nc')
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
        return liste_tot

class Extract_Legos_SIT(Extractor):

    """ Class to extract Legos SIT l3 files """
    def __init_(self, log):
        self.log = log

    def run_list(self, param_dict, daterun):
        liste_tot=[]
        liste_file=glob(param_dict['dirdata']+'/*'+daterun+'*.nc')
        self.log.info("Liste file {} {} ".format(liste_file, daterun))
        if not liste_file:
            self.log.error("Missing Legos_SIT {} {}".format(param_dict['dirdata'], daterun))
            raise
        self.log.debug('Liste file Legos_SIT {}'.format(liste_file))
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                raise ("I/O error({0}): {1}".format(e.errno, e.strerror))

        return liste_file

    def run_over(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        valeurj_tmp = SyDate(str(date1))
        valeurj = valeurj_tmp
        valeurj2 = SyDate(str(date2))
        liste_tot=[]
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            self.log.info('Day 5.2 %s ' % (dateval))
            month=dateval[0:6]
            year=dateval[0:4]
            frame=dirdata+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            self.log.info('Liste file CORA %s ' % (liste_file))
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.info('copy file {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj_tmp=valeurj_tmp.goforward(1)
        ## TODO Finish the run_over for SIT files

class Extract_CMEMS_drifters(Extractor):

    """ Class to extract CMEMS drifters """

    def run_list(self, param_dict, dateval):
        """
         Create a list of data corresponding to a specific date
         Arguments
         -----------------------------
         param_dict : dictionnary with all the parameters
         dateval : date value
         Returns
         -----------------------------
         liste_tot : list of input data corresponding to a date
        """
        liste_tot = []
        year = SyDate(dateval).year
        month = SyDate(dateval).month
        if month < 10:
            month = '0'+str(month)
        else:
            month = str(month)
        liste_file = glob(param_dict['dirdata']+str(year)+'/'+str(month)+'/*'+dateval+'*.nc')
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
        return liste_tot

class Extract_SSSData(Extractor):

    """ Extract SSS Data files """

    def __init__(self):
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log = logging.getLogger("Extract_SSS_data")
        self.log.setLevel(logging.INFO)
        self.date = SyDate('19500101')

        self.dimension = 'TIME'
    def run(self, date1, date2, dirdata, dirtmp, typedata, template, prefix):

        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log = logging.getLogger("Extract Generic files")
        self.log.setLevel(logging.INFO)
        liste_tot = []
        valeurj = date1
        options = []
        options.extend(['-h'])
        # Nco constructor
        nco = Nco()
        # Create a timeline
        timelinespace = self.timelinespace(date1,date2)
        liste_file = glob(dirdata+'/*nc')
        length = len(liste_file)
        for indice, file in enumerate(liste_file):
            try:
                filename = os.path.basename(file)
                data_type = filename.split(prefix)[1].split('_')[1]
                nc = netCDF4.Dataset(file, 'r')
                # Extract time variable
                variable = self.dimension
                v = nc.variables[variable][:]
                # Convert to date
                valeurtmp = valeurj
                date_all = [SyDate.__str__(self.date.setfromjulian(
                    int(valeurtmp))) for valeurtmp in v]
                unique_date = reduce(
                    lambda l, x: l+[x] if x not in l else l, date_all, [])
                ## Find the correspondance with 2 lists
                result = []
                list1 = set(timelinespace)
                list2 = set(unique_date)
                date_values = list(list1.intersection(list2))
                if date_values:
                    self.log.info("Not empty ")
                    for date in date_values:
                        ## find indexes in date_all
                        indexes = [i for i, x in enumerate(
                                   date_all) if x == date]
                        file_out = prefix+'_'+data_type+'_'+str(date)+'.nc'
                        self.log.info('Creation fileout : %s '%(file_out))
                        ## Create output extracted file
                        nco.ncks(input=file, output=dirtmp+file_out, dimension=self.dimension+','+str(
                            indexes[0])+','+str(indexes[-1]), options=options)
                        if dirtmp+file_out not in liste_tot:
                            liste_tot.append(dirtmp+file_out)
            except IOError as e:
                self.log.error ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
            # Search index 
            self.log.info("File ok : %s %i %i" %(file,indice,length))
        return liste_tot


class Extract_genericData(Extractor):

    """ Extract files """

    def run_list(self, param_dict, dateval):
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log =logging.getLogger("Extract Generic files")
        self.log.setLevel(logging.INFO)
        liste_tot = []
        liste_file = glob(param_dict['dirdata']+'/*'+dateval+'*.nc')
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot

class Extract_BGC_ARGO(Extractor):

    """ Extract files """

    def __init__(self, log):
        self.log = log

    def run_list(self, param_dict, dateval):
        liste_tot = []
        liste_file = glob(param_dict['dirdata']+'/*/'+param_dict['prefix_data']+'*'+dateval+'*.nc')
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                self.log ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot


class Extract_CHLORO(Extractor):

    """ Extract Chloro Globcolour files """
    
    def __init__(self, log):
        self.log = log

    def mkdir(self, path):
        "Create a directory, and parents if needed"
        if not os.path.exists(path):
            os.makedirs(path)

    def run_list(self, param_dict, dateval):
        liste_tot = []
        liste_file = glob(param_dict['dirdata']+'/'+dateval+'*REP'+'*.nc')

        if np.size(liste_file) > 0:
            liste_file = liste_file
        else:
            liste_file = glob(param_dict['dirdata']+'/'+dateval+'*DT'+'*.nc')
            if np.size(liste_file) > 0:
                liste_file = liste_file
            else:
                liste_file = glob(param_dict['dirdata']+'/'+dateval+'*NRT'+'*.nc')
        for file in liste_file:
            try:
                filename = 'Class4_'+dateval+'_'+param_dict['data_origin']+'_'+param_dict['cl_conf']+'_'+param_dict['varname'][0]+'.nc'
                self.mkdir(param_dict['dirwork'])
                shutil.copy(file,param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot

class Extract_corio_raw(Extractor):

    """ Extract coriolis raw common file """

    def __init__(self, log): 

        # ===============
        # LOGGER
        # ===============
        self.log = log
        self.date=SyDate('19500101')

    def search(self,dirdata,**kwargs):
        list_dateval=[]
        ind=0
        for file in glob(dirdata+"*.nc"):
            nc   = netCDF4.Dataset(file,'r')
            variable="JULD"
            v = nc.variables[variable][:]
            # Convert to date
            dateval=[SyDate.__str__(self.date.setfromjulian(int(valeurj))) for valeurj in v]
            ind=0
            for val in dateval : 
                if SyDate(val).tojulian() < 16189 :
                   self.log.error("Probleme  : %s %i  "%(val,ind))
                else :
                    list_dateval.append(val)
                ind+=1
        dateval = sorted(set(list_dateval))
        return SyDate(dateval[0]),SyDate(dateval[-1])

    def run(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        liste_tot=[]
        ind=0
        dimprof='N_PROF'
        options = []
        options.extend(['-h'])
        # Nco constructor
        nco = Nco()
        for file in glob(dirdata+"*.nc"):
            frame=os.path.basename(file).split('.')[0]
            nc   = netCDF4.Dataset(file,'r')
            variable="JULD"
            v = nc.variables[variable][:]
            # Convert to date
            dateval=[SyDate.__str__(self.date.setfromjulian(int(valeurj))) for valeurj in v]
            ind=0
            for val in dateval : 
                if SyDate(val).tojulian() < 16189 :
                   self.log.error("Probleme  : %s %i  "%(val,ind))
                else :
                    file_out=str(val)+'_'+frame+'_profile_'+str(ind)+'.nc'
                    nco.ncks(input=file,output=dirtmp+file_out, fortran=True ,dimension=str(dimprof)+','+str(ind+1),options=options)              
                    liste_tot.append(dirtmp+file_out)
                    # self.log.info('Day %s ' % (dateval))
                ind+=1
        return liste_tot

class Extract_corio(Extractor):

    """ Extract coriolis common file """
    def __init__(self, log):
        self.log = log

    def run(self, param_dict, dateval):
        # ===============
        # LOGGER
        # ===============
        liste_tot=[]
        self.log.info('Day %s ' % (dateval))
        frame=param_dict['dir_data']+'/*'+dateval.strip()+'*.nc'
        liste_file=glob(frame)
        self.log.info('Liste file %s ' % (liste_file)) 
        for new_file in liste_file :
            try :
                filename=os.path.basename(new_file)
                shutil.copy(new_file,param_dict['dirtmp'])
                liste_tot.append(param_dict['dirtmp']+filename)
            except IOError as e:
                self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot


class Extract_cora5_2(Extractor):

    """ Extract cora 5.2 file """

    def __init__(self, log):
        self.date = SyDate('19500101')
        self.log = log

    def run(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        valeurj_tmp = SyDate(str(date1))
        valeurj = valeurj_tmp
        valeurj2 = SyDate(str(date2))
        liste_tot=[]
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            #dateval=str(SyDate(str(self.date.setfromjulian(int(valeurj)))))
            self.log.info('Day 5.2 %s ' % (dateval))
            month=dateval[0:6]
            year=dateval[0:4]
            frame=dirdata+year+'/'+month+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            self.log.info('Liste file CORA %s ' % (liste_file))
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.debug('copy file ok {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj_tmp=valeurj_tmp.goforward(1)

        return liste_tot

    def run_over(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        valeurj_tmp = SyDate(str(date1))
        valeurj = valeurj_tmp
        valeurj2 = SyDate(str(date2))
        liste_tot=[]
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            self.log.info('Day 5.2 %s ' % (dateval))
            month=dateval[0:6]
            year=dateval[0:4]
            frame=dirdata+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            self.log.info('Liste file CORA %s ' % (liste_file))
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.info('copy file {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj_tmp=valeurj_tmp.goforward(1)

        return liste_tot

class Extract_cora4_1(Extractor):

    """ Extract cora 4.1 file """

    def __init__(self, log):
        self.date = SyDate('19500101')
        self.log = log

    def run(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        # ===============
        # LOGGER
        # ===============
        log = logging.getLogger("Extract_ARMOR")
        log.setLevel(logging.INFO)
        valeurj_tmp = SyDate(str(date1))
        # Level of logging output
        valeurj = valeurj_tmp
        valeurj2 = SyDate(str(date2))
        liste_tot=[]
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            #dateval=str(SyDate(str(self.date.setfromjulian(int(valeurj)))))
            self.log.info('Day %s ' % (dateval))
            month=dateval[0:6] 
            #frame=dirdata+month+'/*'+dateval.strip()+'*.nc'
            frame=dirdata+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            self.log.info('Liste file CORA %s ' % (liste_file))
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.info('copy file {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj_tmp=valeurj_tmp.goforward(1)

        return liste_tot

class Extract_corio_cmems(Extractor):

    """ Extract CMEMS coriolis profiles files """

    def __init__(self, log):
        self.date = SyDate('19500101')
        self.log = log

    def run(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        # ===============
        # LOGGER
        # ===============
        valeurj_tmp = SyDate(str(date1))
        # Level of logging output
        valeurj = valeurj_tmp
        valeurj2 = SyDate(str(date2))
        liste_tot=[]
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            self.log.info('Day %s ' % (dateval))
            year=dateval[0:4]
            frame=dirdata+year+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            self.log.info('Liste file CMEMS profiles %s ' % (liste_file))
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.info('copy file {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj_tmp=valeurj_tmp.goforward(1)

        return liste_tot

class Extract_ASCII(Extractor): 

    """ Extract ASCII file """

    def __init__(self):
        self.PREFIX='Ascii file extraction'
    def run_list(self, param_dict, dateval):
        liste_tot=[]
        liste_file=glob(param_dict['dirdata']+'/*_'+dateval+'*.txt')
        for file in liste_file :
            try :
                liste_tot.append(file)
                options = []
                options.extend(['-h','-O','-a','numfcsts'])
                nco.ncwa(input=new_file, output=dirtmp+filename, fortran=True ,options=options)
                nc = netCDF4.Dataset(dirtmp+filename, 'r')
                variables = nc.variables.keys()

            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
        return liste_tot

class Extract_UVDrifters_filtr(Extractor):

    """ Extract and reconstruct UV drifters """

    def __init__(self, log):
        self.log = log
        # Nco constructor
        self.nco = Nco()
        self.nb_vars = 2
        self.nb_depths = 1
        self.fillvalue_b = -128 

    def rewrite(self, file, nb_fcst, nb_fcst2, file_new):
        """
            Rewrite netcdf file to the right GODAE format
        """
        # Create File
        self.log.info(f"Write new filtered file {file_new}")
        self.nb_fcst = nb_fcst
        self.nb_fcst2 = nb_fcst2
        nc_fid = Dataset(file_new, 'w', format='NETCDF4')
        nc_fid.createDimension('numobs', None)
        nc_fid.createDimension('numvars', self.nb_vars)
        nc_fid.createDimension('numdeps', self.nb_depths)
        nc_fid.createDimension('numfcsts', self.nb_fcst)
        nc_fid.createDimension('numfcsts2', self.nb_fcst2)
        nc_fid.createDimension('string_length', 18)
        nc_fid.createDimension('string64', 64)
        nc_lon = nc_fid.createVariable('longitude','f4',('numobs'))
        nc_lon.setncatts({'long_name': u"Longitude of each location filtered over 3 days",\
                                    'units': u"degrees_east",\
                                    'comment': u"3-day Lanczos filter" })
        nc_lat = nc_fid.createVariable('latitude', 'f4',('numobs'))
        nc_lat.setncatts({'long_name': u"Latitude of each location filtered over 3 days",\
                                'units': u"degrees_north",\
                                'comment': u"3-day Lanczos filter" })
        nc_depth = nc_fid.createVariable('depth','f4',('numobs', 'numdeps'))
        nc_depth.setncatts({'long_name': u"Depth",\
                            'standard_name': u"depth",\
                            'valid_min':  -12000.0, \
                            'valid_max': 12000.0,\
                            'axis': u"Z", \
                            'positive': u"down"})
        nc_depth_qc  = nc_fid.createVariable('depth_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
        nc_depth_qc.long_name =  "Depth quality flag"
        nc_depth_qc.valid_min = 0
        nc_depth_qc.valid_max = 9
        nc_depth_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_depth_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        nc_position_qc  = nc_fid.createVariable('position_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
        nc_position_qc.long_name =  "Position quality flag"
        nc_position_qc.valid_min = 0
        nc_position_qc.valid_max = 9
        nc_position_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_position_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        nc_obsfiltr_qc  = nc_fid.createVariable('observation_qc', 'i1',('numobs','numvars'),fill_value=self.fillvalue_b)
        nc_obsfiltr_qc.long_name =  "Filtered observations quality flag"
        nc_obsfiltr_qc.valid_min = 0
        nc_obsfiltr_qc.valid_max = 9
        nc_obsfiltr_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_obsfiltr_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        nc_plateform = nc_fid.createVariable('plateform_code','c',('numobs','string64'))
        nc_plateform.long_name = "Platform code"
        nc_plateform.standard_name = "platform"

        nc_time = nc_fid.createVariable('obs_time', 'f8',('numobs'))
        nc_time.setncatts({'long_name': u"Time",\
                    'standard_name': u"time",\
                    'units': u"days since 1950-01-01T00:00:00Z"})
        nc_time.standard_name = 'time'
        nc_time.calendar = 'gregorian'
        nc_time.axis = 'T'
        nc_time_qc  = nc_fid.createVariable('time_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
        nc_time_qc.long_name =  "Time quality flag"
        nc_time_qc.valid_min = 0
        nc_time_qc.valid_max = 9
        nc_time_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_time_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        nc = Dataset(file, 'r')
        missing_value =  nc.variables['EWCT_FILTR']._FillValue
        nc_obs = nc_fid.createVariable('observation', 'f4',('numobs', 'numvars', 'numdeps'),fill_value=missing_value)
        nc_obs.setncatts({'long_name' : u"3-day filtered currents from in situ drifters",\
                                        "units" : u"m s-1",\
                                        'comment': u"3-day Lanczos filter" })
        nc_file = xr.open_dataset(file, decode_times=False)
        #variables = nc_file.data_vars
        nc_var = nc_fid.createVariable('varname', 'S1',('numvars','string_length'))
        variables_vel = ['eastward_velocity ','northward_velocity']
        nc_var.setncatts({'long_name': u"name of variables"})
        nc_var[:] = netCDF4.stringtochar(np.array(variables_vel, 'S'))
        nc_fid.variables['latitude'][:] = nc_file['LATITUDE_FILTR'].values
        nc_fid.variables['longitude'][:] = nc_file['LONGITUDE_FILTR'].values
        nc_fid.variables['obs_time'][:] = nc_file['TIME'].values
        nc_fid.variables['time_qc'][:] = nc_file['TIME_QC'].values
        nc_fid.variables['position_qc'][:] = nc_file['POSITION_QC'].values
        nc_fid.variables['depth'][:,:] = nc_file['DEPH'].values
        nc_fid.variables['depth_qc'][:] = nc_file['DEPH_QC'].values
        code_values = nc_file['PLATFORM_CODE'].values
        code_values2 = [var.decode("utf-8") for var in code_values]
        nc_fid.variables['plateform_code'][:] = code_values2
        u_cur_filtr = nc_file['EWCT_FILTR'].values
        v_cur_filtr = nc_file['NSCT_FILTR'].values
        nc_fid.variables['observation'][:,0,:] = u_cur_filtr[:,:]
        nc_fid.variables['observation'][:,1,:] = v_cur_filtr[:,:]
        nc_fid.variables['observation_qc'][:,0] = nc_file['EWCT_FILTR_QC'].values
        nc_fid.variables['observation_qc'][:,1] = nc_file['NSCT_FILTR_QC'].values
        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.contact = 'cregnier@mercator-ocean.fr'
        #nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.time_interp = "daily average fields"
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.close()

    def run_list(self,param_dict, daterun):
        liste_tot=[]
        liste_file=glob(param_dict['dirdata']+'/'+daterun[0:4]+'/*'+daterun+'*.nc')
        if not liste_file:
            self.log.error("Missing Drifters files {} {}".format(param_dict['dirdata'], daterun))
            sys.exit(1)
        self.log.info('Liste file UV drifters {}'.format(liste_file))
        nb_fcst = len(param_dict['lead_int'])
        nb_fcst2 = len(param_dict['lead_int2'])
        self.log.debug('Number of forecasts {}'.format(nb_fcst))
        for new_file in liste_file :
            try :
                file_new = 'class4_'+daterun+'_'+param_dict['cl_config_h']+'_'+param_dict['model_type'].lower()+'_currents-filtr.nc'
                ## Read and Rewrite file
                self.rewrite(liste_file[0], nb_fcst, nb_fcst2, param_dict['dirwork']+file_new)
                self.log.debug('Filename {}'.format(param_dict['dirwork']+file_new))
            except IOError as e:
                self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                raise
        liste_tot.append(param_dict['dirwork']+file_new)
        return liste_tot


class Extract_UVDrifters(Extractor):

    """ Extract and reconstruct UV drifters """

    def __init__(self, log):
        self.log = log
        # Nco constructor
        self.nco = Nco()
        self.nb_vars = 2
        self.nb_depths = 1
        self.fillvalue_b = -128 

    def rewrite(self, file, nb_fcst, nb_fcst2, file_new):
        """
            Rewrite netcdf file to the right GODAE format
        """
        # Open Dataset
        self.log.info("Open file {}".format(file))
        nc_file = xr.open_dataset(file, decode_times=False)
        # Create File
        self.log.info("Write new file {}".format(file_new))
        self.nb_fcst = nb_fcst
        self.nb_fcst2 = nb_fcst2
        nc_fid = Dataset(file_new, 'w', format='NETCDF4')
        nc_fid.createDimension('numobs', None)
        nc_fid.createDimension('numvars', self.nb_vars)
        nc_fid.createDimension('numdeps', self.nb_depths)
        nc_fid.createDimension('numfcsts', self.nb_fcst)
        nc_fid.createDimension('numfcsts2', self.nb_fcst2)
        nc_fid.createDimension('string_length', 18)
        nc_fid.createDimension('string64', 64)
        nc_lon = nc_fid.createVariable('longitude','f4',('numobs'))
        nc_lon.setncatts({'long_name': u"Longitudes",\
                                    'units': u"degrees_east"})
        nc_lat = nc_fid.createVariable('latitude', 'f4',('numobs'))
        nc_lat.setncatts({'long_name': u"Latitudes",\
                                'units': u"degrees_north"})
        nc_depth = nc_fid.createVariable('depth','f4',('numobs', 'numdeps'))
        nc_depth.setncatts({'long_name': u"Depth",\
                            'standard_name': u"depth",\
                            'valid_min':  -12000.0, \
                            'valid_max': 12000.0,\
                            'axis': u"Z", \
                            'positive': u"down"})
        nc_depth_qc  = nc_fid.createVariable('depth_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
        nc_depth_qc.long_name =  "Depth quality flag"
        nc_depth_qc.valid_min = 0
        nc_depth_qc.valid_max = 9
        nc_depth_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_depth_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        nc_position_qc  = nc_fid.createVariable('position_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
        nc_position_qc.long_name =  "Position quality flag"
        nc_position_qc.valid_min = 0
        nc_position_qc.valid_max = 9
        nc_position_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_position_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        
        nc_obs_qc  = nc_fid.createVariable('observation_qc', 'i1',('numobs','numvars'),fill_value=self.fillvalue_b)
        nc_obs_qc.long_name =  "Observations quality flag"
        nc_obs_qc.valid_min = 0
        nc_obs_qc.valid_max = 9
        nc_obs_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_obs_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
        
        nc_plateform = nc_fid.createVariable('plateform_code','c',('numobs','string64'))
        nc_plateform.long_name = "Platform code"
        nc_plateform.standard_name = "platform"

        nc_time = nc_fid.createVariable('obs_time', 'f8',('numobs'))
        nc_time.setncatts({'long_name': u"Time",\
                    'standard_name': u"time",\
                    'units': u"days since 1950-01-01T00:00:00Z"})
        nc_time.standard_name = 'time'
        nc_time.calendar = 'gregorian'
        nc_time.axis = 'T'
        nc_time_qc  = nc_fid.createVariable('time_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
        nc_time_qc.long_name =  "Time quality flag"
        nc_time_qc.valid_min = 0
        nc_time_qc.valid_max = 9
        nc_time_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
        nc_time_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"

        nc = Dataset(file, 'r')
        missing_value =  nc.variables['EWCT_FILTR']._FillValue
        nc_obs = nc_fid.createVariable('observation', 'f4',('numobs', 'numvars', 'numdeps'),fill_value=missing_value)
        nc_obs.setncatts({'long_name' : u"currents from in situ drifters",\
                                        "units" : u"m s-1" })
        nc_var = nc_fid.createVariable('varname', 'S1',('numvars','string_length'))
        variables_vel = ['eastward_velocity ','northward_velocity']
        nc_var.setncatts({'long_name': u"name of variables"})
        nc_var[:] = netCDF4.stringtochar(np.array(variables_vel, 'S'))
        nc_fid.variables['longitude'][:] = nc_file['LONGITUDE'].values
        nc_fid.variables['latitude'][:] = nc_file['LATITUDE'].values
        nc_fid.variables['obs_time'][:] = nc_file['TIME'].values
        nc_fid.variables['time_qc'][:] = nc_file['TIME_QC'].values
        nc_fid.variables['position_qc'][:] = nc_file['POSITION_QC'].values
        nc_fid.variables['depth'][:,:] = nc_file['DEPH'].values
        nc_fid.variables['depth_qc'][:] = nc_file['DEPH_QC'].values
        code_values = nc_file['PLATFORM_CODE'].values
        code_values2 = [var.decode("utf-8") for var in code_values]
        nc_fid.variables['plateform_code'][:] = code_values2
        u_cur = nc_file['EWCT'].values
        v_cur = nc_file['NSCT'].values
        nc_fid.variables['observation'][:,0,:] = u_cur[:,:]
        nc_fid.variables['observation'][:,1,:] = v_cur[:,:]
        nc_fid.variables['observation_qc'][:,0] = nc_file['EWCT_QC'].values
        nc_fid.variables['observation_qc'][:,1] = nc_file['NSCT_QC'].values

        # Add global attributs
        nc_fid.institution = 'MERCATOR OCEAN'
        nc_fid.contact = 'cregnier@mercator-ocean.fr'
        #nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
        nc_fid.time_interp = "daily average fields"
        #today = date.today()
        #yyyy = str(today)[0:4]
        #yyyy2 = dateval[0:4]
        #month = str(today)[5:7]
        #month2 = dateval[4:6]
        #day = str(today)[8:10]
        #day2 = dateval[6:8]
        #nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        #nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
        #nc_fid.system = model
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.close()

    def run_list(self,param_dict, daterun):
        liste_tot=[]
        liste_file=glob(param_dict['dirdata']+'/'+daterun[0:4]+'/*'+daterun+'*.nc')
        if not liste_file:
            self.log.error("Missing Drifters files {} {}".format(param_dict['dirdata'], daterun))
            sys.exit(1)
        self.log.info('Liste file UV drifters {}'.format(liste_file))
        nb_fcst = len(param_dict['lead_int'])
        nb_fcst2 = len(param_dict['lead_int2'])
        self.log.debug('Number of forecasts {}'.format(nb_fcst))
        for new_file in liste_file :
            try :
                file_new = 'class4_'+daterun+'_'+param_dict['cl_config_h']+'_'+param_dict['model_type'].lower()+'_currents.nc'
                ## Read and Rewrite file
                self.rewrite(liste_file[0], nb_fcst, nb_fcst2, param_dict['dirwork']+file_new)
                self.log.debug('Filename {}'.format(param_dict['dirwork']+file_new))
            except IOError as e:
                self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                raise
        liste_tot.append(param_dict['dirwork']+file_new)
        return liste_tot

class Extract_GODAE(Extractor):

    """ Extract GODAE file """

    def __init__(self, log):
        self.log = log

    def run(self,daterun,dirdata,dirtmp,typedata,template,nb_fcst):

        if typedata != "SLA" and  typedata != "SST" and typedata != "profile" \
            and typedata !=  "aice" and typedata !=  "AMSR" and  typedata !=  "current" :
            self.log.error("Data %s not known !!! " %(typedata))
            sys.exit(1)
        #valeurj=date1
        liste_tot=[]
        # Nco constructor
        nco = Nco()
        #while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
        #    dateval=SyDate.__str__(valeurj)
        self.log.info('Day  %s ' % (daterun)) 
        if typedata ==  "AMSR" : 
            liste_file=glob(dirdata+'/*'+daterun+'*.nc')
        else :
            liste_file=[glob(dirdata+'/class4*'+daterun+'*'+typedata+'*.nc')[0]]
        # liste_file=glob(dirdata+'/*[TS]*'+daterun+'*.nc')
        self.log.info('Liste file %s ' % (liste_file))
        for new_file in liste_file :
            try :
                filename=os.path.basename(new_file)
                if typedata ==  "AMSR" :
                    filename=re.sub('GL_h5',template,filename)
                elif typedata ==  "current":
                    filename=filename
                else:
                    template1 = filename.split('_')[0:]
                    template_tmp = template1[2]+'_'+template1[3]+'_'+template1[4]
                    filename=re.sub(template_tmp,template,filename)
                # Copy extracted value of GODAE file with nco module
                if typedata != "aice" and typedata != 'current':
                    ## Change numfcts dim
                    options = []
                    options.extend(['-h','-O','-a','numfcsts'])
                    nco.ncwa(input=new_file, output=dirtmp+filename, fortran=True ,options=options)
                    nc = netCDF4.Dataset(dirtmp+filename, 'r')
                    variables = nc.variables.keys()
                    if 'modeljuld' in variables:
                       command ="ncap2 -h -O -s "
                       command2 = "\'defdim(\"numfcsts\","+str(nb_fcst)+");leadtime_new[$numfcsts]=leadtime;modeljuld_new[$numfcsts]=modeljuld\' "
                       os.system(command+command2+dirtmp+filename+" "+dirtmp+filename)
                    else:
                        self.log.info('no modeljuld !!')
                    options = []
                    if typedata == "SLA" :
                        options.extend(['-h','-O','-xv','best_estimate,forecast,persistence,altimeter_bias,mdt_reference,leadtime,modeljuld'])
                    else :
                        options.extend(['-h','-O','-xv','best_estimate,forecast,persistence,leadtime,modeljuld'])
                    nco.ncks(input=dirtmp+filename,output=dirtmp+filename, fortran=True ,options=options)
                    # Rename
                    options = []
                    if 'modeljuld' in variables:
                        options.extend(['-h','-O','-v','modeljuld_new,modeljuld'])
                        nco.ncrename(input=dirtmp+filename,output=dirtmp+filename, options=options)
                        options = []
                        options.extend(['-h','-O','-v','leadtime_new,leadtime'])
                        nco.ncrename(input=dirtmp+filename,output=dirtmp+filename,options=options)
                    self.log.info("add new dim ok {}".format(dirtmp+filename))
                elif typedata == "current":
                    options = []
                    shutil.copy(dirdata+filename,dirtmp)
                else:
                    #typedata == "aice" :
                    options = []
                    options.extend(['-h','-O','-xv','best_estimate,forecast,persistence'])
                    nco.ncks(input=new_file,output=dirtmp+filename,options=options)
                if typedata == "AMSR" :
                    # add missing varname
                    # Solution2 : add dimensions and variable varname
                    cl_fileIn=dirtmp+filename
                    nc   = netCDF4.Dataset(cl_fileIn,'a')
                    nc.createDimension('string_length8',8)
                    # for AMSR
                    nc.createDimension('numvars',1)
                    nc.createVariable('varname','c',('numvars','string_length8'))
                    nc.variables['varname'][:]='ileadfra'
                    nc.close
                self.log.info('Fichier extracted %s ' % (dirtmp+filename)) 
                liste_tot.append(dirtmp+filename)
                # Design output File
                # Design_file('GODAE').run(dirtmp+filename)
            except IOError as e:
                self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                raise
        #valeurj=valeurj.goforward(1)

        return liste_tot



class Extract_ARMOR(Extractor):

    """ Extract ARMOR file """

    def __init__(self, log):
        self.log = log

    def run(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        valeurj=date1
        liste_tot=[]
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            self.log.info('Day %s ' % (dateval)) 
            frame=dirdata+prefix+'*'+dateval.strip()+'*.nc*'
            liste_file=glob(frame)
            # liste_file=glob(dirdata+'/*[TS]*'+dateval+'*.nc')
            self.log.info('Liste file %s ' % (liste_file)) 
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    if filename[-2:] == 'gz' :
                        self.log.info('Dezip')
                        filename2=filename
                        dezip=ZipManipulator(dirtmp)
                        fichier=dirtmp+filename2
                        dezip.gunzip(fichier)
                        filename=fichier.split('.gz')[:][0]
                        # tar = tarfile.open(dirtmp+filename2, "r:gz")
                        # tar.extractall()
                        # tar.close()
                        liste_tot.append(filename)
                    else :
                        liste_tot.append(dirtmp+filename)
                    self.log.info("append : %s " %(filename))
                except IOError as e:
                    print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj=valeurj.goforward(1)

        return liste_tot

    def run_list(self,date1,date2,dirdata):
        liste_tot=[]
        valeurj=date1
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            #print dirdata+'/*'+dateval+'*.nc'
            liste_file=glob(dirdata+'/*'+dateval+'*.nc')
            for file in liste_file :
                try :
                    liste_tot.append(file)
                except IOError as e:
                    print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj=valeurj.goforward(1)
        return liste_tot


class Extract_cora3(Extractor) :

    """ Extract Cora3 file """

    def __init__(self, log):
        self.PREFIX='cora3.4_merc'
        self.log = log

    def run(self,date1,date2,dirdata,dirtmp,typedata,template):
        self.log.info('Extraction of Cora 3 dataset')
        presmonth=SyDate.__str__(date2)[:6]
        backmonth=SyDate.__str__(date1)[:6]
        liste_month=[]
        liste_file=[]
        if presmonth == backmonth : 
            liste_file.append(file)
            liste_month.append(presmonth)
        else :
            file1=self.PREFIX+"_"+presmonth+".tgz"
            liste_file.append(file1)
            file2=self.PREFIX+"_"+backmonth+".tgz"
            liste_file.append(file2)
            liste_month.append(presmonth)
            liste_month.append(backmonth)
        # Extract and copy file
        for file in liste_file:
            file_path=dirdata+file
            if os.path.isfile(file_path)  :
                try :
                    shutil.copy(file_path,dirtmp)
                    os.chdir(dirtmp)
                    tar = tarfile.open(file)
                    tar.extractall()
                    tar.close()
                    os.remove(file)
                except  IOError as e :
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    raise e
            else :
                self.log.error('file not known %s ' %(file_path))
                sys.exit(1)
        liste_tot=[]
        for month in liste_month : 
            valeurj=date1
            year=SyDate.__str__(valeurj)[:4]
            while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
                dateval=SyDate.__str__(valeurj)
                self.log.info('Day  %s ' % (dateval)) 
                liste_file=glob(dirtmp+'/'+year+'/*'+dateval+'*.nc')
                self.log.info('Day list %s ' % (liste_file)) 
                for new_file in liste_file :
                    try :
                        # os.rename(new_file,dirtmp)
                        # shutil.move(dirtmp,new_file)
                        shutil.copy(new_file,dirtmp)
                        liste_tot.append(new_file)
                    except IOError as e:
                        self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                        raise e
                valeurj=valeurj.goforward(1)
            # Remove directory 
            shutil.rmtree(dirtmp+year)
        # Write log

        return liste_tot


class Extract_cora4(Extractor) :

    """ Extract Cora4 file """

    def __init__(self,compressi,log):
        """

        Constructor cora 4

        """
        self.PREFIX='cora4.0_merc'
        self.compress=compress
        self.log = log

    def run(self,date1,date2,dirdata,dirtmp,typedata,templat,prefix):
        self.log.info('Extractor cora4 : '+self.compress)
        presyear=SyDate.__str__(date2)[:4]
        backyear=SyDate.__str__(date1)[:4]
        liste_file=[]
        liste_year=[]
        if presyear == backyear : 
            file=prefix+"_"+presyear+self.compress
            liste_file.append(file)
            liste_year.append(presyear)
        else :
            file1=prefix+"_"+presyear+self.compress
            liste_file.append(file1)
            file2=prefix+"_"+backyear+self.compress
            liste_file.append(file2)
            liste_year.append(presyear)
            liste_year.append(backyear)
        # Extract and copy file
        for file in liste_file :
            file_path=dirdata+file
            # Test the existence of the year
            if not os.path.isdir(dirtmp+liste_year[0]):
                print ("Directory doesn t exist extract")
                if os.path.isfile(file_path)  :
                    try :
                        shutil.copy(file_path,dirtmp)
                        os.chdir(dirtmp)
                        tar = tarfile.open(file)
                        tar.extractall()
                        tar.close()
                        os.remove(file)
                    except  IOError as e :
                        self.log.error ("I/O error({0}): {1}".format(e.errno, e.strerror))
                        raise e
                        # print 'Problem with copy or extraction'
                else :
                    self.log.error('file not known %s ' %(file_path))
                    sys.exit(1)
            else :
                print ("Directory already exist")
        # Remove file
        liste_tot=[]
        for year in liste_year : 
            valeurj=date1
            while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
                dateval=SyDate.__str__(valeurj)
                self.log.info('Day  %s ' % (dateval)) 
                liste_file=glob(dirtmp+'/'+year+'/*'+dateval+'*.nc')
                for file in liste_file :
                    try :
                        self.log.info('Fichier  %s ' % (file))
                        shutil.move(file,dirtmp)
                        filename=os.path.basename(file)
                        liste_tot.append(dirtmp+filename)
                    except IOError as e:
                        self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                        raise e
                valeurj=valeurj.goforward(1)
            # Remove directory 
            # shutil.rmtree(dirtmp+year)
        # Write log
        ok_file=dirtmp+"Extract_cora4_"+str(presyear)+"_"+str(backyear)+"_OK"
        return liste_tot

    def run_list(self,date1,date2,dirdata):
        liste_tot=[]
        valeurj=date1
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            liste_file=glob(dirdata+'/*'+dateval+'*.nc')
            for file in liste_file :
                try :
                    liste_tot.append(file)
                except IOError as e:
                    self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                    raise e
            valeurj=valeurj.goforward(1)
        return liste_tot
