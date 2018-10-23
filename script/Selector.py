from __future__ import generators
import os, sys, string, shutil, re
from glob import glob
import numpy as np
import geojson
from geojson import MultiPoint
import json
from Loader import Loader
from nco.nco import Nco
#from nco import Nco
from QCcontrol import QCcontroller
import logging
import shelve
from Writer import Writer
import itertools
from Extractor import Extractor
from sytoolkit.sydate import SyDate
from collections import OrderedDict
#######################################################################################
## C.REGNIER Juillet 2014
## Class Selector to select profile : the selection depends on QC value and zoom
##			              possibility to store the positions in a file 
#######################################################################################

class Selector(object):

    """ Factory Class to run different objets depending on input type """

    def __init__(self, data_format, data_type, lon_min=-180, lon_max=180, lat_min=-90, lat_max=90, **kwargs):
        self.data_format = data_format
        self.data_type = data_type
        self.lonmin = lon_min
        self.lonmax = lon_max
        self.latmin = lat_min
        self.latmax = lat_max
    def factory(self, type):
        #return eval(type + "()")
        if type == "CORIOLIS" or type == "GODAE" or type == "CORIOLIS_RAW" or type == "GLOBCOLOUR":
            return SelectCorio(self.data_format, self.data_type, self.lonmin,\
                               self.lonmax, self.latmin, self.latmax)
        elif type == "Microwat":
            return Select(self.data_format, self.data_type)
        elif type == "GLOBAL_INPUT_DATA":
            return SelectListData()
        elif type == "GLOBAL_INPUT_MODEL_DATA":
            return SelectListModelData()
        else:
            print("Type not known %s " %(type))

class SelectListModelData(Selector):

    """
        Class to select the list of input Model files
    """
    def __init__(self):
        super(Selector)

    def run(self, param_dict, dateval, log):
        list = OrderedDict()

        data_type = param_dict['data_type']
        if data_type.lower() == "sst" or data_type.lower() == "ssthf":
            gridtype = "gridT"
        elif data_type.lower() == "sss":
            gridtype = "gridS"
        elif data_type.lower() == "sla":
            gridtype = "grid2D"
        elif data_type.lower() == "chloro":
            gridtype = "gridCHL"
        elif data_type.lower() == "aice":
            gridtype = "icemod"
        # loop on lead time
        for time in param_dict['lead_time']:
            list_tmp = []
            log.info('Lead Time  %s ' % (time))
            lead_fin = []
            lead_new = param_dict['lead_int']
            cl_config_use = param_dict['cl_config']
            ll_single = False
            if  time == 'forecast':
                if param_dict['cl_config'][0:6] == 'BIOMER':
                    lead_new = [time[0]+time[4]+time[6:8]]
                    log.info("Config biomer")
                else:
                    lead_new = [time[0]+time[4]+time[6:8]+element for element in lead_new ]
                lead_fin = lead_new
            elif time == 'persistence':
                if filter(lambda x: 'best_weekly' in x, param_dict['lead_time']):
                    lead_fin = ['pers']
                else:
                    lead_tmp = ['nwct']
                    lead_new = [time[:4]+element for element in lead_new[1:]]
                    lead_tmp.extend(lead_new)
                    lead_fin = lead_tmp
            elif time == 'best_estimate':
                cl_config_use = re.sub('Q', '', param_dict['cl_config'])
                lead_fin = ['hdct']
                log.info('Lead fin %s ' % (lead_fin))
            elif time == 'best':
                cl_config_use = re.sub('Q', '', param_dict['cl_config'])
                lead_fin = ['hdct_all']
                log.info('Lead fin %s ' % (lead_fin))
                ll_single = True
            elif time == 'best_weekly':
                lead_fin = ['hdct', 'nwct']
            elif time == 'climatology':
                lead_fin = ['clim']
            else:
                log.error('Lead time %s not expected ' %(time))
            config_d = re.sub("V", "QV", param_dict['cl_config'])
            ## Find and Load the good file
            ind = 0
            for directory in lead_fin:
                modele = cl_config_use
                param_dict['modele'] = modele
                if directory == 'hdct':
                    if param_dict['daily_pref'] == '7dAV':
                        dirmodel_new = param_dict['dirmodel']+"HINDCAST/"
                    else:
                        dirmodel_new = param_dict['dirmodel']+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
                elif directory == 'hdct_all':
                    dirmodel_new = dirmodel+"/"
                elif directory == 'fcst' :
                    if param_dict['daily_pref'] == '7dAV':
                        dirmodel_new = param_dict['dirmodel']+"FORECAST/"
                    else:
                        dirmodel_new = param_dict['dirmodel']+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
                else :
                    dirmodel_new = param_dict['dirmodel']+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
                ## Compute date
                if param_dict['daily_pref'] == '7dAV':
                    jdatemin = SyDate(str(dateval))
                    daytogo = 2-jdatemin.weekday()
                    if daytogo > 0:
                        first_date = jdatemin.goforward(daytogo)
                    else:
                        nbdate = 14
                        daytogo2 = nbdate+daytogo
                        first_date = jdatemin.goforward(daytogo2)
                    daterun = first_date
                    date1 = daterun.gobackward(14)
                    date2 = daterun.gobackward(7)
                    if directory == 'hdct':
                        template = modele+'_'+param_dict['daily_pref']+'_'+ \
                        str(date1)+'_'+ str(date2)+'_' + gridtype+'_R'+str(daterun)
                    elif directory == 'fcst':
                        template = modele+'_'+param_dict['daily_pref']+'_'+ \
                        str(date1)+'_'+ str(date2)+'_' + gridtype+'_R'+str(date1)
                    elif directory == 'clim' and param_dict['data_type'].lower() == 'chloro':
                        print("climatology")
                        dirmodel_new = param_dict['dirclim']
                        datev = SyDate(str(dateval))
                        if int(datev.month) < 10 and int(datev.day) < 10:
                            template = '19980'+str(datev.month)+'0'+str(datev.day)
                        elif datev.month < 10 and datev.day > 9:
                            template = '19980'+str(datev.month)+str(datev.day)
                        elif datev.month > 9 and datev.day < 10:
                            template = '1998'+str(datev.month)+'0'+str(datev.day)
                        else:
                            template = '1998'+str(datev.month)+str(datev.day)
                    list_file = glob(dirmodel_new+template+"*.nc")
                else:
                    log.info('directory %s' % (dirmodel_new+directory))
                    list_file = glob(dirmodel_new+directory+"/"+modele+"_"+ \
                    param_dict['daily_pref']+"_"+dateval+"*_*"+gridtype+"*.nc")
                if not list_file:
                    log.error("Repertory %s" % (dirmodel_new))
                    log.error("File missing for %s" %(directory))
                    ll_miss = True
                    sys.exit(1)
                log.info('dirmodel  %s ' % (param_dict['dirmodel']))
                log.info('directory and file  %s %s ' % (directory, list_file[0]))
                list[directory] = list_file
        return list

class SelectListData(Selector):

    """
        Class to select the list of input files
    """

    def __init__(self):
        super(Selector)

    def run(self, param_dict, daterun, log):
        if param_dict['zoom'] or param_dict['data_origin'] == 'GODAE':
            log.info('========================================================')
            log.info('              DATE Selection and extraction             ')
            log.info('========================================================')
            log.info('Prefix  %s ' %(param_dict['prefix_data']))
            list_files = Extractor().factory(param_dict['prefix_data']).run(param_dict['date1'],\
            param_dict['date2'],param_dict['dirdata'],param_dict['dirwork'],param_dict['data_type'],param_dict['template'])
        elif param_dict['do_decomp']:
            log.info('do decomp')
            list_files = Extractor().factory(param_dict['prefix_data']).run(
                param_dict['date1'], param_dict['date2'], param_dict['dirdata'],\
                param_dict['dirwork'], param_dict['data_type'], param_dict['template'], param_dict['prefix_data'])
        else:
            log.info('========================================================')
            log.info('              DATE Selection and extraction  %s         ' %(param_dict['prefix_data'])) 
            log.info('========================================================')
            list_files = Extractor().factory(param_dict['prefix_data']).run_list(param_dict, daterun)
        if not list_files:
            log.error('Missing files')
            sys.exit(1)
        else:
            log.info('List Files  %s ' % (list_files))
        return list_files

class Select(Selector):
    def __init__(self, data_format, data_type, **kwargs):
        super(Selector, self).__init__(**kwargs)
        self.data_format = data_format
        self.data_type = data_type
    def store_pos(self, tab_pos, type_f, file_db):
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger("store_pos")
        ## Level of logging output
        log.setLevel(logging.INFO)
        # Open a shelve file if not exist
        if not os.path.isfile(file_db):
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
                print("Pb with concatenation store_pos")
                sys.exit(1)
        shelf.close()

class SelectCorio(Selector):

    """ Class for Coriolis files """

    def __init__(self, data_format, data_type, lon_min, lon_max, lat_min, lat_max, **kwargs):
        super(Selector, self).__init__(**kwargs)
        self.data_format = data_format
        self.data_type = data_type
        self.lonmin = lon_min
        self.lonmax = lon_max
        self.latmin = lat_min
        self.latmax = lat_max
        if data_format == "NC_CORIO":
            self.dimprof = 'N_PROF'
        elif data_format == "NC_GODAE":
            self.dimprof = 'numobs'

    def run(self, fichier, zoom, do_qc, TYPEDATA, qc_level):
        logging.basicConfig(format='%(asctime)s %(message)s')
        log = logging.getLogger(" Run Selector")
        ## Level of logging output
        #log.setLevel(logging.INFO)
        log.setLevel(logging.ERROR)
        # Read position of profiles
        position = Loader.factory(self.data_format).read_pos(fichier)
        nb_profs = len(position[:, 0])
        log.info('Nb profiles : %i' %(nb_profs))
        if do_qc:
            log.info('Run with QC')
            log.info('Type of DATA %s ' %(self.data_type))
            # Compute QC flag
            #QCflag=QCcontroller(self.data_type).factory(TYPEDATA).QCrun(fichier,qc_level)
            #QCobj=QCcontroller(self.data_type,TYPEDATA).factory()
            QCflag=QCcontroller(self.data_type,TYPEDATA).factory().QCrun(fichier, qc_level)
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
        #log.setLevel(logging.INFO)
        log.setLevel(logging.ERROR)
        ## Nco constructor
        nco = Nco()
        il_ind=0
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
                print("Pb with concatenation store_pos")
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
            try :
                tab_fin=shelf[type_var]
                tab_fin=np.concatenate((tab_fin,tab_pos_new))
                shelf[type_var] = tab_fin
            except :
                print("Pb with concatenation in GLO")
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
        try:
            ll_exist = shelf[type_f]
        except:
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
                print("Pb with concatenation single")
                sys.exit(1)
        shelf.close()
