from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import netCDF4
import geojson
from geojson import MultiPoint
import json
import ConfigParser
import operator,getopt                                                                                                      
import datetime as dt
from datetime import date
from sytoolkit.sydate import SyDate
from Logger import Logger                                                                                                   
from calendar import monthrange
 
##############################################################
## C.REGNIER Juin 2014
## Class Loader to load different type of file with a pattern factory
##############################################################

class Loader(object):
    # Create based on class name:
    @staticmethod
    def factory(type):
        #return eval(type + "()")
        if type == "NC_CORIO": return LoaderNCcorio()
        if type == "NC_GODAE": return LoaderNCgodae()
        if type == "ASCII": return AsciiLoader()
        if type == "LIST": return ListWriter()
        if type == "NML": return NmlLoader()
        if type == "DAT": return ColocLoader()
        if type == "INPUT": return InputLoader()
        assert 0, "Format not known: " + type


class InputLoader(Loader): 
    def load(self,options,level):
##      Loader for input options
        keywords = ['date1=','date2=','delta=','nbdate=','daterun=','config=','data=','src=','nbproc=']
        cla_opts = getopt.getopt(options,'',keywords)
        log=Logger("InputLoader").run(level)
        ll_delta=None
        ll_date1=None
        ll_date2=None
        ll_daterun=None
        ll_nbdate=None
        ll_config=None
	ll_data=None
	ll_src=None
	cl_daterun=None
        list_var=[]
        nb_proc=0
        for o,p in cla_opts[0] :
           if o in ['--delta'] :
             ll_delta=True
             cl_delta = p
           elif o in  ['--date1'] : 
             ll_date1=True
             cl_start_date = p
           elif o in  ['--date2'] : 
             ll_date2=True
             cl_end_date = p
           elif o in  ['--daterun'] : 
             ll_daterun=True
             cl_daterun = p
           elif o in  ['--nbdate'] : 
             ll_nbdate=True
             cl_nbdate = p
           elif o in  ['--config'] : 
             ll_config=True
             cl_config = p
           elif o in  ['--data'] : 
             ll_data=True
             cl_data = p
	   elif o in  ['--src'] : 
             ll_src=True
             cl_src = p
	   elif o in  ['--nbproc'] : 
             ll_optim=True
             cl_nbproc = p
             nb_proc=int(cl_nbproc)
        list_var.append(ll_date1)
        list_var.append(ll_date2)
        list_var.append(ll_daterun)
        list_var.append(ll_nbdate)
	cl_schedule='d'
        if not ll_config :
            log.error("Config is missing : add --config= in the launcher")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --date1=XXXX --date2=XXXX or ")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --delta=XXXX (delayed time before today)")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --daterun=XXXX --nbdate=X --delta=X  (for example 1 week before today -14 and today -7)")
            sys.exit(1)
        if not ll_data or not ll_src :
            log.error("Type is missing : add --data=SLA/SST/profile/profile_ARMOR and --src=GODAE/CORIO. in the launcher")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --date1=XXXX --date2=XXXX or ")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --delta=XXXX (delayed time before today)")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --daterun=XXXX --nbdate=X --delta=X  (for example 1 week before today -14 and today -7)")
	    sys.exit(1)
        if ll_delta and list_var.count(True) == 0 :
             log.info("Case 1 Delta only")
             datetoday=SyDate(dt.datetime.today().strftime("%Y%m%d"))
             date1=datetoday.gobackward(int(cl_delta))
             date2=date1
        elif ll_date1 and ll_date2 and not ll_delta and not ll_daterun :
             log.info("Case 2 Date1 Date2")
             ## Test LEN of input date
	     datelen1=len(cl_start_date)
	     datelen2=len(cl_end_date)
	     if  datelen1 == datelen2 and datelen1 == 6 :  
		log.info("Monthly values")
		log.info("Values %s %s :" %(cl_start_date[0:4],cl_start_date[4:6]))
	        nb_day1=monthrange(int(cl_start_date[0:4]),int(cl_start_date[4:6]))[1]
		cl_start_date2=cl_start_date+"01"
		cl_end_date2=cl_start_date+str(nb_day1)
		log.info(cl_start_date2)
		log.info(cl_end_date2)
                date1=SyDate(cl_start_date2)
                date2=SyDate(cl_end_date2)
	        cl_schedule='m'
	     elif  datelen1 == datelen2 and datelen1 == 8 :  
                log.info("Daily values")
                date1=SyDate(cl_start_date)
                date2=SyDate(cl_end_date)
	     else :
                log.error("Input date must be in month or day")
        elif ll_daterun and ll_nbdate and ll_delta :
             log.info("Case 3 Backward run")
             jrun=SyDate(cl_daterun)
             date1=jrun.gobackward(int(cl_delta))
             date2=jrun.gobackward(int(cl_delta)-int(cl_nbdate)+1)
        else :
	     log.error("Case not valid")
             log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --date1=XXXX --date2=XXXX or ")
             log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --delta=XXXX (delayed time before today)")
             log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --daterun=XXXX --nbdate=X --delta=X  \
			    (for example 1 week before today -14 and today -7)")
	     sys.exit(1)
	confname='config_'+str(cl_config)+'_'+str(cl_src)+'.cfg'
        return date1,date2,confname,cl_data,cl_daterun,cl_schedule,cl_src,nb_proc

class NmlLoader(Loader): 
   def load(self,filename,level):
         log=Logger("NmlLoader").run(level)
	 db = ConfigParser.ConfigParser()
	 for file in filename : 
           db.read(os.path.expanduser(file))
         if not db.sections():
           log.error("Configuration file not found %s ! " %(filename))
           sys.exit(1)
         return db

class LoaderNCcorio(Loader):

    def read_pos(self,filename):
       print 'read netcdf file : %s ' %(filename)
       nc = netCDF4.Dataset(filename,'r')        
       variable = 'LONGITUDE'
       rla_lon = nc.variables[variable][:]
       #rla_lon[rla_lon <0] += 360.
       variable = 'LATITUDE'
       rla_lat = nc.variables[variable][:]
       #nb_tot=len(rla_lon)
       n_profiles=len(rla_lon)
       #n_profiles=386
       print n_profiles
     #n_profiles=1000
       #position=np.ndarray(shape=(n_profiles,2))
       #position[:,0]=rla_lon[:] 
       #position[:,1]=rla_lat[:] 
       # Solution 1
       position=np.ndarray(shape=(n_profiles,2),dtype=float, order='F',buffer=np.array([rla_lon[:],rla_lat[:]]))
       # Solution 2
       #il_val=0
       #for il_ind in range(nb_tot):
       #  if  rla_lon[il_ind] < 9999. and rla_lat[il_ind] < 9999. :
       #    position[il_val,0]=rla_lon[il_ind]
       #    position[il_val,1]=rla_lat[il_ind]
       #    il_val=il_val+1
       #np.set_printoptions(suppress=True)
       return position

class LoaderNCgodae(Loader):

    def read_pos(self,filename):
       nc = netCDF4.Dataset(filename,'r')        
       variable = 'longitude'
       rla_lon = nc.variables[variable][:]
       variable = 'latitude'
       rla_lat = nc.variables[variable][:]
       n_profiles=len(rla_lon[:])
       ## Optional Read juld
       ##variable='juld'
       ##rla_juld= nc.variables[variable][:]
       position=np.ndarray(shape=(n_profiles,2),dtype=float, order='F')
       il_val=0
       for il_ind in range(n_profiles):
           position[il_val,0]=rla_lon[il_ind]
           position[il_val,1]=rla_lat[il_ind]
           il_val=il_val+1
       np.set_printoptions(suppress=True)
       return position

class AsciiLoader(Loader):
    def read_pos(self,filename):
       #print 'read ASCII file : %s ' %(filename)
       #data=np.genfromtxt(filename,usecols = (2,3),skip_header=1)
       data=np.genfromtxt(filename,usecols = (1,2),skip_header=1)
       position=np.array(data)
       return position
 
class ColocLoader(Loader):
    def read_pos(self,filename):
       #print 'read ASCII file : %s ' %(filename)
       #data=np.genfromtxt(filename,usecols = (5,6))
       data=np.genfromtxt(filename,usecols = (15,16))
       position=np.array(data)
       return position

