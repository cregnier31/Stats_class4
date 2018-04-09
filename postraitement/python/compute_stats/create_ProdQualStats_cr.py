#!/usr/bin/env python

#-------------------------------------------------------------------------------------------------------------------------------------
# .> Brief
#  Program designed to create the quality product statistics (quaterly
#  validation reports, Copernicus)
#
# .> history :
#       22.01.13 creation (L.Zawadzki)
#       18.02.18 Modifs (C.Szczypta)
#
#
#-----------------------------------------------------------------------------------------------------------------------------------


import os,sys,getopt
import ConfigParser
import numpy as np
import shlex, subprocess
from datetime import date
import netCDF4
from netCDF4 import Dataset
sys.path.append("/home/cregnier/python/module/lib/python2.6/site-packages/")
sys.path.append('../module/')
from writer_stat import writer_stat
import param.Def_param_bulletin as params
from sytoolkit.sydate_origin import SyDateOrigin
from sytoolkit.sydate_new import SyDatenew
from sytoolkit.sydate import SyDate


# =============================================
#                 CONFIGURATION
# =============================================

letters = 's:e:c:t:' 
keywords = ['day1=', 'day2=', 'cfg=', 'type=' ] 
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)
print cla_opts
cl_start_date  = 'YYYYMMDD'
cl_end_date  = 'YYYYMMDD'
_DBFILE_        = './environment.cfg'

for o,p in cla_opts[0]:
  if o in ['-s','--day1']:
     cl_start_date = p
  elif o in ['-e','--day2']:
     cl_end_date = p
  elif o in ['-t','--type']:
     cexp=p
  elif o in ['-c','--cfg']:
     _DBFILE_ = p.strip()

cl_start_jdate = str(SyDate(cl_start_date).tojulian())
cl_end_jdate   = str(SyDate(cl_end_date).tojulian())

missing_value = 999999.

def load_db():
        db = ConfigParser.ConfigParser()
        db.read(os.path.expanduser(_DBFILE_))
        if not db.sections():
                print "Error reading configuration file %s" %_DBFILE_
                sys.exit(1)
        return db

# ------------------------------------------------------------
#               Chargement fichier de config
# ------------------------------------------------------------

db = load_db()
cla_areas      = params.liste_zone
cla_areasattr  = params.cla_areasattr
cla_metricname = params.cla_metricname
dirWork        = db.get('input_dir','DIR_WORK')
dirFileIn      = db.get('output_dir','DIR_CL4OUT')
dirFileOut     = db.get('output_dir','DIR_CL4OUT_NC')
cl_layerFile   = db.get('LAYER','layerFile')
cl_prefix      = db.get('INPUT','PREFIX2')
il_ivar        = db.get('INPUT','IVAR')
il_iarea       = db.get('INPUT','IZONE')
cl_conf        = db.get('PARAMS','CONFIGMDL').upper()


if not os.path.exists(dirWork):
    os.makedirs(dirWork)
if not os.path.exists(dirFileOut):
    os.makedirs(dirFileOut)

cl_confres     = db.get('NETCDF','MyOConfig')
cl_reference   = db.get('NETCDF','REFERENCE')
cl_contact     = db.get('NETCDF','CONTACT')
cl_institution = db.get('NETCDF','INSTITUTION')
cl_ref         = db.get('NETCDF','REF')
cl_fmt         = db.get('NETCDF','FMT')

if cexp == 'BIO' :
	cla_vars = ['CHL']
  	rla_forecast = [0., 336.]
elif cexp == 'PHYS' :
	cla_vars = ['PSAL','TEMP','SLA','SST'] 
	rla_forecast = [-240.,12.,36.,84.,132.]

# ------------------------------------------------
#             Lecture fichier couches
# ------------------------------------------------

rla_surface = [0., 0.]
rla_layers = []
if cexp == 'PHYS' :
    fileid = open(cl_layerFile)
    for line in fileid :
        lt = line.split()
   	rla_layers.append(float(lt[0]))
    fileid.close()

# MyO2 Convention for results file name
# -------------------------------------

cl_resultsFileName = 'product_quality_stats_'+cl_confres+'_'+cl_start_date+'_'+cl_end_date+'.nc'
cl_resultsFile = os.path.join(dirFileOut,cl_resultsFileName)


#  Collecting input Files
# ------------------------

cla_fileList = []	
for cl_area in cla_areas :
    print cl_area
    for num_var,cl_var in enumerate(cla_vars) :
        if cl_var == 'PSAL' or cl_var == 'TEMP':
            rla_lay = rla_layers
        else :  
            rla_lay = rla_surface   
        for ij,rl_layers in enumerate(rla_lay[0:-1]) :
            cl_depthdown = "%s"  %int(rla_lay[ij+1])
            cl_depthup   = "%s"  %int(rl_layers)
            cl_filetmplt = cl_prefix+'_'+cl_conf+'_'+cl_area+'_'+cl_start_date+'_'+cl_end_date+'_'+cl_var+'_'+cl_depthup+'-'+cl_depthdown+'m.txt'
            print cl_filetmplt
            if os.path.exists(os.path.join(dirFileIn,cl_filetmplt)) : 
                cla_fileList.append(cl_filetmplt)

for file in cla_fileList : print os.path.basename(file)
if len(cla_fileList) == 0 :
   print ' Error : No input File found'
   sys.exit(1)
else : 
   cl_nfiles = '%s' %len(cla_fileList)


#  Reading Statistics in ASCII files / time
# ------------------------------------------

cl_filename1 = os.path.join(dirFileIn,cla_fileList[0])
cl_file1 = np.loadtxt(cl_filename1)
nts = np.shape(cl_file1)[0]

cl_stats = np.nan*np.zeros((nts,len(rla_forecast),len(rla_layers)-1,len(cla_metricname),len(cla_areas),len(cla_vars)))
vector_time = np.nan*np.zeros((nts))

for a,cl_area in enumerate(cla_areas) :
    for num_var,cl_var in enumerate(cla_vars) :
        if cl_var == 'PSAL' or cl_var == 'TEMP':
            rla_lay = rla_layers
        else :  
            rla_lay = rla_surface   
        for ij,rl_layers in enumerate(rla_lay[0:-1]) :
            cl_depthdown = "%s"  %int(rla_lay[ij+1])
            cl_depthup   = "%s"  %int(rl_layers)      
            cl_filename  = cl_prefix+'_'+cl_conf+'_'+cl_area+'_'+cl_start_date+'_'+cl_end_date+'_'+cl_var+'_'+cl_depthup+'-'+cl_depthdown+'m.txt'
	    cl_file = np.loadtxt(os.path.join(dirFileIn,cl_filename))
	    vector_time[:] = cl_file[:,0]*24.

	    for f,rlfcst in enumerate(rla_forecast) : 
	        cl_stats[:,f,ij,0:3,a,num_var] = cl_file[:,1:4]
		cl_stats[:,f,ij,3,a,num_var] = cl_file[:,4+f*3]
		cl_stats[:,f,ij,4,a,num_var] = cl_file[:,5+f*3]
		cl_stats[:,f,ij,5,a,num_var] = cl_file[:,6+f*3]

w = np.where(np.isnan(cl_stats) == True)
cl_stats[w] = missing_value
w = np.where(cl_stats > missing_value)
cl_stats[w] = missing_value
                         

# ---------------------------------------------------------------------------------------
#               Write and save the corresponding netCDF file
# ---------------------------------------------------------------------------------------


if cexp == 'BIO' :
	writer_stat().write_BIO_files(cl_resultsFile, cl_contact, cl_confres, cl_fmt, cl_start_date, cl_end_date,
                                      cl_resultsFileName, cl_institution, cl_ref, cla_areasattr, cla_metricname, 
                                      cl_start_jdate, cl_end_jdate, cla_areasattr, cla_metricname, rla_forecast, 
                                      rla_surface, vector_time, cl_stats)
elif cexp == 'PHYS' :
	writer_stat().write_PHYS_files(cl_resultsFile, cl_contact, cl_confres, cl_fmt, cl_start_date, cl_end_date,
                                       cl_resultsFileName, cl_institution, cl_ref, cla_areasattr, cla_metricname,
                                       cl_start_jdate, cl_end_jdate, cla_areasattr, cla_metricname, rla_forecast,
                                       rla_layers, vector_time, cl_stats, rla_surface)


#----------  End of Script  --------------------------------------------------------------

