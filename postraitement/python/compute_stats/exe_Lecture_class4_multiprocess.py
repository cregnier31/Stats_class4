#!/usr/bin/env python
import sys,os,getopt,glob
sys.path.append('../../module/')
import numpy as np
import ConfigParser
import netCDF4
from mpi4py import MPI
## modules perso
import param.Def_param_bulletin as params
from supobs import toolkitStats
import supobs
import resource
import geomlib
import datetime as dt

# Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


#~~~~~~~~~~~~~~~~~~~~~ Input parameters settings ~~~~~~~~~~~~~~~~~~~~~

letters = 's:e:c:t:' 
keywords = ['day1=', 'day2=', 'cfg=', 'type=' ] 
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)

cl_dateMinZone  = 'YYYYMMDD'
cl_dateMaxZone  = 'YYYYMMDD'
ll_date1=None
ll_date2=None

_DBFILE_        = './environment.cfg'

for o,p in cla_opts[0]:
    if o in ['-s','--day1']:
        cl_dateMinZone = p
        ll_date1 = True
    elif o in ['-e','--day2']:
        cl_dateMaxZone = p
        ll_date2 = True
    elif o in ['-t','--type']:
        cvar=p
    elif o in ['-c','--cfg']:
        _DBFILE_ = p.strip()

if not ll_date1 and not ll_date2:
    date_now = dt.datetime.now()
    if date_now.month == 1 :
        cl_dateMinZone = str(date_now.year-1)+"1201"
        cl_dateMaxZone = str(date_now.year)+"0101"
    elif date_now.month < 10 :
        cl_dateMinZone = str(date_now.year)+"0"+str(date_now.month-1)+"01"
        cl_dateMaxZone = str(date_now.year)+"0"+str(date_now.month)+"01"
    elif date_now.month == 11 :
        cl_dateMinZone = str(date_now.year)+"0"+str(date_now.month-1)+"01"
        cl_dateMaxZone = str(date_now.year)+str(date_now.month)+"01"
    else :
        cl_dateMinZone = str(date_now.year)+str(date_now.month-1)+"01"
        cl_dateMaxZone = str(date_now.year)+str(date_now.month)+"01"

def load_db():
    db = ConfigParser.ConfigParser()
    db.read(os.path.expanduser(_DBFILE_))
    if not db.sections():
        print ("Error reading configuration file %s" %_DBFILE_)
        sys.exit(1)
    return db

db = load_db()
config_model = db.get('PARAMS','CONFIGMDL').upper()
config_obs   = db.get('PARAMS','CONFIGOBS').upper()
doQC         = db.get('NETCDF','doQC')
cgrid        = db.get('NETCDF','grid').lower()
file_boxmask = db.get('NETCDF','file_boxmask' )
dirNCin     = db.get('input_dir','DIR_IN' )
dirNCout     = db.get('output_dir','DIR_OUT' )
prefix       = db.get('INPUT','PREFIX1' )
lead_time    = eval(db.get('input_dir','LEAD_TIME')).split()


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~ Recuperation definition boites ~~~~~~~~~~~~~~~~~~~~

nc = netCDF4.Dataset(file_boxmask,'r')
rla_mask = nc.variables['mask'][:]
rla_maskvalues = np.unique(rla_mask)
rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))
rla_lonmask = nc.variables['longitude'][:]
rla_latmask = nc.variables['latitude'][:]
nc.close()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cla_dates_tot = toolkitStats.char_period(cl_dateMinZone,cl_dateMaxZone)

#~~~~ repartition dates sur processeurs ~~~~~~~~~~~~~
comm = MPI.COMM_WORLD
ndates = len(cla_dates_tot)
irest  = np.mod(ndates,comm.size) 

ntask  = ndates / comm.size
istart = ntask*comm.rank
iend   = istart + ntask - 1
#if comm.rank == comm.size -1 : iend += irest
cla_dates = cla_dates_tot[istart:iend+1]
iend_tot = ntask*comm.size-1
if irest > 0 and comm.rank < irest : 
    cla_dates.append(cla_dates_tot[iend_tot+comm.rank+1])

#~~~~~~~~~~~~~~~~~~~~~~ Listing fichiers CLASS4 ~~~~~~~~~~~~~~~~~~~~~~~
cla_cl4files = []
for cdate in cla_dates :
    if cvar == 'CHL' or cvar == 'chl':
        cl_filetmplt = prefix+'_'+cdate+'_'+config_obs+'_'+config_model+'_'+cvar+'.nc'
    else :
        cl_filetmplt = prefix+'_'+cdate+'_'+config_model+'_'+cgrid+'_'+cvar+'.nc'
    cla_filechck = glob.glob(
                    os.path.join(
                    dirNCin,
                    cl_filetmplt))
    if len(cla_filechck) != 1 :
        print (' Problem while checking for CLASS4 files at date %s \n\
(%i   files corresponding)' %(cdate,len(cla_filechck)))
        print ('file %s : ' %(dirNCin+cl_filetmplt))
        continue
    cla_cl4files.append(cla_filechck[0])

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if comm.rank == 0 :
    print (' ------------------------------ ') 
    print ('|        Lecture CLASS4        |')
    print (' ______________________________ ')
    print ("Cvar %s " %cvar)
    print (' ------------------------------ ')
    if not os.path.exists(dirNCout):
        os.makedirs(dirNCout)

for cl_cl4file,cdate in zip(cla_cl4files,cla_dates) :

    print ('| DATE %s |' %(cdate))

#~~~~~~~~~~~~~~~~~ Recuperation positions observations ~~~~~~~~~~~~~~~~

    if cvar == 'CHL' or cvar =='chl':
        rla_lonobs,rla_latobs, rla_depthobs = \
        supobs.toolkitStats.read_CL4obs_chloro(cl_cl4file)
    else :
        cla_varname,rla_lonobs,rla_latobs,rla_depthobs = \
        supobs.toolkitStats.read_CL4obs(cl_cl4file)

    if rla_depthobs.shape[1] == 1 and (rla_depthobs[:,0]==0).all() : 
        ll_surface = True
        tab_prof   = np.array([-0.5,0.5])
    else :
        ll_surface = False
        tab_prof = params.tab_prof_model


#~~~~~~~~~~~~~ Recuperation valeurs observations et modele ~~~~~~~~~~~~
  
    nc = netCDF4.Dataset(cl_cl4file,'r')
    nb_lead_time = 0
    clim = False
    for time in lead_time : 
        nb_lead_time = nb_lead_time +1
        if time == 'forecast' :
            rla_forecast_init = nc.variables[time][:]
            if type(rla_observation_init) != np.ndarray:
                rla_forecast_init = rla_forecast_init.data
            rla_forecast_init[(rla_forecast_init == -999.)] = np.nan
            rla_forecast_init[(rla_forecast_init>=9999.)] = np.nan
            if cvar == 'CHL' or cvar == 'chl':
                rla_forecast_init[(rla_forecast_init == 0.)] = np.nan
                rla_forecast_init = np.log10(rla_forecast_init)
        if time == 'observation' and config_obs == 'GLOBCOLOUR' :
            rla_observation_init = nc.variables[cvar.upper()][:]
            if type(rla_observation_init) != np.ndarray:
                rla_observation_init = rla_observation_init.data
            rla_observation_init[(rla_observation_init == -999.)] = np.nan
            rla_observation_init[(rla_observation_init>=9999.)] = np.nan
            rla_observation_init[(rla_observation_init == 0.)] = np.nan
            rla_observation_init = np.log10(rla_observation_init)
        if time == 'observation' and config_obs != 'GLOBCOLOUR' :
            rla_observation_init = nc.variables[time][:]
            if type(rla_observation_init) != np.ndarray:
                rla_observation_init = rla_observation_init.data
            rla_observation_init[(rla_observation_init >= 9999.)] = np.nan
            rla_observation_init[rla_observation_init == -999.] = np.nan
        if time == 'best_estimate' :
            rla_best_estimate_init = nc.variables[time][:]
            if type(rla_observation_init) != np.ndarray:
                rla_best_estimate_init = rla_best_estimate_init.data
            rla_best_estimate_init[(rla_best_estimate_init>=9999.)] = np.nan
            rla_best_estimate_init[(rla_best_estimate_init == -999.)] = np.nan
            if cvar == 'CHL' or cvar == 'chl':
                rla_best_estimate_init[(rla_best_estimate_init == 0.)] = np.nan
                rla_best_estimate_init = np.log10(rla_best_estimate_init)
        if time == 'climatology' :
            clim=True
            rla_climatology_init = nc.variables[time][:]
            if type(rla_observation_init) != np.ndarray:
                rla_climatology_init = rla_climatology_init.data
            rla_climatology_init[(rla_climatology_init == -999.)] = np.nan
            rla_climatology_init[(rla_climatology_init >= 9999.)] = np.nan
            if cvar == 'CHL' or cvar == 'chl':
                rla_climatology_init[(rla_climatology_init == 0.)] = np.nan
                rla_climatology_init = np.log10(rla_climatology_init)
        if time == 'persistence' :
            rla_persistence_init = nc.variables[time][:]
            if type(rla_observation_init) != np.ndarray:
                rla_persistence_init = rla_persistence_init.data
            rla_persistence_init[(rla_persistence_init>=9999.)] = np.nan
            rla_persistence_init[(rla_persistence_init == -999.)] = np.nan
            if cvar == 'CHL' or cvar == 'chl':
                rla_persistence_init[(rla_persistence_init == 0.)] = np.nan
                rla_persistence_init = np.log10(rla_persistence_init)
        if config_obs != 'GLOBCOLOUR' :
            rla_qc_init=nc.variables['qc'][:]

    nc.close()


#~~~~~~~~~~~~~~~~~ Travail sur chaque variable (sst,sla,votemper,..) ~~~~~~~
    if config_model == 'FREEBIORYS2' :
        cla_varname = ['chloro']
        yout = 2 # obs,best
        exp_name =  np.chararray(yout,itemsize=11)
        exp_name[0] = 'observation' ; exp_name[1] = 'hindcast'
    elif config_model == 'BIOMER4' :
        cla_varname = ['chloro']
        yout = 3 # obs,best,fcst
        exp_name =  np.chararray(yout,itemsize=11)
        exp_name[0] = 'observation' ; exp_name[1] = 'hindcast' ; exp_name[2] = 'forecast'
    else :
        yout = 13   # obs,best,fcst1,fcst3,fcst5,fcst7,fcst9,pers1,pers3,pers5,pers7,pers9,clim
        exp_name =  np.chararray(yout,itemsize=11)
        exp_name[0] = 'observation' ; exp_name[1] = 'hindcast' ; exp_name[2] = 'forecast1'
        exp_name[3] = 'forecast3' ; exp_name[4] = 'forecast5' ; exp_name[5] = 'forecast7'
        exp_name[6] = 'forecast9' ; exp_name[7] = 'persistence1' ; exp_name[8] = 'persistence3'
        exp_name[9] = 'persistence5' ; exp_name[10] = 'persistence7' ; exp_name[11] = 'persistence9'
        exp_name[12] = 'climatology'
    
    for ivar,cl_var in enumerate(cla_varname) :
        if cvar == 'profile':
            bad_qc=9
            if cl_var in ['vosaline', 'salt    '] :
                rg_EcartMax = params.rg_EcartSalMax
                cl_var='vosaline'
                cl_var_out='PSAL'
            elif cl_var in ['votemper' ,'temp    '] :
                rg_EcartMax = params.rg_EcartTempMax
                cl_var='votemper'
                cl_var_out='TEMP'
                if ll_surface :
                    bad_qc=1
        else :
            cl_var_out = cvar
            if cl_var in ['sossheig' , 'eta_t   '] :
                rg_EcartMax = params.rg_EcartSLAMax
                cl_var='sossheig'
                bad_qc=9
            elif cl_var in ['votemper' ,'temp    '] :
                rg_EcartMax = params.rg_EcartTempMax
                cl_var='votemper'
                bad_qc=9
            elif cl_var in ['chloro'] :
                bad_qc=np.nan
            else :
                print ('Unexpected varname %s ' %(cl_var))
                sys.exit(1)

        if config_model == 'BIOMER4' :
            rla_observation_var   = np.reshape(rla_observation_init,rla_lonobs.size)
            rla_forecast_var      = np.reshape(rla_forecast_init,rla_lonobs.size)
            rla_best_estimate_var = np.reshape(rla_best_estimate_init,rla_lonobs.size)
            if clim == True:
                rla_climatology_var = np.reshape(rla_climatology_init,rla_lonobs.size)
            nb_fcst = 1
            nb_pers = 1
        elif config_model == 'FREEBIORYS2' :
            rla_observation_var   = np.reshape(rla_observation_init,rla_lonobs.size)
            rla_best_estimate_var = np.reshape(rla_best_estimate_init,rla_lonobs.size)
            if clim == True:
                rla_climatology_var = np.reshape(rla_climatology_init,rla_lonobs.size)
        else :
            rla_qc_var = rla_qc_init[:,ivar,:]
            rla_observation_var = rla_observation_init[:,ivar,:]
            rla_forecast_var = rla_forecast_init[:,ivar,:,:]
            rla_persistence_var = rla_persistence_init[:,ivar,:,:]
            rla_best_estimate_var = rla_best_estimate_init[:,ivar,:]
            if clim == True:
                rla_climatology_var = rla_climatology_init[:,ivar,:]
      	
            nb_fcst = rla_forecast_var[0,:,0].size
            nb_pers = rla_persistence_var[0,:,0].size

        # Passe au jour suivant si on n'a pas pas de best analyse)
        # if np.isnan(rla_best_estimate_var).all() : continue
        if np.isnan(rla_best_estimate_var).all() : continue

        if doQC and config_obs != 'GLOBCOLOUR':
            # Test sur la coherence des valeurs et des observations par rapport a la climatologie
            rla_diffclim2obs = np.absolute(rla_climatology_var-rla_observation_var)
            if np.isnan(rla_best_estimate_var).all() :
                rla_diffbest2obs = np.absolute(rla_forecast_var[:,0,:]-rla_observation_var)
            else :
                rla_diffbest2obs = np.absolute(rla_best_estimate_var-rla_observation_var)
            if ~np.isnan(rla_climatology_var).any() :
                qcs = np.where(
                (rla_diffbest2obs > rg_EcartMax) &\
                (rla_diffclim2obs > rg_EcartMax)) 
            else :
                qcs = np.where(
                (rla_diffbest2obs > rg_EcartMax)) 
            if len(qcs[0]) > 0 : 
                rla_observation_var[qcs] = np.nan
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


#~~~~~~~~~~~~~~~~~~~~ Initialisation variables ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
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
        rla_cor_ano = np.nan*np.zeros((len(tab_prof) -1 ,\
                                       yout,\
                                       len(rla_maskvalues)\
                                       ))
        rla_box = np.nan*np.zeros(len(rla_maskvalues))


#~~~~~~~~~~~~~~~~~~~~~~~~~~ Classement donnees dans boites ~~~~~~~~~~~~~~~~~~

        boxind_save = []

        for imask,maskval in enumerate(rla_maskvalues) :


#~~~~~~~~~~~~~~~~~~~~~~ Definition boite 2D ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

            ibox = np.where((rla_lonobs >= boxlonmin) & (rla_lonobs <  boxlonmax) &\
                            (rla_latobs >= boxlatmin) & (rla_latobs <  boxlatmax))[0]	

            if np.size(ibox) == 0 : continue 

            iboxobs = np.where(geomlib.point_inside_polygon2(rla_lonobs[ibox],rla_latobs[ibox],Hull))[0]	

            if np.size(iboxobs) == 0 : continue

            iobs = ibox[iboxobs]
            iobs_alreadyused = []

 
#~~~~~~~~~~~~~~~~~~~~~~~ Calculs Stats avec 3e dimension ~~~~~~~~~~~~~~~~~~~~~

            if np.size(iobs) == 0 : continue

            if config_model != 'FREEBIORYS2':
                rla_fcstmean = np.nan*np.zeros((len(tab_prof)-1, nb_fcst)) ; rla_persmean = np.nan*np.zeros((len(tab_prof)-1, nb_pers))
                rla_fcstrms = np.nan*np.zeros((len(tab_prof)-1, nb_fcst)) ; rla_persrms = np.nan*np.zeros((len(tab_prof)-1, nb_pers))
                rla_fcstbias = np.nan*np.zeros((len(tab_prof)-1, nb_fcst)) ; rla_persbias = np.nan*np.zeros((len(tab_prof)-1, nb_pers))
                rla_fcstrmse = np.nan*np.zeros((len(tab_prof)-1, nb_fcst)) ; rla_persrmse = np.nan*np.zeros((len(tab_prof)-1, nb_pers))
                rla_fcstcorano = np.nan*np.zeros((len(tab_prof)-1, nb_fcst)) ; rla_perscorano = np.nan*np.zeros((len(tab_prof)-1, nb_pers))
                ila_fcstnobs = np.nan*np.zeros((len(tab_prof)-1, nb_fcst)) ; ila_persnobs = np.nan*np.zeros((len(tab_prof)-1, nb_pers))	

            for time in lead_time :
                if len(np.shape(rla_observation_var)) == 2:
                    rla_obs = rla_observation_var[iobs,:]
                    if clim == True :
                        rla_clim = rla_climatology_var[iobs,:]
                    else :
                        rla_clim = np.nan*np.zeros((np.size(rla_obs[0,:])))
                else :
                    rla_obs = rla_observation_var[iobs]
                    if clim == True :
                        rla_clim = rla_climatology_var[iobs]
                    else :
                        rla_clim = np.nan*np.zeros((np.size(rla_obs)))

                if time == 'forecast' :

                    for numF in range(0,nb_fcst) :
                        if nb_fcst == 1 and len(np.shape(rla_forecast_var)) == 2:
                            rla_var = rla_forecast_var[iobs,:]
                        elif nb_fcst == 1 and len(np.shape(rla_forecast_var)) == 1:
                            rla_var = rla_forecast_var[iobs]
                        elif nb_fcst > 1 and len(np.shape(rla_forecast_var)) == 2:
                            rla_var = rla_forecast_var[iobs,numF]			
                        else :
                            rla_var = rla_forecast_var[iobs,numF,:]

                        rla_fcstmean[:,numF],rla_fcstrms[:,numF],rla_fcstbias[:,numF],rla_fcstrmse[:,numF], rla_fcstcorano[:,numF], ila_fcstnobs[:,numF] =\
                        supobs.Statslib.statlayer_CL4var(
                                                         rla_var,\
                                                         rla_obs,\
                                                         rla_clim,\
                                                         rla_depthobs[iobs,:],\
                                                         tab_prof)

                if time == 'persistence' :
                    for numP in range(0,nb_pers) :
                        if nb_pers == 1 and len(np.shape(rla_persistence_var)) == 2:
                            rla_var = rla_persistence_var[iobs,:]
                        elif nb_pers == 1 and len(np.shape(rla_persistence_var)) == 1:
                            rla_var = rla_persistence_var[iobs]
                        elif nb_pers > 1 and len(np.shape(rla_persistence_var)) == 2:
                            rla_var = rla_persistence_var[iobs,numP]			
                        else :
                            rla_var = rla_persistence_var[iobs,numP,:]	

                        rla_persmean[:,numP],rla_persrms[:,numP],rla_persbias[:,numP],rla_persrmse[:,numP], rla_perscorano[:,numP], ila_persnobs[:,numP] =\
                        supobs.Statslib.statlayer_CL4var(
                                                         rla_var,\
                                                         rla_obs,\
                                                         rla_clim,\
                                                         rla_depthobs[iobs,:],\
                                                         tab_prof)

                if time == 'observation' :
                    if len(np.shape(rla_observation_var)) == 2:
                        rla_var = rla_observation_var[iobs,:]
                    else :
                        rla_var = rla_observation_var[iobs]
                    rla_obsmean,rla_obsrms,rla_obsbias,rla_obsrmse, rla_obscorano, ila_obsnobs =\
                    supobs.Statslib.statlayer_CL4var(
                                                     rla_var,\
                                                     rla_obs,\
                                                     rla_clim,\
                                                     rla_depthobs[iobs,:],\
                                                     tab_prof)

                if time == 'best_estimate' :
                    if len(np.shape(rla_best_estimate_var)) == 2:
                        rla_var = rla_best_estimate_var[iobs,:]
                    else :
                        rla_var = rla_best_estimate_var[iobs]

                    rla_bestmean,rla_bestrms,rla_bestbias,rla_bestrmse,rla_bestcorano, ila_bestnobs =\
                    supobs.Statslib.statlayer_CL4var(
                                                     rla_var,\
                                                     rla_obs,\
                                                     rla_clim,\
                                                     rla_depthobs[iobs,:],\
                                                     tab_prof)

                if time == 'climatology' :
                    if len(np.shape(rla_climatology_var)) == 2:
                        rla_var = rla_climatology_var[iobs,:]   
                    else : 
                        rla_var = rla_climatology_var[iobs]

                    rla_climmean,rla_climrms,rla_climbias,rla_climrmse,rla_climcorano, ila_climnobs =\
                    supobs.Statslib.statlayer_CL4var(
                                                     rla_var,\
                                                     rla_obs,\
                                                     rla_clim,\
                                                     rla_depthobs[iobs,:],\
                                                     tab_prof)		


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sauvegarde resultats ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            num_col = 0
            if 'observation' in lead_time :
                rla_mean[:,num_col,imask] = rla_obsmean ; ila_indice_box[:,num_col,imask] = ila_obsnobs ; rla_rms[:,num_col,imask] = rla_obsrms
                rla_rms_diff[:,num_col,imask] = rla_obsrmse ; rla_mean_diff[:,num_col,imask] = rla_obsbias ; rla_cor_ano[:,num_col,imask] = rla_obscorano
                num_col = num_col + 1
            if 'best_estimate' in lead_time :
                rla_mean[:,num_col,imask] = rla_bestmean ; ila_indice_box[:,num_col,imask] = ila_bestnobs ; rla_rms[:,num_col,imask] = rla_bestrms
                rla_rms_diff[:,num_col,imask] = rla_bestrmse ; rla_mean_diff[:,num_col,imask] = rla_bestbias; rla_cor_ano[:,num_col,imask] = rla_bestcorano
                num_col = num_col + 1       
            if 'forecast' in lead_time :
                if nb_fcst == 1:
                    rla_mean[:,num_col,imask] = rla_fcstmean[:,0] ; ila_indice_box[:,num_col,imask] = ila_fcstnobs[:,0] ; rla_rms[:,num_col,imask] = rla_fcstrms[:,0]
                    rla_rms_diff[:,num_col,imask] = rla_fcstrmse[:,0] ; rla_mean_diff[:,num_col,imask] = rla_fcstbias[:,0] ; rla_cor_ano[:,num_col,imask] = rla_fcstcorano[:,0]
                    num_col = num_col + 1
                else :
                    for numF in range(0,nb_fcst/2) :
                        rla_mean[:,num_col,imask] = rla_fcstmean[:,numF*2] ; ila_indice_box[:,num_col,imask] = ila_fcstnobs[:,numF*2] ; rla_rms[:,num_col,imask] = rla_fcstrms[:,numF*2]
                        rla_rms_diff[:,num_col,imask] = rla_fcstrmse[:,numF*2] ; rla_mean_diff[:,num_col,imask] = rla_fcstbias[:,numF*2] ; rla_cor_ano[:,num_col,imask] = rla_fcstcorano[:,numF*2]
                        num_col = num_col + 1
            if 'persistence' in lead_time :
                if nb_pers == 1:
                    rla_mean[:,num_col,imask] = rla_persmean[:,0]; ila_indice_box[:,num_col,imask] = ila_persnobs[:,0] ; rla_rms[:,num_col,imask] = rla_persrms[:,0]
                    rla_rms_diff[:,num_col,imask] = rla_persrmse[:,0] ; rla_mean_diff[:,num_col,imask] = rla_persbias[:,0] ; rla_cor_ano[:,num_col,imask] = rla_perscorano[:,0]
                    num_col = num_col + 1
                else:
                    for numP in range(0,nb_pers/2) :
                        rla_mean[:,num_col,imask] = rla_persmean[:,numP*2]; ila_indice_box[:,num_col,imask] = ila_persnobs[:,numP*2] ; rla_rms[:,num_col,imask] = rla_persrms[:,numP*2]
                        rla_rms_diff[:,num_col,imask] = rla_persrmse[:,numP*2] ; rla_mean_diff[:,num_col,imask] = rla_persbias[:,numP*2] ; rla_cor_ano[:,num_col,imask] = rla_perscorano[:,numP*2]
                        num_col = num_col + 1 
            if 'climatology' in lead_time :
                rla_mean[:,num_col,imask] = rla_climmean ; ila_indice_box[:,num_col,imask] = ila_climnobs ; rla_rms[:,num_col,imask] = rla_climrms
                rla_rms_diff[:,num_col,imask] = rla_climrmse ; rla_mean_diff[:,num_col,imask] = rla_climbias ; rla_cor_ano[:,num_col,imask] = rla_climcorano
 
            rla_box[imask] = maskval

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Ecriture NetCDF ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        if np.isnan(ila_indice_box).all() : continue
        cl_fileOut = os.path.join(dirNCout,cl_var_out+'_'+config_obs+'_'+config_model+'_rms_diff_'+cdate+'.nc')
        nc = netCDF4.Dataset(cl_fileOut, 'w', format='NETCDF3_64BIT',zlib=True, least_significant_digit=4)
        nc.set_fill_off()
        # Dimensions
        nc.createDimension('x', len(rla_maskvalues))
        nc.createDimension('y', yout)
        nc.createDimension('z', len(tab_prof) -1)
        nc.createDimension('string_length', 11)
        # Variables
        ncmean = nc.createVariable('mean', 'f', ('z','y','x'),fill_value=1.e35)
        ncmean.setncattr('long_name',"mean")
        ncmean[:]  = rla_mean
        nc_name = nc.createVariable('run_names','c',('y','string_length'))
        nc_name.description = 'type of considered run - obs hindcast forecast climatology'
        nc.variables['run_names'][:] = netCDF4.stringtochar(np.array(exp_name))
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
        nccor_ano = nc.createVariable('cor_ano', 'f', ('z','y','x'),fill_value=1.e35)
        nccor_ano.setncattr('long_name',"anomaly correlation")
        nccor_ano[:]  = rla_cor_ano
        ncbox = nc.createVariable('box', 'f', ('x',),fill_value=1.e35)
        ncbox.setncattr('long_name',"geographical boxes")
        ncbox[:]  = rla_box

        nc.close()

    print ('| %s | %s |  Done  |' %(cdate,cl_var))
    print (' ------------------------------ ')
    print ('              END               ')
    print (' ------------------------------ ')

comm.Barrier()
if comm.rank == 0 :
   print ('        END                     ')
   print (' ------------------------------ ')
