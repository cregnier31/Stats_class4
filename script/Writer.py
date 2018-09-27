from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import netCDF4
import geojson
from geojson import MultiPoint
import shelve
import json
from Logger import Logger
from datetime import date
from netCDF4 import Dataset

##############################################################
## C.REGNIER Juin 2014
## Class Writer to write output file in ASCII or Geojson
##############################################################

class Writer():

    """ Class to write different type of file """


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
    def write_GODAE_files(self,filename,hdct_tab,fcst_tab,pers_tab,dateval,model):
        nc_fid = Dataset(filename, 'r+', format='NETCDF3_CLASSIC')
        nc_best = nc_fid.createVariable('best_estimate','f4',('numobs','numvars','numdeps'),fill_value=9999.0)
        nc_best.setncatts({'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_fcst = nc_fid.createVariable('forecast','f4',('numobs','numvars','numfcsts','numdeps'),fill_value=9999.0)
        nc_fcst.setncatts({'long_name': u"Model forecast counterpart of obs. value"})
        nc_pers = nc_fid.createVariable('persistence','f4',('numobs','numvars','numfcsts','numdeps'),fill_value=9999.0)
        nc_pers.setncatts({'long_name': u"Model persistence counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:,:,:] = hdct_tab[:,:,:]
        nc_fid.variables['forecast'][:,:,:,:] = fcst_tab[:,:,:,:]
        nc_fid.variables['persistence'][:,:,:,:] = pers_tab[:,:,:,:]
        ## Add global attributs
        nc_fid.institution= 'MERCATOR OCEAN'
        nc_fid.contact= 'cregnier@mercator-ocean.fr'
        nc_fid.obs_type='AMSR2 brightness temperature'
        nc_fid.time_interp = "daily average fields" ;
        today=date.today() 
        yyyy=str(today)[0:4]
        yyyy2=dateval[0:4]
        month=str(today)[5:7]
        month2=dateval[4:6]
        day=str(today)[8:10]
        day2=dateval[7:9]
        nc_fid.validity_time =yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date=yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system=model
        nc_fid.Conventions = 'CF-1.6'
        nc_fid.best_estimate_description = "analysis produced between 7 and 14 days behind real time"
        print '-------------------------------'
        print 'Creation OK %s '
        print '-------------------------------'
        nc_fid.close()  # close the new file

    def write_best_fcst(self,filename,tab1,tab2,dateval,model):
        nc_fid = Dataset(filename, 'r+', format='NETCDF3_CLASSIC')
        nc_file = nc_fid.createVariable('best_estimate','f4',('lat','lon'),fill_value=-999.0)
        nc_file2 = nc_fid.createVariable('forecast','f4',('lat','lon'),fill_value=-999.0)
        nc_file.setncatts({'long_name': u"Model best_estimate counterpart of obs. value"})
        nc_file2.setncatts({'long_name': u"Model forecast counterpart of obs. value"})
        nc_fid.variables['best_estimate'][:] = tab1[:,:]
        nc_fid.variables['forecast'][:] = tab2[:,:]
        ## Add global attributs
        nc_fid.institution= 'MERCATOR OCEAN'
        nc_fid.contact= 'qualif@mercator-ocean.fr'
        today=date.today() 
        yyyy=str(today)[0:4]
        yyyy2=dateval[0:4]
        month=str(today)[5:7]
        month2=dateval[4:6]
        day=str(today)[8:10]
        day2=dateval[7:9]
        nc_fid.validity_time =yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date=yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system=model
        print '-------------------------------'
        print 'Creation OK %s '
        print '-------------------------------'
        nc_fid.close()  # close the new file

    def write_best(self,filename,tab1,dateval,model,dimension):
        nc_fid = Dataset(filename, 'r+', format='NETCDF3_CLASSIC')
        nc_file = nc_fid.createVariable('best_estimate','f4',(dimension),fill_value=np.nan)
        nc_file.setncatts({'long_name': u"Model "+model+" best_estimate counterpart of obs. value"})
        nc_file.setncatts({'minvalue':  np.nanmin(tab1)})
        nc_file.setncatts({'maxvalue': np.nanmax(tab1)})
        nc_fid.variables['best_estimate'][:] = tab1[:]
        ## Add global attributs
        nc_fid.institution= 'MERCATOR OCEAN'
        nc_fid.contact= 'qualif@mercator-ocean.fr'
        today=date.today() 
        yyyy=str(today)[0:4]
        yyyy2=dateval[0:4]
        month=str(today)[5:7]
        month2=dateval[4:6]
        day=str(today)[8:10]
        day2=dateval[7:9]
        nc_fid.validity_time =yyyy2+"-"+month2+"-"+day2+" 00:00:00"
        nc_fid.creation_date=yyyy+"-"+month+"-"+day+" 00:00:00"
        nc_fid.system=model
        print '-------------------------------'
        print 'Creation OK %s '
        print '-------------------------------'
        nc_fid.close()  # close the new file
