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
#from sydate import SyDate
from sytoolkit.sydate import SyDate
from collections import OrderedDict
#######################################################################################
## C.REGNIER Juillet 2014
## Class Selector to select profile : the selection depends on QC value and zoom
##              possibility to store the positions in a file
#######################################################################################

class Selector(object):

    """ Factory Class to run different objets depending on input type """

    def __init__(self, data_format, data_type, log,
                 lon_min=-180, lon_max=180, lat_min=-90,
                 lat_max=90, **kwargs):
        self.data_format = data_format
        self.data_type = data_type
        self.log = log
        self.lonmin = lon_min
        self.lonmax = lon_max
        self.latmin = lat_min
        self.latmax = lat_max

    def factory(self, type):
        #return eval(type + "()")
        if type == "CORIOLIS" or type == "GODAE" or \
           type == "CORIOLIS_RAW" or type == "GLOBCOLOUR":
            return SelectCorio(self.data_format, self.data_type, self.lonmin,\
                               self.lonmax, self.latmin, self.latmax)
        elif type == "Microwat":
            return Select(self.data_format, self.data_type)
        elif type == "GLOBAL_INPUT_DATA":
            return SelectListData(self.log)
        elif type == "GLOBAL_INPUT_MODEL_DATA":
            return SelectListModelData(self.log)
        else:
            print("Type not known %s " %(type))

    def get_template_alleges_new(self, dateval, param_dict):

        """ Get the template for new model inputs  """

        jdatemin = SyDate(dateval)
        type_run = param_dict['type_run']
        sys.exit(1)


    def get_template_alleges(self, dateval, param_dict):

        """ Get the template for model inputs  """

        jdatemin = SyDate(dateval)
        type_run = param_dict['type_run']
        ## Find next daterun on Wednesday
        daytogo = 2-jdatemin.weekday()
        if daytogo > 0:
            first_date = jdatemin.goforward(daytogo)
        else:
            if type_run == 'RTR' or type_run == 'REA':
                nbdate = 7
            elif type_run == 'HINDCAST':
                nbdate = 14
            daytogo2 = nbdate+daytogo
            first_date = jdatemin.goforward(daytogo2)
        daterun = first_date
        if type_run == 'RTR' or type_run == 'REA':
            date1 = daterun.gobackward(7)
            date2 = daterun
        elif type_run == 'HINDCAST':
            date1 = daterun.gobackward(14)
            date2 = daterun.gobackward(7)
        if param_dict['data_type'] == 'profile':
            depthval='50.0'
            typeval='.end.'
            type_out='END'
            dateval=daterun
        elif param_dict['data_type'] == 'SLA':
            depthval='01.0'
            typeval='.run.'
            type_out='RUN'
        elif param_dict['data_type'] == 'SST':
            depthval='01.0'
            typeval='.run.'
            type_out='RUN'
        elif param_dict['data_type'] == 'aice':
            depthval='01.0'
            typeval='.run.'
            type_out='RUN'
        else:
            depthval='01.0'
            type_out='RUN'

        template = []
        for i, val in enumerate(param_dict['gridtype_light']):
            template.append(param_dict['dirmodel_light']+'ALLEGES_'+type_run.lower()+\
                            '_'+str(date1)+'_'+str(date2)+'_R'+str(daterun)+ \
                            '/'+type_out+'/'+val+'.d'+\
                            str(dateval)+typeval+str(depthval))
        self.log.debug("Template allege : {} ".format(template))
        return template

class SelectListModelData(Selector):

    """
        Class to select the list of input Model files
    """
    def __init__(self, log):
        super(Selector)
        self.log = log
        self.list_ice=['sit-legos','snow-legos','sivolu','snvolu','siconc','kaku',
                       'kaku_unc','kakuyear','kakuyear_unc','kakuyearsh','kakuyearsh_unc',
                       'kakush','kakush_unc']

    def set_gridtype(self, param_dict):
        self.data_type = param_dict['data_type']
        if self.data_type.lower() == "sst" or self.data_type.lower() == "ssthf":
            param_dict['gridtype'] =  [param_dict['gridtemp']]
            param_dict['gridtype_clim'] = ["TEMP"]
            param_dict['gridtype_light'] = ["TN.B"]
            param_dict['varname_clim'] = ["temperature"]
        elif self.data_type.lower() == "sss":
            param_dict['gridtype'] =  [param_dict['gridsal']]
            param_dict['gridtype_clim'] = ["SAL"]
            param_dict['gridtype_light'] = ["SN.B"]
            param_dict['varname_clim'] = ["salinity"]
        elif self.data_type.lower() == "sla":
            param_dict['gridtype'] = [param_dict['grid2DT']]
            param_dict['gridtype_light'] = ["SLA.B"]
        elif self.data_type.lower() == "chloro":
            param_dict['gridtype'] = ["chl"]
        elif self.data_type.lower() == "nitrate":
            param_dict['gridtype'] = ["no3"]
        elif self.data_type.lower() == "ph":
            param_dict['gridtype'] = ["ph"]
        elif self.data_type.lower() == "aice":
            param_dict['gridtype'] = [param_dict['gridice']]
        elif self.data_type.lower() == "drifter_filtr" or self.data_type.lower() == "drifter":
            param_dict['gridtype'] = [param_dict['gridu'], param_dict['gridv']]
            param_dict['gridtype_clim'] = ["current"]
        elif self.data_type.lower() == "profile":
            param_dict['gridtype'] = [param_dict['gridtemp'],param_dict['gridsal']]
            param_dict['gridtype_clim'] = ["TEMP", "PSAL"]
            param_dict['gridtype_light'] = ["TN.B", "SN.B"]
        elif self.data_type.lower() == "current":
            #param_dict['gridtype'] = ["gridU", "gridV"]
            param_dict['gridtype'] = ["3DU-uo", "3DV-vo"]
        elif self.data_type.lower() in self.list_ice:
            param_dict['gridtype'] = param_dict['gridice']
        self.typemod = param_dict['cl_typemod'].lower()
        if self.typemod == "pgn":
            self.dirmodel = param_dict['dirmodel_pgn']
        elif self.typemod == "allege" or "allege_new" \
             or self.typemod == "allege_now":
            self.dirmodel = param_dict['dirmodel_light']
        elif self.typemod == "2ease":
            self.dirmodel = param_dict['dirmodel_pgn']
        else:
            raise ('typemod not known')
        return param_dict

    def set_leadtime(self, time, param_dict):
        lead_fin = []
        lead_new = param_dict['lead_int']
        lead_new2 = param_dict['lead_int2']
        cl_config_use = param_dict['cl_config']
        ll_single = False
        if  time == 'forecast':
            if param_dict['cl_config'][0:6] == 'BIOMER':
                lead_new = [time[0]+time[4]+time[6:8]]
                self.log.debug("Config biomer")
            else:
                lead_new = [time[0]+time[4]+time[6:8]+element for element in lead_new ]
            lead_fin = lead_new
        elif time == 'persistence':
            self.log.info(param_dict['lead_time'])
            #if filter(lambda x: 'best_weekly' in x, param_dict['lead_time']):
            if 'best_weekly' in param_dict['lead_time']:
                lead_fin = ['pers']
            else:
                lead_tmp = ['nwct']
                lead_new = [time[:4]+element for element in lead_new[1:]]
                lead_tmp.extend(lead_new)
                lead_fin = lead_tmp
        elif time == 'best_estimate':
            if param_dict['cl_config'][0:6] == 'BIOMER':
                #lead_fin = [time[0]+time[4]+time[6:8]]
                lead_fin = ['hdct']
                self.log.debug("Config biomer")
            else:
                cl_config_use = re.sub('Q', '', param_dict['cl_config'])
                lead_fin = ['hdct']
                self.log.debug('Lead fin %s ' % (lead_fin))
        elif time == 'best':
            cl_config_use = re.sub('Q', '', param_dict['cl_config'])
            lead_fin = ['hdct_all']
            self.log.debug('Lead fin %s ' % (lead_fin))
            ll_single = True
        elif time == 'best_weekly':
            lead_fin = ['hdct', 'nwct']
        elif time == 'rtr':
            lead_fin = ['rtr']
        elif time == 'climatology':
            lead_fin = ['clim']
        elif time == 'bathymetrie':
            lead_fin = ['bathy']
        elif time == 'clim_lev13_A5B2':
            lead_fin = ['clim']
            type_clim = "WOA13_A5B2"
            dirclim = param_dict.get('climato','DIRLEV')
            type_clim = "WOA13_A5B2"
        elif time == 'smoc':
            lead_fin = ['smoc']
        elif time == 'smoc_fcst':
            lead_fin = ['fcst'+element for element in lead_new2 ]
            self.dirmodel_new = self.dirmodel+'DAILY/SMOC/'
        elif time == 'tides':
            lead_fin = ['tides']
        elif time == 'stokes':
            lead_fin = ['stokes']
        elif time == 'stokes_fcst':
            lead_fin = ['fcst'+element for element in lead_new2 ]
            self.dirmodel_new = self.dirmodel+'DAILY/SMOC/'
        else:
            self.log.error('Lead time %s not expected ' %(time))
            sys.exit(1)
        self.config_d = re.sub("V", "QV", param_dict['cl_config'])
        self.config_d = re.sub("V", "QV", param_dict['cl_conf'])
        self.modele = cl_config_use
        param_dict['modele'] = self.modele
        self.leadtime = lead_fin
        return param_dict

    def run(self, param_dict, dateval):
        list = OrderedDict()
        param_dict = self.set_gridtype(param_dict)
        self.log.info(f'Data type {self.data_type}')
        MONTH = str(dateval)[4:6]
        self.log.info(f"Grid type {param_dict['gridtype']} {self.dirmodel=}")
        # loop on lead time
        new_naming = False
        if  param_dict['naming'] == 'new':
            new_naming = True
        for time in param_dict['lead_time']:
            list_tmp = []
            self.log.debug(f'Lead Time {time}')
            lead_new = param_dict['lead_int']
            lead_new2 = param_dict['lead_int2']
            cl_config_use = param_dict['cl_config']
            ll_single = False
            param_dict = self.set_leadtime(time, param_dict)
            ## Find and Load the good file
            ind = 0
            ll_miss = False
            for directory in self.leadtime:
                self.log.debug("directory {}".format(directory))
                ll_miss_rep = False
                datev = SyDate(str(dateval))
                year = str(datev.year)
                month_up = datev.month + 1
                ## Compute date
                if param_dict['data_origin'] == 'GLOBCOLOUR' and directory != 'clim':
                    if directory == 'hdct' and param_dict['daily_pref'] == '7dAV':
                        dirmodel_new = param_dict['dirmodel']+"HINDCAST/"
                    elif directory == 'hdct' and param_dict['daily_pref'] == '1dAV':
                        dirmodel_new = param_dict['dirmodel']
                    elif directory == 'fcst' and param_dict['daily_pref'] == '7dAV':
                        dirmodel_new = param_dict['dirmodel']+"FORECAST/"
                    elif directory == 'fcst' and param_dict['daily_pref'] == '1dAV':
                        self.log.debug('define forecast path')
                        sys.exit()
                else:
                    if directory == 'hdct':
                        if param_dict['daily_pref'] == '7dAV':
                            dirmodel_new = self.dirmodel+"HINDCAST/"
                        else:
                            if self.data_type.lower() == "nitrate" or self.data_type.lower() == "ph" or  self.data_type.lower() == "chl" :
                                dirmodel_new = self.dirmodel
                            else:
                                if param_dict['type_run'] == "REA":
                                    dirmodel_new = self.dirmodel+year+'/'+MONTH+'/'
                                else:
                                    config = param_dict['cl_conf']
                                    self.config_d = re.sub("V", "QV", config)
                                    # PSY4
                                    if new_naming :
                                        # GLO12V4
                                        dirmodel_new = f'{self.dirmodel}HEBDO/{config[0:5]}/{config.lower()}/'
                                    else:
                                        #dirmodel_new = self.dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
                                        dirmodel_new = self.dirmodel+"HEBDO/"+self.modele[:4]+"/"+self.modele.lower()+"/"
                    elif directory == 'hdct_all' and self.typemod == 'allege':
                        self.log.debug("lightout type")
                        dirmodel_new = self.dirmodel+"/"
                        template = self.get_template_alleges(dateval,
                                                             param_dict)
                    elif directory == 'hdct_all':
                        dirmodel_new = param_dict['dirmodel']+"/"
                        self.log.debug("directory {}".format(dirmodel_new))

                    elif self.typemod == 'allege_new' or self.typemod == 'allege_now':
                        self.log.debug("lightout new type")
                        dirmodel_new = self.dirmodel+"/"
                        template = self.get_template_alleges_new(dateval,
                                                                 param_dict)
                    elif directory == 'fcst':
                        self.log.debug("directory fcst !!!")
                        if param_dict['daily_pref'] == '7dAV':
                            dirmodel_new = self.dirmodel+"FORECAST/"
                        else:
                            if new_naming :
                                # Case GLO12
                                dirmodel_new = f'{self.dirmodel}DAILY/{config[0:5]}/{config.lower()}/'
                            else:
                                # Case PSY4
                                dirmodel_new = self.dirmodel+"DAILY/"+self.modele[:5]+"/"+self.modele.lower()+"/"
                    elif param_dict['data_origin'] == 'GLOBCOLOUR' and directory == 'clim':
                        dirmodel_new = param_dict['dirclim']
                    elif directory == "smoc" or directory == "tides" or directory == "stokes":
                        dirmodel_new = self.dirmodel+'DAILY/SMOC/nwct/'
                        self.log.debug('Directory smoc: {}'.format(dirmodel_new))
                    elif directory == "bathy":
                        dirmodel_new =  param_dict['bathy_file']
                    elif time == 'smoc_fcst' or time == 'stokes_fcst':
                        dirmodel_new = self.dirmodel+'DAILY/SMOC/'
                        self.log.debug('Directory smoc/stokes fcst: {}'.format(dirmodel_new))
                    elif directory == "clim":
                        dirmodel_new =  param_dict['dirclim']
                    else:
                        if new_naming :
                            ## Case GLO12
                            dirmodel_new = f'{self.dirmodel}DAILY/{config[0:5]}Q/{self.config_d.lower()}/'
                        else:
                            # Case PSY4
                            dirmodel_new = self.dirmodel+"DAILY/"+self.modele[:5]+"/"+self.modele.lower()+"/"
                if datev.month < 10: month = '0' + str(datev.month)
                else: month = str(datev.month)
                if month_up < 10: month_up = '0' + str(month_up)
                else: month_up = str(month_up)
                if datev.day < 10: day = '0' + str(datev.day)
                else: day = str(datev.day)
                if param_dict['data_origin'] == 'GLOBCOLOUR' and param_dict['daily_pref'] == '7dAV':
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
                    list_file = []
                    if directory == 'hdct':
                        for i in range(len(param_dict['gridtype'])):
                            template = self.modele+'_'+param_dict['daily_pref']+'_'+ \
                            str(date1)+'_'+ str(date2)+'_' + param_dict['gridtype'][i]+'_R'+str(daterun)
                            list_file_tmp = glob(self.dirmodel_new+template+"*.nc")
                            list_file.extend(list_file_tmp)
                    elif directory == 'fcst':
                        for i in range(len(param_dict['gridtype'])):
                            template = self.modele+'_'+param_dict['daily_pref']+'_'+ \
                            str(date1)+'_'+ str(date2)+'_' + param_dict['gridtype'][i]+'_R'+str(date1)
                            list_file_tmp = glob(self.dirmodel_new+template+"*.nc")
                            list_file.extend(list_file_tmp)
                    elif directory == 'clim' and param_dict['data_type'].lower() == 'chloro':

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
                elif param_dict['data_origin'] == 'GLOBCOLOUR' and param_dict['daily_pref'] == '1dAV':
                    if directory == 'clim':
                        template = '1998'+month+day
                        # Code Monthly case  template = '1998'+month
                        self.log.debug('directory clim bio {}'.format(dirmodel_new+"/"+template+"*.nc"))
                        list_file = glob(dirmodel_new+"/"+template+"*.nc")
                    else:
                        #directory = dirmodel_new+'/'+year+'/'+month+'/'
                        dir_input = dirmodel_new
                        list_file = glob(dir_input+self.modele+"_"+ \
                        param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['varname'][0]+"*.nc")
                        if not list_file:
                            if datev.month < 9:
                                month2 = '0' + str(datev.month+1)
                                year2 = str(datev.year)
                            elif datev.month == 12:
                                month2 = '01'
                                year2 = str(datev.year+1)
                            else:
                                month2 = str(datev.month+1)
                                year2 = str(datev.year)
                            list_file = glob(dirmodel_new+"/"+year2+'/'+month2+'/'+self.modele+"_"+ \
                            param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['varname'][0]+"*.nc")
                else:
                    if self.typemod == "pgn":
                        if directory == "clim":
                            if self.data_type.lower() == "drifter_filtr" or self.data_type.lower() == "drifter" \
                                    or self.data_type.lower() == "current":
                                dirmodel_new = param_dict['dirclim']
                                list_file = glob(dirmodel_new+"/*_monthlymeans.nc")
                                list_file.append(glob(dirmodel_new+"/*monthlymeans.nc")[0])
                            else:
                                if param_dict['type_run'] == "REA":
                                    for i in range(len(param_dict['gridtype'])):
                                        list_file_tmp=glob.glob(dir_clim+"/"+type_clim+"_M"+MONTH+"_*"+\
                                                gridtype_clim+".nc")
                                       # list_file_tmp = glob(dirmodel_new+ "/"+self.modele+"_"+ \
                                       # param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['gridtype'][i]+"*.nc")
                                        list_file.extend(list_file_tmp)
                                else:
                                    list_file = glob(dirmodel_new+"/"+type_clim+"_M"+MONTH+"_*"+\
                                    param_dict['gridtype_clim']+".nc")
                        else:
                            list_file = []
                            if self.data_type.lower() == "nitrate" or self.data_type.lower() == "ph" or  self.data_type.lower() == "chl":
                                for i in range(len(param_dict['gridtype'])):
                                    list_file_tmp = glob(dirmodel_new+"/"+year+"/"+month+"/"+self.modele+"_"+ \
                                    param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['gridtype'][i]+"*.nc")
                                    if not list_file_tmp:
                                        list_file_tmp = glob(dirmodel_new+"/"+year+"/"+month_up+"/"+self.modele+"_"+ \
                                            param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['gridtype'][i]+"*.nc")

                                    list_file.extend(list_file_tmp)

                            else:
                                self.log.debug(f"Type run {param_dict['type_run']}")
                                if param_dict['type_run'] == "REA":
                                    for i in range(len(param_dict['gridtype'])):
                                        list_file_tmp = glob(dirmodel_new+ "/"+self.modele+"_"+ \
                                        param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['gridtype'][i]+"*.nc")
                                        list_file.extend(list_file_tmp)
                                elif param_dict['type_run'] == "free":
                                    list_file_tmp = glob(dirmodel_new+self.modele+"_"+param_dict['daily_pref']+"_*_"+param_dict['gridtype']+\
                                                '_'+dateval+"*.nc")
                                    list_file.extend(list_file_tmp)
                                elif param_dict['type_run'] == "RTR":
                                    #print(dirmodel_new + self.modele + "_" + param_dict['daily_pref'] + "_" +\
                                    #      dateval+ '*' +param_dict['gridtype'] + "*.nc")
                                    #list_file_tmp = glob(dirmodel_new + self.modele + "_" + param_dict['daily_pref'] + "_" +\
                                    #                dateval+ '*' +param_dict['gridtype'] + "*.nc")
                                    #list_file.extend(list_file_tmp)
                                    for i, grid in enumerate(param_dict['gridtype']):
                                        list_file_tmp = glob(f"{dirmodel_new}{self.modele}_{param_dict['daily_pref']}_"
                                                              f"{dateval}*{param_dict['gridtype'][i]}*.nc")
                                        list_file.extend(list_file_tmp)
                                        #print(f"{dirmodel_new}{self.modele}_{param_dict['daily_pref']}_"
                                        #      f"{dateval}*{param_dict['gridtype'][i]}*.nc")
                                    self.log.info(f'{list_file=}')
                                else:
                                    if directory == "smoc" or directory == "stokes" or directory == "tides":
                                        for i in range (2):
                                            list_file_tmp = glob(dirmodel_new+"SMOC_"+dateval+"*.nc")
                                            list_file.extend(list_file_tmp)
                                    elif time == "smoc_fcst":
                                        for i in range (2):
                                            list_file_tmp = glob(dirmodel_new+directory+"/SMOC_"+dateval+"*.nc")
                                            #print (dirmodel_new+directory+"/SMOC_"+dateval+"*.nc")
                                            list_file.extend(list_file_tmp)
                                        directory="smoc_"+directory
                                    elif time == "stokes_fcst":
                                        for i in range (2):
                                            list_file_tmp = glob(dirmodel_new+directory+"/SMOC_"+dateval+"*.nc")
                                            #print (dirmodel_new+directory+"/SMOC_"+dateval+"*.nc")
                                            list_file.extend(list_file_tmp)
                                        directory="stokes_"+directory
                                    elif time == "bathymetrie":
                                        list_file_tmp = glob(dirmodel_new)
                                        list_file.extend(list_file_tmp)
                                    else:
                                        #print(f'Passe la {self.modele=}')
                                        ## Oper Case
                                        for i in range(len(param_dict['gridtype'])):
                                            #list_file_tmp = glob(dirmodel_new+directory+"/"+self.modele+"_"+ \
                                            #param_dict['daily_pref']+"_"+dateval+"*_*"+param_dict['gridtype'][i]+"*.nc")
                                            #print(f'{dirmodel_new}{directory}/{self.modele}_{param_dict["daily_pref"]}_{dateval}*_*{param_dict["gridtype"][i]}*.nc')
                                            list_file_tmp = glob(f'{dirmodel_new}{directory}/{self.modele}_{param_dict["daily_pref"]}_{dateval}*_*{param_dict["gridtype"][i]}*.nc')
                                            list_file.extend(list_file_tmp)
                                self.log.debug(list_file)
                    elif self.typemod == "allege":
                        if directory == "clim":
                            list_file = []
                            dirmodel_new = param_dict['dirclim']
                            for i in range(len(param_dict['gridtype_clim'])):
                                list_file_tmp = glob(dirmodel_new+"/"+type_clim+"_M"+MONTH+"_*"+\
                                param_dict['gridtype_clim'][i]+".nc")
                                list_file.extend(list_file_tmp)
                            self.log.debug('Liste File clim :{}'.format(list_file))

                        else:
                            self.log.debug('Liste template')
                            list_file = template
                    elif self.typemod == "2ease":
                        list_file = []
                        if param_dict['type_run']== "kaku":
                            list_file_tmp = glob(dirmodel_new+"*"+dateval[:6]+"*.nc")
                            self.log.debug('File {}'.format(dirmodel_new+"*"+dateval[:6]+"*.nc"))
                            list_file.extend(list_file_tmp)
                        else:
                            raise ("type not known for 2ease files")
                    else:
                        self.log.debug('directory %s' % (dirmodel_new+'/'+year+'/'+month))
                        list_file = glob(dirmodel_new+"/"+year+'/'+month+'/'+self.modele+"_"+ \
                        param_dict['daily_pref']+"_"+dateval+"*_*"+gridtype+"*.nc")
                        if not list_file:
                            if datev.month < 9:
                                month2 = '0' + str(datev.month+1)
                                year2 = str(datev.year)
                            elif datev.month == 12:
                                month2 = '01'
                                year2 = str(datev.year+1)
                            else:
                                month2 = str(datev.month+1)
                                year2 = str(datev.year)
                            list_file = glob(dirmodel_new+"/"+year2+'/'+month2+'/'+self.modele+"_"+ \
                            param_dict['daily_pref']+"_"+dateval+"*_*"+gridtype+"*.nc")
                        #print ("Type not define %s" %(cl_typemod.lower()))
                        #sys.exit(1)
                    self.log.debug('directory %s' % (dirmodel_new))

                if not list_file:
                    self.log.error("Repertory %s" % (dirmodel_new))
                    self.log.error("File missing for %s" %(directory))
                    ll_miss_rep = True
                    continue
                    #sys.exit(1)
                self.log.debug('dirmodel  %s ' % (self.dirmodel))
                if not ll_miss_rep : self.log.debug('directory and file  %s %s ' % (directory, list_file[0]))
                list[directory] = list_file
        if not list:
            self.log.error("No repertories")
            ll_miss = True
        else:
            self.log.info(f'List input files {list}')
        self.log.debug(f'List input files {list}')
        return list, ll_miss

class SelectListData(Selector):

    """
        Class to select the list of input files
    """

    def __init__(self, log):
        super(Selector)
        self.log = log

    def run(self, param_dict, daterun):
        """
         Create list of input data for a defined daterun
         Parameters
        -----------------------
        param_dict : dictionnary of parameters
        daterun : datevalue
        Returns
        -----------------------
        list_files : 
        """
        ll_miss = False
        if param_dict['zoom'] or param_dict['data_origin'] == 'GODAE':
            self.log.debug('========================================================')
            self.log.debug('              DATE Selection and extraction zoom or GODAE ')
            self.log.debug('========================================================')
            self.log.debug(f"Prefix {param_dict['prefix_data']}")
            #list_files = Extractor().factory(param_dict['prefix_data']).run(param_dict['date1'],\
            #param_dict['date2'],param_dict['dirdata'],param_dict['dirwork'],param_dict['data_type'],param_dict['template'])
            list_files = Extractor(self.log).factory(param_dict['prefix_data']).run(daterun,param_dict['dirdata'],\
                         param_dict['dirwork'],param_dict['data_type'],param_dict['template'], len(param_dict['lead_int']))
        elif param_dict['do_decomp']:
            self.log.debug('do decomp {} '.format(param_dict['prefix_data']))
            list_files = Extractor(self.log).factory(param_dict['prefix_data']).run(
                param_dict['date1'], param_dict['date2'], param_dict['dirdata'],\
                param_dict['dirwork'], param_dict['data_type'], param_dict['template'], param_dict['prefix_data'])
        elif param_dict['over']:
            self.log.debug('inside over {} '.format(param_dict['prefix_data']))
            list_files = Extractor(self.log).factory(param_dict['prefix_data']).run_over(
                param_dict['date1'], param_dict['date2'], param_dict['diroutput'],\
                param_dict['dirwork'], param_dict['data_type'], param_dict['template'], param_dict['prefix_data'])
        else:
            self.log.debug('========================================================')
            self.log.debug('              DATE Selection and extraction  %s         ' %(param_dict['prefix_data']))
            self.log.debug(f" Prefix Data {param_dict['prefix_data']}")
            self.log.debug('========================================================')
            list_files = Extractor(self.log).factory(param_dict['prefix_data']).run_list(param_dict, daterun)
        if not list_files:
            self.log.error(f"Missing Obs files {param_dict['prefix_data']}"
                           f" {param_dict['dirdata']} {param_dict['dirwork']}"
                           f"{param_dict['prefix_data']}")
            ll_miss = True
        else:
            self.log.debug('List Files  %s ' % (list_files))
        return list_files, ll_miss

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
        try:
            ll_exist = shelf[type_f]
        except:
            log.debug("Create %s" %(type_f))
            shelf[type_f] = tab_pos
            ll_exist = []
        if len(ll_exist) > 0:
            try:
                log.debug("Tab_fin")
                tab_fin = shelf[type_f]
                log.debug("concatenation")
                tab_fin = np.concatenate((tab_fin,tab_pos))
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
