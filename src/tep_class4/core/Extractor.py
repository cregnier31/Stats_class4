from __future__ import generators
import os
import sys
import shutil
from glob import glob
import re
import numpy as np
import logging
import time
import netCDF4
from .sydate import SyDate
import zipfile
#from nco.nco import Nco
import xarray as xr
from netCDF4 import Dataset, stringtochar
import subprocess
from datetime import datetime
from functools import reduce
from datetime import date
from filelock import FileLock

import tempfile

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
        if type == "CORA5.2":
            return Extract_cora5_2(self.log)
        if type == "CORIO_ASSIM":
            return Extract_corio_cmems(self.log)
        if type == "CORIOLIS":
            return Extract_corio(self.log)
        if "CORIOLIS_RAW" in type :
            return Extract_corio_raw(self.log, type)
        if "ARMOR_" in type  or type == "AR_":
            return Extract_ARMOR(self.log)
        if type == "GODAE_UV":
            return Extract_UVDrifters(self.log)
        if type == "GODAE_UV_filtr": 
            return Extract_UVDrifters_filtr(self.log)
        if type == "GODAE":
            return Extract_GODAE(self.log)
        if type == "L3m":
            return Extract_genericData(self.log)
        if type.startswith("BGC_ARGO"):
            return Extract_BGC_ARGO(self.log)
        if type == "L3mCHL":
            return Extract_CHLORO(self.log)
        if "Microwat_" in type :
            return Extract_genericData(self.log)
        if type == "001_048" :
            return Extract_CMEMS_drifters(self.log)
        if "sssdata_netcdf_" in type :
            return Extract_SSSData(self.log)
        if type == "Legos_SIT" :
            return Extract_Legos_SIT(self.log)
        if type == "MDS_L3_SLA" :
            return Extract_MDS_L3_SLA(self.log)
        else :
            raise NameError(f'type {type} not found ')

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

    def run_list_data(self, param_dict, dirdata, dateval):
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
        liste_file = glob(f"{dirdata}{YEAR}/*{dateval}*.nc")
        if len(liste_file) == 0:
            raise NameError(f"Empty list: {dirdata}{YEAR}/*{dateval}*.nc")
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                if not os.path.exists(param_dict['dirwork']+filename):
                    shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:  
                raise IOError(f"Couldn't copy file={file} to {param_dict['dirwork']}.")
        return liste_tot
        
        
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
        liste_file = glob(f"{param_dict['dirdata']}/{YEAR}/*{dateval}*.nc")
        if len(liste_file) == 0 :
            raise IOError(f"There are no files in: {param_dict['dirdata']}/{YEAR}/*{dateval}*.nc")
        for file in liste_file:
            filename = os.path.basename(file)
            if not os.path.exists(param_dict['dirwork']+filename):
                shutil.copy(file, param_dict['dirwork']+filename)
            liste_tot.append(param_dict['dirwork']+filename)
        return liste_tot

class Extract_Legos_SIT(Extractor):

    """ Class to extract Legos SIT l3 files """
    def __init_(self, log):
        self.log = log

    def run_list(self, param_dict, daterun):
        liste_tot=[]
        liste_file=glob(f"{param_dict['dirdata']}/*{daterun}*.nc")
        if len(liste_file)==0:
            raise IOError(f"Missing Legos_SIT {param_dict['dirdata']}/*{daterun}*.nc")
        for file in liste_file:
            filename = os.path.basename(file)
            shutil.copy(file, param_dict['dirwork']+filename)
            liste_tot.append(param_dict['dirwork']+filename)

        return liste_file

    def run_over(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        valeurj_tmp = SyDate(str(date1))
        valeurj = valeurj_tmp
        valeurj2 = SyDate(str(date2))
        liste_tot=[]
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            self.log.info('Day 5.2 %s ' % (dateval))
            #month=dateval[0:6]
            #year=dateval[0:4]
            frame=dirdata+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            if len(liste_file) == 0:
                raise IOError(f"There are no files in {frame}")
            self.log.info(f'Liste file CORA {liste_file}')
            for new_file in liste_file :
                filename=os.path.basename(new_file)
                shutil.copy(new_file,dirtmp)
                self.log.info('copy file {}'.format(dirtmp+filename))
                liste_tot.append(dirtmp+filename)
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
        liste_file = glob(f"{param_dict['dirdata']}*{dateval}*.nc")
        if len(liste_file) == 0:
            raise IOError(f"There are no files {param_dict['dirdata']}*{dateval}*.nc")

        for file in liste_file:
            filename = os.path.basename(file)
            shutil.copy(file, param_dict['dirwork']+filename)
            liste_tot.append(param_dict['dirwork']+filename)
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
        options = []
        options.extend(['-h'])
        # Nco constructor
        #nco = Nco()
        # Create a timeline
        timelinespace = self.timelinespace(date1,date2)
        liste_file = glob(f"{dirdata+}/*nc")
        length = len(liste_file)
        if length == 0 :
            self.log.debug(f'There are no files in {dirdata}/*nc')
        for indice, file in enumerate(liste_file):
                filename = os.path.basename(file)
                data_type = filename.split(prefix)[1].split('_')[1]
                nc = netCDF4.Dataset(file, 'r')
                # Extract time variable
                variable = self.dimension
                v = nc.variables[variable][:]
                # Convert to date
                date_all = [SyDate.__str__(self.date.setfromjulian(
                    int(valeurtmp))) for valeurtmp in v]
                unique_date = reduce(
                    lambda l_val, x: l_val+[x] if x not in l_val else l_val, date_all, [])
                ## Find the correspondance with 2 lists
                list1 = set(timelinespace)
                list2 = set(unique_date)
                date_values = list(list1.intersection(list2))
                if date_values:
                    self.log.info("Not empty ")
                    for date in date_values:
                        ## find indexes in date_all
                        indexes = [i for i, x in enumerate(
                                   date_all) if x == date]
                        file_out = f"{prefix}_{data_type}_{date}.nc"
                        out_path = dirtmp + file_out
                        self.log.info("Creation fileout: %s" % file_out) 
                        ## Create output extracted file
                        # Open dataset
                        ds = xr.open_dataset(file)
                        # Slice the dimension between first and last index
                        ds_sel = ds.isel({self.dimension: slice(indexes[0], indexes[-1] + 1)})
                        # Save to new file
                        ds_sel.to_netcdf(out_path)
                        #nco.ncks(input=file, output=dirtmp+file_out, dimension=self.dimension+','+str(
                        #    indexes[0])+','+str(indexes[-1]), options=options)
                        if dirtmp+file_out not in liste_tot:
                            #liste_tot.append(dirtmp+file_out)
                            liste_tot.append(out_path)
            # Search index 
            self.log.debug("File ok : %s %i %i" %(file,indice,length))
        return liste_tot


class Extract_genericData(Extractor):

    """ Extract files """

    def run_list(self, param_dict, dateval):
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log =logging.getLogger("Extract Generic files")
        self.log.setLevel(logging.INFO)
        liste_tot = []
        liste_file = glob(f"{param_dict['dirdata']}/*{dateval}*.nc")
        if len(liste_file) == 0:
            self.log.debug(f"There are no files at {param_dict['dirdata']}/*{dateval}*.nc")

        for file in liste_file:
            filename = os.path.basename(file)
            shutil.copy(file, param_dict['dirwork']+filename)
            liste_tot.append(param_dict['dirwork']+filename)

        return liste_tot

class Extract_BGC_ARGO(Extractor):

    """ Extract files """

    def __init__(self, log):
        self.log = log

    def run_list(self, param_dict, dateval):
        liste_tot = []
        self.log.info(f"Inside Extract_BGC_ARGO {dateval}")
        liste_file = glob(f"{param_dict['dirdata']}/*{dateval[0:6]}*.nc")
        if len(liste_file) == 0:
            self.log.debug(f"There are no files {param_dict['dirdata']}/*{dateval[0:6]}*.nc")
        for file in liste_file:
            filename = os.path.basename(file)
            shutil.copy(file, param_dict['dirwork']+filename)
            liste_tot.append(param_dict['dirwork']+filename)
        self.log.info(f"liste {liste_tot}")
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
        self.log.info('Extract_CHLORO')
        liste_file = glob(f"{param_dict['dirdata']}/{dateval}*.nc")
        if len(liste_file) == 0:
            liste_file = glob(param_dict['dirdata']+'/'+dateval+'*DT'+'*.nc')
            if len(liste_file) == 0:
                liste_file = glob(param_dict['dirdata']+'/'+dateval+'*NRT'+'*.nc')
                if len(liste_file) == 0:
                    raise NameError(f"There are no files in list for CHLORO {param_dict['dirdata']}/{dataeval}*.nc")
        for file in liste_file:
            filename = 'Class4_'+dateval+'_'+param_dict['data_origin']+'_'+param_dict['cl_conf']+'_'+param_dict['varname'][0]+'.nc'
            self.mkdir(param_dict['dirwork'])
            shutil.copy(file,param_dict['dirwork']+filename)
            liste_tot.append(param_dict['dirwork']+filename)

        return liste_tot

class Extract_corio_raw(Extractor):

    """ Extract coriolis raw common file """

    def __init__(self, log, datatype): 

        # ===============
        # LOGGER
        # ===============
        self.log = log
        self.date=SyDate('19500101')
        self.datatype = datatype

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
                    file_out = f"{val}_{frame}_profile_{ind}.nc"
                    out_path = dirtmp + file_out
                    # Open dataset
                    ds = xr.open_dataset(file)
                    # Select slice along the dimension
                    ds_sel = ds.isel({dimprof: ind})
                    # Save to new file
                    ds_sel.to_netcdf(out_path)
                    liste_tot.append(out_path)
                ind+=1
        return liste_tot
    
    def run_list(self, param_dict, dateval):
        """
         Create a list of data corresponding to a specific date
         Arguments
         -----------------------------
         param_dict : dictionnary with all the parameters
         dateval : date value
         Returns
         -----------------------------
         liste_tot : list of input data corresponding to a date and a type on input data
        """
        liste_tot = []
        YEAR = dateval[0:4]
        liste_prof_PR_PF = ['PR_PF']
        liste_prof_TS_DB = ['TS_DB']
        liste_prof_type1 = ['PR_CT', 'PR_XB', 'PR_SM', 'PR_GL']

        base_pattern = f"{param_dict['dirdata']}/*{dateval}*.nc"
        liste_all = glob(base_pattern)

        if self.datatype == "CORIOLIS_RAW_PR_PF":
            frame = "PR_PF"
            liste_file = [f for f in liste_all if any(tag in f for tag in liste_prof_PR_PF)]
            self.log.debug(f"Search file {self.datatype} {param_dict['dirdata']}/*{frame}*{dateval}*nc")
        elif self.datatype == "CORIOLIS_RAW_TS_DB":
            frame = "TS_DB"
            liste_file = [f for f in liste_all if any(tag in f for tag in liste_prof_TS_DB)]
            self.log.debug(f"Search file {self.datatype} {param_dict['dirdata']}/*{frame}*{dateval}*nc")
        elif self.datatype == "CORIOLIS_RAW_type1":
            liste_file = [f for f in liste_all if any(tag in f for tag in liste_prof_type1)]
            self.log.debug(f"Search file {self.datatype} {param_dict['dirdata']}/*{frame}*{dateval}*nc")
        elif self.datatype == "CORIOLIS_RAW_type2":
            liste_file = [
                        f for f in liste_all
                        if not any(tag in f for tag in liste_prof_PR_PF + liste_prof_TS_DB + liste_prof_type1)
            ] 
            self.log.debug(f"Search file {self.datatype} {param_dict['dirdata']}/*{frame}*{dateval}*nc")
        elif self.datatype == "CORIOLIS_RAW":
            liste_file = liste_all
            self.log.debug(f"Search file {liste_file}")

        for file in liste_file:
                filename = os.path.basename(file)
                if not os.path.exists(param_dict['dirwork']+filename):
                    shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
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
        if len(liste_file) == 0 :
            raise IOError(f'There are no files in {frame}')
        for new_file in liste_file :
                filename=os.path.basename(new_file)
                shutil.copy(new_file,param_dict['dirtmp'])
                liste_tot.append(param_dict['dirtmp']+filename)

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
        self.log.info(f'Extract CORA 5.2 {valeurj_tmp} {valeurj} {valeurj2}')
        while  valeurj_tmp >= valeurj and valeurj_tmp <= valeurj2 :
            dateval = str(valeurj_tmp)
            self.log.info(f'Day 5.2 {dateval}')
            year=dateval[0:4]
            type_obs = "PR_PF"
            frame=dirdata+year+'/*'+dateval.strip()+f"*{type_obs}_*.nc"
            self.log.info(f"{frame=}")
            liste_file=glob(frame)
            self.log.debug(f'{frame=}')
            self.log.info(f'Liste file CORA {liste_file}')

            for new_file in liste_file :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.debug('copy file ok {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
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
            dateval[0:6]
            dateval[0:4]
            frame=dirdata+'/*'+dateval.strip()+'*.nc'
            liste_file=glob(frame)
            self.log.info('Liste file CORA %s ' % (liste_file))
            for new_file in liste_file :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.info('copy file {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
            valeurj_tmp=valeurj_tmp.goforward(1)

        return liste_tot

    def run_list(self, param_dict, dateval):
        liste_tot = []
        YEAR = dateval[0:4]
        #type_obs = "PR_PF"
        #type_obs = "TS_MO"
        #type_obs = "XX"
        #type_obs = "PR_GL"
        #type_obs = "PR_CT"
        #type_obs = "TS_FB"
        #type_obs = "PR_BO"
        #type_obs = "PR_XB"
        type_obs = "*"
        liste_file = glob(f"{param_dict['dirdata']}/{YEAR}/*{dateval}*{type_obs}*.nc")
        self.log.debug(f"Search file  {liste_file}")
        for file in liste_file:
                filename = os.path.basename(file)
                if not os.path.exists(param_dict['dirwork']+filename):
                    self.log.debug(f"Copy file {file}")
                    if os.path.exists(file) and os.access(file, os.R_OK):
                        shutil.copy(file, param_dict['dirwork']+filename)
                    else:
                        print(f"Source file {file} is not accessible.")
                        sys.exit(1)
                liste_tot.append(param_dict['dirwork']+filename)
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
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    self.log.info('copy file {}'.format(dirtmp+filename))
                    liste_tot.append(dirtmp+filename)
            valeurj_tmp=valeurj_tmp.goforward(1)

        return liste_tot

class Extract_UVDrifters_filtr(Extractor):

    """ Extract and reconstruct UV drifters """

    def __init__(self, log):
        self.log = log
        self.nb_vars = 2
        self.nb_depths = 1
        self.fillvalue_b = -128
        self.fillvalue_s = -32767
        self.fillvalue_R4 = netCDF4.default_fillvals['f4']

    def check_all_attributes(self, nc):
        errors = []
        for attr in nc.ncattrs():
                getattr(nc, attr)
        for var_name, var in nc.variables.items():
            for attr in var.ncattrs():
                    getattr(var, attr)
        return errors
 
 
    def check_netcdf_valid(self, filename, timeout=10, log=None):
        start = time.time()
        while True:
            try:
                with Dataset(filename, 'r') as nc:
                    if log: log.info(f"{filename} is valid")
                    return True
            except OSError:
                if time.time() - start > timeout:
                    if log: log.error(f"{filename} not readable after {timeout}s")
                    return False
                time.sleep(0.5)

    def rewrite(self, file, nb_fcst, nb_fcst2, file_new):
        """
            Rewrite netcdf file to the right GODAE format
        """
        # Create File
        self.log.info(f"NEW rewrite function")
        self.log.debug(f"Write new filtered file {file_new}")
        lock_path = file_new + ".lock"
        with FileLock(lock_path):
            if not os.path.exists(file_new):
                self.nb_fcst = nb_fcst
                self.nb_fcst2 = nb_fcst2
                nc_file = xr.open_dataset(file, decode_times=False, chunks=None)
                variables = nc_file.data_vars
                lon_obs  = nc_file['LONGITUDE_FILTR'].values
                lat_obs = nc_file['LATITUDE_FILTR'].values
                time_obs =  nc_file['TIME'].values
                time_obs_qc = nc_file['TIME_QC'].values
                position_qc = nc_file['POSITION_QC'].values
                depth_obs = nc_file['DEPH'].values
                depth_obs_qc = nc_file['DEPH_QC'].values
                code_values_obs = nc_file['PLATFORM_CODE'].values
                u_obs_filt = nc_file['EWCT_FILTR'].values
                v_obs_filt = nc_file['NSCT_FILTR'].values
                u_obs_qc = nc_file['EWCT_FILTR_QC'].values
                v_obs_qc = nc_file['NSCT_FILTR_QC'].values
                if 'EWCT_WS_FILTR' and 'NSCT_WS_FILTR' in variables.keys():
                    u_filtr_ws = nc_file['EWCT_WS_FILTR'].values
                    v_filtr_ws = nc_file['NSCT_WS_FILTR'].values
                    u_filtr_ws_qc = nc_file['EWCT_WS_FILTR_QC'].values
                    v_filtr_ws_qc = nc_file['NSCT_WS_FILTR_QC'].values
                else:
                    u_filtr_ws = np.full(u_obs_filt.shape, np.nan)
                    v_filtr_ws = np.full(v_obs_filt.shape, np.nan)
                    u_filtr_ws_qc = np.copy(u_obs_qc)
                    v_filtr_ws_qc = np.copy(v_obs_qc)
                    u_filtr_ws_qc[:, :] = 9
                    v_filtr_ws_qc[:, :] = 9
                if "CURRENT_TEST" in variables.keys():
                    current_test = nc_file['CURRENT_TEST'].values
                else:
                    current_test = None
                
                nc_file.close()
                nc = Dataset(file, 'r')
                missing_value =  nc.variables['EWCT_FILTR']._FillValue
                nc.close()
                #nc_fid_rewrite = Dataset(file_new, 'w', format='NETCDF4', locking=True)
                self.log.info(f"Rewrite file")
                nc_fid_rewrite = Dataset(file_new, 'w', format='NETCDF4')
                nc_fid_rewrite.createDimension('numobs', None)
                nc_fid_rewrite.createDimension('numvars', self.nb_vars)
                nc_fid_rewrite.createDimension('numdeps', self.nb_depths)
                nc_fid_rewrite.createDimension('numfcsts', self.nb_fcst)
                nc_fid_rewrite.createDimension('numfcsts2', self.nb_fcst2)
                nc_fid_rewrite.createDimension('string_length', 18)
                nc_fid_rewrite.createDimension('string64', 64)
                #nc_fid_rewrite.close()
                nc_lon = nc_fid_rewrite.createVariable('longitude','f4',('numobs'))
                nc_lon.setncatts({'long_name': u"Longitude of each location filtered over 3 days",\
                                            'units': u"degrees_east",\
                                            'comment': u"3-day Lanczos filter" })
                nc_lat = nc_fid_rewrite.createVariable('latitude', 'f4',('numobs'))
                nc_lat.setncatts({'long_name': u"Latitude of each location filtered over 3 days",\
                                        'units': u"degrees_north",\
                                        'comment': u"3-day Lanczos filter" })
                nc_depth = nc_fid_rewrite.createVariable('depth','f4',('numobs', 'numdeps'))
                nc_depth.setncatts({'long_name': u"Depth",\
                                    'standard_name': u"depth",\
                                    'valid_min':  -12000.0, \
                                    'valid_max': 12000.0,\
                                    'axis': u"Z", \
                                    'positive': u"down"})
                nc_depth_qc  = nc_fid_rewrite.createVariable('depth_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
                nc_depth_qc.long_name =  "Depth quality flag"
                nc_depth_qc.valid_min = 0
                nc_depth_qc.valid_max = 9
                nc_depth_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
                nc_depth_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
                nc_position_qc  = nc_fid_rewrite.createVariable('position_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
                nc_position_qc.long_name =  "Position quality flag"
                nc_position_qc.valid_min = 0
                nc_position_qc.valid_max = 9
                nc_position_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
                nc_position_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
                nc_obsfiltr_qc  = nc_fid_rewrite.createVariable('observation_qc', 'i1',('numobs','numvars'),fill_value=self.fillvalue_b)
                nc_obsfiltr_qc.long_name =  "Filtered observations quality flag"
                nc_obsfiltr_qc.valid_min = 0
                nc_obsfiltr_qc.valid_max = 9
                nc_obsfiltr_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
                nc_obsfiltr_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
                nc_plateform = nc_fid_rewrite.createVariable('plateform_code','c',('numobs','string64'))
                nc_plateform.long_name = "Platform code"
                nc_plateform.standard_name = "platform"

                nc_ws_qc  = nc_fid_rewrite.createVariable('windage_qc', 'i1',('numobs','numvars'),fill_value=self.fillvalue_b)
                nc_ws_qc.long_name =  "Windage quality flag"
                nc_ws_qc.valid_min = 0
                nc_ws_qc.valid_max = 9
                nc_ws_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
                nc_ws_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
       
                nc_current_test  = nc_fid_rewrite.createVariable('current_test', 'i2',('numobs'),fill_value=self.fillvalue_s)
                nc_current_test.long_name = "Flag tests of drogue loss results"
                nc_current_test.description ="3 flags for 3 tests : Submersion Acceleration_buoy Wind-current-corr"
                nc_current_test.flag_values = "0, 1, 2, 3"
                nc_current_test.flag_meanings = "Drogue_probably_missing Test_not_performed Weak_probability_of_drogue_presence Strong_probability_of_drogue_presence"
                 
                nc_time = nc_fid_rewrite.createVariable('obs_time', 'f8',('numobs'))
                nc_time.setncatts({'long_name': u"Time",\
                            'standard_name': u"time",\
                            'units': u"days since 1950-01-01T00:00:00Z"})
                nc_time.standard_name = 'time'
                nc_time.calendar = 'gregorian'
                nc_time.axis = 'T'
                nc_time_qc  = nc_fid_rewrite.createVariable('time_qc', 'i1',('numobs'),fill_value=self.fillvalue_b)
                nc_time_qc.long_name =  "Time quality flag"
                nc_time_qc.valid_min = 0
                nc_time_qc.valid_max = 9
                nc_time_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
                nc_time_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
                nc_obs = nc_fid_rewrite.createVariable('observation', 'f4',('numobs', 'numvars', 'numdeps'),fill_value=missing_value)
                nc_obs.setncatts({'long_name' : u"3-day filtered currents from in situ drifters",\
                                                "units" : u"m s-1",\
                                                'comment': u"3-day Lanczos filter" })
                nc_ws = nc_fid_rewrite.createVariable('windage', 'f4',('numobs', 'numvars', 'numdeps'),fill_value=missing_value)
                nc_ws.setncatts({'long_name' : u"wind slippage correction at the drog depth",\
                                                "units" : u"m s-1",\
                                                'comment': u"3-day Lanczos filter" })
                #variables = nc_file.data_vars
                nc_var = nc_fid_rewrite.createVariable('varname', 'S1',('numvars','string_length'))
                variables_vel = ['eastward_velocity ','northward_velocity']
                nc_var.setncatts({'long_name': u"name of variables"})
                nc_var[:] = netCDF4.stringtochar(np.array(variables_vel, 'S'))
                mask = lon_obs <= 180
                lon_obs = lon_obs[mask]
                lat_obs = lat_obs[mask]
                time_obs = time_obs[mask]
                time_obs_qc = time_obs_qc[mask]
                position_qc = position_qc[mask]
                depth_obs = depth_obs[mask]
                depth_obs_qc = depth_obs_qc[mask]
                code_values_obs = code_values_obs[mask]
                u_obs_filt = u_obs_filt[mask]
                v_obs_filt = v_obs_filt[mask]
                u_obs_qc = u_obs_qc[mask]
                v_obs_qc = v_obs_qc[mask]
                if "CURRENT_TEST" in variables.keys():
                    current_test = current_test[mask]
                if 'EWCT_WS_FILTR' and 'NSCT_WS_FILTR' in variables.keys():
                    u_filtr_ws = u_filtr_ws[mask]
                    v_filtr_ws = v_filtr_ws[mask]
                    u_filtr_ws_qc = u_filtr_ws_qc[mask]
                    v_filtr_ws_qc = v_filtr_ws_qc[mask]
                
                nc_fid_rewrite.variables['latitude'][:] = lat_obs
                nc_fid_rewrite.variables['longitude'][:] = lon_obs
                nc_fid_rewrite.variables['obs_time'][:] = time_obs
                nc_fid_rewrite.variables['time_qc'][:] = time_obs_qc
                nc_fid_rewrite.variables['position_qc'][:] = position_qc
                nc_fid_rewrite.variables['depth'][:,:] = depth_obs
                nc_fid_rewrite.variables['depth_qc'][:] = depth_obs_qc
                code_values2 = [var.decode("utf-8") for var in code_values_obs]
                nc_fid_rewrite.variables['plateform_code'][:] = code_values2
                nc_fid_rewrite.variables['observation'][:,0,:] = u_obs_filt[:,:]
                nc_fid_rewrite.variables['observation'][:,1,:] = v_obs_filt[:,:]
                nc_fid_rewrite.variables['observation_qc'][:,0] = u_obs_qc[:,:]
                nc_fid_rewrite.variables['observation_qc'][:,1] = v_obs_qc[:,:]
                nc_fid_rewrite.variables['windage'][:,0,:] = u_filtr_ws[:,:]
                nc_fid_rewrite.variables['windage'][:,1,:] = v_filtr_ws[:,:]
                nc_fid_rewrite.variables['windage_qc'][:,0] = u_filtr_ws_qc
                nc_fid_rewrite.variables['windage_qc'][:,1] = v_filtr_ws_qc
                if current_test is not None:
                    nc_fid_rewrite.variables['current_test'][:] = current_test

                # Add global attributs
                nc_fid_rewrite.institution = 'MERCATOR OCEAN INTERNATIONAL'
                nc_fid_rewrite.contact = 'cregnier@mercator-ocean.fr'
                #nc_fid_rewrite.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
                nc_fid_rewrite.time_interp = "daily average fields"
                today = date.today()
                yyyy = str(today)[0:4]
                month = str(today)[5:7]
                day = str(today)[8:10]
                nc_fid_rewrite.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
                nc_fid_rewrite.Conventions = 'CF-1.6'
                nc_fid_rewrite.close()
                nc_fid_rewrite = Dataset(file_new, 'r+')
            else:
                self.log.info(f"File {file_new} already exists — skipping write")
                time.sleep(10)

    def list(self, daterun, dirdata, typedata):
        year = daterun[0:4]
        month = daterun[4:6]
        liste_file = glob(f"{dirdata}/{year}/{month}/*{daterun}*.nc")
        if not liste_file:
            self.log.error(f"Missing Drifters files {dirdata}/{year}/{month}/*{daterun}*.nc")
            return [], True
        else:
            self.log.debug('Liste file UV drifters {}'.format(liste_file))
            return liste_file, False

    def run_list(self, param_dict, daterun):
        liste_tot=[]
        year = daterun[0:4]
        month = daterun[4:6]
        liste_file=glob(f"{param_dict['dirdata']}/*{daterun}*.nc}")
        if not liste_file:
            raise IOError(f"Missing Drifters files {param_dict['dirdata']}/*{daterun}*.nc")
        self.log.debug('Liste file UV drifters {}'.format(liste_file))
        nb_fcst = len(param_dict['lead_int'])
        nb_fcst2 = len(param_dict['lead_int2'])
        self.log.debug('Number of forecasts {}'.format(nb_fcst))
        self.log.info('NEW')
        for new_file in liste_file :
            try :
                file_new = 'class4_' + daterun + '_' + param_dict['cl_conf']\
                           +  '_' + param_dict['model_type'].lower() + \
                           '_currents-filtr.nc'
                ## If missing Read and Rewrite file
                if not  os.path.exists(param_dict['dirwork']+file_new):
                    self.log.info(f"Write Filename {param_dict['dirwork']}{file_new}")
                    self.rewrite(liste_file[0], nb_fcst, nb_fcst2, param_dict['dirwork']+file_new)
                else:
                    self.log.info(f"Filename exist {param_dict['dirwork']}{file_new}")
                    time.sleep(10)
            except IOError as e:
                raise IOError("I/O error({0}): {1}".format(e.errno, e.strerror))
                
        liste_tot.append(param_dict['dirwork']+file_new)
        return liste_tot


class Extract_UVDrifters(Extractor):

    """ Extract and reconstruct UV drifters """

    def __init__(self, log):
        self.log = log
        self.nb_vars = 2
        self.nb_depths = 1
        self.fillvalue_b = -128
        self.fillvalue_s = -32767
        self.fillvalue_R4 = netCDF4.default_fillvals['f4']

    def check_netcdf_valid(self, filename, timeout=10, log=None):
        start = time.time()
        while True:
            try:
                with Dataset(filename, 'r') as nc:
                    if log: log.info(f"{filename} is valid")
                    return True
            except OSError:
                if time.time() - start > timeout:
                    if log: log.error(f"{filename} not readable after {timeout}s")
                    return False
                time.sleep(0.5)


    def rewrite(self, file, nb_fcst, nb_fcst2, file_new):
        """
            Rewrite netcdf file to the right GODAE format
        """
        self.log.debug(f"Write new file {file_new}")
        lock_path = file_new + ".lock"
        with FileLock(lock_path):
            if not os.path.exists(file_new):
                # Open Dataset
                self.log.info("Open file {}".format(file))
                nc_file = xr.open_dataset(file, decode_times=False)
                variables = nc_file.data_vars
                # Create File
                self.log.info("Write new file {}".format(file_new))
                self.nb_fcst = nb_fcst
                self.nb_fcst2 = nb_fcst2
                nc_fid = Dataset(file_new, 'w', format='NETCDF4', locking=True)
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

                nc_ws_qc  = nc_fid.createVariable('windage_qc', 'i1',('numobs','numvars'),fill_value=self.fillvalue_b)
                nc_ws_qc.long_name =  "Windage quality flag"
                nc_ws_qc.valid_min = 0
                nc_ws_qc.valid_max = 9
                nc_ws_qc.flag_values = "0, 1, 2, 3, 4, 5, 6, 7, 8, 9"
                nc_ws_qc.flag_meanings = "no_qc_performed good_data probably_good_data bad_data_that_are_potentially_correctable bad_data value_changed not_used nominal_value interpolated_value missing_value"
                
                nc_current_test  = nc_fid.createVariable('current_test', 'i2',('numobs'),fill_value=self.fillvalue_s)
                nc_current_test.long_name = "Flag tests of drogue loss results"
                nc_current_test.description ="3 flags for 3 tests : Submersion Acceleration_buoy Wind-current-corr"
                nc_current_test.flag_values = "0, 1, 2, 3"
                nc_current_test.flag_meanings = "Drogue_probably_missing Test_not_performed Weak_probability_of_drogue_presence Strong_probability_of_drogue_presence"

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
                nc_ws = nc_fid.createVariable('windage', 'f4',('numobs', 'numvars', 'numdeps'),fill_value=missing_value)
                nc_ws.setncatts({'long_name' : u"wind slippage correction at the drog depth",\
                                                "units" : u"m s-1",\
                                                'comment': u"raw data" })
                nc_var = nc_fid.createVariable('varname', 'S1',('numvars','string_length'))
                variables_vel = ['eastward_velocity ','northward_velocity']
                nc_var.setncatts({'long_name': u"name of variables"})
                nc_var[:] = netCDF4.stringtochar(np.array(variables_vel, 'S'))
                lon_obs  = nc_file['LONGITUDE'].values
                lat_obs = nc_file['LATITUDE'].values
                time_obs =  nc_file['TIME'].values
                time_obs_qc = nc_file['TIME_QC'].values
                position_qc = nc_file['POSITION_QC'].values
                depth_obs = nc_file['DEPH'].values
                depth_obs_qc = nc_file['DEPH_QC'].values
                code_values_obs = nc_file['PLATFORM_CODE'].values
                u_obs = nc_file['EWCT'].values
                v_obs = nc_file['NSCT'].values
                u_obs_qc = nc_file['EWCT_QC'].values
                v_obs_qc = nc_file['NSCT_QC'].values 
                code_values_obs = nc_file['PLATFORM_CODE'].values
                if "CURRENT_TEST" in variables.keys():
                    current_test = nc_file['CURRENT_TEST'].values
                else:
                    current_test = None
                #variables = ncdata.data_vars
                mask = lon_obs <= 180
                lon_obs = lon_obs[mask]
                lat_obs = lat_obs[mask]
                time_obs = time_obs[mask]
                time_obs_qc = time_obs_qc[mask]
                position_qc = position_qc[mask]
                depth_obs = depth_obs[mask]
                depth_obs_qc = depth_obs_qc[mask]
                code_values_obs = code_values_obs[mask]
                u_obs = u_obs[mask]
                v_obs = v_obs[mask]
                u_obs_qc = u_obs_qc[mask]
                v_obs_qc = v_obs_qc[mask]
                if current_test is not None:
                    current_test = current_test[mask]
                if 'EWCT_WS' and 'NSCT_WS' in variables.keys():
                    print('Windage ok')
                    u_ws = nc_file['EWCT_WS'].values
                    v_ws = nc_file['NSCT_WS'].values
                    u_ws_qc = nc_file['EWCT_WS_QC'].values
                    v_ws_qc = nc_file['NSCT_WS_QC'].values
                    u_ws = u_ws[mask]
                    v_ws = v_ws[mask]
                    u_ws_qc = u_ws_qc[mask] 
                    v_ws_qc = v_ws_qc[mask]
                else:
                    print('No Windage')
                    u_ws = np.full(u_obs.shape, np.nan)
                    v_ws = np.full(v_obs.shape, np.nan)
                    u_ws_qc = np.copy(u_obs_qc)
                    v_ws_qc = np.copy(v_obs_qc)
                    u_ws_qc[:, :] = 9
                    v_ws_qc[:, :] = 9
                nc_fid.variables['longitude'][:] = lon_obs 
                nc_fid.variables['latitude'][:] = lat_obs
                nc_fid.variables['obs_time'][:] = time_obs
                nc_fid.variables['time_qc'][:] = time_obs_qc
                nc_fid.variables['position_qc'][:] = position_qc
                nc_fid.variables['depth'][:,:] = depth_obs
                nc_fid.variables['depth_qc'][:] = depth_obs_qc 
                code_values2 = [var.decode("utf-8") for var in code_values_obs]
                nc_fid.variables['plateform_code'][:] = code_values2
                nc_fid.variables['observation'][:,0,:] = u_obs[:,:]
                nc_fid.variables['observation'][:,1,:] = v_obs[:,:]
                nc_fid.variables['observation_qc'][:,0] = u_obs_qc
                nc_fid.variables['observation_qc'][:,1] = v_obs_qc
                nc_fid.variables['windage'][:,0,:] = u_ws[:,:]
                nc_fid.variables['windage'][:,1,:] = v_ws[:,:]
                nc_fid.variables['windage_qc'][:,0] = u_ws_qc
                nc_fid.variables['windage_qc'][:,1] = v_ws_qc
                if current_test is not None:
                    nc_fid.variables['current_test'][:] = current_test
                # Add global attributs
                nc_fid.institution = 'MERCATOR OCEAN INTERNATIONAL'
                nc_fid.contact = 'cregnier@mercator-ocean.fr'
                #nc_fid.obs_type = self.type_data.get(variable, {}).get('defaults').get('name')
                nc_fid.time_interp = "daily average fields"
                today = date.today()
                yyyy = str(today)[0:4]
                #yyyy2 = dateval[0:4]
                month = str(today)[5:7]
                #month2 = dateval[4:6]
                day = str(today)[8:10]
                #day2 = dateval[6:8]
                #nc_fid.validity_time = yyyy2+"-"+month2+"-"+day2+" 00:00:00"
                nc_fid.creation_date = yyyy+"-"+month+"-"+day+" 00:00:00"
                #nc_fid.system = model
                nc_fid.Conventions = 'CF-1.6'
                nc_fid.close()
                nc_file.close()

    def run_list(self,param_dict, daterun):
        liste_tot=[]
        year = daterun[0:4]
        month = daterun[4:6]
        liste_file=glob(param_dict['dirdata'] + '/*' + daterun+'*.nc')
        if not liste_file:
            raise IOError(f"- - CRUZ - - - - - Extractor: 1163 Missing Drifters files {param_dict['dirdata']}/*{daterun}*.nc")
        self.log.debug('Liste file UV drifters {}'.format(liste_file))
        nb_fcst = len(param_dict['lead_int'])
        nb_fcst2 = len(param_dict['lead_int2'])
        self.log.debug('Number of forecasts {}'.format(nb_fcst))
        for new_file in liste_file :
            try :
                file_new = 'class4_' + daterun + '_' + param_dict['cl_conf']\
                           +  '_' + param_dict['model_type'].lower() + \
                           '_currents.nc'
                ## Read and Rewrite file
                self.rewrite(liste_file[0], nb_fcst, nb_fcst2, param_dict['dirwork']+file_new)
                self.log.debug('Filename {}'.format(param_dict['dirwork']+file_new))
            except IOError as e:
                raise IOError("I/O error({0}): {1}".format(e.errno, e.strerror))
        liste_tot.append(param_dict['dirwork']+file_new)
        return liste_tot

class Extract_MDS_L3_SLA(Extractor):
    """ Extract MDS L3 SLA file """

    def __init__(self, log):
        self.log = log

    # Function to extract dates and calculate differences
    def find_largest_date_difference(self, files):
        date_diffs = []
        date_pattern = re.compile(r"_(\d{8})_(\d{8})\.nc")

        for file in files:
            match = date_pattern.search(file)
            if match:
                start_date = datetime.strptime(match.group(1), "%Y%m%d")
                end_date = datetime.strptime(match.group(2), "%Y%m%d")
                day_difference = (end_date - start_date).days
                date_diffs.append((file, day_difference))
                # Find the file with the largest day difference
        largest_diff_file = max(date_diffs, key=lambda x: x[1])
        return largest_diff_file[0]

    def run_list(self, param_dict, dateval):
        liste_tot=[]
        year = dateval[0:4]
        dirdata = param_dict['dirdata']
        list_files = glob(f'{dirdata}/nrt_global_*{dateval}*.nc')
        #if len(list_files) == 0: CHARLY
        #    list_files = glob(f'{dirdata}{str(int(year)-1)}/nrt_global_*{dateval}*.nc')
        #    year = str(int(year) - 1)
        if  len(list_files) == 0:
            raise IOError(f'{dirdata}/nrt_global_*{dateval}*.nc')
        list_sat = {os.path.basename(filename).split("_")[2] for filename in list_files}
        self.log.debug(f'{list_sat=}')
        nb_sat = 0
        for sat in list_sat:
            frame = "nrt_global_" + sat + "_phy_l3_1hz_"
            list_files = glob(f'{dirdata}/{frame}{dateval}*.nc')
            if len(list_files) == 0:
                raise(f" - - CRUZ - - - - - Extractor: 1192 list_files lenght 0 {dirdata}/{frame}{dateval}*.nc")
            nb_sat += 1
            choose_file = self.find_largest_date_difference(list_files)
            self.log.info(f"Satellite {sat} and choose file {choose_file}")
            try:
                filename = os.path.basename(choose_file)
                if not os.path.exists(param_dict['dirwork']+filename):
                    shutil.copy(choose_file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
        self.log.debug(f"Nb Sats {nb_sat}")

        return liste_tot

class Extract_GODAE(Extractor):

    """ Extract GODAE file """

    def __init__(self, log):
        self.log = log

    def is_netcdf4_classic(self, file_path):
        try:
            output = subprocess.check_output(['ncdump', '-k', file_path], text=True)
            return 'classic' in output
        except subprocess.CalledProcessError as e:
            print(f"An error occurred while checking the file type: {e}")
            return False
    def list(self, daterun, dirdata, typedata):
        if typedata not in ["SLA","SST","profile","aice","AMSR","current"] :
            raise NameError(f"Data {typedata} unknown! Choose from: SLA,SST,profile,aice,AMSR,current")
        #valeurj=date1
        if typedata ==  "AMSR" :
            liste_file=glob(dirdata+'/*'+daterun+'*.nc')
            if len(list_files) == 0:
                raise(f"lenght of list_files = 0; there is no {dirdata}/*{daterun}*.nc")

        else :
            try:
                print(dirdata+'/class4*'+daterun+'*'+typedata+'*.nc')
                sys.exit(1)
                liste_file = [glob(dirdata+'/class4*'+daterun+'*'+typedata+'*.nc')[0]]
            except IndexError:
                raise IOError(f'Missing CLASS4 {daterun} {typedata} file')
        if liste_file:
            return liste_file, False
        else:
            raise IOError(f'file is missing for {daterun}')
    
    def run_list(self, param_dict, daterun, template=''):
        
        dirdata = param_dict['dirdata']
        typedata = param_dict['data_type']
        nb_fcst = len(param_dict['lead_int'])
        dirtmp = param_dict['dirwork']
        template = param_dict['template']
        if typedata not in ["SLA","SST","profile","aice","AMSR","current"] :
            raise NameError(f"Data {typedata} unknown! Choose from: SLA,SST,profile,aice,AMSR,current")
        
        liste_tot=[]
        self.log.info('Day  %s ' % (daterun))
 
        # Select input file(s)
        if typedata ==  "AMSR" :
            liste_file = glob(f"{dirdata}/*{daterun}*.nc")
            if len(liste_file) == 0 :
                raise IOError(f"No files in {dirdata}/*{daterun}*.nc")
        else :
            liste_file = [glob(f"{dirdata}/class4*{daterun}*{typedata}*.nc")[0]]
        
        if not liste_file:
            return liste_tot
        
        self.log.debug(f'Liste file {liste_file}')

        for new_file in liste_file :
                filename=os.path.basename(new_file)

                # Adjust filename
                if typedata ==  "AMSR" :
                    filename=re.sub('GL_h5',template,filename)
                elif typedata !=  "current":
                    template1 = filename.split("_")
                    if len(template1) > 5:
                        template_tmp = "_".join(template1[2:5])
                    else:
                        template_tmp = "_".join(template1[2:4])
                    filename=re.sub(template_tmp, template, filename)

                out_path = os.path.join(dirtmp, filename)

                if typedata not in ["aice", "current"]:
                    # If it doesn't exist, create it
                    os.makedirs(dirtmp, exist_ok=True)

                    # Open dataset
                    ds = xr.open_dataset(new_file)
                    
                    # ---- 1) Handle numfcsts ----
                    if "numfcsts" in ds.dims:
                        ds = ds.isel(numfcsts=0, drop=True)

                    # ---- 2) Handle modeljuld + leadtime ----
                    if "modeljuld" in ds and nb_fcst > 0:
                        # Expand to add numfcsts dimension
                        ds = ds.expand_dims({"numfcsts": nb_fcst})

                        # Rename like ncap2 + ncrename steps
                        if "leadtime" in ds:
                            ds = ds.rename({"leadtime": "leadtime_new"})
                        if "modeljuld" in ds:
                            ds = ds.rename({"modeljuld": "modeljuld_new"})

                        ds = ds.rename({"modeljuld_new": "modeljuld",
                                        "leadtime_new": "leadtime"})
                    else:
                        self.log.info("no modeljuld !!")

                    # ---- 3) Drop unwanted variables ----
                    drop_vars = ["best_estimate", "forecast", "persistence", "leadtime", "modeljuld"]
                    if typedata == "SLA":
                        drop_vars.extend(["altimeter_bias", "mdt_reference", "varname"])
                    ds = ds.drop_vars([v for v in drop_vars if v in ds.variables], errors="ignore")

                    # ---- 4) Save output ----
                    comp = dict(zlib=True, complevel=4)
                    encoding = {var: comp for var in ds.data_vars}
                    ds.to_netcdf(out_path, encoding=encoding)
                    ds.close()
                
                elif typedata == "current":
                    shutil.copy(os.path.join(dirdata, filename), out_path)

                else:  # aice
                    ds = xr.open_dataset(new_file)
                    drop_vars = ["best_estimate", "forecast", "persistence"]
                    ds = ds.drop_vars([v for v in drop_vars if v in ds.variables], errors="ignore")
                    if "obs_time" in ds:
                        if "units" in ds["obs_time"].attrs:
                            ds["obs_time"].attrs["units"] = (
                                ds["obs_time"].attrs["units"]
                                .replace("Seconds", "seconds")
                                .replace("utc", "UTC")
                        )
                        encoding = {
                            "obs_time": {
                            "units": "seconds since 1950-01-01 00:00:00 UTC",
                            "calendar": "gregorian"
                            }
                        }
                    if "time" in ds:
                        if "units" in ds["time"].attrs:
                            ds["time"].attrs["units"] = (
                                ds["time"].attrs["units"]
                                .replace("Seconds", "seconds")
                                .replace("utc", "UTC")
                            )
                        encoding = {
                            "time": {
                                "units": "seconds since 1950-01-01 00:00:00 UTC",
                                "calendar": "gregorian"
                            }
                        }
                    ds.to_netcdf(out_path, encoding=encoding)
                    ds.close()
                
                # ---- 5) AMSR special case ----
                if typedata == "AMSR":
                    with netCDF4.Dataset(out_path, "a") as nc:
                        if "string_length8" not in nc.dimensions:
                            nc.createDimension("string_length8", 8)
                        if "numvars" not in nc.dimensions:
                            nc.createDimension("numvars", 1)
                        if "varname" not in nc.variables:
                            var = nc.createVariable("varname", "S1", ("numvars", "string_length8"))
                            var[:] = netCDF4.stringtochar(np.array([["ileadfra"]], dtype="S8"))

                self.log.debug(f"Fichier extracted {out_path}")
                liste_tot.append(out_path)


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
            self.log.debug(f'Frame {dirdata}{prefix}*{dateval.strip()}*.nc*')
            self.log.debug(f'Liste file ARMOR {liste_file}') 
            for new_file in liste_file :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    if filename[-2:] == 'gz' :
                        self.log.info('Dezip')
                        filename2=filename
                        fichier=dirtmp+filename2
                        with zipfile.ZipFile(fichier, 'r') as zip_ref:
                            zip_ref.extractall(fichier)
                        filename=fichier.split('.gz')[:][0]
                        liste_tot.append(filename)
                    else :
                        liste_tot.append(dirtmp+filename)
                    self.log.info("append : %s " %(filename))
            valeurj=valeurj.goforward(1)

        return liste_tot

    def run_list(self,date1,date2,dirdata):
        liste_tot=[]
        valeurj=date1
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            #print dirdata+'/*'+dateval+'*.nc'
            liste_file=glob(dirdata+'/*'+dateval+'*.nc')
            if len(liste_file) == 0 :
                raise IOError(f"File does not exist {dirdata}/*{dateval}*.nc")
            for file in liste_file :
                    liste_tot.append(file)
            valeurj=valeurj.goforward(1)
        return liste_tot
