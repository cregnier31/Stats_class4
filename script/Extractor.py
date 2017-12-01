from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import logging
import tarfile
import netCDF4
from sytoolkit.sydate import SyDate
from nco import Nco
from gz import ZipManipulator

##############################################################
## C.REGNIER Juin 2014
## Class Extractor to extract profile : the selection depends on date
##############################################################

class Extractor(object) :

    """ Factory extract file depending on type """

    def factory(self,type):
        if type == "CORA3": return Extract_cora3()
        if type == "cora4.0_merc": return Extract_cora4('.tgz')
        if type == "cora4.1_raw": return Extract_cora4_1()
        if type == "CORA4.1_MERC": return Extract_cora4('.tgz')
        if type == "cora5.0_raw": return Extract_cora4('.tar.gz')
        if type == "CORA5.0": return Extract_cora4('.tgz')
        if type == "CORIOLIS": return Extract_corio()
        if type == "CORIOLIS_RAW": return Extract_corio_raw()
        if type == "ENS": return ExtractEns()
        if type == "ARMOR_CO" or type == "ARMOR_AR" or type == "AR_" : return Extract_ARMOR()
        if type == "GODAE" : return Extract_GODAE()
        if type == "ASCII" : return Extract_ASCII()
        if type == "L3m" : return Extract_genericData()
        if type == "Microwat_Lband_Orbite_1day_Lband" : return Extract_genericData()




class Extract_genericData(Extractor): 

    """ Extract files """
    def run_list(self,date1,date2,dirdata,dirwork):
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log = logging.getLogger("Extract Generic files")
        self.log.setLevel(logging.INFO)
        liste_tot=[]
        valeurj=date1
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            liste_file=glob.glob(dirdata+'/*'+dateval+'*.nc')
            for file in liste_file :
                try :
                    print file
                    filename=os.path.basename(file)
                    print filename
                    shutil.copy(file,dirwork+filename)
                    liste_tot.append(dirwork+filename)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)

        return liste_tot

class Extract_corio_raw(Extractor):

    """ Extract coriolis raw common file """

    def __init__(self): 

        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        self.log = logging.getLogger("Extract_corio_raw")
        self.log.setLevel(logging.INFO)
        self.date=SyDate('19500101')

    def search(self,dirdata,**kwargs):
        list_dateval=[]
        ind=0
        for file in glob.glob(dirdata+"*.nc"):
            nc   = netCDF4.Dataset(file,'r')
            variable="JULD"
            v = nc.variables[variable][:]
            # Convert to date
            dateval=[SyDate.__str__(self.date.setfromjulian(int(valeurj))) for valeurj in v]
            ind=0
            for val in dateval : 
                if SyDate(val).tojulian() < 16189 :
                   print file
                   print "Probleme  : %s %i  "%(val,ind)
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
        ## Nco constructor
        nco = Nco()
        for file in glob.glob(dirdata+"*.nc"):
            print file
            frame=os.path.basename(file).split('.')[0]
            nc   = netCDF4.Dataset(file,'r')
            variable="JULD"
            v = nc.variables[variable][:]
            # Convert to date
            dateval=[SyDate.__str__(self.date.setfromjulian(int(valeurj))) for valeurj in v]
            ind=0
            for val in dateval : 
                if SyDate(val).tojulian() < 16189 :
                   print file
                   print "Probleme  : %s %i  "%(val,ind)
                else :
                    file_out=str(val)+'_'+frame+'_profile_'+str(ind)+'.nc'
                    nco.ncks(input=file,output=dirtmp+file_out, fortran=True ,dimension=str(dimprof)+','+str(ind+1),options=options)              
                    liste_tot.append(dirtmp+file_out)
                    #self.log.info('Day %s ' % (dateval))
                ind+=1
        return liste_tot

class Extract_corio(Extractor):

    """ Extract coriolis common file """

    def run(self,date1,date2,dirdata,dirtmp,typedata,template):
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract_ARMOR")
        log.setLevel(logging.INFO)
        ## Level of logging output
        valeurj=date1
        liste_tot=[]
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            log.info('Day %s ' % (dateval))
            frame=dirdata+'/*'+dateval.strip()+'*.nc'
            print frame
            liste_file=glob.glob(frame)
            log.info('Liste file %s ' % (liste_file)) 
            print 'OK'
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)

        return liste_tot


class Extract_cora4_1(Extractor):

    """ Extract cora 4.1 file """

    def run(self,date1,date2,dirdata,dirtmp,typedata,template):
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract_ARMOR")
        log.setLevel(logging.INFO)
        ## Level of logging output
        valeurj=date1
        liste_tot=[]
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            log.info('Day %s ' % (dateval))
            month=dateval[0:6] 
            frame=dirdata+month+'/*'+dateval.strip()+'*.nc'
            print frame
            liste_file=glob.glob(frame)
            log.info('Liste file %s ' % (liste_file)) 
            print 'OK'
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    shutil.copy(new_file,dirtmp)
                    liste_tot.append(dirtmp+filename)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)

        return liste_tot

class Extract_ASCII(Extractor): 

    """ Extract cora 4.1 file """

    def __init__(self):
        self.PREFIX='Ascii file extraction'
    def run_list(self,date1,date2,dirdata):
        liste_tot=[]
        valeurj=date1
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            liste_file=glob.glob(dirdata+'/*_'+dateval+'*.txt')
            print liste_file
            for file in liste_file :
                try :
                    liste_tot.append(file)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)
        return liste_tot

class Extract_GODAE(Extractor):

    """ Extract cora 4.1 file """

    def run(self,date1,date2,dirdata,dirtmp,typedata,template):
        if typedata != "SLA" and  typedata != "SST" and typedata != "profile" and typedata !=  "aice" and typedata !=  "AMSR" :
            print "Data %s not known !!! " %(typedata)
            sys.exit(1)
        # =============== 
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract GODAE")
        log.setLevel(logging.INFO)
        log.info('Extract_GODAE') 
        ## Level of logging output
        valeurj=date1
        liste_tot=[]
        ## Nco constructor
        nco = Nco()
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            log.info('Day  %s ' % (dateval)) 
            if typedata ==  "AMSR" : 
            	liste_file=glob.glob(dirdata+'/*'+dateval+'*.nc')
	    else :
            	liste_file=glob.glob(dirdata+'/class4*'+dateval+'*'+typedata+'*.nc')
            	print dirdata+'/class4*'+dateval+'*'+typedata+'*.nc'
            #liste_file=glob.glob(dirdata+'/*[TS]*'+dateval+'*.nc')
            log.info('Liste file %s ' % (liste_file)) 
            for new_file in liste_file :
                try :
                    filename=os.path.basename(new_file)
                    if typedata ==  "AMSR" : 
                        #filename=re.sub('GIOPS_CONCEPTS_1.1',template,filename)
                        filename=re.sub('GL_h5',template,filename)
                    else:
                        #filename=re.sub('PSY4V2R2','PSY4V3R1',filename)
                        if typedata == "aice" :
                            filename=re.sub('GIOPS_CONCEPTS_2.3',template,filename)
                        else : 
                            filename=re.sub('FOAM_orca025_12.0',template,filename)
                    ## Copy extracted value of GODAE file with nco module
                    #shutil.copy(new_file,dirtmp)
                    options = []
                    if typedata == "SLA" :
                        options.extend(['-h','-O','-xv','best_estimate,forecast,persistence,altimeter_bias,mdt_reference'])
                    else : 
                       options.extend(['-h','-O','-xv','best_estimate,forecast,persistence'])
                    nco.ncks(input=new_file,output=dirtmp+filename, fortran=True ,options=options)
                    if typedata == "aice" :
                        ## add missing varname
                        #options = []
                        #options.extend(['-h','-v','varname'])
                        #filein='varname_ice.nc'
                        #nco.ncks(input=dirstatic+'/'+filein,output=dirtmp+filename,fortran=True,options=options)
                        # Solution2 : add dimensions and variable varname
                        cl_fileIn=dirtmp+filename
                        #nc   = netCDF4.Dataset(cl_fileIn,'a')
                        #nc.createDimension('string_length8',8)
                        ## for AMSR
                        ## nc.createDimension('numvars',1)
                        ##nc.createVariable('varname','c',('numvars','string_length8'))
                        ##nc.variables['varname'][:]='ileadfra'
                        ##nc.close
                    if typedata == "AMSR" :
                        ## add missing varname
                        # Solution2 : add dimensions and variable varname
                        cl_fileIn=dirtmp+filename
                        nc   = netCDF4.Dataset(cl_fileIn,'a')
                        nc.createDimension('string_length8',8)
                        # for AMSR
                        nc.createDimension('numvars',1)
                        nc.createVariable('varname','c',('numvars','string_length8'))
                        nc.variables['varname'][:]='ileadfra'
                        nc.close
                    log.info('Fichier %s ' % (dirtmp+filename)) 
                    liste_tot.append(dirtmp+filename)
                    ##  Design output File
                    #Design_file('GODAE').run(dirtmp+filename)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)

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
        ## Level of logging output
        valeurj=date1
        liste_tot=[]
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            log.info('Day %s ' % (dateval)) 
            frame=dirdata+prefix+'*'+dateval.strip()+'*.nc*'
            print frame
            liste_file=glob.glob(frame)
            #liste_file=glob.glob(dirdata+'/*[TS]*'+dateval+'*.nc')
            log.info('Liste file %s ' % (liste_file)) 
            print 'OK'
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
                        ##tar = tarfile.open(dirtmp+filename2, "r:gz")
                        ##tar.extractall()
                        ##tar.close()
                        liste_tot.append(filename)
                    else :
                        liste_tot.append(dirtmp+filename)
                    log.info("append : %s " %(filename))
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)

        return liste_tot

    def run_list(self,date1,date2,dirdata):
        liste_tot=[]
        valeurj=date1
        print valeurj
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            print dirdata+'/*'+dateval+'*.nc'
            liste_file=glob.glob(dirdata+'/*'+dateval+'*.nc')
            for file in liste_file :
                try :
                    liste_tot.append(file)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
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
        ## Level of logging output
        log.info('Extraction of Cora 3 dataset') 
        presmonth=SyDate.__str__(date2)[:6]
        backmonth=SyDate.__str__(date1)[:6]     
        liste_month=[]
        liste_file=[]
        if presmonth == backmonth : 
            file=self.PREFIX+"_"+presmonth+".tgz"
            print "Same month %s " %(file)
            liste_file.append(file)
            liste_month.append(presmonth)
        else :
            file1=self.PREFIX+"_"+presmonth+".tgz"
            liste_file.append(file1)
            file2=self.PREFIX+"_"+backmonth+".tgz"
            liste_file.append(file2)
            liste_month.append(presmonth)
            liste_month.append(backmonth)
        ## Extract and copy file
        for file in liste_file : 
            file_path=dirdata+file
            if os.path.isfile(file_path)  :
                print 'file ok'	
                try :
                    shutil.copy(file_path,dirtmp)
                    os.chdir(dirtmp)
                    tar = tarfile.open(file)
                    tar.extractall()
                    tar.close()
                    os.remove(file)
                except  IOError as e :
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
                    #print 'Problem with copy or extraction'
            else :
                print 'file not known %s ' %(file_path) 
                sys.exit(1)
        liste_tot=[]
        for month in liste_month : 
            valeurj=date1
            year=SyDate.__str__(valeurj)[:4]
            while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
                dateval=SyDate.__str__(valeurj)
                log.info('Day  %s ' % (dateval)) 
                liste_file=glob.glob(dirtmp+'/'+year+'/*'+dateval+'*.nc')
                log.info('Day list %s ' % (liste_file)) 
                for new_file in liste_file :
                    try :
                        print new_file,dirtmp
                        # os.rename(new_file,dirtmp)
                        # shutil.move(dirtmp,new_file)
                        shutil.copy(new_file,dirtmp)
                        liste_tot.append(new_file)
                    except IOError as e:
                        print "I/O error({0}): {1}".format(e.errno, e.strerror)
                valeurj=valeurj.goforward(1)
            ## Remove directory 
            shutil.rmtree(dirtmp+year)
        ## Write log

        return liste_tot


class Extract_cora4(Extractor) :

    """ Extract Cora4 file """

    def __init__(self,compress):
        print "Constructor cora 4 ------"
        self.PREFIX='cora4.0_merc'
        self.compress=compress
    def run(self,date1,date2,dirdata,dirtmp,typedata,templat,prefix):
        print 'Extractor cora4 : '+self.compress
        # ===============
        # LOGGER
        # ===============
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("Extract_cora4")
        ## Level of logging output
        log.setLevel(logging.INFO)
        print type(date2),date1
        print "------------"
        presyear=SyDate.__str__(date2)[:4]
        backyear=SyDate.__str__(date1)[:4]
        liste_file=[]
        liste_year=[]
        print presyear,backyear
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
        ## Extract and copy file
        print " Liste file "
        print liste_file
        for file in liste_file :
            file_path=dirdata+file
            print file_path
            ## Test the existence of the year
            if not os.path.isdir(dirtmp+liste_year[0]):
                print "Directory doesn t exist extract"
                if os.path.isfile(file_path)  :
                    try :
                        shutil.copy(file_path,dirtmp)
                        os.chdir(dirtmp)
                        tar = tarfile.open(file)
                        tar.extractall()
                        tar.close()
                        os.remove(file)
                    except  IOError as e :
                        print "I/O error({0}): {1}".format(e.errno, e.strerror)
                        #print 'Problem with copy or extraction'
                else :
                    print 'file not known %s ' %(file_path) 	
                    sys.exit(1)
            else :
                print "Directory already exist"
        ## Remove file
        liste_tot=[]
        for year in liste_year : 
            valeurj=date1
            while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
                dateval=SyDate.__str__(valeurj)
                log.info('Day  %s ' % (dateval)) 
                liste_file=glob.glob(dirtmp+'/'+year+'/*'+dateval+'*.nc')
                print dirtmp+'/'+year+'/*'+dateval+'*.nc'
                print liste_file
                for file in liste_file :
                    print file
                    try :
                        log.info('Fichier  %s ' % (file))
                        shutil.move(file,dirtmp)
                        filename=os.path.basename(file)
                        liste_tot.append(dirtmp+filename)
                    except IOError as e:
                        print "I/O error({0}): {1}".format(e.errno, e.strerror)
                valeurj=valeurj.goforward(1)
            ## Remove directory 
            #shutil.rmtree(dirtmp+year)
        ## Write log
        ok_file=dirtmp+"Extract_cora4_"+str(presyear)+"_"+str(backyear)+"_OK"
        return liste_tot

    def run_list(self,date1,date2,dirdata):
        liste_tot=[]
        valeurj=date1
        while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
            dateval=SyDate.__str__(valeurj)
            liste_file=glob.glob(dirdata+'/*'+dateval+'*.nc')
            for file in liste_file :
                try :
                    liste_tot.append(file)
                except IOError as e:
                    print "I/O error({0}): {1}".format(e.errno, e.strerror)
            valeurj=valeurj.goforward(1)
        return liste_tot
