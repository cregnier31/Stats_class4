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
rl_maxt=1.36
rl_maxs=0.27
rl_maxsst=0.9
rl_maxsla=0.13
data = {
             'column names':
                 ['T', 'S', 'SST', 'SLA'],
             'FRCST_1D':
                 [[0.59/rl_maxt,0.14/rl_maxs,0.39/rl_maxsst,0.06/rl_maxsla],
		  [0.72/rl_maxt,0.19/rl_maxs,0.34/rl_maxsst,0.07/rl_maxsla],
		  [0.72/rl_maxt,0.19/rl_maxs,0.47/rl_maxsst,0.09/rl_maxsla],
		  [0.70/rl_maxt,0.16/rl_maxs,0.59/rl_maxsst,0.08/rl_maxsla],
		  [0.73/rl_maxt,0.17/rl_maxs,0.58/rl_maxsst,0.07/rl_maxsla],
		  [0.82/rl_maxt,0.19/rl_maxs,0.68/rl_maxsst,np.nan],
		  [0.99/rl_maxt,0.22/rl_maxs,0.88/rl_maxsst,np.nan],
		  [1.36/rl_maxt,0.27/rl_maxs,0.9/rl_maxsst,0.13/rl_maxsla],
],
}
N = 4
colors = ['#C0C0C0', 'g', '#87CEEB','#FFA500','#FFD700','r','m','k']
theta = radar_chart.radar_factory(N, frame='polygon')
for n, title in enumerate(data.keys()):
  print n,title
  for d, color in zip(data[title], colors):
    print d,color
spoke_labels = data.pop('column names')
fig = plt.figure(figsize=(9, 9))
#fig.subplots_adjust(wspace=0.25, hspace=0.20, top=0.85, bottom=0.05)
fig.subplots_adjust(wspace=0.20, hspace=0.15, top=0.85, bottom=0.1)
# Plot the four cases from the example data on separate axes
for n, title in enumerate(data.keys()):
    ax = fig.add_subplot(1, 1, n+1, projection='radar')
  #  plt.rgrids([0.4,0.6,0.8,1.0])
  #  plt.rgrids([0.6, 0.7, 0.8,0.9,1.0])
    ax.set_title(title, weight='bold', size='medium', position=(0.5, 1.1),
                 horizontalalignment='center', verticalalignment='center')
    for d, color in zip(data[title], colors):
        ax.plot(theta, d, color=color,linewidth=2)
       # ax.fill(theta, d, facecolor=color, alpha=0.25)
    ax.set_varlabels(spoke_labels)

# add legend relative to top-left plot
#  plt.subplot(1, 1, 1)
#labels = ('PSY3V3R3','FOAM','GIOPS_CONCEPTS','HYCOM','PSY4V2R2')
labels = ('ENSEMBLE','FOAM','GIOPS','PSY3','PSY4','RTOFS','WOA01','OMAPS')
legend = plt.legend(labels, loc=(0.9, .95), labelspacing=0.1)
plt.setp(legend.get_texts(), fontsize='small')

plt.figtext(0.5, 0.965, '',
            ha='center', color='black', weight='bold', size='large')
plt.show()
plt.savefig('radar_chart_GODAE_2013_FCST1_draft.pdf')
