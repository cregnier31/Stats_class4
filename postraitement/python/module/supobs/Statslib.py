"""
---------------------------------------------------------------------------
 Module pour elaborer des statistiques a partir des fichiers CLASS4
 au format GODAE
 history : 01.03.2013   L.ZAWADZKI
---------------------------------------------------------------------------
"""
import numpy as np
import os, sys
import datetime as dt
import netCDF4
import toolkitStats
sys.path.append('../module')
import arithm
from copy import deepcopy

def calculer_stats_MYO2(czoneFile,modele,tab_prof,\
			tab_prof_model,tab_e3t,variable_name,\
			liste_zone,filelist,cd_CL4type,\
			days, dir_stats_MERC,dirASCIIOut,cd_dateMinZone,cd_dateMaxZone   ) :

   """
========================================================================================

  Trace de l'evolution de la rms difference pour les fichiers class4

    author: C REGNIER  Septembre 2007
    author: C REGNIER  Mai       2009 :: Compute rms diff for differentes
    		         			echeances et differents runs
    author: C REGNIER  Janvier   2010 :: corrections to adapt the number of prof
    author: C REGNIER  Aout      2010 :: 
    author: C.REGNIER  Juin      2011 :: ajout des zones baltic, NordSea et Facade
    author: C.REGNIER  Janvier   2013 :: calcul des stats MyOcean2
    author: L.ZAWADZKI Avril     2013 :: conversion python, adaptation fichiers GODAE
    author: C.SZCZYPTA Fevrier   2018 :: Ajout de la variance dans les fichiers 
    author: C.REGNIER  Mars      2018 :: Ajout missing value =/ nan pour les fichiers ascii

   Dans ce code un poids plus grand est donne aux boites qui ont le plus de donnees
   et qui ont donc une representativite plus grande

=========================================================================================
   """

   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #         Definition des variables
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   nb_prof       = np.size(tab_prof)
   nb_prof_model = np.size(tab_prof_model)-1
   range_values  = np.zeros((2,nb_prof))
   nb_variables  = np.size(variable_name)
   missing_value= 9999.
   print nb_variables
   print variable_name
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
      print 'ZONE ::  %s' %(zone)

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      #               Choix de la zone
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      FIND = toolkitStats.find_indice(boite,zone)
      taille = np.size(FIND)
      nfichiers = len(filelist)
      print 'nb_prof :: %i' %nb_prof
      print 'nfichiers :: %i' %nfichiers
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
      indice_tot   = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))

      for i in range(nfichiers) :
         file  = filelist[i]
         dirin = dir_stats_MERC
         nc    = netCDF4.Dataset(file,'r')
         rms_diff   = nc.variables['rms_diff'][:]			
	 rms_diff[(rms_diff>= 9999.)] = missing_value
         ms_difftot[:,:,:,i]  = np.square(rms_diff)
         mean_diff  = nc.variables['mean_diff'][:]			
	 mean_diff[(mean_diff>= 9999.)] = missing_value
         mean_difftot[:,:,:,i] = mean_diff
         rms        = nc.variables['rms'][:]
         rms[(rms>= 9999.)] = missing_value
         ms_tot[:,:,:,i]      = np.square(rms)
         mean       = nc.variables['mean'][:]			
	 mean[(mean>= 9999.)] = missing_value
         mean_tot[:,:,:,i]     = mean
         indice_box = nc.variables['indice_box'][:]			
         indice_tot[:,:,:,i]   = indice_box
         nc.close()

         del rms_diff,mean,indice_box,mean_diff

      # Normalisation par le nombre d'obs par boite
      # ii = np.where(indice_tot > 0)
      # if np.size(ii) >0 :
      #   ms_difftot[ii]  = np.divide(ms_difftot[ii],indice_tot[ii])
      #   mean_difftot[ii] = np.divide(mean_difftot[ii],indice_tot[ii])
      #   ms_tot[ii]      = np.divide(ms_tot[ii],indice_tot[ii])
      #   mean_tot[ii]     = np.divide(mean_tot[ii],indice_tot[ii])
      
      # Valeurs des jours en jours juliens
      ndays = len(days)
      if ndays != nfichiers	: 
         print ' Number of dates does not match number of files'
         sys.exit(1)			
      jours = np.zeros(ndays)
      for il_ind,day in enumerate(days) :
         jours[il_ind] = dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref
      
      ## Calcul de la moyenne et de la MSE
      for iprof,cprof in enumerate(profondeur) :
         tab_ASCII = np.zeros((2+2+3*nb_variables,nfichiers))
         tab_ASCII2= np.zeros((2+1+2*nb_variables,nfichiers))
         for ifichier in range(len(filelist)) :		
            il_var = 0
            il_var2 = 0
            for il_ind2 in range(len(variable_name)+1) :
               val_ms_tmp   = 0.
               val_diffms_tmp   = 0.
               val_mean_tmp  = 0.
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
                     ## Mean
                     val_mean_tmp  += np.sum(
                     		   np.multiply(
                     		     mean_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                     		     tab_e3t[vect+tab_indice_ini[iprof]]				
                     		              )
                     		       )
                     val_ms_tmp  += np.sum(
                     		   np.multiply(
                     		     ms_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                     		     tab_e3t[vect+tab_indice_ini[iprof]]				
                     		              )
                     		       )
                     val_nbval_tmp += np.sum(
                     		   indice_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier]
                     		       )
                     val_tot_e3t   += np.sum(
                     		   tab_e3t[vect+tab_indice_ini[iprof]]
                     		       )
                  vect2 = np.where((ms_difftot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0) &\
                                  (indice_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0))[0]
                  vect2 = np.array(vect2)
                  if vect2.size > 0:
                     val_diffms_tmp   += np.sum(np.multiply(ms_difftot[vect2+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                     		     tab_e3t[vect2+tab_indice_ini[iprof]]))
		     val_mean_diff_tmp   += np.sum(np.multiply(mean_difftot[vect2+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                                             tab_e3t[vect2+tab_indice_ini[iprof]]))
                     val_tot2_e3t  += np.sum(tab_e3t[vect2+tab_indice_ini[iprof]])

               if val_tot2_e3t == 0 : val_diffms_new  = 0.
               else :	val_diffms_new  = val_diffms_tmp  / val_tot2_e3t

               if val_tot_e3t == 0 : val_mean_new  = 0.
               else : val_mean_new = val_mean_tmp / val_tot_e3t

               if val_tot_e3t == 0 : val_ms_new  = 0.
               else : val_ms_new = val_ms_tmp / val_tot_e3t

	       if val_tot2_e3t == 0 : val_meandiff_new  = 0.
	       else : val_meandiff_new = val_mean_diff_tmp / val_tot2_e3t

               if il_ind2 == 0 :
                  tab_ASCII[0,ifichier] = jours[ifichier]
                  tab_ASCII[1,ifichier] = val_nbval_tmp
                  tab_ASCII[2,ifichier] = val_mean_new
                  tab_ASCII[3,ifichier] = val_ms_new
		  tab_ASCII2[0,ifichier] = jours[ifichier]
                  tab_ASCII2[1,ifichier] = val_nbval_tmp
                  tab_ASCII2[2,ifichier] = val_meandiff_new
                  il_var = 4
                  il_var2 = 3
               else :
                  tab_ASCII[il_var,ifichier] = val_mean_new
                  tab_ASCII2[il_var2,ifichier] = val_meandiff_new
                  il_var += 1
                  il_var2 += 1
                  tab_ASCII[il_var,ifichier] = val_ms_new
                  il_var += 1
                  tab_ASCII[il_var,ifichier] = val_diffms_new
                  tab_ASCII2[il_var2,ifichier] = np.sqrt(val_diffms_new)
                  il_var += 1
               	
         tab_ASCII = tab_ASCII.transpose()
         tab_ASCII2 = tab_ASCII2.transpose()
         tab_ASCII=np.where(tab_ASCII == 0,missing_value,tab_ASCII)
         tab_ASCII=np.where(tab_ASCII >= 999999.0,missing_value,tab_ASCII)
         tab_ASCII2=np.where(tab_ASCII2 == 0,missing_value,tab_ASCII2)
         tab_ASCII2=np.where(tab_ASCII2 >= 999999.0,missing_value,tab_ASCII2)
         ## write ASCII file						
         file = os.path.join(
			dirASCIIOut,\
			'MYO2_product_quality_'+modele+'_'+zone+'_'+cd_dateMinZone+'_'+cd_dateMaxZone+'_'+cd_CL4type+'_'+cprof+'.txt'
			    )
         if nb_variables == 8 : 
            np.savetxt(file,tab_ASCII,fmt='%10.2f  %10.1f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f ')
         elif nb_variables == 12 : 
            np.savetxt(file,tab_ASCII,fmt='%10.2f  %10.1f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  \
%10.7f  %10.7f  %10.7f ')
         elif nb_variables == 2 :
            np.savetxt(file,tab_ASCII,fmt='%10.2f  %10.1f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f  %10.7f')
         file2=os.path.join(
                        dirASCIIOut,\
                        'BasicStats_product_quality_'+modele+'_'+zone+'_'+cd_dateMinZone+'_'+cd_dateMaxZone+'_'+cd_CL4type+'_'+cprof+'.txt')
         if nb_variables == 8 : 
            np.savetxt(file2,tab_ASCII2,fmt='%10.2f  %10.1f  %10.7f  \
%10.7f %10.7f \
%10.7f %10.7f %10.7f  %10.7f  \
%10.7f  %10.7f %10.7f  %10.7f \
%10.7f  %10.7f %10.7f  %10.7f \
%10.7f %10.7f ') 
         elif nb_variables == 12 :
            np.savetxt(file2,tab_ASCII2,fmt='%10.2f  %10.1f  %10.7f  \
%10.7f %10.7f \
%10.7f %10.7f %10.7f  %10.7f  \
%10.7f %10.7f %10.7f  %10.7f  \
%10.7f  %10.7f %10.7f  %10.7f \
%10.7f  %10.7f %10.7f  %10.7f \
%10.7f  %10.7f %10.7f  %10.7f \
%10.7f %10.7f ') 
         elif nb_variables == 2 :
            np.savetxt(file2,tab_ASCII2,fmt='%10.2f  %10.1f  %10.7f  \
%10.7f  %10.7f  \
%10.7f  %10.7f')

   """
==========================================================================
==========================================================================
         
   """

def calculer_stats_all(czoneFile,modele,tab_prof,\
			tab_prof_model,tab_e3t,variable_name,\
			liste_zone,filelist,cd_CL4type,\
			days, dir_stats_MERC,dirASCIIOut,cd_dateMinZone,cd_dateMaxZone   ) :
   """
==========================================================================
  Trace de l'evolution de la rms difference pour les fichiers class4

    author: C REGNIER  Septembre 2007
    author: C REGNIER  Mai       2009 :: Compute rms diff for differentes
    		         			echeances et differents runs
    author: C REGNIER  Janvier   2010 :: corrections to adapt the number of prof
    author: C REGNIER  Aout      2010 :: 
    author: C.REGNIER  Juin      2011 :: ajout des zones baltic, NordSea et Facade
    author: C.REGNIER  Janvier   2013 :: calcul des stats MyOcean2
    author: L.ZAWADZKI Avril     2013 :: conversion python, adaptation fichiers GODAE
    author: C.REGNIER  Octobre   2013 :: stats globales 
   Dans ce code un poids plus grand est donne aux boites qui ont le plus de donnees
   et qui ont donc une representativite plus grande

==========================================================================
   """
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #       Definition des variables
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   nb_prof       = np.size(tab_prof)
   nb_prof_model = np.size(tab_prof_model)-1
   range_values  = np.zeros((2,nb_prof))
   nb_variables  = np.size(variable_name)
   missing_value= 999999.
   print nb_variables
   print variable_name
   dateCNESref   = dt.datetime.strptime('19500101','%Y%m%d').toordinal()

   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ## Lecture des boites
   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   #nc = netCDF4.Dataset(czoneFile,'r')
   #boite = nc.variables['box'][:]
   #nc.close()
   nc = netCDF4.Dataset(czoneFile,'r')
   mask = nc.variables['mask'][:]
   rla_maskvalues = np.unique(mask)
   rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))
   nc.close()
   boite = np.unique(mask)
   boite = np.delete(boite,np.where(boite==0)) 
   for zone in liste_zone :
      print 'ZONE ::  %s' %(zone)
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      #              Choix de la zone
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      FIND = toolkitStats.find_indice(boite,zone)
      taille = np.size(FIND)
      nfichiers = len(filelist)
      print 'nb_prof :: %i' %nb_prof
      print 'nfichiers :: %i' %nfichiers
     
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
      	   
      # Derniere case du tableau : toute la colonne d eau
      if len(tab_indice_ini) > 1 :
         tab_indice_ini[-1] = 0
         tab_indice_fin[-1] = tab_indice_fin[-2]
         profondeur[-1] = '%i-%im'%(np.int(tab_prof[0]),np.int(tab_prof[-1]))
      
      #  Allocate tab
      print nb_prof_model, nb_variables+1,len(rla_maskvalues),nfichiers
      ms_difftot  = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      #mean_difftot = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      #ms_tot      = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      mean_tot     = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      indice_tot   = np.nan*np.zeros((nb_prof_model,nb_variables+1,len(rla_maskvalues),nfichiers))
      
      for i in range(nfichiers) :
         file  = filelist[i]
         dirin = dir_stats_MERC
         nc    = netCDF4.Dataset(file,'r')
         rms_diff   = nc.variables['rms_diff'][:]			
	 rms_diff[(rms_diff>= 9999.)] = missing_value
         ms_difftot[:,:,:,i]  = np.square(rms_diff)
         #mean_diff  = nc.variables['mean_diff'][:]			
	 #mean_diff[(mean_diff>= 9999.)] = missing_value
         #mean_difftot[:,:,:,i] = mean_diff
         #rms        = nc.variables['rms'][:]			
	 #rms[(rms>= 9999.)] = missing_value
         #ms_tot[:,:,:,i]      = np.square(rms)
         mean       = nc.variables['mean_diff'][:]			
	 mean[(mean>= 9999.)] = missing_value
         mean_tot[:,:,:,i]     = mean
         indice_box = nc.variables['indice_box'][:]			
	 #indice_box[(indice_box== 99999.)] = 0
         indice_tot[:,:,:,i]   = indice_box
         nc.close()
         #del rms_diff,mean_diff,rms,mean,indice_box
         del rms_diff,mean,indice_box
    
      # Normalisation par le nombre d'obs par boite
      # ii = np.where(indice_tot > 0)
      # if np.size(ii) >0 :
      #   ms_difftot[ii]  = np.divide(ms_difftot[ii],indice_tot[ii])
      #   mean_difftot[ii] = np.divide(mean_difftot[ii],indice_tot[ii])
      #   ms_tot[ii]      = np.divide(ms_tot[ii],indice_tot[ii])
      #   mean_tot[ii]     = np.divide(mean_tot[ii],indice_tot[ii])
      
      # Valeurs des jours en jours juliens
      ndays = len(days)
      if ndays != nfichiers	: 
         print ' Number of dates does not match number of files'
         sys.exit(1)			
      jours = np.zeros(ndays)
      for il_ind,day in enumerate(days) :
         jours[il_ind] = dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref
         #print 'Jour :: %f' %jours[il_ind]
      
      ## Calcul de la moyenne et de la MSE
      for iprof,cprof in enumerate(profondeur) :
         tab_ASCII = np.zeros((2*nb_variables-1)-1)
         val_sum_ms_tmp=np.zeros(nb_variables)
	 val_sum_mean_tmp=np.zeros(nb_variables)
         val_sum_tot_e3t=np.zeros(nb_variables)
         val_sum_tot2_e3t=np.zeros(nb_variables) 
         for ifichier in range(len(filelist)) :		
            il_var = 0
            for il_ind2 in range(len(variable_name)+1) :
               val_ms_tmp   = 0.
               val_mean_tmp  = 0.
               val_nbval_tmp = 0.
               val_tot_e3t   = 0.
               val_tot2_e3t  = 0.
               
               for il_indice in FIND :
                  vect = np.where((mean_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] != 0) &\
                                  (indice_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0))[0]
                  vect = np.array(vect)
                  if vect.size > 0 :
                     ## Mean
                     val_mean_tmp  += np.sum(
                     		   np.multiply(
                     		     mean_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                     		     tab_e3t[vect+tab_indice_ini[iprof]]				
                     		              )
                     		       )
                     val_nbval_tmp += np.sum(
                     		   indice_tot[vect+tab_indice_ini[iprof],il_ind2,il_indice,ifichier]
                     		       )
                     val_tot_e3t   += np.sum(
                     		   tab_e3t[vect+tab_indice_ini[iprof]]
                     		       )
                  vect2 = np.where((ms_difftot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0) &\
                                  (indice_tot[tab_indice_ini[iprof]:tab_indice_fin[iprof]+1,il_ind2,il_indice,ifichier] > 0))[0]
                  vect2 = np.array(vect2)
                  if vect2.size > 0:
                     val_ms_tmp   += np.sum(
                     		   np.multiply(
                     		     ms_difftot[vect2+tab_indice_ini[iprof],il_ind2,il_indice,ifichier],\
                     		     tab_e3t[vect2+tab_indice_ini[iprof]]				
                     		              )
                     		       )

                     val_tot2_e3t  += np.sum(
                     		   tab_e3t[vect2+tab_indice_ini[iprof]]
                     		       )
	       if il_ind2 != 0 :
                 if val_tot2_e3t != 0 :
                     val_sum_ms_tmp[il_var]=val_sum_ms_tmp[il_var]+val_ms_tmp
                     val_sum_tot2_e3t[il_var]=val_sum_tot2_e3t[il_var]+val_tot2_e3t
                 if val_tot_e3t != 0 :
	           val_sum_mean_tmp[il_var]=val_sum_mean_tmp[il_var]+val_mean_tmp
                   val_sum_tot_e3t[il_var]=val_sum_tot_e3t[il_var]+val_tot_e3t
	         il_var += 1 	
         il_indice=0
	 il_cpt=0
         if nb_variables == 8 :
             val_ind=14
         elif nb_variables == 12 :
             val_ind=22
         elif nb_variables == 2 :
            val_ind= 2
	 for il_indice in range(0,val_ind,2):
	    print 'valeurs :',il_indice,il_cpt, np.sqrt(val_sum_ms_tmp[il_cpt]/val_sum_tot2_e3t[il_cpt])
            tab_ASCII[il_indice] = np.sqrt(val_sum_ms_tmp[il_cpt]/val_sum_tot2_e3t[il_cpt])
            tab_ASCII[il_indice+1] = val_sum_mean_tmp[il_cpt]/val_sum_tot_e3t[il_cpt]
	    print tab_ASCII[il_indice],tab_ASCII[il_indice+1]
	    il_cpt += 1
         tab_ASCII = tab_ASCII.transpose()
         print tab_ASCII
	 print len(tab_ASCII)
         tab_ASCII=np.where(tab_ASCII== 0,missing_value,tab_ASCII)
         
         # write ASCII file						
         file = os.path.join(
			dirASCIIOut,\
			'Global_stats'+modele+'_'+zone+'_'+cd_dateMinZone+'_'+cd_dateMaxZone+'_'+cd_CL4type+'_'+cprof+'.txt'
			    )
	 np.savetxt(file,np.column_stack(tab_ASCII),fmt='%10.7f')
         print 'save file %s ' %(file)
	 print 'file ok prof %s' %(cprof)

        
#------------------------------------------------------------------------------------------------------------------------------------------
def statlayer_CL4var(rda_val,\
			rda_observations,\
			rda_depthobs,\
			rda_depth_layers) :
   """
Returns mean, RMS, Bias (/observations), RMSE (/observations), number of observations of input array rda_val in depth layers
   """
   n_layers = len(rda_depth_layers)-1
   if len(np.shape(rda_val)) == 2 : n_obs = np.shape(rda_val)[0]
   elif len(np.shape(rda_val)) == 1 : n_obs = 1
   else: 
      print 'problem with shape of rda_val'
      sys.exit(1)

   rla_mean = np.nan*np.zeros(n_layers)
   rla_bias = np.nan*np.zeros(n_layers)
   rla_rms  = np.nan*np.zeros(n_layers)
   rla_rmse = np.nan*np.zeros(n_layers)
   ila_nobs = np.zeros(n_layers)
   ilayer   = 0
   for depthmin,depthmax in zip(rda_depth_layers[:-1],rda_depth_layers[1:]) :
      rla_mean_lay = np.nan*np.zeros(n_obs)
      rla_bias_lay = np.nan*np.zeros(n_obs)
      rla_ms_lay   = np.nan*np.zeros(n_obs)
      rla_mse_lay  = np.nan*np.zeros(n_obs)
      ila_nobs_lay = np.zeros(n_obs)
      for iobs in range(n_obs) :
         if n_obs > 1 :
            if ((rda_depthobs[iobs,:] >= depthmin) & \
              	    (rda_depthobs[iobs,:] < depthmax) \
              	   ).any() :
               ila_inds = np.where(\
                       (rda_depthobs[iobs,:] >= depthmin) & \
                       (rda_depthobs[iobs,:] < depthmax) \
                       )
               rla_mean_lay[iobs] = arithm.nanmean(rda_val[iobs,ila_inds])
               rla_bias_lay[iobs] = arithm.nanmean(rda_val[iobs,ila_inds]-\
               			    rda_observations[iobs,ila_inds])
               rla_ms_lay[iobs]   = arithm.nanms(rda_val[iobs,ila_inds])
               rla_mse_lay[iobs]  = arithm.nanmse(rda_val[iobs,ila_inds],\
               			    rda_observations[iobs,ila_inds])
               ila_nobs_lay[iobs] = np.size(np.where(~ np.isnan(rda_val[iobs,ila_inds]))[0])
         elif n_obs == 1 :
            if ((rda_depthobs >= depthmin) & \
              	    (rda_depthobs < depthmax) \
              	   ).any() :
               ila_inds = np.where(\
                       (rda_depthobs >= depthmin) & \
                       (rda_depthobs < depthmax) \
                       )[0]
               rla_mean_lay[iobs] = arithm.nanmean(rda_val[ila_inds])
               rla_bias_lay[iobs] = arithm.nanmean(rda_val[ila_inds]-\
               			    rda_observations[ila_inds])
               rla_ms_lay[iobs]   = arithm.nanms(rda_val[ila_inds])
               rla_mse_lay[iobs]  = arithm.nanmse(rda_val[ila_inds],\
               			    rda_observations[ila_inds])
               ila_nobs_lay[iobs] = np.size(np.where(~ np.isnan(rda_val[ila_inds]))[0])
         
      ila_nobs[ilayer] = np.sum(ila_nobs_lay)
      if np.isnan(ila_nobs[ilayer]) : ila_nobs[ilayer] = 0
      if ila_nobs[ilayer] > 0 :
         rla_mean[ilayer] = arithm.nansum(np.multiply(rla_mean_lay,ila_nobs_lay))/arithm.nansum(ila_nobs_lay)
         rla_bias[ilayer] = arithm.nansum(np.multiply(rla_bias_lay,ila_nobs_lay))/arithm.nansum(ila_nobs_lay)
         rla_rms[ilayer]  = np.sqrt(arithm.nansum(np.multiply(rla_ms_lay,ila_nobs_lay))/arithm.nansum(ila_nobs_lay))
         rla_rmse[ilayer] = np.sqrt(arithm.nansum(np.multiply(rla_mse_lay,ila_nobs_lay))/arithm.nansum(ila_nobs_lay))
      else :
         rla_mean[ilayer] = np.nan 
         rla_bias[ilayer] = np.nan 
         rla_rms[ilayer]  = np.nan 
         rla_rmse[ilayer] = np.nan 
      ilayer += 1

   return rla_mean, rla_rms, rla_bias, rla_rmse, ila_nobs

#------------------------------------------------------------------------------------------------------------------------------------------

def statlayer_CL4var_bis(rda_val,\
			rda_observations,\
			rda_depthobs,\
			rda_depth_layers) :
   """
Returns mean, RMS, Bias (/observations), RMSE (/observations), number of observations of input array rda_val in depth layers
   """
   n_layers = len(rda_depth_layers)-1
   if len(np.shape(rda_val)) == 2 : n_obs = np.shape(rda_val)[0]
   elif len(np.shape(rda_val)) == 1 : n_obs = 1
   else: 
      print 'problem with shape of rda_val'
      sys.exit(1)
   #print 'nombre de profondeurs :: ',n_obs
   #rla_mean = np.zeros(n_layers)
   #rla_bias = np.zeros(n_layers)
   #rla_rms  = np.zeros(n_layers)
   #rla_rmse = np.zeros(n_layers)
   #ila_nobs = np.zeros(n_layers)
   rla_mean = np.nan*np.zeros(n_layers)
   rla_bias = np.nan*np.zeros(n_layers)
   rla_rms  = np.nan*np.zeros(n_layers)
   rla_rmse = np.nan*np.zeros(n_layers)
   ila_nobs = np.zeros(n_layers)
   ilayer   = 0
   for depthmin,depthmax in zip(rda_depth_layers[:-1],rda_depth_layers[1:]) :
      #rla_mean_lay = np.zeros(n_obs)
      #rla_bias_lay = np.zeros(n_obs)
      #rla_ms_lay   = np.zeros(n_obs)
      #rla_mse_lay  = np.zeros(n_obs)
      #ila_nobs_lay = np.zeros(n_obs)
      rla_mean_lay = np.nan*np.zeros(n_obs)
      rla_bias_lay = np.nan*np.zeros(n_obs)
      rla_ms_lay   = np.nan*np.zeros(n_obs)
      rla_mse_lay  = np.nan*np.zeros(n_obs)
      ila_nobs_lay = np.nan*np.zeros(n_obs)
      for iobs in range(n_obs) :
         if n_obs > 1 :
            if ((rda_depthobs[iobs,:] >= depthmin) & \
              	    (rda_depthobs[iobs,:] < depthmax) \
              	   ).any() :
               ila_inds = np.where(\
                       (rda_depthobs[iobs,:] >= depthmin) & \
                       (rda_depthobs[iobs,:] < depthmax) \
                       )
               rla_mean_lay[iobs] = arithm.nanmean(rda_val[iobs,ila_inds])
               rla_bias_lay[iobs] = arithm.nanmean(rda_val[iobs,ila_inds]-\
               			    rda_observations[iobs,ila_inds])
               rla_ms_lay[iobs]   = arithm.nanms(rda_val[iobs,ila_inds])
               rla_mse_lay[iobs]  = arithm.nanmse(rda_val[iobs,ila_inds],\
               			    rda_observations[iobs,ila_inds])
               ila_nobs_lay[iobs] = np.size(np.where(~ np.isnan(rda_val[iobs,ila_inds]))[0])
         elif n_obs == 1 :
            if ((rda_depthobs >= depthmin) & \
              	    (rda_depthobs < depthmax) \
              	   ).any() :
               ila_inds = np.where(\
                       (rda_depthobs >= depthmin) & \
                       (rda_depthobs < depthmax) \
                       )
               rla_mean_lay[iobs] = arithm.nanmean(rda_val[ila_inds])
               rla_bias_lay[iobs] = arithm.nanmean(rda_val[ila_inds]-\
               			    rda_observations[ila_inds])
               rla_ms_lay[iobs]   = arithm.nanms(rda_val[ila_inds])
               rla_mse_lay[iobs]  = arithm.nanmse(rda_val[ila_inds],\
               			    rda_observations[ila_inds])
               ila_nobs_lay[iobs] = np.size(np.where(~ np.isnan(rda_val[ila_inds]))[0])


      ila_nobs[ilayer] = np.sum(ila_nobs_lay)
      if np.isnan(ila_nobs[ilayer]) : ila_nobs[ilayer] = 0
      if ila_nobs[ilayer] > 0 :
         rla_mean[ilayer] = arithm.nansum(np.multiply(rla_mean_lay,ila_nobs_lay))
         rla_bias[ilayer] = arithm.nansum(np.multiply(rla_bias_lay,ila_nobs_lay))
         rla_rms[ilayer]  = arithm.nansum(np.multiply(rla_ms_lay,ila_nobs_lay))
         rla_rmse[ilayer] = arithm.nansum(np.multiply(rla_mse_lay,ila_nobs_lay))
      else :
         rla_mean[ilayer] = np.nan
         rla_bias[ilayer] = np.nan 
         rla_rms[ilayer]  = np.nan 
         rla_rmse[ilayer] = np.nan 
      ilayer += 1
   return rla_mean, rla_rms, rla_bias, rla_rmse, ila_nobs
   
   
