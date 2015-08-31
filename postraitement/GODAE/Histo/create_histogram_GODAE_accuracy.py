import numpy as np
import sys,os

import matplotlib.pyplot as plt
from matplotlib.path import Path
pathmod = os.path.join(os.path.split(os.getcwd())[0],'CL4_GODAE_LIB')
sys.path.append(pathmod)
import pylab as P

## C.REGNIER 2014 : plot histograms 
def mkdir(path):
     "Create a directory, and parents if needed"
     if not os.path.exists(path):
         os.makedirs(path)


if len(sys.argv) != 3: 
  print 'Usage: ./create_histogram_GODAE_accuracy.py <YEAR> <QUART>' 
  sys.exit(1) 
else :
  YEAR=sys.argv[1]
  QUART=sys.argv[2]

modele = ['PSY4V2R2','PSY3V3R3']
liste_var=['TEMP','PSAL']
prof0='0-5m'
prof1='5-100m'
prof2='100-300m'
prof3='300-800m'
prof4='800-2000m'
prof5='2000-5000m'
prof6='0-5000m'
reg=['GLO','TAT','TPA','MED','NAT','SAT','SPA','NPA','ARC','ACC','IND']
year=str(YEAR)
trim=str(QUART)
if int(QUART) == 1 :
   date1=year+"0101"
   date2=year+"0331"
   QM="JFM"
   print "First quarter"
elif int(QUART) == 2 :
   date1=year+"0401"
   date2=year+"0630"
   QM="AMJ"
   print "Second quarter"
elif int(QUART) == 3 :
   date1=year+"0701"
   date2=year+"0930"
   QM="JAS"
   print "Third quarter"
elif int(QUART) == 4 :
   date1=year+"1001"
   date2=year+"1231"
   QM="OND"
   print "Fourth quarter"
else  :
  print "Bad choice "
  sys.exit(1)

datetrim=year+'_'+trim
datetrim2=QM+" "+year
nb_mod=2
stats=['RMS','mean']
typestats='mean'

for typestats in stats :
   if typestats == 'RMS': 
      il_begin=0 
      typevar='rmsval'
   elif typestats == 'mean': 
      il_begin=1
      typevar='meanval'
   for variable in liste_var : 
      if variable == 'TEMP': 
        variable2='TEMP'
      elif variable == 'PSAL':
        variable2='SAL'
      stats_list_mod_0=np.nan*np.zeros((nb_mod,7))
      stats_list_mod_1=np.nan*np.zeros((nb_mod,7))
      stats_list_mod_2=np.nan*np.zeros((nb_mod,7))
      stats_list_mod_3=np.nan*np.zeros((nb_mod,7))
      stats_list_mod_4=np.nan*np.zeros((nb_mod,7))
      stats_list_mod_5=np.nan*np.zeros((nb_mod,7))
      stats_list_mod_6=np.nan*np.zeros((nb_mod,7))
      stats_clim=np.nan*np.zeros(7)
      for region in reg : 
         il_ind=0
         for mod in modele:
            file_clim1='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof0+'.txt'
            file_clim2='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof1+'.txt'
            file_clim3='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof2+'.txt'
            file_clim4='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof3+'.txt'
            file_clim5='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof4+'.txt'
            file_clim6='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof5+'.txt'
            file_clim7='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/suivi_rms/'+year+'_'+trim+'/File_ASCII/Fic_ASCII_PREVI_'+typevar+'_'+variable2+'_'+region+'_'+mod+'_'+prof6+'.txt'
            mod2=mod
            file_0='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof0+'.txt'
            file_1='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof1+'.txt'
            file_2='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof2+'.txt'
            file_3='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof3+'.txt'
            file_4='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof4+'.txt'
            file_5='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof5+'.txt'
            file_6='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_'+region+'_'+date1+'_'+date2+'_'+variable+'_'+prof6+'.txt'
            data_clim_0=np.genfromtxt(file_clim1, dtype=None)
            data_clim_1=np.genfromtxt(file_clim2, dtype=None)
            data_clim_2=np.genfromtxt(file_clim3, dtype=None)
            data_clim_3=np.genfromtxt(file_clim4, dtype=None)
            data_clim_4=np.genfromtxt(file_clim5, dtype=None)
            data_clim_5=np.genfromtxt(file_clim6, dtype=None)
            data_clim_6=np.genfromtxt(file_clim7, dtype=None)
            data_0 = np.genfromtxt(file_0, dtype=None)
            data_1 = np.genfromtxt(file_1, dtype=None)
            data_2 = np.genfromtxt(file_2, dtype=None)
            data_3 = np.genfromtxt(file_3, dtype=None)
            data_4 = np.genfromtxt(file_4, dtype=None)
            data_5 = np.genfromtxt(file_5, dtype=None)
            data_6 = np.genfromtxt(file_6, dtype=None)
            stats_clim[0]=data_clim_0[2]
            stats_clim[1]=data_clim_1[2]
            stats_clim[2]=data_clim_2[2]
            stats_clim[3]=data_clim_3[2]
            stats_clim[4]=data_clim_4[2]
            stats_clim[5]=data_clim_5[2]
            stats_clim[6]=data_clim_6[2]
            stats_list_0=data_0[il_begin::2]
            stats_list_1=data_1[il_begin::2]
            stats_list_2=data_2[il_begin::2]
            stats_list_3=data_3[il_begin::2]
            stats_list_4=data_4[il_begin::2]
            stats_list_5=data_5[il_begin::2]
            stats_list_6=data_6[il_begin::2]
            # On passe en Obs - modele
            if typestats == 'RMS': 
               stats_list_mod_0[il_ind,:]=stats_list_0
               stats_list_mod_1[il_ind,:]=stats_list_1
               stats_list_mod_2[il_ind,:]=stats_list_2
               stats_list_mod_3[il_ind,:]=stats_list_3
               stats_list_mod_4[il_ind,:]=stats_list_4
               stats_list_mod_5[il_ind,:]=stats_list_5
               stats_list_mod_6[il_ind,:]=stats_list_6
            elif typestats == 'mean': 
               stats_list_mod_0[il_ind,:]=-stats_list_0
               stats_list_mod_1[il_ind,:]=-stats_list_1
               stats_list_mod_2[il_ind,:]=-stats_list_2
               stats_list_mod_3[il_ind,:]=-stats_list_3
               stats_list_mod_4[il_ind,:]=-stats_list_4
               stats_list_mod_5[il_ind,:]=-stats_list_5
               stats_list_mod_6[il_ind,:]=-stats_list_6
         
            clim_val=[np.around(np.array(stats_clim[6]),decimals=4).tolist(), 
                     np.around(np.array(stats_clim[5]),decimals=4).tolist(),
                     np.around(np.array(stats_clim[4]),decimals=4).tolist(),
                     np.around(np.array(stats_clim[3]),decimals=4).tolist(),
                     np.around(np.array(stats_clim[2]),decimals=4).tolist(),
                     np.around(np.array(stats_clim[1]),decimals=4).tolist(),
                     np.around(np.array(stats_clim[0]),decimals=4).tolist()]
      
            hdct_val=[np.around(np.array(stats_list_mod_6[il_ind,0]),decimals=4).tolist(),
         		   np.around(np.array(stats_list_mod_5[il_ind,0]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_4[il_ind,0]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_3[il_ind,0]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_2[il_ind,0]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_1[il_ind,0]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_0[il_ind,0]),decimals=4).tolist()]
            fcst1_val=[np.around(np.array(stats_list_mod_6[il_ind,1]),decimals=4).tolist(),
         		   np.around(np.array(stats_list_mod_5[il_ind,1]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_4[il_ind,1]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_3[il_ind,1]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_2[il_ind,1]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_1[il_ind,1]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_0[il_ind,1]),decimals=4).tolist()]
            fcst3_val=[np.around(np.array(stats_list_mod_6[il_ind,2]),decimals=4).tolist(),
         		   np.around(np.array(stats_list_mod_5[il_ind,2]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_4[il_ind,2]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_3[il_ind,2]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_2[il_ind,2]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_1[il_ind,2]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_0[il_ind,2]),decimals=4).tolist()]
            fcst5_val=[np.around(np.array(stats_list_mod_6[il_ind,3]),decimals=4).tolist(),
         		   np.around(np.array(stats_list_mod_5[il_ind,3]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_4[il_ind,3]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_3[il_ind,3]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_2[il_ind,3]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_1[il_ind,3]),decimals=4).tolist(),
                            np.around(np.array(stats_list_mod_0[il_ind,3]),decimals=4).tolist()]
            fig=plt.figure()
            ax=fig.add_subplot(111)
            
            ## 
            N=7
            ## necessary variables
            ind = np.arange(N)                # the x locations for the groups
            width = 0.15                   # the width of the bars
            rects1 = ax.barh(ind,hdct_val,width,
                             color='green')
            rects2 = ax.barh(ind+width,fcst1_val,width,
                            color='yellow')
            rects3 = ax.barh(ind+2*width,fcst3_val,width,
                            color='orange')
            rects4 = ax.barh(ind+3*width,fcst5_val,width,
                            color='red')
            rects5 = ax.barh(ind+4*width,clim_val,width,
                            color='gray')
            # axes and labels
            ax.set_ylim(-width,len(ind)+width)
            maxvalue=max([max(hdct_val),max(fcst1_val),max(fcst3_val),max(fcst5_val),max(clim_val)])
            minvalue=min([min(hdct_val),min(fcst1_val),min(fcst3_val),min(fcst5_val),min(clim_val)])
       #     print min(min([hdct_val,fcst1_val,fcst3_val,fcst5_val,clim_val]))
       #     print max(min([hdct_val,fcst1_val,fcst3_val,fcst5_val,clim_val]))
            ax.set_xlim(minvalue*1.1,maxvalue*1.1)
            #ax.set_xlabel('Rms error')
            name_out=typestats+' error (Obs -Mod) '+variable+' '+region+' '+mod+' '+datetrim2
            ax.set_title(name_out)
            #yTickMarks = ['0-5m','5-100m','100-300m','300-800m','800-2000m','2000-5000m','0-5000m']
            yTickMarks = ['0-5000m','2000-5000m','800-2000m','300-800m','100-300m','5-100m','0-5m']
            ax.set(yticks=ind+width,yticklabels=yTickMarks,ylim=[-width,len(ind)+width])
            ytickNames = ax.set_yticklabels(yTickMarks)
            plt.setp(ytickNames, rotation=45, fontsize=11)
            ## add a legend
            ax.legend( (rects1[0], rects2[0],rects3[0], rects4[0],rects5[0]), ('BEST','F1','F3','F5','WOA09'),loc=4)
            ## Create output repertory
            dir_out='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Class4_pics/histo/'+year+'_'+trim+'/'
            mkdir(os.path.dirname(dir_out))                                                                                                          
            #plt.savefig(dir_out+mod+'/Class4_pics/histo/'+year+'_'+trim+'/'+variable+'_'+typestats+'_'+region+'_'+mod+'.png')
            plt.savefig(dir_out+variable+'_'+typestats+'_'+region+'_'+mod+'.png')
            print 'OK %s %s %s %s' %(region,variable,typestats,mod)
            il_ind=il_ind+1


