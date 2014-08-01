from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import netCDF4
import geojson
from geojson import MultiPoint
import shelve
import json
from Logger import Logger                                                                                                   

##############################################################
## C.REGNIER Juin 2014
## Class Writer to write output file in ASCII or Geojson
##############################################################

class Writer():

    def write_geojson(self,filename,position):
       try:
         #print 'Write Geojson file'
         liste_position=[]
         for il_ind in range(len(position)):
             pos=position[il_ind]
             liste_position.append(tuple(pos))
         #print MultiPoint(liste_position)
         with open(filename, 'w') as outfile:
             json.dump(MultiPoint(liste_position), outfile)
       except:
         print 'Probleme d ecriture'
         sys.exit(1)
    
    def write_ASCII(self,filename,position):
       try:
	 #print 'Write ASCII file'
         # Creation fichier
	    length=position.size
	    #if length < 2 : 
            #     print "Empty Position array"
            #elif length == 2 :
	    #     print "Only 1 position" 
            #     np.savetxt(filename, position[None,:],fmt='%12.5f',delimiter='    ')
            #else :  
            #     np.savetxt(filename, position,fmt='%12.5f',delimiter='    ')
            np.savetxt(filename, position,fmt='%12.5f',delimiter='    ')
        # print len(position)
        #print 'Write ASCII file OK'
       except:
         print 'Probleme d ecriture'
         sys.exit(1)

    def write_geojson_fromdb(self,type_f,file_out,file_db):
	# Open a shelve file if not exist
	if not(os.path.isfile(file_db)) :
	   print "Pb persistent file doesn't exist"
	   sys.exit(1)
        else: 
	   shelf = shelve.open(file_db)
           try:
	     tab_fin=shelf[type_f]
             #tab_fin[0,:][tab_fin[0,:] <0] += 360.
	     #print "Type exist %s " %(type_f)
             self.write_geojson(file_out,tab_fin)
           except: 
	     print "Type doesn't exist %s " %(type_f)
           shelf.close()
#
