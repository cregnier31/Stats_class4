"""
---------------------------------------------------------------------------
 Module pour elaborer des statistiques a partir des fichiers CLASS4
 au format GODAE
 history : 01.03.2013   L.ZAWADZKI
---------------------------------------------------------------------------
"""
import numpy as np
import os, sys
from os.path import dirname
sys.path.append(dirname(__file__))
sys.path.append(dirname(__file__)+'/../modules/')
import datetime as dt
import netCDF4
import toolkitStats
import arithm
from copy import deepcopy
from os.path import exists
import utils

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def calculer_stats_MYO2(czoneFile,modele,tab_prof,\
                        tab_prof_model,tab_e3t,\
                        liste_zone,filelist,cd_CL4type,\
                        days, dir_stats_MERC,dirASCIIOut,cd_dateMinZone,cd_dateMaxZone   ) :

   """
========================================================================================

  Trace de l'evolution de la rms difference pour les fichiers class4

    author: C REGNIER  Septembre 2007
    author: C REGNIER  Mai       2009 :: Compute rms diff for differentes
                                         echeances et differents runs
    author: C REGNIER  Janvier   2010 :: corrections to adapt the number of prof
    author: C REGNIER  Aout      2010 :
    author: C.REGNIER  Juin      2011 :: ajout des zones baltic, NordSea et Facade
    author: C.REGNIER  Janvier   2013 :: calcul des stats MyOcean2
    author: L.ZAWADZKI Avril     2013 :: conversion python, adaptation fichiers GODAE

   Dans ce code un poids plus grand est donne aux boites qui ont le plus de donnees
   et qui ont donc une representativite plus grande

=========================================================================================
   """

   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #         Definition des variables
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   nc = netCDF4.Dataset(filelist[0],'r')
   run_names = nc.variables['run_names'][:]
   variable_name = utils.pull_names(run_names)[1:]
   nb_variables  = np.size(variable_name)
   nc.close()

   nb_prof       = np.size(tab_prof)
   nb_prof_model = np.size(tab_prof_model)-1
   range_values  = np.zeros((2,nb_prof))

   missing_value = netCDF4.default_fillvals['f4']
   dateCNESref   = dt.datetime.strptime('19500101','%Y%m%d').toordinal()

   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #            Lecture des boites
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   nc = netCDF4.Dataset(czoneFile,'r')
   mask = nc.variables['mask'][:]
   rla_maskvalues = np.unique(mask)
   rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))
   nc.close()
   boite = np.unique(mask)
   boite = np.delete(boite,np.where(boite==0))

   for zone in liste_zone :
      print ('ZONE ::  %s' %(zone))

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      #               Choix de la zone
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      FIND = toolkitStats.find_indice(boite,zone)
      taille = np.size(FIND)
      nfichiers = len(filelist)

      # Recherche des indice pour les boites
      tab_indice_ini = np.zeros(nb_prof,dtype=int)
      tab_indice_fin = np.zeros(nb_prof,dtype=int)
      profondeur     = np.chararray(nb_prof,itemsize=25)
      for ind,prof in enumerate(tab_prof[:-1]) :
         profondeur[ind] = '%i-%im'%(np.int(prof),np.int(tab_prof[ind+1]))
         FIND2 = np.where((tab_prof_model >= prof) & (tab_prof_model <= tab_prof[ind+1]))[0]
         if np.size(FIND2) > 1 :
            tab_indice_ini[ind] = FIND2[0]
            tab_indice_fin[ind] = FIND2[-1]
         elif np.size(FIND2) == 1 :
            tab_indice_ini[ind] = FIND2
            tab_indice_fin[ind] = FIND2

      ## Derniere case du tableau : toute la colonne d eau
      if len(tab_indice_ini) > 1 :
         tab_indice_ini[-1] = 0
         tab_indice_fin[-1] = tab_indice_fin[-2]
         profondeur[-1] = '%i-%im'%(np.int(tab_prof[0]),np.int(tab_prof[-1]))
      ##  Allocate tab
      ms_difftot  = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      mean_difftot = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      ms_tot      = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      mean_tot     = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      mean_clim     = np.nan*np.zeros((nb_prof_model,len(rla_maskvalues),nfichiers))
      cor_tot     = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      indice_tot   = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))

      for i in range(nfichiers) :
         file  = filelist[i]
         dirin = dir_stats_MERC
         if exists(file) == False :
             ms_difftot[:,:,:,i]  = missing_value
             mean_difftot[:,:,:,i] = missing_value
             ms_tot[:,:,:,i]      = missing_value
             mean_tot[:,:,:,i]     = missing_value
             indice_tot[:,:,:,i]   = missing_value
         else:
             nc    = netCDF4.Dataset(file,'r')
             rms_diff   = nc.variables['rms_diff'][:]
             ms_difftot[:,:,:,i] = np.square(rms_diff)
             mean_diff  = nc.variables['mean_diff'][:]
             mean_difftot[:,:,:,i] = mean_diff
             rms        = nc.variables['rms'][:]
             ms_tot[:,:,:,i]      = np.square(rms)
             mean       = nc.variables['mean'][:]
             mean_tot[:,:,:,i]     = mean
             indice_box = nc.variables['indice_box'][:]
             indice_tot[:,:,:,i]   = indice_box
             nc.close()

             del rms_diff, rms, mean, indice_box, mean_diff

      # Valeurs des jours en jours juliens
      ndays = len(days)
      if ndays != nfichiers:
         print (' Number of dates does not match number of files')
         sys.exit(1)
      jours = np.zeros(ndays)
      for il_ind,day in enumerate(days) :
         jours[il_ind] = dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref

      ## Calcul de la moyenne et de la MSE
      for iprof,cprof in enumerate(profondeur) :
         tab_ASCII = np.zeros((2+2+3*nb_variables,nfichiers))
         tab_SYNTHESE = np.zeros((2+3*nb_variables))
         for ifichier in range(len(filelist)):
            il_var = 0
            for il_ind2 in range(len(variable_name)+1) :
               val_ms_tmp   = 0.
               val_diffms_tmp   = 0.
               val_mean_tmp  = 0.
               val_mean_clim_tmp = 0.
               val_mean_obs_tmp = 0.
               val_mean_diff_tmp  = 0.
               val_nbval_tmp = 0.
               val_tot_e3t   = 0.
               val_tot2_e3t  = 0.
               val_tot3_e3t  = 0.

               for il_indice in FIND :
                  vect = np.where((mean_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] != 0) &\
                                  (indice_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0))[0]
                  vect = np.array(vect)
                  if vect.size > 0 :
                     val_mean_tmp  += np.sum(
                                      np.multiply(
                                      mean_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                                      tab_e3t[vect+tab_indice_ini[iprof]]))

                     val_ms_tmp  += np.sum(
                                    np.multiply(
                                    (ms_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier]),\
                                    tab_e3t[vect+tab_indice_ini[iprof]]))

                     val_nbval_tmp += np.sum(
                                      indice_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier])

                     val_tot_e3t   += np.sum(
                                      tab_e3t[vect+tab_indice_ini[iprof]])

                  vect2 = np.where((ms_difftot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0) &\
                                  (indice_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0))[0]
                  vect2 = np.array(vect2)
                  if vect2.size > 0:
                     val_diffms_tmp   += np.sum(np.multiply((ms_difftot[vect2+tab_indice_ini[iprof],il_ind2,il_indice,ifichier]),\
                                        tab_e3t[vect2+tab_indice_ini[iprof]]))
                     val_tot2_e3t  += np.sum(tab_e3t[vect2+tab_indice_ini[iprof]])

                  vect3 = np.where((mean_difftot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] != 0) &\
                                  (indice_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0))[0]
                  vect3 = np.array(vect3)
                  if vect3.size > 0:
                     val_mean_diff_tmp   += np.sum(np.multiply(mean_difftot[vect3+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                                             tab_e3t[vect3+tab_indice_ini[iprof]]))
                     val_tot3_e3t  += np.sum(tab_e3t[vect3+tab_indice_ini[iprof]])

               if val_tot2_e3t == 0: val_diffms_new  = 0.
               else : val_diffms_new  = val_diffms_tmp  / val_tot2_e3t

               if val_tot_e3t == 0: val_mean_new  = 0.
               else : val_mean_new = val_mean_tmp / val_tot_e3t

               if val_tot_e3t == 0 : val_ms_new  = 0.
               else : val_ms_new = val_ms_tmp / val_tot_e3t

               if val_tot3_e3t == 0: val_meandiff_new  = 0.
               else : val_meandiff_new = val_mean_diff_tmp / val_tot3_e3t

               if il_ind2 == 0 :
                  tab_ASCII[0,ifichier] = jours[ifichier]
                  if val_mean_new != missing_value :
                      tab_ASCII[1,ifichier] = val_nbval_tmp
                      tab_ASCII[2,ifichier] = val_mean_new
                      tab_ASCII[3,ifichier] = val_ms_new
                  else :
                      tab_ASCII[1:4,ifichier] = missing_value
                  il_var = 4
               else :
                  tab_ASCII[il_var,ifichier] = val_mean_new
                  il_var += 1
                  tab_ASCII[il_var,ifichier] = val_ms_new
                  il_var += 1
                  tab_ASCII[il_var,ifichier] = np.sqrt(val_diffms_new)
                  il_var += 1

         tab_ASCII_tmp = np.where(tab_ASCII == 0., np.nan, tab_ASCII)
         tab_ASCII_tmp = np.where(tab_ASCII == missing_value, np.nan, tab_ASCII)
         il_var = 0
         for il_ind2 in range(len(variable_name)+1):
             if il_ind2 == 0:
                 tab_SYNTHESE[0] = (np.nansum(tab_ASCII_tmp[2,:]*tab_ASCII_tmp[1,:]))/(np.nansum(tab_ASCII_tmp[1,:]))
                 tab_SYNTHESE[1] = (np.nansum(tab_ASCII_tmp[3,:]*tab_ASCII_tmp[1,:]))/(np.nansum(tab_ASCII_tmp[1,:]))
                 il_var = 2
             else:
                 tab_SYNTHESE[il_var] = (np.nansum(tab_ASCII_tmp[il_var+2,:]*tab_ASCII_tmp[1,:]))/(np.nansum(tab_ASCII_tmp[1,:]))
                 il_var += 1
                 tab_SYNTHESE[il_var] = (np.nansum(tab_ASCII_tmp[il_var+2,:]*tab_ASCII_tmp[1,:]))/(np.nansum(tab_ASCII_tmp[1,:]))
                 il_var += 1
                 tab_SYNTHESE[il_var] = np.sqrt((np.nansum((tab_ASCII_tmp[il_var+2,:]**2)*tab_ASCII_tmp[1,:]))/(np.nansum(tab_ASCII_tmp[1,:])))
                 il_var += 1

         tab_ASCII = tab_ASCII.transpose()
         tab_ASCII = np.where(tab_ASCII == 0, missing_value, tab_ASCII)
         tab_SYNTHESE=np.where(tab_SYNTHESE == 0,missing_value,tab_SYNTHESE)

         file1 = os.path.join(dirASCIIOut,\
                              'MYO2_product_quality_'+modele+'_'+\
                              zone+'_'+cd_dateMinZone+'_'+cd_dateMaxZone+'_'+cd_CL4type+'_'+cprof+'.txt')
         fmt_type = '%10.2f  %10.1f  %10.7f  %10.7f '
         for v in range(nb_variables):
             fmt_type = fmt_type + '%10.7f  %10.7f  %10.7f '

         np.savetxt(file1,tab_ASCII,fmt=fmt_type)

         file2 = os.path.join(dirASCIIOut,\
                              'Global_stats_'+modele+'_'+zone+'_'+\
                              cd_dateMinZone+'_'+cd_dateMaxZone+'_'+cd_CL4type+'_'+cprof+'.txt')

         np.savetxt(file2,np.column_stack(tab_SYNTHESE),fmt='%10.7f')


#-----------------------------------------------------------------------------------------------------------------------------------

def statlayer_CL4var(rda_val, rda_observations, rda_climatology, rda_depthobs, rda_depth_layers ):
    """
Returns mean, RMS, Bias (/observations), RMSE (/observations), number of observations of input array rda_val in depth layers
    """
    n_layers = len(rda_depth_layers)-1
    if len(np.shape(rda_val)) > 0 : n_obs = np.shape(rda_val)[0]
    else:
        print ('problem with shape of rda_val')
        sys.exit(1)
    ll_debug = True
    rla_mean_O = np.nan*np.zeros(n_layers)
    rla_mean_P = np.nan*np.zeros(n_layers)
    rla_bias = np.nan*np.zeros(n_layers)
    rla_rms_O  = np.nan*np.zeros(n_layers)
    rla_rms_P  = np.nan*np.zeros(n_layers)
    rla_rmse = np.nan*np.zeros(n_layers)
    rla_cor  = np.nan*np.zeros(n_layers)
    rla_skill  = np.nan*np.zeros(n_layers)
    ila_nobs = np.zeros(n_layers)
    ilayer   = 0
    if n_layers == 1:
        if len(np.shape(rda_val)) == 1:  ## BIO case
            ila_nobs[0] = np.size(np.where(~ np.isnan(rda_val[:]))[0]) 
        else:
            ila_nobs[0] = np.size(np.where(~ np.isnan(rda_val[:,0]))[0])
        if ila_nobs[0] > 0 :
            rla_mean_O[0] = arithm.nanmean(rda_observations)
            rla_mean_P[0] = arithm.nanmean(rda_val)
            rla_bias[0] = arithm.nanmean(rda_val-rda_observations)
            rla_rms_O[0]  = np.sqrt(arithm.nanms(rda_observations))
            rla_rms_P[0]  = np.sqrt(arithm.nanms(rda_val))
            rla_rmse[0] = np.sqrt(arithm.nanmse(rda_val,rda_observations))
            rla_cor[0]  = arithm.nanpearson(rda_val-rda_climatology,rda_observations-rda_climatology)
        else :
            rla_mean_O[0] = np.nan
            rla_mean_P[0] = np.nan
            rla_bias[0] = np.nan
            rla_rms_O[0]  = np.nan
            rla_rms_P[0]  = np.nan
            rla_rmse[0] = np.nan
            rla_cor[0]  = np.nan
    else:
        for depthmin,depthmax in zip(rda_depth_layers[:-1],rda_depth_layers[1:]):
            nobs = 0
            for iobs in range(n_obs):
                ila_inds = np.where((rda_depthobs[iobs,:] >= depthmin) & (rda_depthobs[iobs,:] < depthmax))
                nobs = nobs + len(ila_inds[0])

            val_box_depth = np.nan*np.zeros((nobs))
            obs_box_depth = np.nan*np.zeros((nobs))
            clim_box_depth = np.nan*np.zeros((nobs))

            nobs = 0
            for iobs in range(n_obs) :
                ila_inds = np.where((rda_depthobs[iobs,:] >= depthmin) & (rda_depthobs[iobs,:] < depthmax))
                if len(ila_inds[0]) > 0 and len(np.shape(rda_val)) == 2:
                    for ind in ila_inds[0]:
                        val_box_depth[nobs] = rda_val[iobs,ind]
                        obs_box_depth[nobs] = rda_observations[iobs,ind]
                        clim_box_depth[nobs] = rda_climatology[iobs,ind]
                        if np.isnan(val_box_depth[nobs]) or np.isnan(obs_box_depth[nobs]):
                            val_box_depth[nobs] = np.nan
                            obs_box_depth[nobs] = np.nan
                            clim_box_depth[nobs] = np.nan
                        nobs += 1
                elif len(ila_inds[0]) > 0 and len(np.shape(rda_val)) != 2:
                    val_box_depth[nobs] = rda_val[iobs]
                    obs_box_depth[nobs] = rda_observations[iobs]
                    clim_box_depth[nobs] = rda_climatology[iobs]
                    if np.isnan(val_box_depth[nobs]) or np.isnan(obs_box_depth[nobs]):
                        val_box_depth[nobs] = np.nan
                        obs_box_depth[nobs] = np.nan
                        clim_box_depth[nobs] = np.nan
                    nobs += 1

            ila_nobs[ilayer] = np.size(np.where(~ np.isnan(val_box_depth[:]))[0])

            if ila_nobs[ilayer] > 0 :
                rla_mean_O[ilayer] = arithm.nanmean(obs_box_depth)
                rla_mean_P[ilayer] = arithm.nanmean(val_box_depth)
                rla_bias[ilayer] = arithm.nanmean(val_box_depth-obs_box_depth)
                rla_rms_O[ilayer]  = np.sqrt(arithm.nanms(obs_box_depth))
                rla_rms_P[ilayer]  = np.sqrt(arithm.nanms(val_box_depth))
                rla_rmse[ilayer] = np.sqrt(arithm.nanmse(val_box_depth,obs_box_depth))
                rla_cor[ilayer]  = arithm.nanpearson(val_box_depth-clim_box_depth,obs_box_depth-clim_box_depth)
            else :
                rla_mean_O[ilayer] = np.nan
                rla_mean_P[ilayer] = np.nan
                rla_bias[ilayer] = np.nan
                rla_rms_O[ilayer]  = np.nan
                rla_rms_P[ilayer]  = np.nan
                rla_rmse[ilayer] = np.nan
                rla_cor[ilayer]  = np.nan
            ilayer += 1


    return rla_mean_O, rla_rms_O, rla_mean_P, rla_rms_P, rla_rmse, rla_cor, ila_nobs

#-----------------------------------------------------------------------------------------------------------------------------------

def extract_CL4var(rda_val, rda_observations, rda_climatology, rda_depthobs, depthmin, depthmax) :
   """
   Permet de selectionner les valeurs d'une variable par tranche de profondeur pour une date donnee
   """

   if len(np.shape(rda_val)) > 0 : n_obs = np.shape(rda_val)[0]
   else:
       print ('problem with shape of rda_val')
       sys.exit(1)

   nobs = 0
   for iobs in range(n_obs):
       ila_inds = np.where((rda_depthobs[iobs,:] >= depthmin) & (rda_depthobs[iobs,:] < depthmax))
       nobs = nobs + len(ila_inds[0])

   val_box_depth = np.nan*np.zeros((nobs))
   obs_box_depth = np.nan*np.zeros((nobs))
   clim_box_depth = np.nan*np.zeros((nobs))
   nobs = 0
   for iobs in range(n_obs) :
       ila_inds = np.where((rda_depthobs[iobs,:] >= depthmin) & (rda_depthobs[iobs,:] < depthmax))
       if len(ila_inds[0]) > 0 and len(np.shape(rda_val)) == 2:
           for ind in ila_inds[0]:
               val_box_depth[nobs] = rda_val[iobs,ind]
               obs_box_depth[nobs] = rda_observations[iobs,ind]
               clim_box_depth[nobs] = rda_climatology[iobs,ind]
               if np.isnan(val_box_depth[nobs]) or np.isnan(obs_box_depth[nobs]):
                   val_box_depth[nobs] = np.nan
                   obs_box_depth[nobs] = np.nan
                   clim_box_depth[nobs] = np.nan
               nobs += 1
       elif len(ila_inds[0]) > 0 and len(np.shape(rda_val)) != 2:
           val_box_depth[nobs] = rda_val[iobs]
           obs_box_depth[nobs] = rda_observations[iobs]
           clim_box_depth[nobs] = rda_climatology[iobs]
           if np.isnan(val_box_depth[nobs]) or np.isnan(obs_box_depth[nobs]):
               val_box_depth[nobs] = np.nan
               obs_box_depth[nobs] = np.nan
               clim_box_depth[nobs] = np.nan
           nobs += 1

   return val_box_depth, obs_box_depth, clim_box_depth

