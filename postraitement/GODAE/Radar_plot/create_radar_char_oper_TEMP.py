import numpy as np
import sys,os

import matplotlib.pyplot as plt
from matplotlib.path import Path
from matplotlib.spines import Spine
from matplotlib.projections.polar import PolarAxes
from matplotlib.projections import register_projection
pathmod = os.path.join(os.path.split(os.getcwd())[0],'CL4_GODAE_LIB')
sys.path.append(pathmod)
import radar_chart


modele = ['PSY3V3R3','PSY4V2R2']
variable='TEMP'
variable='PSAL'
prof1='5-100m'
prof2='100-300m'
prof3='300-800m'
prof4='800-2000m'
date1="20140101"
date2="20140331"
year="2014"
trim="1"
datetrim=year+'_'+trim
datetrim2="JFM 2014"
il_ind=0
rms_list_mod_3=np.nan*np.zeros((2,7))
rms_list_mod_2=np.nan*np.zeros((2,7))
rms_list_mod_1=np.nan*np.zeros((2,7))
rms_list_mod_4=np.nan*np.zeros((2,7))
for mod in modele:
   mod2=mod
   file_1='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variable+'_'+prof1+'.txt'
   file_2='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variable+'_'+prof2+'.txt'
   file_3='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variable+'_'+prof3+'.txt'
   file_4='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/'+datetrim+'/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variable+'_'+prof4+'.txt'
   data_1 = np.genfromtxt(file_1, dtype=None)
   data_2 = np.genfromtxt(file_2, dtype=None)
   data_3 = np.genfromtxt(file_3, dtype=None)
   data_4 = np.genfromtxt(file_4, dtype=None)
   rms_list_1=data_1[::2]
   rms_list_2=data_2[::2]
   rms_list_3=data_3[::2]
   rms_list_4=data_4[::2]
   rms_list_mod_1[il_ind,:]=rms_list_1
   rms_list_mod_2[il_ind,:]=rms_list_2
   rms_list_mod_3[il_ind,:]=rms_list_3
   rms_list_mod_4[il_ind,:]=rms_list_4
   il_ind=il_ind+1
   
for il_ind in range(7):
  max_1=np.nanmax(rms_list_mod_1[:,il_ind])
  max_2=np.nanmax(rms_list_mod_2[:,il_ind])
  max_3=np.nanmax(rms_list_mod_3[:,il_ind])
  max_4=np.nanmax(rms_list_mod_4[:,il_ind])
  rms_list_mod_1[:,il_ind]=rms_list_mod_1[:,il_ind]/max_1
  rms_list_mod_2[:,il_ind]=rms_list_mod_2[:,il_ind]/max_2
  rms_list_mod_3[:,il_ind]=rms_list_mod_3[:,il_ind]/max_3
  rms_list_mod_4[:,il_ind]=rms_list_mod_4[:,il_ind]/max_4
data = {
          'column names':
              [prof1, prof2, prof3, prof4],
          'HDCST':
              [[np.around(np.array(rms_list_mod_1[0,0]),decimals=2).tolist(),
     	        np.around(np.array(rms_list_mod_2[0,0]),decimals=2).tolist(),
                np.around(np.array(rms_list_mod_3[0,0]),decimals=2).tolist(),
                np.around(np.array(rms_list_mod_4[0,0]),decimals=2).tolist()],
               [np.around(np.array(rms_list_mod_1[1,0]),decimals=2).tolist(),
     	        np.around(np.array(rms_list_mod_2[1,0]),decimals=2).tolist(),
     	        np.around(np.array(rms_list_mod_3[1,0]),decimals=2).tolist(),
                np.around(np.array(rms_list_mod_4[1,0]),decimals=2).tolist()],
	       [0.92,0.92,0.92,0.92],
],
             'FRCST_1D':
                 [[np.around(np.array(rms_list_mod_1[0,1]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_2[0,1]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_3[0,1]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_4[0,1]),decimals=2).tolist()],
                  [np.around(np.array(rms_list_mod_1[1,1]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_2[1,1]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_3[1,1]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_4[1,1]),decimals=2).tolist()],
	          [0.92,0.92,0.92,0.92],
],
             'FRCST_3D':
                 [[np.around(np.array(rms_list_mod_1[0,2]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_2[0,2]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_3[0,2]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_4[0,2]),decimals=2).tolist()],
                  [np.around(np.array(rms_list_mod_1[1,2]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_2[1,2]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_3[1,2]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_4[1,2]),decimals=2).tolist()],
	          [0.92,0.92,0.92,0.92],
],
             'FRCST_5D':
                 [[np.around(np.array(rms_list_mod_1[0,3]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_2[0,3]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_3[0,3]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_4[0,3]),decimals=2).tolist()],
                  [np.around(np.array(rms_list_mod_1[1,3]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_2[1,3]),decimals=2).tolist(),
		   np.around(np.array(rms_list_mod_3[1,3]),decimals=2).tolist(),
                   np.around(np.array(rms_list_mod_4[1,3]),decimals=2).tolist()],
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
fig.subplots_adjust(wspace=0.2, hspace=0.20, top=0.85, bottom=0.05)
#fig.subplots_adjust(wspace=0.20, hspace=0.20, top=0.85, bottom=0.05)
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

plt.figtext(0.5, 0.965, 'Forecast accuracy of Mercator systems for '+variable+' in '+datetrim2,
            ha='center', color='black', weight='bold', size='large')
#    plt.savefig('radar_chart_frcst_accuracy_2013.pdf')
plt.savefig('radar_chart_frcst_accuracy_'+variable+'_'+datetrim+'.png')
plt.show()

