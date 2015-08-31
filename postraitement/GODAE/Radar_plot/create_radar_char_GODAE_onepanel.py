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

modele = ['PSY3V3R3','FOAM','GIOPS_CONCEPTS','HYCOM','PSY4V2R2']
variableT='TEMP'
variableS='PSAL'
variableSST='SST'
variableSLA='SLA'
date1="20130101"
date2="20131231"
il_ind=0
rms_list_mod_T=np.nan*np.zeros((5,7))
rms_list_mod_S=np.nan*np.zeros((5,7))
rms_list_mod_SST=np.nan*np.zeros((5,7))
rms_list_mod_SLA=np.nan*np.zeros((5,7))
for mod in modele:
   if mod in ['HYCOM']:
     mod2="HYCOM_RTOFS"
   elif mod in ['PSY4V2R2']:
     date1="20130501"
     mod2=mod
   else:
     mod2=mod
   #print mod,mod2
   file_T='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/Intercomp2/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableT+'_5-100m.txt'
   file_S='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/Intercomp2/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableS+'_5-100m.txt'
   file_SST='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/Intercomp2/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableSST+'_0-0m.txt'
   data_T = np.genfromtxt(file_T, dtype=None)
   data_S = np.genfromtxt(file_S, dtype=None)
   data_SST = np.genfromtxt(file_SST, dtype=None)
   rms_list_T=data_T[::2]
   rms_list_S=data_S[::2]
   rms_list_SST=data_SST[::2]
   rms_list_mod_T[il_ind,:]=rms_list_T
   rms_list_mod_S[il_ind,:]=rms_list_S
   rms_list_mod_SST[il_ind,:]=rms_list_SST
   if mod in ['PSY3V3R3','FOAM','GIOPS_CONCEPTS','PSY4V2R2']:
      file_SLA='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+mod+'/Stats_GODAE/File_ASCII/Intercomp2/Global_stats'+mod2+'_GLO_'+date1+'_'+date2+'_'+variableSLA+'_0-0m.txt'
      data_SLA = np.genfromtxt(file_SLA, dtype=None)
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
             'FRCST_1D':
                 [[np.array(rms_list_mod_T[0,1]).tolist(),
		  np.array(rms_list_mod_S[0,1]).tolist(),
		  np.array(rms_list_mod_SST[0,1]).tolist(),
                  np.array(rms_list_mod_SLA[0,1]).tolist()],
                 [np.array(rms_list_mod_T[1,1]).tolist(),
		  np.array(rms_list_mod_S[1,1]).tolist(),
		  np.array(rms_list_mod_SST[1,1]).tolist(),
                  np.array(rms_list_mod_SLA[1,1]).tolist()],
                 [np.array(rms_list_mod_T[2,1]).tolist(),
		  np.array(rms_list_mod_S[2,1]).tolist(),
		  np.array(rms_list_mod_SST[2,1]).tolist(),
                  np.array(rms_list_mod_SLA[2,1]).tolist()],
                 [np.array(rms_list_mod_T[3,1]).tolist(),
		  np.array(rms_list_mod_S[3,1]).tolist(),
		  np.array(rms_list_mod_SST[3,1]).tolist(),
                  np.array(rms_list_mod_SLA[3,1]).tolist()],
                 [np.array(rms_list_mod_T[4,1]).tolist(),
		  np.array(rms_list_mod_S[4,1]).tolist(),
		  np.array(rms_list_mod_SST[4,1]).tolist(),
                  np.array(rms_list_mod_SLA[4,1]).tolist()],
],
}
N = 4
colors = ['#FF8C00', 'g', '#87CEEB', 'r', '#FFD700']
theta = radar_chart.radar_factory(N, frame='polygon')
for n, title in enumerate(data.keys()):
  print n,title
  for d, color in zip(data[title], colors):
    print d,color
spoke_labels = data.pop('column names')

fig = plt.figure(figsize=(9, 9))
#fig.subplots_adjust(wspace=0.25, hspace=0.20, top=0.85, bottom=0.05)
fig.subplots_adjust(wspace=0.20, hspace=0.15, top=0.89, bottom=0.1)
# Plot the four cases from the example data on separate axes
for n, title in enumerate(data.keys()):
    ax = fig.add_subplot(1, 1, n+1, projection='radar')
  #  plt.rgrids([0.4,0.6,0.8,1.0])
    plt.rgrids([0.6, 0.7, 0.8,0.9,1.0])
    ax.set_title(title, weight='bold', size='medium', position=(0.5, 1.1),
                 horizontalalignment='center', verticalalignment='center')
    for d, color in zip(data[title], colors):
        ax.plot(theta, d, color=color)
        ax.fill(theta, d, facecolor=color, alpha=0.25)
    ax.set_varlabels(spoke_labels)

# add legend relative to top-left plot
# plt.subplot(1, 1, 1)
#labels = ('PSY3V3R3','FOAM','GIOPS_CONCEPTS','HYCOM','PSY4V2R2')
labels = ('PSY3','FOAM','GIOPS','RTOFS','PSY4')
legend = plt.legend(labels, loc=(0.9, .95), labelspacing=0.1)
plt.setp(legend.get_texts(), fontsize='small')

plt.figtext(0.5, 0.965, '',
            ha='center', color='black', weight='bold', size='large')
plt.show()
plt.savefig('radar_chart_GODAE_2013_FCST1.pdf')
