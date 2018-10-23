from __future__ import generators
import os
import sys
import string
import shutil
from glob import glob
import re
import numpy as np
import netCDF4
import geojson
from geojson import MultiPoint
import json
if sys.version_info[0] >= 3:
    import configparser as ConfigParser
else:
    import ConfigParser
import operator
import getopt
import datetime as dt
from datetime import date
from sytoolkit.sydate import SyDate
from Logger import Logger
from calendar import monthrange
from Reader import read_lightout

##############################################################
# C.REGNIER Juin 2014
# Class Loader to load different type of file with a pattern factory
##############################################################


class Loader(object):

    """Create factory for the loader"""

    @staticmethod
    def factory(type):
        """
            Factory for different type of loaders
        """
        # return eval(type + "()")
        if type == "NC_CORIO": return LoaderNCcorio()
        if type == "NC_CORIO_ORIGIN": return LoaderNCcorio()
        if type == "NC_CHLORO": return LoaderNCChloro()
        if type == "NC_CLIM": return LoaderNCClim()
        if type == "NC_GODAE": return LoaderNCgodae()
        if type == "Microwat": return LoaderSyntheticValue()
        if type == "SSS_ship": return LoaderSSSVessel()
        if type == "ASCII": return AsciiLoader()
        if type == "LIST": return ListWriter()
        if type == "NML": return NmlLoader()
        if type == "DAT": return ColocLoader()
        if type == "INPUT": return InputLoader()
        if type == "INPUT_DATA": return InputDataLoader()
        if type == "PGN_coords": return PGN_coords_Loader()
        if type == "alleges_coords": return alleges_coords()
        assert 0, "Format not known: " + type

    def generic_read_pos_and_value(self,filename, var_lon, var_lat, varname):
        rla_lon, rla_lat, nc = self.generic_read_pos(filename, var_lon, var_lat)
        _FillValue = nc.variables[varname]._FillValue
        #rla_value = nc.variables[varname][0, :, :]
        #nb_obs = int(np.shape(rla_value.flatten())[0])
        #print len(np.shape(rla_value))
        #sys.exit(1)
        #return rla_lon, rla_lat, rla_value, nb_obs, _FillValue
        return rla_lon, rla_lat, _FillValue, nc

    def generic_read_pos(self, filename, var_lon, var_lat):
        nc = netCDF4.Dataset(filename, 'r')
        rla_lon = nc.variables[var_lon][:]
        rla_lat = nc.variables[var_lat][:]
        return rla_lon, rla_lat, nc


class InputDataLoader(Loader):
    """
        Function to read input data
    """

    def run(self, param_dict, fichier, log):
        # Extract if necessary and read position of input data
        ll_interp = True
        if param_dict['do_qc'] or param_dict['zoom']:
            if param_dict['zoom']:
                log.info("REGIONAL MODE => AREA SELECTION ")
                selector = Selector(param_dict['data_format'],
                                    param_dict['data_type'], param_dict['lon_min'],
                                    param_dict['lon_max'], param_dict['lat_min'],
                                    param_dict['lat_max']).factory(param_dict['data_origin'])
                [new_position, list_index] = selector.run(fichier, param_dict['zoom'],
                                                          param_dict['do_qc'], param_dict['data_origin'], param_dict['qc_level'])
                if list_index:
                    selector.write(fichier, list_index, param_dict['dirtmp'])
                    file_new = 'ext-'+os.path.basename(fichier)
                    os.remove(fichier)
                    fichier = param_dict['dirwork'] + file_new
                    lon, lat, obs_value = Loader.factory(
                        param_dict['data_format']).read_pos_and_value(fichier)
                else:
                    os.remove(fichier)
                    log.info('No position find in %s for the zoom ' %
                             (fichier))
                    ll_file_interp = False
        else:
            # Case Global without qc
            log.info("GLOBAL MODE => SELECT ALL ")
            selector = Selector(param_dict['data_format'], param_dict['data_type']).factory(
                param_dict['data_origin'])
            if param_dict['data_origin'] == "Microwat":
                lon, lat, juld = Loader.factory(
                    param_dict['data_format']).read_pos(fichier)
            else:
                lon, lat, obs_value = Loader.factory(param_dict['data_format'])\
                .read_pos_and_value(fichier)
            nb_obs = int(np.shape(lat)[0])
            if param_dict['write_geojson']:
                new_position = np.ndarray(
                    shape=(nb_obs, 2), dtype=float, order='F')
                new_position[:, 0] = lon
                new_position[:, 1] = lat

        return lon, lat, ll_interp


class LoaderNCChloro(Loader):
    def __init__(self):
        self.lon = 'lon'
        self.lat = 'lat'
        self.varname = 'CHL'
    def read_pos_and_value(self,filename):
        rla_lon, rla_lat, _FillValue, nc = \
          self.generic_read_pos_and_value(filename, self.lon, self.lat, self.varname)
        rla_value = nc.variables[self.varname][0, :, :]
        nb_obs = int(np.shape(rla_value.flatten())[0])
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue

class LoaderNCClim(Loader):
    def __init__(self):
        self.lon = 'longitude'
        self.lat = 'latitude'
        self.varname = 'CHL_MEAN'

    def read_pos_and_value(self,filename):
        rla_lon, rla_lat, nb_obs, _FillValue = \
         self.generic_read_pos_and_value(filename, self.lon, self.lat, self.varname)
        rla_value = nc.variables[self.varname][0, :, :]
        nb_obs = int(np.shape(rla_value.flatten())[0])
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue

    def read_pos(self, filename):
        rla_lon, rla_lat, nc = self.generic_read_pos(filename, self.lon, self.lat)
        return rla_lon, rla_lat

class InputLoader(Loader):
    def load(self, options, level, log):
        """Loader for input options"""
        keywords = ['date1=', 'date2=', 'delta=', 'nbdate=', 'daterun=',
        'config=', 'data=', 'src=', 'nbproc=', 'typemod=', 'schedule=', 'data_id=']
        cla_opts = getopt.getopt(options, '', keywords)
        log = Logger("InputLoader").run(level)
        ll_delta = None
        ll_date1 = None
        ll_date2 = None
        ll_daterun = None
        ll_nbdate = None
        ll_config = None
        ll_data = None
        ll_src = None
        cl_daterun = None
        ll_data_id = None
        list_var = []
        nb_proc = 0
        cl_schedule = 'd'
        cl_data_id = ""
        for o, p in cla_opts[0]:
            if o in ['--delta']:
                ll_delta = True
                cl_delta = p
            elif o in ['--date1']:
                ll_date1 = True
                cl_start_date = p
            elif o in ['--date2']:
                ll_date2 = True
                cl_end_date = p
            elif o in ['--typemod']:
                cl_typemod = p
                if cl_typemod not in ['pgs', 'pgn', 'allege']:
                    print ("input data type not known : must be pgn pgs or allege")
                    sys.exit(1)
            elif o in ['--daterun']:
                ll_daterun = True
                cl_daterun = p
            elif o in ['--nbdate']:
                ll_nbdate = True
                cl_nbdate = p
            elif o in ['--config']:
                ll_config = True
                cl_config = p
            elif o in ['--data']:
                ll_data = True
                cl_data = p
            elif o in ['--src']:
                ll_src = True
                cl_src = p
            elif o in ['--schedule']:
                cl_schedule = p
            elif o in ['--nbproc']:
                ll_optim = True
                cl_nbproc = p
                nb_proc = int(cl_nbproc)
            elif o in ['--data_id']:
                ll_data_id = True
                cl_data_id = p
        list_var.append(ll_date1)
        list_var.append(ll_date2)
        list_var.append(ll_daterun)
        list_var.append(ll_nbdate)
        if not ll_config:
            log.error("Config is missing : add --config= in the launcher")
            log.error(
                "Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --date1=XXXX --date2=XXXX or ")
            log.error(
                "Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --delta=XXXX (delayed time before today)")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --daterun=XXXX --nbdate=X --delta=X  (for example 1 week before today -14 and today -7)")
            sys.exit(1)
        if not ll_data or not ll_src:
            log.error(
                "Type is missing : add --data=SLA/SST/profile/profile_ARMOR and --src=GODAE/CORIO. in the launcher")
            log.error(
                "Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --date1=XXXX --date2=XXXX or ")
            log.error(
                "Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --delta=XXXX (delayed time before today)")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --daterun=XXXX --nbdate=X --delta=X  (for example 1 week before today -14 and today -7)")
            sys.exit(1)
        if ll_delta and list_var.count(True) == 0:
            log.info("Case 1 Delta only")
            datetoday = SyDate(dt.datetime.today().strftime("%Y%m%d"))
            date1 = datetoday.gobackward(int(cl_delta))
            date2 = date1
        elif ll_date1 and ll_date2 and not ll_delta and not ll_daterun:
            log.info("Case 2 Date1 Date2")
            # Test LEN of input date
            datelen1 = len(cl_start_date)
            datelen2 = len(cl_end_date)
            log.info("Lenght of date %i %i" % (datelen1, datelen2))
            if datelen1 == datelen2 and datelen1 == 6:
                log.info("Monthly values")
                log.info("Values %s %s :" %
                         (cl_start_date[0:4], cl_start_date[4:6]))
                nb_day1 = monthrange(
                    int(cl_start_date[0:4]), int(cl_start_date[4:6]))[1]
                cl_start_date2 = cl_start_date+"01"
                cl_end_date2 = cl_start_date+str(nb_day1)
                log.info(cl_start_date2)
                log.info(cl_end_date2)
                date1 = SyDate(cl_start_date2)
                date2 = SyDate(cl_end_date2)
                cl_schedule = 'm'
            elif datelen1 == datelen2 and datelen1 == 8:
                log.info("Daily values")
                date1 = SyDate(cl_start_date)
                date2 = SyDate(cl_end_date)
                cl_schedule = 'd'
            elif datelen1 == datelen2 and datelen1 == 4:
                log.info("Year values")
                date1 = SyDate(cl_start_date+"0101")
                date2 = SyDate(cl_end_date+"1231")
                cl_schedule = 'y'
            else:
                log.error("Input date must be in year month or day")
        elif ll_daterun and ll_nbdate and ll_delta:
            log.info("Case 3 Backward run")
            jrun = SyDate(cl_daterun)
            date1 = jrun.gobackward(int(cl_delta))
            date2 = jrun.gobackward(int(cl_delta)-int(cl_nbdate)+1)
        elif ll_date1:
            log.info("Only one date")
            print (cl_start_date)
            if len(str(cl_start_date)) == 4:
                date1 = SyDate(cl_start_date+"0101")
                date2 = SyDate(cl_start_date+"1231")
                log.info("Year values")
                cl_schedule = 'y'
            else:
                log.info("Date must be a year")
                sys.exit(1)
        elif not ll_date1 and not ll_date2:
            log.info("No date: last month")
            date_now = dt.datetime.now()
            if date_now.month == 1:
                cl_start_date = str(date_now.year-1)+"1201"
                cl_end_date = str(date_now.year)+"0101"
            elif date_now.month < 10:
                cl_start_date = str(date_now.year)+"0" + \
                                    str(date_now.month-1)+"01"
                cl_end_date = str(date_now.year)+"0"+str(date_now.month)+"01"
            elif date_now.month == 11:
                cl_start_date = str(date_now.year)+"0" + \
                                    str(date_now.month-1)+"01"
                cl_end_date = str(date_now.year)+str(date_now.month)+"01"
            else:
                cl_start_date = str(date_now.year)+str(date_now.month-1)+"01"
                cl_end_date = str(date_now.year)+str(date_now.month)+"01"
            print (cl_start_date)
            date1=SyDate(cl_start_date)
            date2=SyDate(cl_end_date)
        elif cl_daterun == "all" :
            log.info("Need to find dates in file")
            date1=None
            date2=None
        else :
            log.error("Case not valid")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --date1=XXXX --date2=XXXX or ")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --delta=XXXX (delayed time before today)")
            log.error("Type TEP_CLASS4.py --data=XXX --src=XXX --config=XXX --daterun=XXXX --nbdate=X --delta=X  \
                            (for example 1 week before today -14 and today -7)")
            sys.exit(1)
        if ll_date1 and ll_date2 :
            log.info("Date1 %s Date2 %s " %(date1,date2))
        confname='config_'+str(cl_config)+'_'+str(cl_src)+'_'+str(cl_data)+'.cfg'
        # Logger
        log.info("Nombre de proc %i" %(nb_proc))
        log.info("Type des fichiers d'entree %s " %(cl_typemod))
        log.info("Schedule %s " %(cl_schedule))
        log.info("Dates %s %s " %(date1,date2))
        log.info("Datatype %s " %(cl_data))
        log.info("Daterun %s " %(cl_daterun))
        # Create dictionnary
        param_dict={}
        param_dict['date1'] = date1
        param_dict['date2'] = date2
        param_dict['confname'] = confname
        param_dict['data_type'] = cl_data
        param_dict['cl_daterun'] = cl_daterun
        param_dict['cl_schedule'] = cl_schedule
        param_dict['cl_src'] = cl_src
        param_dict['nb_proc'] = nb_proc
        param_dict['cl_typemod'] = cl_typemod
        param_dict['cl_data_id'] = cl_data_id

        return param_dict

class NmlLoader(Loader):
    """Loader for namelists"""
    def load(self, filename, level, param_dict):
        log = Logger("NmlLoader").run(level)
        db = ConfigParser.ConfigParser()
        for file in filename:
            db.read(os.path.expanduser(filename))
        if not db.sections():
            log.error("Configuration file not found %s ! " %(filename))
            sys.exit(1)
        # Add new parameters in the dictionnary
        param_dict['dirdata'] = db.get('input_dir', 'INPUTDATA')
        param_dict['dirmodel'] = db.get('input_dir', 'DATA_IN')
        param_dict['nb_level'] = int(db.get('GLOBAL', 'LEVELS'))
        param_dict['zoom'] = int(db.get('GLOBAL', 'zoom'))
        param_dict['write_geojson'] = int(db.get('GLOBAL', 'write_geojson'))
        if param_dict['write_geojson']:
            # Write Geojson file
            log.info("Write Geojson file")
            # Db file for extracted positions
            file_db = 'CLASS4_shelf.db'
            file_db2 = 'Coloc_CLASS4_shelf.db'
            # Clean old db
            if os.path.isfile(file_db):
                os.remove(file_db)
            # Clean old db
            if os.path.isfile(file_db2):
                os.remove(file_db2)
        param_dict['qc_level'] = int(db.get('GLOBAL','qc_level'))
        param_dict['do_qc'] = int(db.get('GLOBAL','do_qc'))
        param_dict['do_sort'] = int(db.get('GLOBAL','do_sort'))
        #==========================================================================
        # Sort model values if necessary
        #==========================================================================
        if param_dict['do_sort']:
            log.info('              Sort Values for interp               ')
            param_dict['sort_rep'] = param_dict.get('input_dir', 'DATA_SORT')
            file_template = param_dict['cl_config'] + \
            '_'+param_dict['daily_pref']+'_'
            if cl_schedule == "WEEKLY":
                Sorter().run_weekly(param_dict['lead_time'], param_dict['lead_int'],
                                    date1, date2, daterun, param_dict['file_template'], param_dict['gridtemp'],
                                    param_dict['gridsal'], param_dict['dirmodel'], param_dict['sort_rep'])
            elif cl_schedule == "DAILY":
                Sorter().run_daily(param_dict['lead_time'], param_dict['lead_int'],
                                   date1, date2, param_dict['file_template'], param_dict['dirmodel'], param_dict['sort_rep'])
            else:
                log.error("Schedule not valid")
                sys.exit(1)
        else:
            log.info('              Input data already sorted               ')
            param_dict['sort_rep'] = param_dict['dirmodel']
        log.info('Sort rep : %s' % (param_dict['sort_rep']))
        param_dict['do_decomp'] = int(db.get('GLOBAL', 'do_decomp'))
        param_dict['model_type'] = db.get('GLOBAL', 'MODELTYPE')
        param_dict['data_format'] = db.get('input_dir', 'DATA_FMT')
        param_dict['dirwork'] = db.get('output_dir', 'DIRTMP')
        param_dict['diroutput'] = db.get('output_dir', 'DIROUTPUT')
        param_dict['homedir'] = db.get('GLOBAL', 'DIRHOME')
        param_dict['dirclim'] = db.get('climato', 'DIRCLIM')
        param_dict['coord_clim'] = glob(param_dict['dirclim'] + "*.nc")[0]
        param_dict['dirtmp'] = param_dict['dirwork'] + 'ext-'
        param_dict['prefix_data'] = db.get('input_dir', 'PREFIX')
        param_dict['nml_dir'] = db.get('GLOBAL', 'NAMELIST_DIR')
        param_dict['daily_pref'] = db.get('GLOBAL', 'DAILY_PREF')
        param_dict['direxec'] = db.get('GLOBAL', 'EXEDIR')
        param_dict['data_origin'] = db.get('input_dir', 'DATA_ORIGIN')
        param_dict['cl_conf'] = db.get('GLOBAL', 'CONF')
        param_dict['cl_config'] = db.get('GLOBAL', 'CONFIGURATION')
        param_dict['cl_config_h'] = re.sub("QV", "V", param_dict['cl_config'])
        param_dict['template'] = param_dict['cl_config_h'] + \
            '_'+param_dict['model_type'].lower()
        param_dict['lead_time'] = db.get('input_dir', 'LEAD_TIME').split()
        param_dict['lead_int'] = db.get('input_dir', 'LEAD_INT').split()
        param_dict['coloc_rep'] = db.get('output_dir', 'DIRCOLOC')
        param_dict['dir_log'] = db.get('GLOBAL', 'DIRLOG')
        param_dict['gridtemp'] = db.get('GLOBAL', 'gridtemp')
        param_dict['gridsal'] = db.get('GLOBAL', 'gridsal')
        param_dict['type_run'] = db.get('GLOBAL', 'TYPE_RUN')
        param_dict['type_archi'] = db.get('GLOBAL', 'TYPE_ARCHI')
        param_dict['varname'] = db.get('GLOBAL', 'variable')
        param_dict['nb_points'] = int(db.get('GLOBAL', 'nb_points_interp'))
        param_dict['schedule'] = db.get('GLOBAL', 'SCHEDULE')
        if param_dict['zoom'] or param_dict['do_qc']:
            param_dict['lon_min'] = int(param_dict.get('GLOBAL', 'LONMIN'))
            param_dict['lon_max'] = int(param_dict.get('GLOBAL', 'LONMAX'))
            param_dict['lat_min'] = int(param_dict.get('GLOBAL', 'LATMIN'))
            param_dict['lat_max'] = int(param_dict.get('GLOBAL', 'LATMAX'))
#        param_dict['dimension']=db.get('input_dir','DIMENSION')
        param_dict['coordinates'] = db.get('static', 'fic_coordinates')
        if param_dict['cl_data_id']:
            param_dict['dirwork'] = param_dict['dirwork']+str(cl_data_id)+'/'
            param_dict['diroutput'] = param_dict['diroutput']+str(cl_data_id)+'/'
            param_dict['dirdata'] = param_dict['dirdata']+str(cl_data_id)+'/'
        else:
            param_dict['dirwork'] = param_dict['dirwork']
            param_dict['diroutput'] = param_dict['diroutput']
            param_dict['dirdata'] = param_dict['dirdata']
        # Create Output and tmp directory if doesn't exist
        if not os.path.exists(param_dict['dirwork']):
            log.info("Create dirwork : %s" % (param_dict['dirwork']))
            os.makedirs(param_dict['dirwork'])
        if not os.path.exists(param_dict['diroutput']):
            os.makedirs(param_dict['diroutput'])
        if not os.path.exists(param_dict['coloc_rep']):
            os.makedirs(param_dict['coloc_rep'])

        return param_dict

class LoaderNCcorio(Loader):

    """Loader for coriolis dataset"""

    def read_pos(self,filename):
        # print 'read netcdf file : %s ' %(filename)
        nc = netCDF4.Dataset(filename,'r')
        variable = 'LONGITUDE'
        rla_lon = nc.variables[variable][:]
        # rla_lon[rla_lon <0] += 360.
        variable = 'LATITUDE'
        rla_lat = nc.variables[variable][:]
        # nb_tot=len(rla_lon)
        n_profiles = len(rla_lon)
        # n_profiles=386
        # print n_profiles
        # n_profiles=1000
        # position=np.ndarray(shape=(n_profiles,2))
        # position[:,0]=rla_lon[:] 
        # position[:,1]=rla_lat[:] 
        # Solution 1
        position = np.ndarray(shape=(n_profiles,2),dtype=float, \
             order='F',buffer=np.array([rla_lon[:],rla_lat[:]]))
        # Solution 2
        # il_val=0
        # for il_ind in range(nb_tot):
        #  if  rla_lon[il_ind] < 9999. and rla_lat[il_ind] < 9999. :
        #    position[il_val,0]=rla_lon[il_ind]
        #    position[il_val,1]=rla_lat[il_ind]
        #    il_val=il_val+1
        # np.set_printoptions(suppress=True)
        return position

class LoaderSyntheticValue(Loader):

    """Loader for synthetic dataset"""

    def read_pos(self, filename):
        nc = netCDF4.Dataset(filename, 'r')
        variable = 'longitude'
        rla_lon = nc.variables[variable][:]
        variable = 'latitude'
        rla_lat = nc.variables[variable][:]
        n_profiles = len(rla_lon[:])
        # Optional Read juld
        # variable='juld'
        # rla_juld= nc.variables[variable][:]
        return rla_lon, rla_lat

class LoaderSSSVessel(Loader):

    def read_pos_and_value(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'LON'
        rla_lon = nc.variables[variable][:]
        variable = 'LAT'
        rla_lat = nc.variables[variable][:]
        n_profiles=len(rla_lon[:])
        rla_value = nc.variables['SSS'][:]
        _FillValue = nc.variables['SSS']._FillValue
        nb_obs = len(rla_lon)
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue
        # Optional Read juld
        # variable='juld'
        # rla_juld= nc.variables[variable][:]

class LoaderNCgodae(Loader):

    """Loader for GODAE dataset"""

    def __init__(self):
        self.lon = 'longitude'
        self.lat = 'latitude'
        self.varname = 'observation'

    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'longitude'
        rla_lon = nc.variables[variable][:]
        variable = 'latitude'
        rla_lat = nc.variables[variable][:]
        n_profiles=len(rla_lon[:])
        # Optional Read juld
        # variable='juld'
        # rla_juld= nc.variables[variable][:]
        position=np.ndarray(shape=(n_profiles,2),dtype=float, order='F')
        il_val=0
        for il_ind in range(n_profiles):
            position[il_val,0] = rla_lon[il_ind]
            position[il_val,1] = rla_lat[il_ind]
            il_val = il_val+1
        np.set_printoptions(suppress=True)
        return position


    def read_pos_amsr(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'LON'
        rla_lon = nc.variables[variable][:]
        variable = 'LAT'
        rla_lat = nc.variables[variable][:]
        n_profiles=len(rla_lon[:])
        # Optional Read juld
        # variable='juld'
        # rla_juld= nc.variables[variable][:]
        position=np.ndarray(shape=(n_profiles,2),dtype=float, order='F')
        il_val = 0
        for il_ind in range(n_profiles):
            position[il_val,0] = rla_lon[il_ind]
            position[il_val,1] = rla_lat[il_ind]
            il_val = il_val+1
        np.set_printoptions(suppress=True)
        return position

    def read_pos_and_value(self,filename):
        rla_lon, rla_lat, _FillValue, nc = \
         self.generic_read_pos_and_value(filename, self.lon, self.lat, self.varname)
        rla_value = nc.variables[self.varname][:]
        nb_obs = len(rla_value)
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue

class PGN_coords_Loader(Loader):

    """Loader for PGN dataset"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'nav_lon'
        rla_lon = nc.variables[variable][:,:]
        variable = 'nav_lat'
        rla_lat = nc.variables[variable][:,:]
        return rla_lon,rla_lat

class alleges_coords(Loader):

    """Loader for Alleges Mask"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'longitude'
        rla_lon = nc.variables[variable][:,:]
        variable = 'latitude'
        rla_lat = nc.variables[variable][:,:]
        return rla_lon,rla_lat

class AsciiLoader(Loader):

    """Loader for ASCII dataset"""

    def read_pos(self,filename):
        # print 'read ASCII file : %s ' %(filename)
        # data=np.genfromtxt(filename,usecols = (2,3),skip_header=1)
        data = np.genfromtxt(filename,usecols = (1,2),skip_header=1)
        position = np.array(data)
        return position

class ColocLoader(Loader):

    """Loader for coloc ASCII file"""

    def read_pos(self,filename):
        # print 'read ASCII file : %s ' %(filename)
        # data=np.genfromtxt(filename,usecols = (5,6))
        data = np.genfromtxt(filename,usecols = (15,16))
        position = np.array(data)
        return position

