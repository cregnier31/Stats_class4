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
from sydate import SyDate
from Logger import Logger
from gz import ZipManipulator
from os.path import dirname
sys.path.append(dirname(__file__))
from nco.nco import Nco

##############################################################
# C.REGNIER Juin 2014
# Class Extractor to extract profile : the selection depends on date
##############################################################


class Extractor(object):

    """ Factory extract file depending on type """

    def factory(self, type):
        """
         Create an interface for different type of data
         Factory
        """
        if type == "CORA3": return Extract_cora3()
        if type == "cora4.0_merc": return Extract_cora4('.tgz')
        if type == "cora4.1_raw": return Extract_cora4_1()
        if type == "CORA4.1_MERC": return Extract_cora4('.tgz')
        if type == "cora5.0_raw": return Extract_cora4('.tar.gz')
        if type == "CORA5.0": return Extract_cora4('.tgz')
        if type == "CORA5.2": return Extract_cora4_1()
        if type == "CORIOLIS": return Extract_corio()
        if type == "CORIOLIS_RAW": return Extract_corio_raw()
        if type == "ENS": return ExtractEns()
        if type == "ARMOR_CO" or type == "ARMOR_AR" or type == "AR_": return Extract_ARMOR()
        if type == "GODAE": return Extract_GODAE()
        if type == "ASCII": return Extract_ASCII()
        if type == "L3m": return Extract_genericData()
        if type.startswith("BGC_ARGO"): return Extract_BGC_ARGO()
        if type == "L3mCHL": return Extract_CHLORO()
        if type == "Microwat_Lband_Orbite_1day_Lband" or type == "Microwat_6.9GHz_Orbite_1day": return Extract_genericData()
        if type == "001_048" : return Extract_CMEMS_drifters()
        if type == "sssdata_netcdf_good_FNAV" or "sssdata_netcdf_all": return Extract_SSSData()

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
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
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

    def run_list(self, param_dict, dateval):
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log =logging.getLogger("Extract Generic files")
        self.log.setLevel(logging.INFO)
        liste_tot = []
        liste_file = glob(param_dict['dirdata']+'/*/'+param_dict['prefix_data']+'*'+dateval+'*.nc')
        for file in liste_file:
            try:
                filename = os.path.basename(file)
                shutil.copy(file, param_dict['dirwork']+filename)
                liste_tot.append(param_dict['dirwork']+filename)
            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot


class Extract_CHLORO(Extractor):

    """ Extract Chloro Globcolour files """

    def mkdir(self, path):
        "Create a directory, and parents if needed"
        if not os.path.exists(path):
            os.makedirs(path)

    def run_list(self, param_dict, dateval):
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log = logging.getLogger("Extract Chloro")
        self.log.setLevel(logging.INFO)
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
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot

class Extract_corio_raw(Extractor):

    """ Extract coriolis raw common file """

    def __init__(self): 

        # ===============
        # LOGGER
        # ===============
        self.log = logging.getLogger("Extract_corio_raw")
        self.log.setLevel(logging.INFO)
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

    def run(self, param_dict, dateval):
        # ===============
        # LOGGER
        # ===============
        log = logging.getLogger("Extract_ARMOR")
        log.setLevel(logging.INFO)
        # Level of logging output
        liste_tot=[]
        log.info('Day %s ' % (dateval))
        frame=param_dict['dir_data']+'/*'+dateval.strip()+'*.nc'
        liste_file=glob(frame)
        log.info('Liste file %s ' % (liste_file)) 
        for new_file in liste_file :
            try :
                filename=os.path.basename(new_file)
                shutil.copy(new_file,param_dict['dirtmp'])
                liste_tot.append(param_dict['dirtmp']+filename)
            except IOError as e:
                self.log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)

        return liste_tot


class Extract_cora4_1(Extractor):

    """ Extract cora 4.1 file """

    def __init__(self, level=2):
        self.date = SyDate('19500101')
        self.log = Logger("Extract Cora").run(level)

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
            except IOError as e:
                print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
        return liste_tot

class Extract_GODAE(Extractor):

    """ Extract GODAE file """

    def run(self,daterun,dirdata,dirtmp,typedata,template,nb_fcst):
        # =============== 
        # LOGGER
        # ===============
        log = logging.getLogger("Extract GODAE")
        log.setLevel(logging.INFO)
        log.info('Extract_GODAE')
        if typedata != "SLA" and  typedata != "SST" and typedata != "profile" \
            and typedata !=  "aice" and typedata !=  "AMSR" and  typedata !=  "current" :
            log.error("Data %s not known !!! " %(typedata))
            sys.exit(1)
        # Level of logging output
        #valeurj=date1
        liste_tot=[]
        # Nco constructor
        nco = Nco()
        #while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
        #    dateval=SyDate.__str__(valeurj)
        log.info('Day  %s ' % (daterun)) 
        if typedata ==  "AMSR" : 
            liste_file=glob(dirdata+'/*'+daterun+'*.nc')
        else :
            liste_file=glob(dirdata+'/class4*'+daterun+'*'+typedata+'*.nc')
        # liste_file=glob(dirdata+'/*[TS]*'+daterun+'*.nc')
        log.info('Liste file %s ' % (liste_file))
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
                        log.info('no modeljuld !!')
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
                    log.info("add new dim ok {}".format(dirtmp+filename))
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
                log.info('Fichier extracted %s ' % (dirtmp+filename)) 
                liste_tot.append(dirtmp+filename)
                # Design output File
                # Design_file('GODAE').run(dirtmp+filename)
            except IOError as e:
                log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
                sys.exit(1)
        #valeurj=valeurj.goforward(1)

        return liste_tot



class Extract_ARMOR(Extractor):

    """ Extract ARMOR file """

    def run(self,date1,date2,dirdata,dirtmp,typedata,template,prefix):
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract_ARMOR")
        log.setLevel(logging.INFO)
        # Level of logging output
        valeurj=date1
        liste_tot=[]
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            log.info('Day %s ' % (dateval)) 
            frame=dirdata+prefix+'*'+dateval.strip()+'*.nc*'
            liste_file=glob(frame)
            # liste_file=glob(dirdata+'/*[TS]*'+dateval+'*.nc')
            log.info('Liste file %s ' % (liste_file)) 
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    if filename[-2:] == 'gz' :
                        log.info('Dezip')
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
                    log.info("append : %s " %(filename))
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

    def __init__(self):
        self.PREFIX='cora3.4_merc'
    def run(self,date1,date2,dirdata,dirtmp,typedata,template):
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract_cora3")
        log.setLevel(logging.INFO)
        # Level of logging output
        log.info('Extraction of Cora 3 dataset')
        presmonth=SyDate.__str__(date2)[:6]
        backmonth=SyDate.__str__(date1)[:6]
        liste_month=[]
        liste_file=[]
        if presmonth == backmonth : 
            file=self.PREFIX+"_"+presmonth+".tgz"
            print ("Same month %s " %(file))
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
                print ('file ok')
                try :
                    shutil.copy(file_path,dirtmp)
                    os.chdir(dirtmp)
                    tar = tarfile.open(file)
                    tar.extractall()
                    tar.close()
                    os.remove(file)
                except  IOError as e :
                    print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
                    # print 'Problem with copy or extraction'
            else :
                print ('file not known %s ' %(file_path))
                sys.exit(1)
        liste_tot=[]
        for month in liste_month : 
            valeurj=date1
            year=SyDate.__str__(valeurj)[:4]
            while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
                dateval=SyDate.__str__(valeurj)
                log.info('Day  %s ' % (dateval)) 
                liste_file=glob(dirtmp+'/'+year+'/*'+dateval+'*.nc')
                log.info('Day list %s ' % (liste_file)) 
                for new_file in liste_file :
                    try :
                        # os.rename(new_file,dirtmp)
                        # shutil.move(dirtmp,new_file)
                        shutil.copy(new_file,dirtmp)
                        liste_tot.append(new_file)
                    except IOError as e:
                        print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                        sys.exit(1)
                valeurj=valeurj.goforward(1)
            # Remove directory 
            shutil.rmtree(dirtmp+year)
        # Write log

        return liste_tot


class Extract_cora4(Extractor) :

    """ Extract Cora4 file """

    def __init__(self,compress):
        """

        Constructor cora 4

        """
        self.PREFIX='cora4.0_merc'
        self.compress=compress
    def run(self,date1,date2,dirdata,dirtmp,typedata,templat,prefix):
        print ('Extractor cora4 : '+self.compress)
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract_cora4")
        # Level of logging output
        log.setLevel(logging.INFO)
        presyear=SyDate.__str__(date2)[:4]
        backyear=SyDate.__str__(date1)[:4]
        liste_file=[]
        liste_year=[]
        print (presyear,backyear)
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
        print (liste_file)
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
                        print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                        sys.exit(1)
                        # print 'Problem with copy or extraction'
                else :
                    print ('file not known %s ' %(file_path))
                    sys.exit(1)
            else :
                print ("Directory already exist")
        # Remove file
        liste_tot=[]
        for year in liste_year : 
            valeurj=date1
            while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
                dateval=SyDate.__str__(valeurj)
                log.info('Day  %s ' % (dateval)) 
                liste_file=glob(dirtmp+'/'+year+'/*'+dateval+'*.nc')
                print (liste_file)
                for file in liste_file :
                    try :
                        log.info('Fichier  %s ' % (file))
                        shutil.move(file,dirtmp)
                        filename=os.path.basename(file)
                        liste_tot.append(dirtmp+filename)
                    except IOError as e:
                        print ("I/O error({0}): {1}".format(e.errno, e.strerror))
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
                    print ("I/O error({0}): {1}".format(e.errno, e.strerror))
                    sys.exit(1)
            valeurj=valeurj.goforward(1)
        return liste_tot
