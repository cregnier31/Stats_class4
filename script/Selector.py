from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import netCDF4
import geojson
from geojson import MultiPoint
import json
from nco import Nco
from Loader import Loader
from QCcontrol import QCcontroller
import logging
import shelve
from Writer import Writer
import itertools

#######################################################################################
## C.REGNIER Juillet 2014
## Class Selector to select profile : the selection depends on QC value and zoom
##			              possibility to store the positions in a file 
#######################################################################################

class Selector(object) :

    """ Factory Class to run different objets depending on input type """

    def __init__(self,data_format,data_type,lon_min=-180,lon_max=180,lat_min=-90,lat_max=90,**kwargs):
        self.data_format=data_format
        self.data_type=data_type
        self.lonmin = lon_min
        self.lonmax = lon_max
        self.latmin = lat_min
        self.latmax = lat_max
    def factory(self,type):
        #return eval(type + "()")
        if type == "ARGO":
            return QCArgo()
        elif type == "CORIOLIS" or type == "GODAE" : 
            return SelectCorio(self.data_format,self.data_type,self.lonmin,\
                               self.lonmax,self.latmin,self.latmax)
        elif type == "ENS": 
            return QCEns()
        elif type == "IAOOS": 
            return QCEns()
        else :
            print "Type not known %s " %(type)

class SelectCorio(Selector) :

    """ Class for Coriolis files """

    def __init__(self,data_format,data_type,lon_min,lon_max,lat_min,lat_max,**kwargs):
        super(Selector,self).__init__(**kwargs)
        self.data_format=data_format
        self.data_type=data_type
        self.lonmin = lon_min
        self.lonmax = lon_max
        self.latmin = lat_min
        self.latmax = lat_max
        if data_format == "NC_CORIO" :
            self.dimprof='N_PROF'
        elif data_format == "NC_GODAE" :
            self.dimprof='numobs'

    def run(self,fichier,zoom,do_qc,TYPEDATA,qc_level):
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger(" Run Selector")
        ## Level of logging output
        log.setLevel(logging.INFO)
        #log.setLevel(logging.ERROR)
        # Read position of profiles
        position=Loader.factory(self.data_format).read_pos(fichier)
        nb_profs=len(position[:,0])
        log.info('Nb profiles : %i' %(nb_profs)) 
        if do_qc : 
            log.info('Run with QC') 
            log.info('Type of DATA %s ' %(self.data_type)) 
            # Compute QC flag
            #QCflag=QCcontroller(self.data_type).factory(TYPEDATA).QCrun(fichier,qc_level)
            #QCobj=QCcontroller(self.data_type,TYPEDATA).factory()
            QCflag=QCcontroller(self.data_type,TYPEDATA).factory().QCrun(fichier,qc_level)
            #QCflag=QCobj.QCrun(fichier,qc_level)
        else :
            QCflag=np.chararray(nb_profs, itemsize=1)
            # QCflag=np.array[nb_profs]
            QCflag[:]="1"
        #log.info('QC Flags %s ' %(QCflag)) 
        #  Index of valid profiles
        index= [i for i,x in enumerate(QCflag) if x == "1"]
        log.info('Profiles Totaux : %i / Valides : %i ' % (len(QCflag),len(index)))
        nb_prof_clean=len(index)
        ## Loop on valid profil to find if it 
        il_ind=0
        il_ind2=0
        list_file=[]
        list_index=[]
        tab_new=np.ndarray(shape=(1,2),dtype=float, order='F')
        # init
        tab_new[:,:]=np.nan
        for il_it in index:
            if zoom : 
                position_lon=position[il_it,0]
                position_lat=position[il_it,1]
                if (position_lon <=  self.lonmax) & (position_lon >= self.lonmin) & \
                    (position_lat <= self.latmax) & ( position_lat >= self.latmin) :
                    log.info("Profile inside region : %f %f %f %f  %f %f  " % (position_lon,position_lat,self.lonmin, \
                                                                                 self.lonmax,self.latmin,self.latmax)) 
                    list_index.append(il_it)
                    if il_ind == 0 : 
                        #tab_pos[0,:]=position[il_it,:]
                        #tab_new=position[il_it,:] 
                        tab_new[0,0]=position[il_it,0]
                        tab_new[0,1]=position[il_it,1]
                    else :
                        tab_new=np.vstack((tab_new,position[il_it,:]))
                    il_ind=il_ind+1
            else : 
                list_index.append(il_it)
                if il_ind2 == 0 : 
                    tab_new=position[il_it,:]
                else :
                    tab_new=np.vstack((tab_new,position[il_it,:]))
                il_ind2=il_ind2+1
        if np.isnan(tab_new).all() :
        #try  
        #   tab_new
        #except :
            tab_new=[]
            tab_new=np.array(tab_new)
        return tab_new,list_index


    def write(self,fichier,list_index,output_dir):
        # Write extracted files
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger(" Run Selector")
        ## Level of logging output
        log.setLevel(logging.INFO)
        ## Nco constructor
        nco = Nco()
        il_ind=0
        print fichier
        file_out=os.path.basename(fichier)
        for il_it in list_index:
            file_out2=os.path.basename(fichier).split('.')[0]+'_pf_'+str(il_it)+'.nc'
            if il_ind == 0 : 
                ## Create file with unlimited dimension
                options = []
                options.extend(['-h'])
                nco.ncks(input=fichier,output=output_dir+file_out, fortran=True ,dimension=str(self.dimprof)+','+str(il_it+1),options=options)
                nco.ncecat(input=output_dir+file_out,output=output_dir+file_out,fortran=True,options=options)
                options = []
                options.extend(['-h','-O','-a',self.dimprof+',record'])
                nco.ncpdq(input=output_dir+file_out,output=output_dir+file_out,fortran=True,options=options)
                ## Remove record dimension
                options = []
                options.extend(['-h','-O','-a','record'])
                nco.ncwa(input=output_dir+file_out,output=output_dir+file_out,fortran=True,options=options)
            else :
                options = []
                options.extend(['-h'])
                log.info("Do ncks")
                nco.ncks(input=fichier,output=output_dir+file_out2, fortran=True ,append=True,dimension=self.dimprof+','+str(il_it+1),options=options)
                log.info("Do ncks ok")
                infiles = [output_dir+file_out,output_dir+file_out2]
                log.info("Inputfiles :  %s " %(infiles) )
                ## Concatenation of valid profiles
                log.info("Do ncrcat")
                nco.ncrcat(input=infiles, output=output_dir+'test.nc',fortran=True,options=options) 
                log.info("Do ncrcat OK")
                ## remove profile
                os.remove(output_dir+file_out2) 
                log.info("Do remove OK")
                os.rename(output_dir+'test.nc',output_dir+file_out)
                log.info("Do rename OK")
            il_ind=il_ind+1

    def store_pos(self,tab_pos,type_f,file_db):
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("store_pos")
        ## Level of logging output
        log.setLevel(logging.INFO)
        # Open a shelve file if not exist
        if not(os.path.isfile(file_db)) :
            log.debug("Create persistent file")
            shelf = shelve.open(file_db, 'c')
        else: 
            log.debug("File exist %s " %(file_db))
            shelf = shelve.open(file_db)
        # Add position values in the serialized dictionnary 
        try : 
            ll_exist = shelf[type_f]
        except : 
            log.debug("Create %s" %(type_f))
            shelf[type_f] = tab_pos
            ll_exist=[]
        if len(ll_exist) > 0 : 
            try :
                log.debug("Tab_fin")
                tab_fin=shelf[type_f]
                log.debug("concatenation")
                tab_fin=np.concatenate((tab_fin,tab_pos))
                shelf[type_f] = tab_fin
            except:
                print "Pb with concatenation store_pos"
                sys.exit(1)
        ## Create global position
        type_var='GLO'
        # Clean tab_pos to remove bad value
        nb_prof=len(tab_pos[:,0])
        nb_prof_safe=(tab_pos[:,0] < 99999 ) & (tab_pos[:,0] < 99999 )
        tab_pos_new=np.ndarray(shape=(nb_prof_safe.sum(),2),dtype=float, order='F')
        il_val=0
        for il_ind in range(nb_prof) : 
            value=nb_prof_safe[il_ind]
            if value : 
                tab_pos_new[il_val,:]=tab_pos[il_ind,:]
                il_val=il_val+1
        try : 
            ll_GLO = shelf[type_var]
        except :
            shelf[type_var] = tab_pos_new
            ll_GLO=[]
        if len(ll_GLO) > 0 : 
            try  :
                tab_fin=shelf[type_var]
                tab_fin=np.concatenate((tab_fin,tab_pos_new))
                shelf[type_var] = tab_fin
                # print shelf[type_var]
            except : 
                print "Pb with concatenation in GLO"
                sys.exit(1)
        shelf.close()

    def store_pos_single(self,tab_pos,type_f,file_db):
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("store_pos_single")
        ## Level of logging output
        #log.setLevel(logging.DEBUG)
        log.setLevel(logging.INFO)
        # Open a shelve file if not exist
        if not(os.path.isfile(file_db)) :
            log.debug('Create persistent file')
            shelf = shelve.open(file_db, 'c')
        else:
            log.debug("File exist %s " %(file_db))
            shelf = shelve.open(file_db)
        # Add position values in the serialized dictionnary 
        try : 
            ll_exist = shelf[type_f]
        except : 
            shelf[type_f] = tab_pos
            ll_exist=[]
        if len(ll_exist) > 0 : 
            try :
                log.debug("Concatenation")
                tab_fin=shelf[type_f]
                log.debug("==== TAB FIN ==============")
                log.debug(tab_fin)
                log.debug(tab_fin.size)
                log.debug("===== TAB POS =============")
                log.debug(tab_pos)
                log.debug(tab_pos.size)
                log.debug("==================")

               # Clean tab_pos to remove bad value
                if np.any( tab_pos  < 9999 ) : 
                    if  tab_pos.size > 2 and tab_fin.size == 2 :
                        log.debug('Cas -1 concatenate')
                        new_position=np.concatenate(([tab_fin],tab_pos))
                    elif tab_pos.size == 2 and tab_fin.size == 2 :
                        log.debug('Cas 0 concatenate')
                        new_position=np.concatenate(([tab_fin],[tab_pos]))
                    elif tab_pos.size == 2 :
                        log.debug('Cas 1 concatenate')
                        new_position=np.concatenate((tab_fin,[tab_pos]))
                        log.debug('Cas 1 OK')
                    else :
                        log.debug('Cas 2 concatenate')
                        new_position=np.concatenate((tab_fin,tab_pos))
                        log.debug('Cas 2 ok')
                    log.debug("Concatenation ok")
                    shelf[type_f] = new_position
                else :
                    log.debug('Bad profiles')
            except:
                print "Pb with concatenation single"
                sys.exit(1)
        shelf.close()
