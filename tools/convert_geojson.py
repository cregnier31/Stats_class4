from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import netCDF4
import geojson
from geojson import MultiPoint
import json

##############################################################
## C.REGNIER Juin 2014
## Class Writer to write output file in ASCII or Geojson
##############################################################


file="pos_xy.txt"
filename="pos_xy.geojson"
data = open(file,'r')
liste_position=[]
pos=np.ndarray(shape=(2),dtype=float, order='F')
for line in data: 
   lon=float(line.split()[0])
   lat=float(line.split()[1])
   pos[0]=lon
   pos[1]=lat
   liste_position.append(tuple(pos))

#    liste_position.append(f.read())
#    print liste_position
with open(filename, 'w') as outfile:
       json.dump(MultiPoint(liste_position), outfile)

#class Writer():
#
#    def write_geojson(self,filename,position):
#       try:
#         #print 'Write Geojson file'
#         liste_position=[]
#         for il_ind in range(len(position)):
#             pos=position[il_ind]
#             liste_position.append(tuple(pos))
#         #print MultiPoint(liste_position)
#         with open(filename, 'w') as outfile:
#             json.dump(MultiPoint(liste_position), outfile)
#       except:
#         print 'Probleme d ecriture'
#         sys.exit(1)
    

