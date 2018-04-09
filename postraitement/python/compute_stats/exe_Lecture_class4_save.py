#!/usr/bin/env python

import sys,os,getopt,glob
import numpy as np
import ConfigParser
import netCDF4
## modules perso
sys.path.append('../module/')
#sys.path.append(pathmod)
import param.Def_param_bulletin as params
from supobs import toolkitStats
#import supobs
import resource
import geomlib

## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
print "OK"
#~~~~ Input parameters settings ~~~~~~~~~~~~~~~~~~~~~
letters = 's:e:c:t:' 
keywords = ['day1=', 'day2=', 'cfg=', 'type=' ] 
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)
print cla_opts
cl_dateMinZone  = 'YYYYMMDD'
cl_dateMaxZone  = 'YYYYMMDD'
_DBFILE_        = './environment.cfg'

for o,p in cla_opts[0]:
  if o in ['-s','--day1']:
     cl_dateMinZone = p
  elif o in ['-e','--day2']:
     cl_dateMaxZone = p
  elif o in ['-t','--type']:
     cvar=p
  elif o in ['-c','--cfg']:
     _DBFILE_ = p.strip()

def load_db():
        db = ConfigParser.ConfigParser()
        db.read(os.path.expanduser(_DBFILE_))
        if not db.sections():
                print "Error reading configuration file %s" %_DBFILE_
                sys.exit(1)
        return db

db = load_db()
#~
config       = eval(db.get('params','config')).upper()
doQC         = eval(db.get('NETCDF','doQC'))
cgrid        = eval(db.get('NETCDF','grid')).lower()
#cvar         = eval(db.get('NETCDF','cvar'))
dirNCin      = eval(db.get('NETCDF','dirNCin' ))
dirNCout     = eval(db.get('NETCDF','dirNCout' ))
file_boxmask = eval(db.get('NETCDF','file_boxmask' ))
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~ Recuperation definition boites ~~~~~~~~~~~~~~~~
nc = netCDF4.Dataset(file_boxmask,'r')
rla_mask = nc.variables['mask'][:]
rla_maskvalues = np.unique(rla_mask)
rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))
rla_lonmask = nc.variables['longitude'][:]
rla_latmask = nc.variables['latitude'][:]
nc.close()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cla_dates_tot = toolkitStats.char_period(cl_dateMinZone,cl_dateMaxZone)
print cla_dates_tot

#~~~~ Listing fichiers CLASS4 ~~~~~~~~~~~~~~~~~~~~~~~
cla_cl4files = []
for cdate in cla_dates_tot :
   print "OK"
   sys.exit(1)
   cl_filetmplt = 'class4_'+cdate+'_'+config+'_'+cgrid+'_'+cvar+'.nc'	   
   #print cl_filetmplt
   cla_filechck = glob.glob(os.path.join(dirNCin,cl_filetmplt))
   if len(cla_filechck) != 1 :
      print ' Problem while checking for CLASS4 files at date %s \n\
(%i files corresponding)' %(cdate,len(cla_filechck))
      print 'file %s : ' %(dirNCin+cl_filetmplt)
      continue
   cla_cl4files.append(cla_filechck[0])
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

print ' ------------------------------ '
print '|        Lecture CLASS4        |'
print ' ______________________________ '
print '|   Date   |   Var   | Status  |'
print ' ------------------------------ '
for cl_cl4file,cdate in zip(cla_cl4files,cla_dates) :

#   print '| DATE %s |' %(cdate)

   #~~~~ Recuperation positions observations ~~~~~~~~~~~
   cla_varname,rla_lonobs,rla_latobs,rla_depthobs = \
                supobs.toolkitStats.read_CL4obs(cl_cl4file)
   if rla_depthobs.shape[1] == 1 and (rla_depthobs[:,0]==0).all() : 
      ll_surface = True
      tab_prof   = np.array([-0.5,0.5])
   else :
      ll_surface = False
      tab_prof = params.tab_prof_model
   #~~~~ Recuperation valeurs observations et modele ~~~
   nc = netCDF4.Dataset(cl_cl4file,'r')
   variable = 'observation'
   rla_observation_init = nc.variables[variable][:]
   rla_observation_init[(rla_observation_init>=9999.)] = np.nan
   variable='qc'
   rla_qc_init=nc.variables[variable][:]
   variable = 'climatology'
   rla_climatology_init = nc.variables[variable][:]
   rla_climatology_init[(rla_climatology_init>=9999.)] = np.nan
   variable = 'forecast'
   rla_forecast_init = nc.variables[variable][:]
   rla_forecast_init[(rla_forecast_init>=9999.)] = np.nan
   variable = 'persistence'
   rla_persistence_init = nc.variables[variable][:]
   rla_persistence_init[(rla_persistence_init>=9999.)] = np.nan
   variable = 'best_estimate'
   rla_best_estimate_init = nc.variables[variable][:]
   rla_best_estimate_init[(rla_best_estimate_init>=9999.)] = np.nan
   nc.close()

	
#   print '| DATE read OK %s |' %(cdate)

   #~~~~ Travail sur chaque variable (sst,sla,votemper,..) ~~
   for ivar,cl_var in enumerate(cla_varname) :
      if cl_var in ['vosaline', 'salt    '] :
         rg_EcartMax = params.rg_EcartSalMax
	 cl_var='vosaline'
         cl_var_out='PSAL'
         bad_qc=9
      elif cl_var in ['votemper' ,'temp    '] :
         rg_EcartMax = params.rg_EcartTempMax
	 cl_var='votemper'
	 cl_var_out='TEMP'
         bad_qc=9
         if ll_surface :
           bad_qc=1
      elif cl_var in ['sossheig' , 'eta_t   '] :
         rg_EcartMax = params.rg_EcartSLAMax
	 cl_var='sossheig'
	 cl_var_out='SLA'
         bad_qc=9
	 if config in ['GIOPS_CONCEPTS']: 
	   rl_var=0.09 ## 8 mai
	   #rl_var=0.185 ## 1 janv - 7 mai
	   rla_best_estimate_init[:,ivar,:] =np.ma.filled(np.ma.masked_array(rla_best_estimate_init[:,ivar,:]+rl_var,fill_value=np.nan))
	   rla_persistence_init[:,ivar,:] =np.ma.filled(np.ma.masked_array(rla_persistence_init[:,ivar,:]+rl_var,fill_value=np.nan))
	   rla_forecast_init[:,ivar,:,:] =np.ma.filled(np.ma.masked_array(rla_forecast_init[:,ivar,:,:]+rl_var,fill_value=np.nan))
      else :
         print 'Unexpected varname %s ' %(cl_var)
         sys.exit(1)
      rla_qc_var            = rla_qc_init[:,ivar,:]
      rla_observation_var   = rla_observation_init[:,ivar,:]
      rla_forecast_var      = rla_forecast_init[:,ivar,:,:]
      rla_persistence_var   = rla_persistence_init[:,ivar,:,:]
      rla_best_estimate_var = rla_best_estimate_init[:,ivar,:]
      rla_climatology_var   = rla_climatology_init[:,ivar,:]
      ## Passe au jour suivant si on n'a pas pas de best analyse)
      #if np.isnan(rla_best_estimate_var).all() : continue
      if np.isnan(rla_forecast_var).all() : continue

      if doQC :
         #Test sur la coherence des valeurs et des observations par rapport a la climatologie
         rla_diffclim2obs = np.absolute(rla_climatology_var-rla_observation_var)
	 if np.isnan(rla_best_estimate_var).all() :
	   # print rla_best_estimate_var
	   # print '---------------'
	   # print rla_forecast_var[:,0,:]
	   # print '---------------'
	    rla_diffbest2obs = np.absolute(rla_forecast_var[:,0,:]-rla_observation_var)
	 else :
            rla_diffbest2obs = np.absolute(rla_best_estimate_var-rla_observation_var)
	 if ~np.isnan(rla_climatology_var).any() :
	         qcs = np.where(
              		       (rla_diffbest2obs > rg_EcartMax) &\
              		       (rla_diffclim2obs > rg_EcartMax) \
              		      ) 
	 else :
	         qcs = np.where(
              		       (rla_diffbest2obs > rg_EcartMax)
              		      ) 
         if len(qcs[0]) > 0 : 
            rla_observation_var[qcs] 		    = np.nan
      ## print 'bad qc %s ' %(bad_qc)
      ## Prise en compte du qc dans les fichiers
      qc_file= np.where(rla_qc_var==bad_qc)	 
      if len(qc_file[0]) > 0 : 
            rla_observation_var[qc_file] = np.nan
      #Harmonisation des obs ignorees
      rla_best_estimate_var[(np.isnan(rla_observation_var))] = np.nan
      rla_climatology_var[(np.isnan(rla_observation_var))] = np.nan
      for il in range(rla_forecast_var.shape[1]) :
         rla_forecast_tmp = rla_forecast_var[:,il,:]
         rla_persistence_tmp = rla_persistence_var[:,il,:]
         rla_forecast_tmp[(np.isnan(rla_observation_var))] = np.nan
         rla_persistence_tmp[(np.isnan(rla_observation_var))] = np.nan
         del rla_forecast_tmp,rla_persistence_tmp
      
      #~~~~ Initialisation variables ~~~~~~~~~~~~~~~~~~~~~~
      yout = 13   # obs,best,fcst1,fcst3,fcst5,fcst7,fcst9,pers1,pers3,pers5,pers7,pers9,clim
      rla_mean = np.nan*np.zeros((len(tab_prof) -1,\
      			   yout,\
      			   len(rla_maskvalues)\
      			  ))
      ila_indice_box = np.zeros((len(tab_prof) -1,\
      			   yout,\
      			   len(rla_maskvalues)\
      			  ))
      rla_rms = np.nan*np.zeros((len(tab_prof) -1 ,\
      			   yout,\
      			   len(rla_maskvalues)\
      			  ))
      rla_rms_diff = np.nan*np.zeros((len(tab_prof) -1 ,\
      			   yout,\
      			   len(rla_maskvalues)\
      			  ))
      rla_mean_diff = np.nan*np.zeros((len(tab_prof) -1 ,\
      			   yout,\
      			   len(rla_maskvalues)\
      			  ))
      rla_box = np.nan*np.zeros(len(rla_maskvalues))

      #~~~~ Classement donnees dans boites ~~~~~~~~~~~~~~~~
      boxind_save = []
      for imask,maskval in enumerate(rla_maskvalues) :
         #~~~~ Definition boite 2D ~~~~~~~~~~~~~~~~~~~
         i,j = np.where(rla_mask == maskval)
         boxlonmin = rla_lonmask[i,j].min()
         boxlonmax = rla_lonmask[i,j].max()
         boxlatmin = rla_latmask[i,j].min()
         boxlatmax = rla_latmask[i,j].max()
         pos   = np.array(zip(rla_lonmask[i,j], rla_latmask[i,j]))
	 if np.isnan(pos).any() : 
	    ISNA = np.where(np.isnan(pos))
	    pos = np.delete(pos,ISNA[0],0)
	 Hull = geomlib.cloudHull(pos)

         ibox = np.where(
         		(rla_lonobs >= boxlonmin) &\
         		(rla_lonobs <  boxlonmax) &\
         		(rla_latobs >= boxlatmin) &\
         		(rla_latobs <  boxlatmax) \
                )[0]	
         if np.size(ibox) == 0 : continue
         iboxobs = np.where(
	        	geomlib.point_inside_polygon2(rla_lonobs[ibox],rla_latobs[ibox],Hull)
                )[0]	
	 
         if np.size(iboxobs) == 0 : continue
	 iobs = ibox[iboxobs]

         iobs_alreadyused = []
	 for jiobs in iobs : 
	    if jiobs in boxind_save :
               iobs_alreadyused = np.where(iobs == jiobs)[0]
	       iobs = np.delete(iobs,iobs_alreadyused,0)
	 boxind_save.extend(iobs)


         #~~~~ Calculs Stats avec 3e dimension ~~~~~~~
         rla_climmean,rla_climrms,rla_climbias,rla_climrmse,ila_nobs_clim = \
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_climatology_var[iobs,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )

         rla_obsmean,rla_obsrms,rla_obsbias,rla_obsrmse,ila_nobs_obs =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_observation_var[iobs,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )

         rla_fcst1mean,rla_fcst1rms,rla_fcst1bias,rla_fcst1rmse,ila_nobs_fcst1 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_forecast_var[iobs,1,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )

         rla_fcst3mean,rla_fcst3rms,rla_fcst3bias,rla_fcst3rmse,ila_nobs_fcst3 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_forecast_var[iobs,3,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_fcst5mean,rla_fcst5rms,rla_fcst5bias,rla_fcst5rmse,ila_nobs_fcst5 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_forecast_var[iobs,5,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_fcst7mean,rla_fcst7rms,rla_fcst7bias,rla_fcst7rmse,ila_nobs_fcst7 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_forecast_var[iobs,7,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )

         rla_fcst9mean,rla_fcst9rms,rla_fcst9bias,rla_fcst9rmse,ila_nobs_fcst9 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_forecast_var[iobs,9,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )

         rla_pers1mean,rla_pers1rms,rla_pers1bias,rla_pers1rmse,ila_nobs_pers1 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_persistence_var[iobs,1,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_pers3mean,rla_pers3rms,rla_pers3bias,rla_pers3rmse,ila_nobs_pers3 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_persistence_var[iobs,3,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_pers5mean,rla_pers5rms,rla_pers5bias,rla_pers5rmse,ila_nobs_pers5 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_persistence_var[iobs,5,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_pers7mean,rla_pers7rms,rla_pers7bias,rla_pers7rmse,ila_nobs_pers7 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_persistence_var[iobs,7,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_pers9mean,rla_pers9rms,rla_pers9bias,rla_pers9rmse,ila_nobs_pers9 =\
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_persistence_var[iobs,9,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         rla_bestmean,rla_bestrms,rla_bestbias,rla_bestrmse,ila_nobs_best = \
                                         supobs.Statslib.statlayer_CL4var(
                                                        rla_best_estimate_var[iobs,:],\
                                                        rla_observation_var[iobs,:],\
                                                        rla_depthobs[iobs,:],\
                                                        tab_prof
                                                                       )
         #~~~~ Sauvegarde resultats ~~~~~~~~~~~~~~~~~~
         rla_mean[:,0,imask] = rla_obsmean
         rla_mean[:,1,imask] = rla_bestmean
         rla_mean[:,2,imask] = rla_fcst1mean
         rla_mean[:,3,imask] = rla_fcst3mean
         rla_mean[:,4,imask] = rla_fcst5mean
         rla_mean[:,5,imask] = rla_fcst7mean
         rla_mean[:,6,imask] = rla_fcst9mean
         rla_mean[:,7,imask] = rla_pers1mean
         rla_mean[:,8,imask] = rla_pers3mean
         rla_mean[:,9,imask] = rla_pers5mean
         rla_mean[:,10,imask] = rla_pers7mean
         rla_mean[:,11,imask] = rla_pers9mean
         rla_mean[:,12,imask] = rla_climmean
        # nb_mean= np.where(rla_mean[:,0:7,imask] == 0 )
        # if len(nb_mean[0]) > 0 : 
        #                   = np.nan


         ila_indice_box[:,0,imask] = ila_nobs_obs
         #print ila_indice_box[:,0,imask]
         ila_indice_box[:,1,imask] = ila_nobs_best
         ila_indice_box[:,2,imask] = ila_nobs_fcst1
         ila_indice_box[:,3,imask] = ila_nobs_fcst3
         ila_indice_box[:,4,imask] = ila_nobs_fcst5
         ila_indice_box[:,5,imask] = ila_nobs_fcst7
         ila_indice_box[:,6,imask] = ila_nobs_fcst9
         ila_indice_box[:,7,imask] = ila_nobs_pers1
         ila_indice_box[:,8,imask] = ila_nobs_pers3
         ila_indice_box[:,9,imask] = ila_nobs_pers5
         ila_indice_box[:,10,imask] = ila_nobs_pers7
         ila_indice_box[:,11,imask] = ila_nobs_pers9
         ila_indice_box[:,12,imask] = ila_nobs_clim

         rla_rms[:,0,imask] = rla_obsrms
         rla_rms[:,1,imask] = rla_bestrms
         rla_rms[:,2,imask] = rla_fcst1rms
         rla_rms[:,3,imask] = rla_fcst3rms
         rla_rms[:,4,imask] = rla_fcst5rms
         rla_rms[:,5,imask] = rla_fcst7rms
         rla_rms[:,6,imask] = rla_fcst9rms
         rla_rms[:,7,imask] = rla_pers1rms
         rla_rms[:,8,imask] = rla_pers3rms
         rla_rms[:,9,imask] = rla_pers5rms
         rla_rms[:,10,imask] = rla_pers7rms
         rla_rms[:,11,imask] = rla_pers9rms
         rla_rms[:,12,imask] = rla_climrms

         rla_rms_diff[:,0,imask] = rla_obsrmse
         rla_rms_diff[:,1,imask] = rla_bestrmse
         rla_rms_diff[:,2,imask] = rla_fcst1rmse
         rla_rms_diff[:,3,imask] = rla_fcst3rmse
         rla_rms_diff[:,4,imask] = rla_fcst5rmse
         rla_rms_diff[:,5,imask] = rla_fcst7rmse
         rla_rms_diff[:,6,imask] = rla_fcst9rmse
         rla_rms_diff[:,7,imask] = rla_pers1rmse
         rla_rms_diff[:,8,imask] = rla_pers3rmse
         rla_rms_diff[:,9,imask] = rla_pers5rmse
         rla_rms_diff[:,10,imask] = rla_pers7rmse
         rla_rms_diff[:,11,imask] = rla_pers9rmse
         rla_rms_diff[:,12,imask] = rla_climrmse

         rla_mean_diff[:,0,imask] = rla_obsbias
         rla_mean_diff[:,1,imask] = rla_bestbias
         rla_mean_diff[:,2,imask] = rla_fcst1bias
         rla_mean_diff[:,3,imask] = rla_fcst3bias
         rla_mean_diff[:,4,imask] = rla_fcst5bias
         rla_mean_diff[:,5,imask] = rla_fcst7bias
         rla_mean_diff[:,6,imask] = rla_fcst9bias
         rla_mean_diff[:,7,imask] = rla_pers1bias
         rla_mean_diff[:,8,imask] = rla_pers3bias
         rla_mean_diff[:,9,imask] = rla_pers5bias
         rla_mean_diff[:,10,imask] = rla_pers7bias
         rla_mean_diff[:,11,imask] = rla_pers9bias
         rla_mean_diff[:,12,imask] = rla_climbias

         rla_box[imask] = maskval

      #print,'Write netcdf file %s' %(dirNCout)
      #~~~~ Ecriture NetCDF ~~~~~~~~~~~~~~~~~~~~~~~
      if np.isnan(ila_indice_box).all() : continue
      cl_fileOut = os.path.join(dirNCout,config+'_'+cgrid+'_rms_diff_'+cdate+'_'+cvar+'_'+cl_var+'.nc')
      nc = netCDF4.Dataset(cl_fileOut, 'w', format='NETCDF3_64BIT',zlib=True, least_significant_digit=4)
      nc.set_fill_off()
      # Dimensions
      nc.createDimension('x', len(rla_maskvalues))
      nc.createDimension('y', yout)
      nc.createDimension('z', len(tab_prof) -1)
      # Variables
      ncmean     = nc.createVariable('mean', 'f', ('z','y','x'),fill_value=1.e35)
      ncmean.setncattr('long_name',"mean")
      ncmean[:]  = rla_mean

      ncindice_box    = nc.createVariable('indice_box', 'f', ('z','y','x'),fill_value=1.e35)
      ncindice_box.setncattr('long_name',"indice_box")
      ncindice_box[:] = ila_indice_box

      ncrms      = nc.createVariable('rms', 'f', ('z','y','x'),fill_value=1.e35)
      ncrms.setncattr('long_name',"root mean square")
      ncrms[:]  = rla_rms

      ncrms_diff = nc.createVariable('rms_diff', 'f', ('z','y','x'),fill_value=1.e35)
      ncrms_diff.setncattr('long_name',"square diff cumul")
      ncrms_diff[:]  = rla_rms_diff

      ncmean_diff = nc.createVariable('mean_diff', 'f', ('z','y','x'),fill_value=1.e35)
      ncmean_diff.setncattr('long_name',"mean diff")
      ncmean_diff[:]  = rla_mean_diff

      ncbox = nc.createVariable('box', 'f', ('x',),fill_value=1.e35)
      ncbox.setncattr('long_name',"geographical boxes")
      ncbox[:]  = rla_box

      nc.close()
 
      print '| %s | %s |  Done  |' %(cdate,cl_var)
      print ' ------------------------------ '
   print '        END '
   print ' ------------------------------ '
