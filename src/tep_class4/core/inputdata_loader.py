from __future__ import generators
import warnings
warnings.filterwarnings("ignore")
import os
import fcntl
import sys
import numpy as np
import netCDF4
from collections import namedtuple
from .reader import read_drifter_filt, read_drifter
from .QCcontrol import QCcontroller
import seawater as sw
from .Selector import Selector
import time as tm
import xarray as xr

##############################################################
# C.REGNIER Juin 2014
# Class Loader to load different type of file with a pattern factory
##############################################################

def read_observations(file_obs, param_dict, log):
    # Read obs file
    ObsData = namedtuple("ObsData", ["lon", "lat", "obs_value", "nb_obs", "depth", "tab_dims", "FillValue", "qc"])
    log.debug(f"Format of the data {param_dict['data_format']}")
    lon_obs, lat_obs, obs_value, nb_obs, depth, rla_qc, tab_dims, param_dict, _FillValue = \
                inputdata_loader(log).factory(param_dict['data_format']).\
                read_pos_and_value(file_obs, param_dict)
    #obs_data = ObsData(lon_obs, lat_obs, obs_value.squeeze(), nb_obs, depth, tab_dims, _FillValue)
    obs_data = ObsData(lon_obs, lat_obs, obs_value, nb_obs, depth, tab_dims, _FillValue, rla_qc)
    tuple_obs = (np.shape(lon_obs)[0], np.shape(lat_obs)[0])

    return obs_data, tuple_obs


class inputdata_loader(object):

    """Create factory for the loader"""

    def __init__(self, log, **kwargs):
        self.log = log

    #@staticmethod
    def factory(self, type):
        """
            Factory for different type of loaders
        """
        # return eval(type + "()")
        if type == "NC_CORIO":
            return LoaderNCcorio()
        if type == "NC_CORIO_TAC":
            return loaderNCcorio_tac(self.log)
        if type == "NC_CHLORO":
            return LoaderNCChloro(self.log)
        if type == "NC_BIOARGO":
            return LoaderNCBioArgo()
        if type == "NC_CLIM":
            return LoaderNCClim()
        if type == "NC_INSCLIM":
            return LoaderInsituClim()
        if type == "NC_GODAE":
            return LoaderNCgodae()
        if type == "Microwat":
            return LoaderSyntheticValue()
        if type == "SSS_ship":
            return LoaderSSSVessel()
        if type == "ASCII":
            return AsciiLoader()
        if type == "DAT":
            return ColocLoader()
        if type == "INPUT_DATA":
            return InputDataLoader(self.log)
        if type == "PGN_coords":
            return PGN_coords_Loader(self.log)
        if type == "PGS_coords":
            return PGS_coords_Loader(self.log)
        if type == "PGN_coords_clim":
            return PGN_coords_clim_Loader(self.log)
        if type == "SMOC_coords":
            return SMOC_coords_Loader(self.log)
        if type == "DRIFTER_CMEMS":
            return LoaderCMEMSDrifter(self.log)
        if type == "DRIFTER_CMEMS_filtr":
            return LoaderCMEMSDrifter_filtr(self.log)
        if type == "alleges_coords":
            return alleges_coords()
        if type == "bathymetrie":
            return bathy_coords(self.log)
        if type == "Legos_SIT":
            return read_Legos_SIT()
        if type == "2ease_coords":
            return ease_coords_Loader()
        if type == "L3_SEALEVEL":
            return L3_SEALEVEL_Loader()
        assert 0, "Format not known: " + type

    def generic_read_pos_and_value(self,filename, varname):
        rla_lon, rla_lat, nc = self.generic_read_pos(filename)
        #_FillValue = nc.variables[varname[0]]._FillValue
        _FillValue = nc.variables[varname]._FillValue

        return rla_lon, rla_lat, _FillValue, nc

    def generic_read_pos(self, filename):

        nc = netCDF4.Dataset(filename, 'r')
        ll_ravel = False
        if 'longitude' in nc.variables:
            var_lon = 'longitude' 
            var_lat = 'latitude'
        elif 'lon' in nc.variables and 'lon_20hz' not in nc.variables and 'lon_20_ku' not in nc.variables:
            var_lon = 'lon'
            var_lat = 'lat'
        elif 'LON' in nc.variables:
            var_lon = 'LON'
            var_lat = 'LAT'
        elif 'Lon' in nc.variables:
            var_lon = 'Lon'
            var_lat = 'Lat'
        elif 'LONGITUDE' in nc.variables:
            var_lon = 'LONGITUDE'
            var_lat = 'LATITUDE'
        elif 'Longitude' in nc.variables:
            var_lon = 'Longitude'
            var_lat = 'Latitude'
        elif 'lon_20hz' in nc.variables:
            var_lon = 'lon_20hz'
            var_lat = 'lat_20hz'
            ll_ravel = True
        elif 'lon_20_ku' in nc.variables:
            var_lon = 'lon_20_ku'
            var_lat = 'lat_20_ku'
            ll_ravel = True
        if ll_ravel:
            rla_lon = np.ravel(nc.variables[var_lon][:,:])
            rla_lat = np.ravel(nc.variables[var_lat][:,:])
        else:
            rla_lon = nc.variables[var_lon][:]
            rla_lat = nc.variables[var_lat][:]

        return rla_lon, rla_lat, nc


class InputDataLoader(inputdata_loader):
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
                    lon, lat, obs_value = inputdata_loader.factory(
                        param_dict['data_format']).read_pos_and_value(fichier)
                else:
                    os.remove(fichier)
                    log.info('No position find in %s for the zoom ' %
                             (fichier))
                    ll_interp = False
        else:
            # Case Global without qc
            log.info("GLOBAL MODE => SELECT ALL ")
            #selector = Selector(param_dict['data_format'], param_dict['data_type']).factory(
            #    param_dict['data_origin'])
            if param_dict['data_origin'] == "Microwat":
                lon, lat, juld = inputdata_loader.factory(
                    param_dict['data_format']).read_pos(fichier)
                nb_obs = int(np.shape(lat)[0])
                position = np.ndarray(
                    shape=(nb_obs, 2), dtype=float, order='F')
                position[:, 0] = lon
                position[:, 1] = lat
            elif param_dict['data_type'] ==  "AMSR" :
                position=inputdata_loader.factory(param_dict['data_format']).read_pos_amsr(fichier)
            else :
                position=inputdata_loader.factory(param_dict['data_format']).read_pos(fichier)
            #else:
            #    lon, lat, obs_value = inputdata_loader.factory(param_dict['data_format'])\
            #    .read_pos_and_value(fichier)
            #if param_dict['write_geojson']:
            #    nb_obs = int(np.shape(lat)[0])
            #    new_position = np.ndarray(
            #        shape=(nb_obs, 2), dtype=float, order='F')
            #    new_position[:, 0] = lon
            #    new_position[:, 1] = lat
            ## Create Geojson file for coloc verification with Qgis
            #if param_dict['write_geojson'] : 
            #    liste_type=['GLO','XB','CT','DC','BA','GL','ML','PF','TE','DB','FB','MO','TS']
            #    for type_var in liste_type : 
            #        ## Write files with positions of dataset
            #        file_out=dirtmp+'Positions_'+type_var+'_'+data_format+'_'+data_type+'_D'+SyDate.__str__(date1)+'_'+SyDate.__str__(date2)+'.geojson'
            #        Writer(log).write_geojson_fromdb(type_var,file_out,file_db)
            #    file_out2=dirtmp+'Positions_coloc_'+data_type+'_'+data_format+'_'+data_type+'_D'+SyDate.__str__(date1)+'_'+SyDate.__str__(date2)+'.geojson'
            #    Writer(log).write_geojson_fromdb('coloc',file_out2,file_db2)

        return position, ll_interp
        #return lon, lat, ll_interp


class LoaderNCChloro(inputdata_loader):
    def __init__(self, log):
        self.varname = ['CHL']
        self.log = log

    def read_pos_and_value(self, filename, param_dict):
        rla_lon, rla_lat, _FillValue, nc = \
          self.generic_read_pos_and_value(filename, self.varname[0])
        self.log.info(f"Read filename {filename=}")
        rla_value = nc.variables[self.varname[0]][0, :, :]
        nb_obs = int(np.shape(rla_value.flatten())[0])
        self.log.info(f"{nb_obs=}")
        tab_dims = {}
        #for dim_name in dimension_names:
        #                        tab_dims[dim_name] = ds[dim_name].size
        if 'depth' in nc.variables.keys():
            rla_depth = nc.variables['depth'][:]
        elif 'DEPH' in nc.variables.keys():
            rla_depth = nc.variables['DEPH'][:]
        elif 'pres' in nc.variables.keys():
            rla_depth = nc.variables['pres'][:]
        elif 'PRES' in nc.variables.keys():
            rla_depth = nc.variables['PRES'][:]
        else:
            ## No depth: surface variable
            nb_lats, nb_lons = np.shape(rla_value)
            rla_depth = np.ndarray(shape=(nb_lats,nb_lons),dtype=float, order='F')
            rla_depth[:,:] = 0
        nc.close()
        param_dict['Design_GODAE_file'] = False
        param_dict['varname_select'] = ['chl']
        self.log.debug("Read CHL ok")
        return rla_lon, rla_lat, rla_value, nb_obs, rla_depth, tab_dims, param_dict, _FillValue

class LoaderNCBioArgo(inputdata_loader):

    def read_pos_and_value(self,filename, varname='NITRATE_ADJUSTED'):
        rla_lon, rla_lat, _FillValue, nc = \
          self.generic_read_pos_and_value(filename, varname)
        rla_value = nc.variables[varname][:, :, :]
        nb_obs, nb_vars, nb_deps = np.shape(rla_value)
        if 'depth' in nc.variables.keys():
            rla_depth = nc.variables['depth'][:,0,:]
        elif 'DEPH' in nc.variables.keys():
            rla_depth = nc.variables['DEPH'][:,0,:]
        elif 'DEPH_ADJUSTED' in nc.variables.keys():
            rla_depth = nc.variables['DEPH_ADJUSTED'][:,0,:]
        elif 'pres' in nc.variables.keys():
            rla_depth = nc.variables['pres'][:,0,:]
        elif 'PRES' in nc.variables.keys():
            rla_depth = nc.variables['PRES'][:,0,:]
        elif 'PRES_ADJUSTED' in nc.variables.keys():
            rla_depth = nc.variables['PRES_ADJUSTED'][:,0,:]
        else:
            ## No depth: surface variable
            nb_lats, nb_lons = np.shape(rla_value)
            rla_depth = np.ndarray(shape=(nb_lats,nb_lons),dtype=float, order='F')
            rla_depth[:,:] = 0
        nc.close()

        return np.float32(rla_lon), np.float32(rla_lat), np.float32(rla_value), nb_obs, np.float32(rla_depth), _FillValue

class LoaderInsituClim(inputdata_loader):
    def __init__(self):
        self.varname = 'Temperature'

    def read_pos_and_value(self,filename):
        rla_lon, rla_lat, nb_obs, _FillValue, nc = \
        self.generic_read_pos_and_value(filename, self.varname)
        rla_value = nc.variables[self.varname][0, :, :]
        nb_obs = int(np.shape(rla_value.flatten())[0])
        nc.close()
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue

    def read_pos(self, filename):
        rla_lon, rla_lat, nc = self.generic_read_pos(filename)
        return rla_lon, rla_lat


class LoaderNCClim(inputdata_loader):
    def __init__(self):
        self.varname = 'CHL_MEAN'

    def read_pos_and_value(self,filename, param_dict):

        rla_lon, rla_lat, nb_obs, _FillValue, nc = \
         self.generic_read_pos_and_value(filename, self.varname)
        rla_value = nc.variables[self.varname][0, :, :]
        nb_obs = int(np.shape(rla_value.flatten())[0])
        nc.close()
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue

    def read_pos(self, filename):
        rla_lon, rla_lat, nc = self.generic_read_pos(filename)
        return rla_lon, rla_lat, None, None

class loaderNCcorio_tac(inputdata_loader):
    """Loader for coriolis dataset from TAC"""
    def __init__(self, log):
        self.log = log
        self.varname_list = []
        self.list_temp = ['votemper', 'thetao', 'temperature', \
                          'thetao_glor', 'thetao_cglo', 'thetao_oras',\
                          'thetao_mean', 'tos']
        self.list_psal = ['vosaline', 'so', 'salinity',\
                          'so_glor', 'so_cglo', 'so_oras', 'so_mean', 'sos']
        self.list_instemp = ['TEMP', 'TEMP_ADJUSTED']
        self.list_inspsal = ['PSAL', 'PSAL_ADJUSTED']
        self.fillvalue_dep= 99999.
        self.fillvalue_temp= 9999.
        self.fillvalue_sal = 9999.
        self.fillvalue_err=  9999.

    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'LONGITUDE'
        rla_lon = nc.variables[variable][:]
        variable = 'LATITUDE'
        rla_lat = nc.variables[variable][:]
        n_profiles = len(rla_lon)
        position = np.ndarray(shape=(n_profiles,2),dtype=float, \
             order='F',buffer=np.array([rla_lon[:],rla_lat[:]]))
        nc.close()
        return position

    def is_file_locked(self, filepath):
        try:
            fd = os.open(filepath, os.O_RDONLY)
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)
            return False  # File is not locked
        except OSError:
            return True  # File is locked

    def read_pos_and_value(self, filename,
                           param_dict,
                           qc_level=0,
                           filter_levels=False,
                           input_var=[''],
                           **args):
        self.log.debug(f"Read pos and value {filename} {self.is_file_locked(filename)} {filter_levels=}")
        #if not self.is_file_locked(filename):
        #ds = xr.open_dataset(filename)
        ds = xr.open_dataset(filename, engine="netcdf4")
        #else:
        #    print(f"File {filename} is currently being used by another process.")
        #    sys.exit(1)
        #nc = netCDF4.Dataset(filename, 'r')
        param_dict['Design_GODAE_file'] = True
        # Get the list of variable names
        variable_names = list(ds.variables)
        dimension_names = list(ds.dims)
        tab_dims = {}
        for dim_name in dimension_names:
            tab_dims[dim_name] = ds[dim_name].size
        n_profiles = ds['N_PROF'].size
        n_profs = ds['N_LEVELS'].size
        ll_depth = ll_depth_adj = ll_pres = ll_pres_adj = False
        ll_temp = ll_psal = ll_temp_adj = ll_psal_adj = False
        # Check for the presence of variables
        ll_depth = 'DEPTH' in ds.variables
        ll_depth = 'DEPH' in ds.variables
        ll_depth_adj = 'DEPTH_ADJUSTED' in ds.variables
        ll_pres = 'PRES' in ds.variables
        ll_pres_adj = 'PRES_ADJUSTED' in ds.variables
        ll_data_mode = 'DATA_MODE' in ds.variables
        ll_clim_temp = False
        ll_clim_psal = False
        ll_clim_temp_adjust = False
        ll_clim_psal_adjust = False
        if 'SMLEV' in variable_names:
            clim_psal = ds['SMLEV'].values
            ll_clim_psal = True
        if 'TMLEV' in variable_names:
            clim_temp = ds['TMLEV'].values
            ll_clim_temp = True
        if 'TEMP_ADJUSTED' in variable_names:
            ll_temp_adj = True
        if 'PSAL_ADJUSTED' in variable_names:
            ll_psal_adj = True
        if 'SMLEV_ADJUSTED' in variable_names:
            clim_psal_adj = ds['SMLEV_ADJUSTED'].values
            ll_clim_psal_adjust = True
        if 'TMLEV_ADJUSTED' in variable_names:
            clim_temp_adj = ds['TMLEV_ADJUSTED'].values
            ll_clim_temp_adjust = True
        #if 'POSITION_QC' in variable_names:
        #    position_qc = ds['POSITION_QC'].values
        #if 'JULD_QC' in variable_names:
        #    juld_qc = ds['JULD_QC'].values
        if 'TEMP_QC' in variable_names:
            temp_qc = ds['TEMP_QC'].values
        if 'TEMP_ADJUSTED_QC' in variable_names:
            temp_adjusted_qc = ds['TEMP_ADJUSTED_QC'].values
        if 'PSAL_QC' in variable_names:
            psal_qc = ds['PSAL_QC'].values
        if 'PSAL_ADJUSTED_QC' in variable_names:
            psal_adjusted_qc = ds['PSAL_ADJUSTED_QC'].values
        #if 'PRES_ADJUSTED_QC' in variable_names:
        #    pres_adjusted_qc =  ds['PRES_ADJUSTED_QC'].values
        #if 'PRES_QC' in variable_names:
        #    pres_qc =  ds['PRES_QC'].values
        #if 'DEPH_ADJUSTED_QC' in variable_names:
        #    depth_adjusted_qc =  ds['DEPH_ADJUSTED_QC'].values
        #if 'DEPH_QC' in variable_names:
        #    depth_qc =  ds['DEPH_QC'].values
        if 'LONGITUDE' in variable_names:
            rla_lon = ds['LONGITUDE'].values
            #rla_lon_2 = nc.variables['LONGITUDE'][:]
        if 'LATITUDE' in variable_names:
            rla_lat =  ds['LATITUDE'].values
            #rla_lat_2 = nc.variables['LATITUDE'][:]
            sum_lat = np.nansum(rla_lat)
            sum_lat_2 = np.nanmean(ds['LATITUDE'])
        var_pres = 'PRES'
        var_pres_adj = 'PRES_ADJUSTED'
        #if ll_pres:
        #    var_prof = 'PRES'
        #    var_prof_adj = 'PRES_ADJUSTED'
        #    var_qc = 'PRES_QC'
        #    var_qc_adj = 'PRES_ADJUSTED_QC'
        #    if ll_pres_adj:
        #        var_prof_adjusted_qc = pres_adjusted_qc
        #    else:
        #        var_prof_adjusted_qc = pres_qc
        #else:
        #    var_prof = 'DEPH'
        #    var_prof_adj = 'DEPH_ADJUSTED'
        #    var_qc = 'DEPH_QC'
        #    var_qc_adj = 'DEPH_ADJUSTED_QC'
        #    if ll_depth_adj:
        #        var_prof_adjusted_qc = depth_adjusted_qc
        #    else:
        #        var_prof_adjusted_qc = depth_qc
        #else:
        #    var_prof = 'PRES'
        #    var_prof_adj = 'PRES_ADJUSTED'
        #    var_qc = 'PRES_QC'
        #    var_qc_adj = 'PRES_ADJUSTED_QC'
        #    if ll_pres_adj:
        #        var_prof_adjusted_qc = pres_adjusted_qc
        #    else:
        #        var_prof_adjusted_qc = pres_qc
        if ll_data_mode:
            DATA_MODE = ds['DATA_MODE'].values
        if any(var in variable_names for var in self.list_instemp):
            ll_temp = True
            self.varname_list.append('TEMP')
            rla_temp = np.ndarray(shape=(n_profiles, n_profs))
        if any(var in variable_names for var in self.list_inspsal):
            ll_psal = True
            self.varname_list.append('PSAL')
            rla_psal = np.ndarray(shape=(n_profiles, n_profs))
        if not ll_temp and not ll_psal:
            self.log.error('PROF not valid with no TEMP and no PSAL or ADJUSTED')
        if not ll_data_mode:
            self.log.error('Missing Data Mode')
        rla_temp = np.ndarray(shape=(n_profiles, n_profs))
        rla_psal = np.ndarray(shape=(n_profiles, n_profs))
        rla_clim_temp = np.ndarray(shape=(n_profiles, n_profs))
        rla_clim_psal = np.ndarray(shape=(n_profiles, n_profs))
        rla_prof = np.ndarray(shape=(n_profiles, n_profs))
        rla_pres = np.ndarray(shape=(n_profiles, n_profs))
        rla_qc_temp = np.ndarray(shape=(n_profiles, n_profs))
        rla_qc_psal = np.ndarray(shape=(n_profiles, n_profs))
        for ind in range(ds['N_PROF'].size):
            nb_pres = 0
            nb_depth = 0
            if ll_pres:
                nb_pres = np.count_nonzero(~np.isnan(ds['PRES'][ind, :].values ))
            if ll_depth:
                nb_depth = np.count_nonzero(~np.isnan(ds['DEPH'][ind, :].values))
            if nb_pres > nb_depth:
                var_prof = 'PRES'
                var_prof_adj = 'PRES_ADJUSTED'
                #var_qc = 'PRES_QC'
                #var_qc_adj = 'PRES_ADJUSTED_QC'
                #if ll_pres_adj:
                #    var_prof_adjusted_qc = pres_adjusted_qc
                #else:
                #    var_prof_adjusted_qc = pres_qc
            else:
                var_prof = 'DEPH'
                var_prof_adj = 'DEPH_ADJUSTED'
                ##var_qc = 'DEPH_QC'
                #var_qc_adj = 'DEPH_ADJUSTED_QC'
                #if ll_depth_adj:
                #    var_prof_adjusted_qc = depth_adjusted_qc
                #else:
                #    var_prof_adjusted_qc = depth_qc
            if DATA_MODE[ind] in [b'A', b'D']:
                self.log.debug(f'Case 1 Ajusted or Delayed Mode {ind} {DATA_MODE[ind]}')
                #val_posqc = position_qc[ind]
                #val_juldqc = juld_qc[ind]
                #val_depthqc=((var_prof_adjusted_qc[ind, :] == b'1') |
                #             (var_prof_adjusted_qc[ind, :] == b'0') |
                #             (var_prof_adjusted_qc[ind, :] == b'7')).sum()
                if ll_depth_adj or ll_pres_adj:
                    rla_prof[ind, :] = ds[var_prof_adj][ind, :].values
                    rla_prof[rla_prof < 0] = self.fillvalue_dep
                else:
                    rla_prof[ind, :] = ds[var_prof][ind, :].values
                    rla_prof[rla_prof < 0] = self.fillvalue_dep
                if ll_pres:
                    if ll_pres_adj:
                        rla_pres[ind, :] = ds[var_pres_adj][ind, :].values
                        rla_pres[rla_pres < 0] = self.fillvalue_dep
                    else:
                        rla_pres[ind, :] = ds[var_pres][ind, :].values
                        rla_pres[rla_pres < 0] = self.fillvalue_dep
                #else:
                #    self.log.debug(f"Missing pres {DATA_MODE[ind]}")

                # read adjusted values
                if ll_temp:
                    if ll_temp_adj:
                        rla_temp[ind, :] =  ds['TEMP_ADJUSTED'][ind, :].values
                        list_pattern = [b'\xbf', b'>', b'\x02', b'\xb7', b'\xa6', b'B', b'\xad', \
                                            b'\xf9', b'L', b')', b'\000', b'\x0b', b'y', b'\xe5',\
                                            b'\x7f', b'\xf0' ,b'}', b'\xbb', b'\xec', b'|', b'\xbc',\
                                            b'e', b',', b'A', b'\x0b', b'\x0c',  b'\xe9', b'\xd0']
                        if any(pattern in temp_adjusted_qc[ind, :] for pattern in list_pattern):
                            temp_adjusted_qc[ind, :]  = 9
                            rla_qc_temp[ind, :] = temp_adjusted_qc[ind, :]
                        else:
                            string_data = [byte_data if byte_data != b"" else 9 for byte_data in temp_adjusted_qc[ind, :]]
                            rla_qc_temp[ind, :] = string_data[:]
                    else:
                        rla_temp[ind, :] =  ds['TEMP'][ind, :].values
                        try:
                            list_pattern = [b'\xbf', b'>', b'\x02', b'\xb7', b'\xa6', b'B', b'\xad', \
                                            b'\xf9', b'L', b')', b'\000', b'\x0b', b'y', b'\xe5',\
                                            b'\x7f', b'\xf0' ,b'}', b'\xbb', b'\xec', b'|', b'\xbc',\
                                            b'e', b',', b'A', b'\x0b', b'\x0c',  b'\xe9', b'\xd0']
                            if any(pattern in temp_qc[ind, :] for pattern in list_pattern):
                                rla_qc_temp[ind, :]  = 9
                            else:
                                #string_data = [float(byte_data) if byte_data != b"" else 9 for byte_data in temp_qc[ind, :]]
                                rla_qc_temp[ind, :] =[float(byte_data) if byte_data != b"" else 9 for byte_data in temp_qc[ind, :]]
                        except (ValueError, UnicodeDecodeError) as e:
                            self.log.error(f"Conversion error: {e} {filename}")
                            self.log.error(f"Conversion error: {e}, Data: {string_data} {filename}")
                            sys.exit(1)
                    #string_data = [byte_data.decode('utf-8') if byte_data != b"" else 9 for byte_data in temp_adjusted_qc[ind, :]]
                    #rla_qc_temp[ind, :] = string_data[:]
                    #rla_qc_temp[ind, :] = temp_adjusted_qc[ind, :]
                    if ll_clim_temp_adjust:
                        rla_clim_temp[ind, :] = clim_temp_adj[ind, :]
                    # Replace QC values of CORIOLIS by GODAE QC values 0 is good and 9 is bad
                    # Coriolis QC 0: Non_qc 1: good 2: probably good ... 8: interpolated
                    # GODAE QC 0: good, 9: bad
                    rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] < 1, 9, rla_qc_temp[ind, :])
                    rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] == 1, 0, rla_qc_temp[ind, :])
                    rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] > 1, 9, rla_qc_temp[ind, :])
                    #rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] < 1, 9,
                    #                               np.where(rla_qc_temp[ind, :] == 1, 0, 9))
                if ll_psal:
                    if ll_psal_adj:
                        rla_psal[ind, :] =  ds['PSAL_ADJUSTED'][ind, :].values
                        list_pattern = [b'\xbf', b'>', b'\x02', b'\xb7', b'\xa6', b'B', b'\xad', \
                                            b'\xf9', b'L', b')', b'\000', b'\x0b', b'y', b'\xe5',\
                                            b'\x7f', b'\xf0' ,b'}', b'\xbb', b'\xec', b'|', b'\xbc',\
                                            b'e', b',', b'A', b'\x0b', b'\x0c',  b'\xe9', b'\xd0']
                        if any(pattern in psal_adjusted_qc[ind, :] for pattern in list_pattern):
                            psal_adjusted_qc[ind, :]  = 9
                            rla_qc_psal[ind, :] = psal_adjusted_qc[ind, :]
                        else:
                            rla_qc_psal[ind, :] = [float(byte_data) if byte_data != b"" else 9 for byte_data in psal_adjusted_qc[ind, :]]
                    else:
                        rla_psal[ind, :] =  ds['PSAL'][ind, :].values
                        ##
                        if any(pattern in psal_qc[ind, :] for pattern in list_pattern):
                            psal_qc[ind, :]  = 9
                            rla_qc_psal[ind, :] = psal_qc[ind, :] 
                        else:
                            string_data = [float(byte_data) if byte_data != b"" else 9 for byte_data in psal_qc[ind, :]]
                            rla_qc_psal[ind, :] = string_data[:]
                        #string_data = [float(byte_data) if byte_data != b"" else 9 for byte_data in psal_qc[ind, :]]
                    #string_data = [byte_data.decode('utf-8') for byte_data in psal_adjusted_qc[ind, :]]
                    #string_data = [byte_data.decode('utf-8') if byte_data != b"" else 9 for byte_data in psal_adjusted_qc[ind, :]]
                    ###rla_qc_psal[ind, :] = string_data[:]
                    #rla_qc_psal[ind, :] = psal_adjusted_qc[ind, :]
                    if ll_clim_psal_adjust:
                        rla_clim_psal[ind, :] = clim_psal_adj[ind, :]
                    rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] < 1, 9, rla_qc_psal[ind, :])
                    rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] == 1, 0, rla_qc_psal[ind, :])
                    rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] > 1, 9, rla_qc_psal[ind, :])
                   # rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] < 1, 9,
                   #                                np.where(rla_qc_psal[ind, :] == 1, 0, 9))
            else:
                #self.log.debug(f'Real time mode {DATA_MODE[ind]}')
                # read Normal values
                if ll_temp:
                    rla_temp[ind, :] =  ds['TEMP'][ind, :].values
                    list_pattern = [b'\xbf', b'>', b'\x02', b'\xb7', b'\xa6', b'B', b'\xad', \
                                    b'\xf9', b'L', b')', b'\000', b'\x0b', b'y', b'\xe5',\
                                    b'\x7f', b'\xf0' ,b'}', b'\xbb', b'\xec', b'|', b'\xbc',\
                                    b'e', b',', b'A', b'\x0b', b'\x0c',  b'\xe9', b'\xd0']
                    if any(pattern in temp_qc[ind, :] for pattern in list_pattern):
                    #if pattern in temp_qc[ind, :]:
                        #self.log.error(f"bad qc value TEMP {filename}")
                        rla_qc_temp[ind, :]  = 9
                    else:
                        try:
                            string_data = [float(byte_data) if byte_data != b"" else 9 for byte_data in temp_qc[ind, :]]
                        except (ValueError, UnicodeDecodeError) as e:
                            self.log.error(f"Conversion error: {e} {filename}")
                            self.log.error(f"Conversion error: {e}, Data: {string_data} {filename}")
                            sys.exit(1)
                        #rla_qc_temp[ind, :] = temp_qc[ind, :]
                        rla_qc_temp[ind, :] = string_data[:]
                        if ll_clim_temp:
                            rla_clim_temp[ind, :] = clim_temp[ind, :]
                        #rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] < 1, 9, 
                        #                               np.where(rla_qc_temp[ind, :] == 1, 0, 9))
                        rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] < 1, 9, rla_qc_temp[ind, :])
                        rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] == 1, 0, rla_qc_temp[ind, :])
                        rla_qc_temp[ind, :] = np.where(rla_qc_temp[ind, :] > 1, 9, rla_qc_temp[ind, :])
                if ll_psal:
                    rla_psal[ind, :] =  ds['PSAL'][ind, :].values
                    #string_data = [byte_data.decode('utf-8') for byte_data in psal_qc[ind, :]]
                    #string_data = [byte_data.decode('utf-8') if byte_data != b"" else 9 for byte_data in psal_qc[ind, :]]
                    #pattern = b'\000'
                    list_pattern = [b'\xbf', b'>', b'\x02', b'\xb7', b'\xa6', b'B', b'\xad', \
                                    b'\xf9', b'L', b')', b'\000', b'\x0b', b'y', b'\xe5',\
                                    b'\x7f', b'\xf0' ,b'}', b'\xbb', b'\xec', b'|', b'\xbc',\
                                    b'e', b',', b'A', b'\x0b', b'\x0c',  b'\xe9', b'\xd0']
                    if any(pattern in psal_qc[ind, :] for pattern in list_pattern):
                    #if pattern in psal_qc[ind, :]:
                        #self.log.error(f"bad qc value PSAL")
                        rla_qc_psal[ind, :]  = 9
                    else:
                        string_data = [float(byte_data) if byte_data != b"" else 9 for byte_data in psal_qc[ind, :]]
                        rla_qc_psal[ind, :] = string_data[:]
                        #rla_qc_psal[ind, :] = psal_qc[ind, :]
                        if ll_clim_psal:
                            rla_clim_psal[ind, :] = clim_psal[ind, :]
                        #rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] < 1, 9, 
                        #                               np.where(rla_qc_psal[ind, :] == 1, 0, 9))
                        rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] < 1, 9, rla_qc_psal[ind, :])
                        rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] == 1, 0, rla_qc_psal[ind, :])
                        rla_qc_psal[ind, :] = np.where(rla_qc_psal[ind, :] > 1, 9, rla_qc_psal[ind, :])
                rla_prof[ind, :] = ds[var_prof][ind, :].values
                rla_prof[rla_prof < 0] = self.fillvalue_dep
                if ll_pres:
                    rla_pres[ind, :] = ds[var_pres][ind, :].values
                    rla_pres[rla_pres < 0] = self.fillvalue_dep
                #else:
                #    self.log.debug(f"Missing pres {DATA_MODE[ind]}")
        rla_prof = np.nan_to_num(rla_prof, nan=self.fillvalue_dep)
        nb_variables = len(self.varname_list)
        results = {}
        results_qc = {}
        _FillValue = self.fillvalue_dep
        if ll_temp:
            results['TEMP'] = rla_temp
            results_qc['TEMP'] = rla_qc_temp
            if ll_clim_temp_adjust or ll_clim_temp:
                results['clim_TEMP'] = rla_clim_temp
            indices_temp = len(np.where(~np.isnan(results['TEMP']))[0])
            #pourcent_valid = (100*indices)/n_profiles
        if ll_psal:
            results['PSAL'] = rla_psal
            results_qc['PSAL'] = rla_qc_psal
            if ll_clim_psal_adjust or ll_clim_psal:
                results['clim_PSAL'] = rla_clim_psal
            indices_psal = len(np.where(~np.isnan(results['PSAL']))[0])
        if ll_temp and ll_psal:
            pourcent_valid =  (indices_psal*100)/indices_temp
        rla_obs = np.ndarray(shape=(n_profiles, nb_variables, n_profs))
        rla_clim = np.ndarray(shape=(n_profiles, nb_variables, n_profs))
        rla_qc = np.ndarray(shape=(n_profiles, nb_variables, n_profs))
        rl_threshold = 90
        if ll_temp and ll_psal and param_dict['insitu_corr'] and pourcent_valid > rl_threshold:
            self.log.debug("Add Potential correction")
            obs_temp_pot = sw.ptmp(results['PSAL'], results['TEMP'], rla_pres, pr=0)
            if ll_clim_temp_adjust or ll_clim_temp:
                obs_clim_temp_pot = sw.ptmp(results['clim_PSAL'], results['clim_TEMP'], rla_pres, pr=0)
                results['clim_TEMP'] = obs_clim_temp_pot
            results['TEMP'] = obs_temp_pot
        # Create observation array that combine all the dataset
        for ind, varname in enumerate(self.varname_list):
            rla_obs[:, ind, :] =  results[varname]
            rla_qc[:, ind, :] =  results_qc[varname]
            if ll_clim_temp_adjust or ll_clim_temp:
                rla_clim[:, ind, :] = results[f'clim_{varname}']
        # Replace nan by missing value
        ##rla_obs = np.where(rla_obs == np.nan, self.fillvalue_dep, rla_obs)
        ##rla_qc = np.where(rla_qc == np.nan, self.fillvalue_dep, rla_qc)
        ##rla_obs = np.nan_to_num(rla_obs, nan=self.fillvalue_dep)
        #if ll_clim_temp_adjust or ll_clim_temp:
        #    rla_clim = np.nan_to_num(rla_clim, nan=self.fillvalue_dep)
        #rla_qc = np.nan_to_num(rla_qc, nan=self.fillvalue_dep)
        param_dict['qc'] = rla_qc
        ## Filtered unrealistic value with 0 for longitude and latitude
        if sum_lat_2  <  -90.0 or sum_lat_2 > 90.0 or sum_lat_2 == 0.0:
            rla_lon[:] = np.nan
            rla_lat[:] = np.nan
            self.log.info(f'Missing values for lat {sum_lat} for {filename}')
        list_mod = param_dict['varname']
        #print(param_dict['varname'])
        list_psal = []
        list_temp = []

        if len(set(self.list_psal).intersection(param_dict['varname'])) == 1:
            list_psal =  list(set.intersection(set(self.list_psal), set(param_dict['varname'])))
        if len(set(self.list_temp).intersection(param_dict['varname'])) == 1:
            list_temp =  list(set.intersection(set(self.list_temp), set(param_dict['varname'])))
        param_dict['ll_PSAL'] = False
        param_dict['ll_TEMP'] = False
        if not ll_psal:
            if not list_psal:
                list_mod = list(set(list_mod))
            else:
                list_mod = list(set(list_mod) - set(list_psal))
        else:
                param_dict['ll_PSAL'] = True
        if not ll_temp:
            list_mod = list(set(list_mod) - set(list_temp))
        else:
            param_dict['ll_TEMP'] = True
        param_dict['varname_select'] = list_mod
        if ll_clim_temp_adjust or ll_clim_temp:
            param_dict['LEVITUS_clim'] = rla_clim

        ds.close()
        del ds
        if filter_levels:
            selected_var = args.get("selected_var")
            good = rla_qc[:, 0:1, :] == 0
            self.log.debug(f"TEMP {ll_temp}' PSAL {ll_psal}")
            # Index of the first good value along the last dimension
            self.log.debug(f"Dimensions good values {np.shape(good)}")
            qc_idx = np.argmax(good, axis=2)
            # Check whether each (profile, variable) has at least one good value
            has_good = good.any(axis=2)
            if selected_var == 'profile_TS_DB':
                rla_obs = np.squeeze(np.take_along_axis(
                    rla_obs,
                    qc_idx[..., None],
                    axis=2
                )[..., 0])
                rla_prof = np.squeeze(np.take_along_axis(
                    rla_prof,
                    qc_idx,
                    axis=1
                ))
            tab_dims = np.shape(rla_prof)
            rla_prof = np.where(rla_prof >= self.fillvalue_dep, np.nan, rla_prof)
            #if len(np.shape(rla_obs)) == 2:
            #    rla_obs = rla_obs[:, 0]
        self.log.debug(f'Dimension obs {len(np.shape(rla_obs))} {len(input_var)=}') 
        # If only TEMP or PSAL is need
        if len(np.shape(rla_obs)) > 2 and len(input_var) < 2:
            if input_var[0] in self.list_temp and 'TEMP' in self.varname_list:
                indx = self.varname_list.index('TEMP')
                self.log.debug(f"Extract TEMP {indx}")
            if input_var[0] in self.list_psal and 'PSAL' in self.varname_list:
                self.log.debug(f"Extract PSAL")
                indx = self.varname_list.index('PSAL')
                self.log.debug(f"Extract TEMP {indx}")
            rla_obs = rla_obs[:, indx, :]
            rla_qc = rla_qc[:, indx, :]
            self.log.debug(f"Dimensions {np.shape(rla_obs)}")
            self.log.debug(f"Variables of the profile {self.varname_list}")
        return np.float32(rla_lon), np.float32(rla_lat), np.float32(rla_obs),\
               n_profiles, np.float32(rla_prof), rla_qc, tab_dims, param_dict,  _FillValue

class LoaderNCcorio(inputdata_loader):

    """Loader for coriolis dataset"""
    def __init__(self):
        self.varname_list = []
        self.list_temp = ['votemper', 'thetao', 'temperature', \
                          'thetao_glor', 'thetao_cglo', 'thetao_oras']
        self.list_psal = ['vosaline', 'so', 'salinity',\
                          'so_glor', 'so_cglo', 'so_oras']
        self.depth_fillval = 99999.
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'LONGITUDE'
        rla_lon = nc.variables[variable][:]
        # rla_lon[rla_lon <0] += 360.
        variable = 'LATITUDE'
        rla_lat = nc.variables[variable][:]
        n_profiles = len(rla_lon)
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
        nc.close()
        return position

    def read_pos_and_value(self,filename, param_dict, qc_level=0):
        param_dict['Design_GODAE_file'] = True
        ll_pres=0
        ll_depth=0
        ll_temp=0
        ll_psal=0
        nc = netCDF4.Dataset(filename)
        if  'DEPH' in nc.variables.keys():
            ll_depth = 1
        if  'PRES' in nc.variables.keys():
            ll_pres = 1
        if  'TEMP' in nc.variables.keys():
            rla_temp =  nc.variables['TEMP'][:,:]
            ll_temp = 1
            self.varname_list.append('TEMP')
            n_profiles, n_profs = np.shape(rla_temp)
        if  'PSAL' in nc.variables.keys():
            rla_temp =  nc.variables['PSAL'][:,:]
            ll_psal = 1
            self.varname_list.append('PSAL')
            n_profiles, n_profs = np.shape(rla_temp)
        if not ll_temp and not ll_psal :
            print (f'PROF not valid with no TEMP and no PSAL {filename}')
            sys.exit(1)
        nb_variables = len(self.varname_list)
        #print(self.varname_list)
        #print(f"Number of variables in {filename} {nb_variables}")
        #rla_obs = np.ndarray(shape=(n_profiles,n_profs, nb_variables))
        rla_obs = np.ndarray(shape=(n_profiles, nb_variables, n_profs))
        for ind in range(nb_variables):
            rla_obs[:, ind, :] = nc.variables[self.varname_list[ind]][:,:]
            _FillValue = nc.variables[self.varname_list[ind]]._FillValue

        tab_dims = {}
        dimension_names = nc.dimensions.keys()

        for dim_name in dimension_names:
            dimension = nc.dimensions[dim_name]
            tab_dims[dim_name] = len(dimension)
        if ll_depth and ll_pres :
            rla_depth = nc.variables['PRES'][:,:]
        elif ll_depth and not ll_pres :
            rla_depth = nc.variables['DEPH'][:,:]
        elif ll_pres and not ll_depth :
            rla_depth = nc.variables['PRES'][:,:]
        else :
            print ('Not pres and depth')
            sys.exit(1)
        rla_depth[rla_depth < 0] = self.depth_fillval
        #"if 'depth' in nc.variables.keys():
        #"    rla_depth = nc.variables['depth'][:,0,:]
        #"elif 'DEPH' in nc.variables.keys():
        #"    rla_depth = nc.variables['DEPH_ADJUSTED'][:,0,:]
        #"elif 'pres' in nc.variables.keys():
        #"    rla_depth = nc.variables['pres'][:,0,:]
        #"elif 'PRES' in nc.variables.keys():
        #"    rla_depth = nc.variables['PRES'][:,0,:]
        if 'LONGITUDE' in nc.variables.keys():
            rla_lon =  nc.variables['LONGITUDE'][:]
        if 'LATITUDE' in nc.variables.keys():
            rla_lat =  nc.variables['LATITUDE'][:]
        nc.close()
        list_mod = param_dict['varname']
        if len(set(self.list_psal).intersection(param_dict['varname'])) == 1:
            list_psal =  list(set.intersection(set(self.list_psal), set(param_dict['varname'])))
        if len(set(self.list_temp).intersection(param_dict['varname'])) == 1:
            list_temp =  list(set.intersection(set(self.list_temp), set(param_dict['varname'])))
        #print(f"{list_psal=} {ll_psal}")
        #print(f"{list_temp=} {ll_temp}")
        param_dict['ll_PSAL'] = False
        param_dict['ll_TEMP'] = False
        if not ll_psal:
           #print('Remove psal')
           list_mod = list(set(list_mod) - set(list_psal))
        else:
            param_dict['ll_PSAL'] = True
        if not ll_temp:
           #print('Remove temp')
           list_mod = list(set(list_mod) - set(list_temp))
        else:
           param_dict['ll_TEMP'] = True
        param_dict['varname_select'] = list_mod
        ## Qc control
        QCflag = QCcontroller(param_dict['data_type'],param_dict['data_origin']).factory().QCrun(filename, qc_level)
        param_dict['qc'] = QCflag
        nc.close()

        return np.float32(rla_lon), np.float32(rla_lat), np.float32(rla_obs),\
               n_profiles, np.float32(rla_depth), tab_dims, param_dict,  _FillValue

class LoaderSyntheticValue(inputdata_loader):

    """Loader for synthetic dataset"""

    def read_pos(self, filename):
        nc = netCDF4.Dataset(filename, 'r')
        variable = 'longitude'
        rla_lon = nc.variables[variable][:]
        variable = 'latitude'
        rla_lat = nc.variables[variable][:]
        # Optional Read juld
        # variable='juld'
        # rla_juld= nc.variables[variable][:]
        nc.close()
        return rla_lon, rla_lat

class LoaderSSSVessel(inputdata_loader):

    def read_pos_and_value(self, filename, param_dict):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'LON'
        rla_lon = nc.variables[variable][:]
        variable = 'LAT'
        rla_lat = nc.variables[variable][:]
        rla_value = nc.variables['SSS'][:]
        _FillValue = nc.variables['SSS']._FillValue
        nb_obs = len(rla_lon)
        nc.close()
        return rla_lon, rla_lat, rla_value, nb_obs, _FillValue
        # Optional Read juld
        # variable='juld'
        # rla_juld= nc.variables[variable][:]

class L3_SEALEVEL_Loader(inputdata_loader):

    """ Loader for L3_SEALEVEL dataset """

    def __init__(self):
        self.varname = 'sla_filtered'
    
    def read_pos_and_value(self, filename, param_dict):
        param_dict['Design_GODAE_file'] = True
        rla_lon, rla_lat, _FillValue, nc = \
          self.generic_read_pos_and_value(filename, self.varname)
        
        rla_value = nc.variables[self.varname][:]
        dimensions = nc.dimensions
        tab_dims = {}
        for dims in dimensions.keys():
            sizedim = dimensions[dims].size
            if dims == 'numfcsts':
                tab_dims['nb_fcsts'] = sizedim
            elif dims == 'numobs':
                tab_dims['nb_obs'] = sizedim
            elif dims == 'numdeps':
                tab_dims['nb_depths'] = sizedim

        if 'flag' in nc.variables.keys():
            rla_qc = nc.variables['flag'][:]
        if 'depth' in nc.variables.keys():
            rla_depth = nc.variables['depth'][:]
        elif 'DEPH' in nc.variables.keys():
            rla_depth = nc.variables['DEPH'][:]
        elif 'pres' in nc.variables.keys():
            rla_depth = nc.variables['pres'][:]
        elif 'PRES' in nc.variables.keys():
            rla_depth = nc.variables['PRES'][:]
        else:
            ## No depth: surface variable
            nb_obs = np.shape(rla_value)[0]
            nb_deps = 1
            rla_depth = np.ndarray(shape=(nb_obs,nb_deps),dtype=float, order='F')
            rla_depth[:, 0] = 0
        param_dict['varname_select'] = param_dict['varname']
        return rla_lon, rla_lat, rla_value, nb_obs, rla_depth, rla_qc, tab_dims, param_dict, _FillValue


class LoaderNCgodae(inputdata_loader):

    """Loader for GODAE dataset"""

    def __init__(self):
        self.varname = 'observation'
        self.icevarname = ['siconc', 'iceconc']
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
        nc.close()
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
        nc.close()
        return position


    def read_pos_and_value(self, filename, param_dict, **args):

        param_dict['Design_GODAE_file'] = True
        input_var = args.get("input_var")

        ds = xr.open_dataset(
            filename,
            cache=False
        )
        try:
            # --------------------------------------------------
            # Find lon/lat
            # --------------------------------------------------
            variables = ds.variables

            if 'longitude' in variables:
                lon_name, lat_name = 'longitude', 'latitude'
            elif (
                'lon' in variables
                and 'lon_20hz' not in variables
                and 'lon_20_ku' not in variables
            ):
                lon_name, lat_name = 'lon', 'lat'
            elif 'LON' in variables:
                lon_name, lat_name = 'LON', 'LAT'
            elif 'Lon' in variables:
                lon_name, lat_name = 'Lon', 'Lat'
            elif 'LONGITUDE' in variables:
                lon_name, lat_name = 'LONGITUDE', 'LATITUDE'
            elif 'Longitude' in variables:
                lon_name, lat_name = 'Longitude', 'Latitude'
            elif 'lon_20hz' in variables:
                lon_name, lat_name = 'lon_20hz', 'lat_20hz'
            elif 'lon_20_ku' in variables:
                lon_name, lat_name = 'lon_20_ku', 'lat_20_ku'
            else:
                raise KeyError("Could not find longitude/latitude")

            # --------------------------------------------------
            # Variables
            # --------------------------------------------------
            value = ds[self.varname]

            lon = ds[lon_name]
            lat = ds[lat_name]

            # --------------------------------------------------
            # Depth
            # --------------------------------------------------
            depth_name = next(
                (
                    name for name in
                    ('depth', 'DEPH', 'pres', 'PRES')
                    if name in variables
                ),
                None
            )

            if depth_name is not None:
                depth = ds[depth_name]
            else:
                # Create later once value is loaded
                depth = None

            # --------------------------------------------------
            # QC
            # --------------------------------------------------
            qc = ds['qc'] if 'qc' in variables else np.nan

            # --------------------------------------------------
            # Dimensions
            # --------------------------------------------------
            tab_dims = {}

            if 'numfcsts' in ds.sizes:
                tab_dims['nb_fcsts'] = ds.sizes['numfcsts']

            if 'numobs' in ds.sizes:
                tab_dims['nb_obs'] = ds.sizes['numobs']

            if 'numdeps' in ds.sizes:
                tab_dims['nb_depths'] = ds.sizes['numdeps']

            # --------------------------------------------------
            # Ice case
            # --------------------------------------------------
            if input_var is not None and input_var[0] in self.icevarname:
                resol = 10
                seuil = 0.15

                # IMPORTANT:
                # Ideally use the observation dimension here.
                value = value.isel(numobs=slice(None, None, resol))

                if 'numobs' in lon.dims:
                    lon = lon.isel(numobs=slice(None, None, resol))

                if 'numobs' in lat.dims:
                    lat = lat.isel(numobs=slice(None, None, resol))

                if depth is not None and 'numobs' in depth.dims:
                    depth = depth.isel(numobs=slice(None, None, resol))

                value = value.load()
                lon = lon.load()
                lat = lat.load()

                if depth is not None:
                    depth = depth.load()
                if not isinstance(qc, float):
                    rla_qc = qc.load().values.squeeze()
                else:
                    rla_qc = qc

                value_np = np.asarray(value).squeeze()

                mask = (
                    ~np.isnan(value_np)
                    & (value_np > seuil)
                )

                rla_value = value_np[mask]
                rla_lon = np.asarray(lon).squeeze()[mask]
                rla_lat = np.asarray(lat).squeeze()[mask]

                if depth is not None:
                    rla_depth = np.asarray(depth).squeeze()[mask]
                else:
                    rla_depth = np.zeros_like(rla_value)
                if not isinstance(rla_qc, float):
                    rla_qc = rla_qc[mask]

                tab_dims['nb_obs'] = np.count_nonzero(mask)

            else:
                # Load only here
                rla_value = value.load().values
                rla_lon = lon.load().values
                rla_lat = lat.load().values

                if depth is not None:
                    rla_depth = depth.load().values
                else:
                    nb_obs, nb_vars, nb_deps = rla_value.shape
                    rla_depth = np.zeros(
                        (nb_obs, nb_deps),
                        dtype=float,
                        order='F'
                    )
                if not isinstance(qc, float):
                    rla_qc = qc.load().values
                else:
                    rla_qc = qc
            _FillValue = value.attrs.get('_FillValue')
        finally:
            ds.close()
        nb_obs = len(rla_value)
        param_dict['ll_PSAL'] = True
        param_dict['ll_TEMP'] = True
        param_dict['varname_select'] = param_dict['varname']
        return (
            rla_lon,
            rla_lat,
            rla_value,
            nb_obs,
            rla_depth,
            rla_qc,
            tab_dims,
            param_dict,
            _FillValue
        )


    def read_pos_and_value_old(self, filename, param_dict, **args):
        param_dict['Design_GODAE_file'] = True
        rla_lon, rla_lat, _FillValue, nc = \
         self.generic_read_pos_and_value(filename, self.varname)
        rla_value = nc.variables[self.varname][:]
        input_var = args.get("input_var")
        #ncdata = xr.open_dataset(filename)
        #variables = ncdata.data_vars
        dimensions = nc.dimensions
        tab_dims = {}
        for dims in dimensions.keys():
            sizedim = dimensions[dims].size
            if dims == 'numfcsts':
                tab_dims['nb_fcsts'] = sizedim
            elif dims == 'numobs':
                tab_dims['nb_obs'] = sizedim
            elif dims == 'numdeps':
                tab_dims['nb_depths'] = sizedim

        if 'depth' in nc.variables.keys():
            rla_depth = nc.variables['depth'][:]
        elif 'DEPH' in nc.variables.keys():
            rla_depth = nc.variables['DEPH'][:]
        elif 'pres' in nc.variables.keys():
            rla_depth = nc.variables['pres'][:]
        elif 'PRES' in nc.variables.keys():
            rla_depth = nc.variables['PRES'][:]
        else:
            ## No depth: surface variable
            nb_obs, nb_vars, nb_deps = np.shape(rla_value)
            rla_depth = np.ndarray(shape=(nb_obs,nb_deps),dtype=float, order='F')
            rla_depth[:, 0] = 0
        if 'qc' in nc.variables.keys():
            rla_qc = nc.variables['qc'][:]
        else:
            rla_qc = np.nan
        nb_obs = len(rla_value)
        param_dict['ll_PSAL'] = True
        param_dict['ll_TEMP'] = True
        param_dict['varname_select'] = param_dict['varname']
        nc.close()
        if input_var[0] in self.icevarname:
            print('Oversampling ice')
            resol = 10
            seuil = 0.15
            indexes = np.where(
                    (~np.isnan(np.squeeze(rla_value)[::resol])) 
                    & (np.squeeze(rla_value)[::resol] > seuil))
            rla_lon = np.squeeze(rla_lon)[indexes]
            rla_lat = np.squeeze(rla_lat)[indexes]
            rla_value = np.squeeze(rla_value)[indexes]
            rla_depth = np.squeeze(rla_depth)[indexes]
            #rla_qc = np.squeeze(rla_qc)[indexes]
            tab_dims['nb_obs'] = len(indexes)

        return rla_lon, rla_lat, rla_value, nb_obs, rla_depth, rla_qc, tab_dims, param_dict, _FillValue

class PGN_coords_Loader(inputdata_loader):

    """Loader for PGN dataset"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variables = nc.variables
        list_lon = ['x', 'X', 'lon', 'LON', 'lons', 'longitude', 'LONGITUDE', 'nav_lon']
        list_lat = ['y', 'Y', 'lat', 'LAT', 'LATS', 'latitude', 'LATITUDE', 'nav_lat']
        list_depth = [ 'deptht', 'depth', 'z', 'Z', 'DEPTH','nav_lev']
        list_mask = [ 'tmask', 'mask']
        try:
            lon_name = [ k for k in variables.keys() & set(list_lon)][0]
            lat_name = [ k  for k in variables.keys() & set(list_lat)][0]
            depth_name = [ k for k in variables.keys() & set(list_depth)][0]
            mask_name = [ k for k in variables.keys() & set(list_mask)][0]
        except Exception as e:
            print(f'lon lat or depth not defined {e}')
            raise
        rla_lon = nc.variables[lon_name][:,:]
        rla_lat = nc.variables[lat_name][:,:]
        rla_mask = nc.variables[mask_name][:,:,:]
        depth_mod =  nc.variables[depth_name][:]
        nlat, nlon, ndepth = np.shape(rla_mask)
        mask_tab = np.full((nlat,nlon,ndepth), True)
        mask_tab = np.where(rla_mask == 1, False, mask_tab)
        nc.close()
        return rla_lon,rla_lat,mask_tab,depth_mod

class PGS_coords_Loader(inputdata_loader):

    """Loader for PGN dataset"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variables = nc.variables
        list_lon = ['x', 'X', 'lon', 'LON', 'lons', 'longitude', 'LONGITUDE', 'nav_lon']
        list_lat = ['y', 'Y', 'lat', 'LAT', 'LATS', 'latitude', 'LATITUDE', 'nav_lat']
        list_depth = [ 'deptht', 'depth', 'z', 'Z', 'DEPTH','nav_lev']
        list_mask = [ 'tmask', 'mask']
        try:
            lon_name = [ k for k in variables.keys() & set(list_lon)][0]
            lat_name = [ k  for k in variables.keys() & set(list_lat)][0]
            depth_name = [ k for k in variables.keys() & set(list_depth)][0]
            mask_name = [ k for k in variables.keys() & set(list_mask)][0]
        except Exception as e:
            print(f'lon lat or depth not defined {e}')
            raise
        rla_lon = nc.variables[lon_name][:]
        rla_lat = nc.variables[lat_name][:]
        rla_mask = nc.variables[mask_name][:,:,:]
        depth_mod =  nc.variables[depth_name][:]
        nlat, nlon, ndepth = np.shape(rla_mask)
        mask_tab = np.full((nlat,nlon,ndepth), True)
        mask_tab = np.where(rla_mask == 1, False, mask_tab)
        nc.close()
        return rla_lon,rla_lat,mask_tab,depth_mod

class ease_coords_Loader(inputdata_loader):

    """Loader for 2 ease stereopolar grid"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variables = nc.variables
        list_lon = ['x', 'X', 'lon', 'LON', 'lons', 'longitude', 'LONGITUDE', 'nav_lon']
        list_lat = ['y', 'Y', 'lat', 'LAT', 'LATS', 'latitude', 'LATITUDE', 'nav_lat']
        try:
            lon_name = [ k for k in variables.keys() & set(list_lon)][0]
            lat_name = [ k  for k in variables.keys() & set(list_lat)][0]
        except Exception as e:
            print(f'lon lat or depth not defined {e}')
            raise
        rla_lon = nc.variables[lon_name][:,:]
        rla_lat = nc.variables[lat_name][:,:]
        depth_mod = 0
        mask_tab = np.nan
        nc.close()
        return rla_lon,rla_lat,mask_tab,depth_mod


class PGN_coords_clim_Loader(inputdata_loader):

    """Loader for PGN dataset"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'lon'
        rla_lon = nc.variables[variable][:,:]
        variable = 'lat'
        rla_lat = nc.variables[variable][:,:]
        variable = 'tmask'
        rla_mask = nc.variables[variable][:,:,:]
        variable = 'nav_lev'
        depth_mod =  nc.variables[variable][:]
        nlat, nlon, ndepth = np.shape(rla_mask)
        mask_tab = np.full((nlat,nlon,ndepth), True)
        mask_tab = np.where(rla_mask == 1, False, mask_tab)
        nc.close()
        return rla_lon,rla_lat,mask_tab,depth_mod


class alleges_coords(inputdata_loader):

    """Loader for Alleges Mask"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'longitude'
        rla_lon = nc.variables[variable][:,:]
        variable = 'latitude'
        rla_lat = nc.variables[variable][:,:]
        variable = 'depth'
        rla_depth = nc.variables[variable][:]
        variable = 'mask'
        rla_mask = nc.variables[variable][:,:,:]
        ndepth, nlat, nlon = np.shape(rla_mask)
        print ("depth {} Lat {} Lon {}".format(ndepth,nlat, nlon))
        mask_tab = np.full((ndepth,nlat,nlon), True)
        mask_tab = np.where(rla_mask == 1, False, mask_tab)
        nc.close()
        return rla_lon, rla_lat, mask_tab, rla_depth

class bathy_coords(inputdata_loader):
    """Loader for bathy coordinates"""
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'nav_lon'
        rla_lon = nc.variables[variable][:,:]
        variable = 'nav_lat'
        rla_lat = nc.variables[variable][:,:]
        mask_tab = None
        rla_depth = 0
        nc.close()
        return rla_lon,rla_lat, mask_tab, rla_depth

class read_Legos_SIT(inputdata_loader):
    
    """Loader LEGOS SIT files"""
    def __init__(self):
        self.varname_list = ['snow_depth_W99','radar_freeboard_20hz']

    def read_pos_and_value(self,filename):

        try:
            nc = netCDF4.Dataset(filename, 'r')
            if len(set(nc.variables).intersection(self.varname_list)) == 1:
                self.varname = list(set.intersection(set(self.varname_list), set(nc.variables)))[0]
            nc.close()
        except Exception as e:
            raise (f"Pb read_Legos_SIT varname missing {self.varname_list} {e}")
        rla_lon, rla_lat, _FillValue, nc = \
          self.generic_read_pos_and_value(filename, self.varname)
        rla_value = nc.variables[self.varname][:]
        if 'depth' in nc.variables.keys():
            rla_depth = nc.variables['depth'][:]
        elif 'DEPH' in nc.variables.keys():
            rla_depth = nc.variables['DEPH'][:]
        elif 'pres' in nc.variables.keys():
            rla_depth = nc.variables['pres'][:]
        elif 'PRES' in nc.variables.keys():
            rla_depth = nc.variables['PRES'][:]
        else:
            ## No depth: surface variable
            nb_obs = np.shape(rla_lon)[0]
            nb_deps = 1
            rla_depth = np.ndarray(shape=(nb_obs,nb_deps),dtype=float, order='F')
            rla_depth[:,0] = 0
        nc.close()
        return rla_lon, rla_lat, rla_value, nb_obs, rla_depth, _FillValue


class AsciiLoader(inputdata_loader):

    """Loader for ASCII dataset"""

    def read_pos(self,filename):
        # print 'read ASCII file : %s ' %(filename)
        # data=np.genfromtxt(filename,usecols = (2,3),skip_header=1)
        data = np.genfromtxt(filename,usecols = (1,2),skip_header=1)
        position = np.array(data)
        return position

class ColocLoader(inputdata_loader):

    """Loader for coloc ASCII file"""

    def read_pos(self,filename):
        # print 'read ASCII file : %s ' %(filename)
        # data=np.genfromtxt(filename,usecols = (5,6))
        data = np.genfromtxt(filename,usecols = (15,16))
        position = np.array(data)
        return position

class LoaderCMEMSDrifter_filtr(inputdata_loader):

     """
        Loader for CMEMS drifters filtered
     """
     def read_pos_and_value(self, filename, param_dict, **args):
        lon, lat, depth, depth_qc, time, u, v, u_filtr, v_filtr, ll_var,\
            u_qc, v_qc, u_filtr_qc, v_filtr_qc, wind_u, wind_v, current_test, current_test_qc,\
            position_qc, time_qc, dc_reference = read_drifter_filt(filename)
        nb_obs = len(lon)
        _FillValue = np.nan
        tab_dims = {}
        param_dict['Design_GODAE_file'] = True
        #for dims in dimensions.keys():
        #    sizedim = dimensions[dims].size
        #    if dims == 'numfcsts':
        #        tab_dims['nb_fcsts'] = sizedim
        #    elif dims == 'numobs':
        #        tab_dims['nb_obs'] = sizedim
        #    elif dims == 'numdeps':
        #        tab_dims['nb_depths'] = sizedim
        #mask = lon <= 180
        mask = (
            np.isfinite(lon) &
            np.isfinite(lat) &
            (lon <= 180)
        )
        list_uo = ['uo', 'u']
        list_vo = ['vo', 'v']
        lon = lon[mask]
        lat = lat[mask]
        time = time[mask]
        current_test = current_test[mask]
        u_filtr_qc = u_filtr_qc[mask]
        v_filtr_qc = v_filtr_qc[mask]
        depth = depth[mask]
        u_filtr = u_filtr[mask]
        v_filtr = v_filtr[mask]
        # Filter with QC
        ll_filter= True
        if ll_filter:
            qc_val = np.where(current_test[:] >= 311)[0]
            lon = lon[qc_val]
            lat = lat[qc_val]
            time = time[qc_val]
            u_filtr = u_filtr[qc_val]
            v_filtr = v_filtr[qc_val]
            u_filtr_qc = u_filtr_qc[qc_val]
            v_filtr_qc = v_filtr_qc[qc_val]
            depth = depth[qc_val]
            print(f'% of good values : {len(qc_val)*100/len(current_test)}')
        nb_obs = len(lon)
        param_dict['varname_select'] = param_dict['varname']
        input_var = args.get("input_var")
        if len(input_var) < 2:
            if input_var[0] in list_uo:
                combined_UV = [u_filtr]
                combined_qc =  [u_filtr_qc]
            if input_var[0] in list_vo:
                combined_UV = [v_filtr]
                combined_qc = [v_filtr_qc]
        else:
            combined_UV= np.stack((np.squeeze(u_filtr), np.squeeze(v_filtr)), axis=1)
            combined_qc =  np.stack((np.squeeze(u_filtr_qc), np.squeeze(v_filtr_qc)), axis=1)
        param_dict['varname_select'] = param_dict['varname']

        return lon, lat, combined_UV, nb_obs, depth, combined_qc,  tab_dims, param_dict, _FillValue

class LoaderCMEMSDrifter(inputdata_loader):

     """
        Loader for CMEMS drifters
     """
     def read_pos_and_value(self, filename, param_dict, **args):
        lon, lat, depth, depth_qc, time, u, v, ll_var,\
            u_qc, v_qc, wind_u, wind_v, current_test, current_test_qc,\
            position_qc, time_qc, dc_reference = read_drifter(filename)
        mask = (
            np.isfinite(lon) &
            np.isfinite(lat) &
            (lon <= 180)
        )
        lon = lon[mask]
        lat = lat[mask]
        u_qc = u_qc[mask]
        v_qc = v_qc[mask]
        depth = depth[mask]
        u = u[mask]
        v = v[mask]
        nb_obs = len(lon)
        _FillValue = np.nan
        tab_dims = {}
        list_uo = ['uo', 'u']
        list_vo = ['vo', 'v']

        param_dict['Design_GODAE_file'] = True
        #for dims in dimensions.keys():
        #    sizedim = dimensions[dims].size
        #    if dims == 'numfcsts':
        #        tab_dims['nb_fcsts'] = sizedim
        #    elif dims == 'numobs':
        #        tab_dims['nb_obs'] = sizedim
        #    elif dims == 'numdeps':
        #        tab_dims['nb_depths'] = sizedim
        #combined_qc =  np.stack((u_qc, v_qc), axis=1)
        #combined_UV = np.stack((u, v), axis=1)
        param_dict['varname_select'] = param_dict['varname']
        input_var = args.get("input_var")
        if len(input_var) < 2:
            if input_var[0] in list_uo:
                list_obs = [u]
                list_qc = [u_qc]
            if input_var[0] in list_vo:
                list_obs = [v]
                list_qc = [v_qc]
        else:
            list_obs = [u, v]
            list_qc = [u_qc, v_qc]

        return lon, lat, list_obs, nb_obs, depth, list_qc, tab_dims, param_dict, _FillValue
        #return lon, lat, combined_UV, nb_obs, depth, combined_qc, tab_dims, param_dict, _FillValue

class SMOC_coords_Loader(inputdata_loader):
    """
       SMOC coordinates
    """
    def read_pos(self,filename):
        nc = netCDF4.Dataset(filename,'r')
        variable = 'longitude'
        rla_lon = nc.variables[variable][:]
        variable = 'latitude'
        rla_lat = nc.variables[variable][:]
        variable = 'depth'
        rla_depth = nc.variables[variable][:]
        variable = 'mask'
        rla_mask = nc.variables[variable][:,:,:]
        ndepth, nlat, nlon = np.shape(rla_mask)
        #print ("depth {} Lat {} Lon {}".format(ndepth,nlat, nlon))
        mask_tab = np.full((ndepth,nlat,nlon), True)
        mask_tab = np.where(rla_mask == 1, False, mask_tab)
        nc.close()
        return rla_lon,rla_lat,mask_tab,rla_depth

