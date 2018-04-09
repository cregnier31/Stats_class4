import numpy as np
import sys,os

import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.spines import Spine
from matplotlib.projections.polar import PolarAxes
from matplotlib.projections import register_projection
pathmod = os.path.join(os.path.split(os.getcwd())[0],'')
sys.path.append(pathmod)
import radar_chart

## C.REGNIER 2014 : plot histograms 
def mkdir(path):
     "Create a directory, and parents if needed"
     if not os.path.exists(path):
         os.makedirs(path)


if len(sys.argv) != 3: 
  print 'Usage: ./create_radar_char_oper.py <YEAR> <QUART>' 
  sys.exit(1) 
else :
  YEAR=sys.argv[1]
  QUART=sys.argv[2]

modele = ['PSY3V3R3','PSY4V2R2']
variableT='TEMP'
variableS='PSAL'
variableSST='SST'
variableSLA='SLA'


year=str(YEAR)
trim=str(QUART)
if int(QUART) == 1 :
   date1=year+"0101"
   date2=year+"0331"
   trim="1"
   QM="JFM"
   print "First quarter"
elif int(QUART) == 2 :
   date1=year+"0401"
   date2=year+"0630"
   trim="2"
   QM="AMJ"
   print "Second quarter"
elif int(QUART) == 3 :
   date1=year+"0701"
   date2=year+"0930"
   trim="3"
   QM="JAS"
   print "Third quarter"
elif int(QUART) == 4 :
   date1=year+"1001"
   date2=year+"1231"
   trim="4"
   QM="OND"
   print "Fourth quarter"
else  :
  print "Bad choice "
  sys.exit(1)

datetrim=year+'_'+trim
datetrim2=QM+" "+year
profondeurs=['0-5m','5-100m','100-300m','300-800m','800-2000m','2000-5000m','0-5000m']
#profondeur="0-5m"
#profondeur="5-100m"
#profondeur="100-300m"
#profondeur="300-800m"
#profondeur="800-2000m"
#profondeur="2000-5000m"
#profondeur="0-5000m"
datetrim=year+'_'+trim
datetrim2=QM+" "+year
for profondeur in profondeurs :
   il_ind=0
   rms_list_mod_T=np.nan*np.zeros((2,7))
   rms_list_mod_S=np.nan*np.zeros((2,7))
   rms_list_mod_SST=np.nan*np.zeros((2,7))
   rms_list_mod_SLA=np.nan*np.zeros((2,7))
   modele = ['PSY3V3R3','PSY4V2R2']
   print "Work on datetrim %s profondeur %s" %(datetrim,profondeur)
   for mod in modele:
      mod2=mod
      file_T='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableT+'_'+profondeur+'.txt'
      file_S='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableS+'_'+profondeur+'.txt'
      file_SST='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableSST+'_0-0m.txt'
      file_SST='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableSST+'_0-0m.txt'
      file_SLA='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/MYO/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableSLA+'_0-0m.txt'
      data_T = np.genfromtxt(file_T, dtype=None)
      data_S = np.genfromtxt(file_S, dtype=None)
      data_SST = np.genfromtxt(file_SST, dtype=None)
      data_SLA = np.genfromtxt(file_SLA, dtype=None)
      rms_list_T=data_T[::2]
      rms_list_S=data_S[::2]
      rms_list_SST=data_SST[::2]
      rms_list_mod_T[il_ind,:]=rms_list_T
      rms_list_mod_S[il_ind,:]=rms_list_S
      rms_list_mod_SST[il_ind,:]=rms_list_SST
      rms_list_SLA=data_SLA[::2]
      rms_list_mod_SLA[il_ind,:]=rms_list_SLA
      il_ind=il_ind+1
      
   for il_ind in range(7):
     max_sst=np.nanmax(rms_list_mod_SST[:,il_ind])
     max_S=np.nanmax(rms_list_mod_S[:,il_ind])
     max_T=np.nanmax(rms_list_mod_T[:,il_ind])
     max_SLA=np.nanmax(rms_list_mod_SLA[:,il_ind])
     rms_list_mod_SST[:,il_ind]=rms_list_mod_SST[:,il_ind]/max_sst
     rms_list_mod_SLA[:,il_ind]=rms_list_mod_SLA[:,il_ind]/max_SLA
     rms_list_mod_S[:,il_ind]=rms_list_mod_S[:,il_ind]/max_S
     rms_list_mod_T[:,il_ind]=rms_list_mod_T[:,il_ind]/max_T
   data = {
             'column names':
                 ['TEMP', 'SAL', 'SST', 'SLA'],
             'HDCST':
                 [[np.around(np.array(rms_list_mod_T[0,0]),decimals=2).tolist(),
        	        np.around(np.array(rms_list_mod_S[0,0]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_SST[0,0]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_SLA[0,0]),decimals=2).tolist()],
                  [np.around(np.array(rms_list_mod_T[1,0]),decimals=2).tolist(),
        	        np.around(np.array(rms_list_mod_S[1,0]),decimals=2).tolist(),
        	        np.around(np.array(rms_list_mod_SST[1,0]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_SLA[1,0]),decimals=2).tolist()],
   	       [0.92,0.92,0.92,0.92],
   ],
                'FRCST_1D':
                    [[np.around(np.array(rms_list_mod_T[0,1]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_S[0,1]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_SST[0,1]),decimals=2).tolist(),
                      np.around(np.array(rms_list_mod_SLA[0,1]),decimals=2).tolist()],
                     [np.around(np.array(rms_list_mod_T[1,1]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_S[1,1]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_SST[1,1]),decimals=2).tolist(),
                      np.around(np.array(rms_list_mod_SLA[1,1]),decimals=2).tolist()],
   	          [0.92,0.92,0.92,0.92],
   ],
                'FRCST_3D':
                    [[np.around(np.array(rms_list_mod_T[0,2]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_S[0,2]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_SST[0,2]),decimals=2).tolist(),
                      np.around(np.array(rms_list_mod_SLA[0,2]),decimals=2).tolist()],
                     [np.around(np.array(rms_list_mod_T[1,2]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_S[1,2]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_SST[1,2]),decimals=2).tolist(),
                      np.around(np.array(rms_list_mod_SLA[1,2]),decimals=2).tolist()],
   	          [0.92,0.92,0.92,0.92],
   ],
                'FRCST_5D':
                    [[np.around(np.array(rms_list_mod_T[0,3]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_S[0,3]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_SST[0,3]),decimals=2).tolist(),
                      np.around(np.array(rms_list_mod_SLA[0,3]),decimals=2).tolist()],
                     [np.around(np.array(rms_list_mod_T[1,3]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_S[1,3]),decimals=2).tolist(),
   		   np.around(np.array(rms_list_mod_SST[1,3]),decimals=2).tolist(),
                      np.around(np.array(rms_list_mod_SLA[1,3]),decimals=2).tolist()],
   	          [0.92,0.92,0.92,0.92],
   ],}
   N = 4
   colors = ['b', 'r', 'w']
   theta = radar_chart.radar_factory(N, frame='polygon')
   
   for n, title in enumerate(data.keys()):
     print n,title
     for d, color in zip(data[title], colors):
       print d,color
   spoke_labels = data.pop('column names')
   fig = plt.figure(figsize=(9, 9))
   #fig.subplots_adjust(wspace=0.25, hspace=0.20, top=0.85, bottom=0.05)
   fig.subplots_adjust(wspace=0.20, hspace=0.20, top=0.85, bottom=0.05)
   # Plot the four cases from the example data on separate axes
   for n, title in enumerate(data.keys()):
       ax = fig.add_subplot(2, 2, n+1, projection='radar')
       plt.rgrids([0.92,0.94,0.96,0.98,1.0])
       #plt.rgrids([0.9,1.0])
       #plt.rgrids([0.6,0.7,0.8,0.9,1])
       ax.set_title(title, weight='bold', size='medium', position=(0.5, 1.1),
                    horizontalalignment='center', verticalalignment='center')
       for d, color in zip(data[title], colors):
       #    print d, color 
           ax.plot(theta, d, color=color)
           ax.fill(theta, d, facecolor=color, alpha=0.25)
       ax.set_varlabels(spoke_labels)
   
   # add legend relative to top-left plot
   plt.subplot(2, 2, 1)
   #labels = ('PSY3V3R3','FOAM','GIOPS_CONCEPTS','HYCOM','BLK','PSY4V2R2')
   labels = ('PSY3','PSY4')
   legend = plt.legend(labels, loc=(0.9, .95), labelspacing=0.1)
   plt.setp(legend.get_texts(), fontsize='small')
   
   plt.figtext(0.5, 0.965, 'Forecast accuracy of Mercator systems in '+datetrim2,
               ha='center', color='black', weight='bold', size='large')
   #    plt.savefig('radar_chart_frcst_accuracy_2013.pdf')
   dir_out='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/Radar_plot/'+datetrim+'/'
   plt.savefig(dir_out+'radar_chart_frcst_accuracy_'+datetrim+'_'+profondeur+'.png')
   print "datetrim %s profondeur %s OK" %(datetrim,profondeur)
  # plt.show()
sys.exit(1)
