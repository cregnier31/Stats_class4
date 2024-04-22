import os
import re
import sys
import numpy as np
import numpy.ma as ma
import json
from scipy.spatial import cKDTree
import xarray as xr
import dask
import vertical
from lib_pyt.libtools import *
from lib_pyt.reader.reader import ReadModel
from utils import find_index_month
from inputdata_loader import inputdata_loader
from collections import OrderedDict
from Interp_kdtree import interp_KDtree
from interpolate import search_orca, search_orca_4pts
from scipy.interpolate import InterpolatedUnivariateSpline, interp1d
from lib_pyt.plot.Profile import plot_2profiles, plot_3profiles, plot_2profiles_2
import matplotlib.pyplot as plt
from matplotlib import style
from Writer import Writer
from glob import glob
from reader import read_GODAE_profile
from Selector import Selector
from netCDF4 import Dataset
import netCDF4
from timeit import default_timer as timer
import dask
from dask.distributed import Client, SSHCluster
from joblib import Parallel, delayed

if sys.version_info[0] >= 3:
    import pickle
else:
    import cPickle

class BroadcastError(Exception):
        pass

class Interpolator(object):
    """
        Interpolator Class File : Interpolation with KDtree method
    """

    def __init__(self, log, dask=False):
        self.log = log
        self.missing_value = netCDF4.default_fillvals['f4']
        self.list_ssh = ["sossheig", "ssh"]
        self.ll_UVcorr = False
        self.compute_corr = False
        self.model_var = ['uo', 'vo', 'vozocrtx', 'vomecrty']
        self.listUV = ['drifter', 'drifter_filtr']
        self.list_insitu = ['BGC_ARGO', 'NC_CORIO_ORIGIN', 'NC_CORIO']
        self.tab_interp = {}
        if dask:
            self.log.debug("Launch dask server")
            #client = Client(n_workers=2, threads_per_worker=2, processes=False)
            #client
            #   worker_options={"nthreads": 2},
            cluster = SSHCluster( ["fidjim05-sihpc","fidjim06-sihpc","fidjim07-sihpc","fidjim08-sihpc"],
                                    connect_options={"known_hosts": "/home/smer/regnierc/.ssh/known_hosts" },
                                   scheduler_options={"port": 0, "dashboard_address": ":8797"})
            client = Client(cluster)
            client
        else:
            self.log.debug("Dask server not defined")


    def getneardepth(self, array, value):
       idx = (np.abs(array-value)).argmin()
       return idx

    def getnearpos(self, array, value):
       if array == 0 :
           idx1 = 0
           idx2 = 0
       else:
          idx = (np.abs(array-value)).argmin()
          if value[idx] >= array:
             idx1 = idx - 1
             idx2 = idx
          else:
             idx1 = idx
             idx2 = idx + 1
       return idx1, idx2

    def getweight(self, depth1, depth2, depth):
        dist_tot = abs(depth2 - depth1)
        w1 = abs(1 -(abs(depth1 - depth) / dist_tot))
        w2 = abs(1- (abs(depth2 - depth) / dist_tot))

        if w1 + w2 > 1.0001 :
           self.log.error(f"Pb with weight files {w1} + {w2} > 1.00001 => {w1+w2}")
           sys.exit(1)
        return w1, w2

    def search_dims(self, filename):
        """
        Find the lon/lat dimensions of a file
        """
        nc = Dataset(filename,'r')
        list_lon = ['x','X','lon','long','longitude','longitudes']
        list_lat = ['y','Y','lat','lati','latitude','latitudes']
        nlon = None
        nlat = None
        for dim in nc.dimensions.keys():
            if dim.lower() in list_lon: nlon = nc.dimensions[dim].size
            if dim.lower() in list_lat: nlat = nc.dimensions[dim].size

        return nlon, nlat

    def compute_weight(self, ind, TreeObj, lon_mod, lat_mod, lon_obs, lat_obs,nb_ptsinterp, mask):
        ## Compute weight at each level
        d1, inds = TreeObj.tree_and_query(lon_mod, lat_mod,
                                          np.array(lon_obs), np.array(lat_obs), nb_ptsinterp,\
                                          weight_file='test.p',save=False, mask=mask)
        weight = TreeObj.get_weight(d1)

        return weight, inds


    def check_dimensions(self, list_input_file):
        """
        Check the existence and the dimensions of different lead times
        Arguments
        --------------------
        list_input_file : dictionnary with all the files to interp
        Returns
        --------------------
        len(best), len(fcst), len(pers), len(clim): len of different lead time files
        """
        best = {k for k, v in list_input_file.items() if "hdct" in k}
        clim = {k for k, v in list_input_file.items() if "clim" in k}
        #fcst = {k for k, v in list_input_file.items() if "fcst" in k}
        fcst = {k for k, v in list_input_file.items() if k.startswith("fcst")}
        pers = {k for k, v in list_input_file.items() if "pers" in k}
        nwct = {k for k, v in list_input_file.items() if "nwct" in k}
        return len(best), len(fcst), len(pers), len(clim), len(nwct)

    #def read_and_interp(self, data_file, list_input_file, param_dict, date=None):
    def read_and_interp(self, data_file, param_dict, date=None, leadtime=None, lead_int=None):
        """
        Read and Interp data files
        Read input file, compute coloc value and interp with KDtree
        Arguments
        --------------------
        data_file : input data file
        list_input_file : list of input files to interp
        param_dict : dictionnary with all the parameters
        Returns
        --------------------
        tab_results : dictionnary with interpolated arrays
        file_out : name of output file
        """
        # Initialisation
        ll_clim = False
        ll_json = False
        ll_verif = False
        ## Todo write into a file
        nb_ptsinterp = param_dict['nb_points']
        # Read input obs value
        self.log.debug(f"Format of the data {param_dict['data_format']}")
        if param_dict['prefix_data'].startswith("BGC_ARGO"):
            variable_obs = param_dict['prefix_data'].split('BGC_ARGO_')[1]+'_ADJUSTED'
            lon_obs, lat_obs, obs_value, nb_obs, depth, _FillValue = \
                    inputdata_loader(self.log).factory(param_dict['data_format']).\
                    read_pos_and_value(data_file, param_dict, varname=variable_obs)
        else:
            self.log.debug(f"Read pos and value : {param_dict['data_format']}")
            lon_obs, lat_obs, obs_value, nb_obs, depth, tab_dims, param_dict,  _FillValue = \
                    inputdata_loader(self.log).factory(param_dict['data_format']).\
                    read_pos_and_value(data_file, param_dict)
        tuple_obs = (np.shape(lon_obs)[0], np.shape(lat_obs)[0])
        ## Find input model files
        # Selection of the input model data
        self.log.info(f"Selection of input model {param_dict['data_type']}")
        self.log.info('========================================================')
        list_input_file, ll_miss = Selector(param_dict['data_format'], param_dict['data_type'], self.log).\
            factory("GLOBAL_INPUT_MODEL_DATA").run(param_dict, date, leadtime, lead_int)
        self.log.debug(f'Select model ok {list_input_file}')
        nb_best, nb_fcst, nb_pers, nb_clim, nb_nwct = \
                    self.check_dimensions(list_input_file)
        self.log.info("==================================================")
        self.log.info(f" Interp file {data_file}")
        self.log.info("==================================================")
        self.log.info(f"Dimensions best : {nb_best} nwct: {nb_nwct} "\
                      f"fcst : {nb_fcst} pers : {nb_pers} clim : {nb_clim}")
        #nb_profs, nb_levels, nb_vars = np.shape(obs_value)
        ## TODO compare parameters in obs_value and input variables to remove variable if necessary

        if param_dict['coordinates_hgr']:
            try:
                self.log.debug("Read coordinates for the correction of UV drifters")
                mod_hgr = xr.open_dataset(param_dict['coordinates_hgr'])
                self.gsinU = mod_hgr['gsinu']
                self.gcosU = mod_hgr['gcosu']
                self.gsinV = mod_hgr['gsinv']
                self.gcosV = mod_hgr['gcosv']
                self.gsinT = mod_hgr['gsint']
                self.gcosT = mod_hgr['gcost']
                self.log.debug(f"Read ok")
            except IOError:
                self.log.error("Open Error coordinates_hgr")
            self.log.debug("Open hgr ok")

        if param_dict['corr']:
            self.compute_corr = True
            self.log.info(f"Add Correction {param_dict['corr']}")
        else:
            self.log.debug(f"No correction")
        self.log.debug(f"{lon_obs=}")
        ll_best = False
        nb_obs2, nb_profs = np.shape(depth)
        self.log.debug("Number of observations {} Profondeurs {}".format(nb_obs2, nb_profs))
        if 'varname_select' in param_dict.keys():
            variable = param_dict['varname_select']
        else:
            variable = param_dict['varname']
        self.log.debug(f"Variable : {variable}")
        if nb_best > 0:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                hdct_tab = np.ndarray(shape=(nb_obs, 1, 1), dtype=float, order='F')
            else :
                hdct_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs), dtype=float, order='F')
            hdct_tab[:, :, :] = self.missing_value
            self.log.debug("Taille hdct_tab {}".format(np.shape(hdct_tab)))
            ll_best = True
        ll_fcst = False
        if nb_fcst > 0:
            if 'nb_fcsts' not in tab_dims.keys():
                nb_fcst = len(param_dict['lead_int'])
                fcst_tab = np.ndarray(shape=(nb_obs, len(variable), nb_fcst, nb_profs),
                                      dtype=float, order='F')
            else:
                fcst_tab = np.ndarray(shape=(nb_obs, len(variable), tab_dims['nb_fcsts'], nb_profs),
                                      dtype=float, order='F')
            fcst_tab[:, :, :, :] = self.missing_value
            ll_fcst = True
        ll_pers = False
        if nb_pers > 0 or nb_nwct >0:
            if 'nb_fcsts' not in tab_dims.keys():
                nb_fcst = len(param_dict['lead_int'])
                #pers_tab = np.ndarray(shape=(nb_obs, len(variable), nb_pers+1, nb_profs),
                #                      dtype=float, order='F')
                pers_tab = np.ndarray(shape=(nb_obs, len(variable), nb_fcst, nb_profs),
                                      dtype=float, order='F')
            else:
                pers_tab = np.ndarray(shape=(nb_obs, len(variable), tab_dims['nb_fcsts'], nb_profs),
                                      dtype=float, order='F')
            pers_tab[:, :, :, :] = self.missing_value
            ll_pers = True
        if nb_clim > 0:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                clim_tab = np.ndarray(shape=(nb_obs, 1, 1),
                           dtype=float, order='F')
                clim_tab[:, :, :] = self.missing_value
            else:
                clim_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs),
                                      dtype=float, order='F')
                clim_tab[:, :, :] = self.missing_value
            ll_clim = True
        self.log.debug('Number obs to coloc {} '.format(nb_obs2))
        file_coloc_tmp = os.path.basename(data_file)
        file_out = file_coloc_tmp
        list_2D = ["smoc", "tides", "clim", "bathy", "stokes"]
        list_2D_smoc = ["smoc", "tides", "stokes"]
        # Loop on lead times
        ll_light = False
        ll_smoc = False
        ll_smoc_fcst = False
        ll_tides = False
        ll_stokes = False
        ll_stokes_fcst = False
        ll_c_smoc =  False
        ll_c_stokes =  False
        ll_bathy = False
        tab_depth = {}

        for i, key in enumerate(list_input_file.keys()):
            self.log.debug("Lead time "+key)
            if 'varname_select' in param_dict.keys():
                variable = param_dict['varname_select']
            else:
                variable = param_dict['varname']
            if key.lower() == "smoc":
                variable = param_dict['varname_smoc']
                ll_smoc = True
                smoc_tab = np.ndarray(shape=(nb_obs,len(variable), nb_profs),
                           dtype=float, order='F')
                smoc_tab[:, :, :] = self.missing_value
            if key.lower().startswith("smoc_fcst"):
                variable = param_dict['varname_smoc']
                ll_smoc_fcst = True
                if not ll_c_smoc :
                    nb_fcst2 = len(param_dict['lead_int2'])
                    smoc_fcst_tab = np.ndarray(shape=(nb_obs,len(variable), nb_fcst2, nb_profs),
                           dtype=float, order='F')
                    smoc_fcst_tab[:, :, :, :] = self.missing_value
                    ll_c_smoc = True
            if key.lower() == "tides":
                variable = param_dict['varname_tides']
                ll_tides = True
                tides_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs),
                           dtype=float, order='F')
                tides_tab[:, :, :] = self.missing_value
            if key.lower() == "stokes":
                variable = param_dict['varname_stokes']
                ll_stokes = True
                if not ll_c_stokes :
                    stokes_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs),
                               dtype=float, order='F')
                    stokes_tab[:, :, :] = self.missing_value
                    ll_c_stokes = True
            if key.lower().startswith("stokes_fcst"):
                nb_fcst2 = len(param_dict['lead_int2'])
                variable = param_dict['varname_stokes']
                ll_stokes_fcst = True
                stokes_fcst_tab = np.ndarray(shape=(nb_obs, len(variable), nb_fcst2, nb_profs),
                           dtype=float, order='F')
                stokes_fcst_tab[:, :, :, :] = self.missing_value
            if key.lower() == "bathy":
                ll_bathy = True
                variable = param_dict['varname_bathy']
                bathy_tab = np.ndarray(shape=(nb_obs,nb_profs), dtype=float, order='F')
                bathy_tab[:, :] = self.missing_value
            # Create weight file
            if key.lower() == "clim": ll_clim = True
            if key.lower() == "clim" and param_dict['data_type'].lower() == 'chloro':
                lon_mod, lat_mod = inputdata_loader(self.log).factory(
                    'NC_CLIM').read_pos(param_dict['coord_clim'])
                file_coloc_tmp = re.sub('.nc', '_Kdtree_CLIM_' +
                                        param_dict['cl_typemod'].upper()+'_idw' +
                                        str(nb_ptsinterp) + 'pt.p', file_out)
                variable = []
                variable.append(param_dict['varname_select'][0].upper()+'_mean')
                nlon, nlat = self.search_dims(param_dict['coord_clim'])
                tuple_coord = (nlon, nlat)
            elif key.lower() == "clim" and param_dict['data_type'].lower() == 'drifter_filtr' \
                or key.lower() == "clim" and param_dict['data_type'].lower() == 'drifter' \
                or key.lower() == "clim" and param_dict['data_type'].lower() == 'current':
                self.log.debug("CLIM coordinates")
                lon_mod, lat_mod = inputdata_loader(self.log).factory(
                    'NC_CLIM').read_pos(param_dict['coord_clim'])
                variable = ['U', 'V']
                nlon, nlat = self.search_dims(param_dict['coord_clim'])
                tuple_coord = (nlon, nlat)
            elif key.lower() == "bathy":
                self.log.debug("bathy coordinates")
                lon_mod, lat_mod = inputdata_loader(self.log).factory(
                    'bathymetrie').read_pos(param_dict['bathy_file'])
                nlon, nlat = self.search_dims(param_dict['bathy_file'])
                tuple_coord = (nlon, nlat)
            else:
                if param_dict['coordinates']:
                    if param_dict['cl_typemod'].lower() == "pgn":
                        if key.lower() in list_2D_smoc or key.lower().startswith("stokes_fcst") or key.lower().startswith("smoc_fcst"):
                            self.log.debug("SMOC coordinates")
                            lon_mod, lat_mod, mask_tab, depth_mod = inputdata_loader(self.log).factory('SMOC_coords').\
                                read_pos(param_dict['coordinates_SMOC'])
                        else:
                            self.log.debug("PGN coordinates")
                            lon_mod, lat_mod, mask_tab, depth_mod = inputdata_loader(self.log).factory('PGN_coords').\
                                read_pos(param_dict['coordinates'])
                    elif param_dict['cl_typemod'].lower() == "allege":
                        lon_mod, lat_mod, mask_tab, depth_mod = inputdata_loader(self.log).factory('alleges_coords').\
                            read_pos(param_dict['coordinates'])
                        self.log.debug('Read coords Alleges OK ')
                        ll_light = True
                        if key.lower() == "clim" : ll_light = False
                    elif param_dict['cl_typemod'].lower() == "2ease":
                        lon_mod, lat_mod, mask_tab, depth_mod = inputdata_loader(self.log).factory('2ease_coords').\
                            read_pos(param_dict['coordinates'])
                    else:
                        self.log.error("Type mod not known")
                    nlon, nlat = self.search_dims(param_dict['coordinates'])
                    tuple_coord = (nlon, nlat)
                else:
                    self.log.error("No coordinates files")
                    # TODO read lon/lat from first file
                    raise
                file_coloc_tmp = re.sub('.nc', '_Kdtree_' +
                                        param_dict['cl_typemod'].upper()+'_idw' +
                                        str(nb_ptsinterp) + 'pt.p', file_out)
            weight_file = param_dict['coloc_rep'] + file_coloc_tmp
            self.log.debug("Weight_file: {} ".format(weight_file))
            same_grid = False
            if tuple_obs == tuple_coord:
                same_grid = True
                weights =  None
                indexes = None
            self.log.debug("Dimension tuples {} {} same_grid {}".format(tuple_obs,tuple_coord,same_grid))
            # Coloc file
            if len(np.unique(depth)) == 1 or \
                key.lower() == "clim" and param_dict['data_type'].lower() == 'current':
                TreeObj = interp_KDtree(self.log) #level=self.log.level)
                ## No mask with ice dataset create issues in the ANT
                d1, indexes = TreeObj.tree_and_query(lon_mod, lat_mod,
                                                     lon_obs, lat_obs, nb_ptsinterp,\
                                                      weight_file=weight_file,save=False)
                weights = TreeObj.get_weight(d1)
                tab_weight = np.asarray(weights)
                tab_indexes = np.asarray(indexes)
                maxdepth =  np.nanmax(depth)
                self.log.debug('maxdepth {}'.format(maxdepth))
                ind_depth = self.getneardepth(depth_mod, maxdepth)
                ind_tot = len(depth_mod)
                ## Loop on levels
                ind_max = ind_depth


            elif len(np.unique(depth)) > 1:
                ## Compte weight file
                nb_obs, nb_profs = np.shape(depth)
                self.log.debug(f"Nb_profils {nb_obs} Nb levels {nb_profs}")
                maxdepth =  np.nanmax(depth)
                self.log.debug('maxdepth {}'.format(maxdepth))
                ind_depth = self.getneardepth(depth_mod, maxdepth)
                ind_tot = len(depth_mod)
                ## Loop on levels
                if ind_depth < ind_tot-2:
                   ind_max = ind_depth+2
                else:
                    ind_max = ind_depth
                self.log.debug(f'maxdepth {maxdepth} maxind {ind_max} nearest depth model {depth_mod[ind_depth]}')
                ## Compute weight
                TreeObj = interp_KDtree(self.log)
                tab_weight = np.nan*np.zeros((nb_obs,nb_ptsinterp,ind_max),dtype=float)
                tab_indexes = np.ndarray(shape=(nb_obs, nb_ptsinterp,ind_max), dtype=int, order='F')
                start = timer()
                ## Parallelize Loop on levels
                self.log.debug(f'Dimensions {len(lon_obs)}')
                nb_compute = len(lon_obs)
                #num_cores = int(ind_max/10)
                #if num_cores < 1:
                #    num_cores = 1
                num_cores = 10
                ## Compute weight
                with Parallel(n_jobs=num_cores, prefer="threads", verbose=1) as parallel:
                    weight, indexes  = zip(*parallel(delayed(self.compute_weight)(ind,TreeObj,lon_mod,lat_mod,np.array(lon_obs),\
                                                                    np.array(lat_obs), nb_ptsinterp,\
                                                                    mask_tab[ind,:,:]) for ind in range(ind_max)))
                tab_weight = np.asarray(weight)
                tab_indexes = np.asarray(indexes)
                end = timer()
                self.log.debug('~~~~~~~~ Time elapsed compute weight on levels: %s %s' %
                              (str(end - start), " seconds ~~~~~~~~~~~~"))

            # Interp model file for different lead times
            self.log.debug('Variable to interpolate {} '.format(variable))
            tab_results = {}
            list_file = []
            list_file = list_input_file[key]
            self.log.debug("Work on {} variables".format(len(variable)))
            ## loop on variable
            for var in range(len(variable)):
               ## Get the correct file
               varname = variable[var]
               tab_results['varname'] = varname
               ll_miss = False
               try:
                   file_input = list_input_file[key][var]
               except IndexError as error:
                   self.log.error(f"Error {error} Missing file for key {key} var {var}")
                   self.log.error("Varname {}".format(varname))
                   ll_miss = True
                   sys.exit(1)
               ll_unique = False
               if not ll_miss:
                  if len(np.unique(depth)) == 1:
                      index_time=0
                      if key.lower() == "clim": index_time=find_index_month(date)-1
                      self.log.debug("Unique depth for all the observations")
                      if len(np.shape(depth)) == 1 :
                          depthval = depth[0]
                      elif len(np.shape(depth)) == 2 :
                          depthval = depth[0,0]
                      else:
                          self.log.error("Case not known")
                      ## Selection of the depth value
                      if key.lower() in list_2D or key.lower().startswith("stokes_fcst") or key.lower().startswith("smoc_fcst"):
                          tab_depth[key.lower()] = 0 
                      else:
                          tab_depth[key.lower()] = depthval 
                      self.log.debug("Depth of interpolation {}".format(tab_depth[key.lower()]))
                      self.log.debug("Index time {}".format(index_time))
                      self.log.debug(f"Interp 2D {varname=}")
                      interp_values = self.interp_2D(weights, indexes,
                                                     file_input,
                                                     nb_ptsinterp,
                                                     varname, param_dict, key=key,
                                                     depth=tab_depth[key.lower()], fillvalue=_FillValue,
                                                     time=index_time, nblon=nlon, nblat=nlat,
                                                     lon_mod=lon_mod, lat_mod=lat_mod,
                                                     missing_value=self.missing_value,
                                                     same_grid=same_grid)
                      self.log.debug(f"Interp value {interp_values}")
                      self.compute = False
                      if varname in self.model_var and self.compute_corr and not self.compute: 
                          self.log.debug('Interp grid coordinates for the correction')
                          #self.tab_interp['gsinU'] = ma.array(self.gsinU).flatten()[indexes]
                          #self.tab_interp['gsinV'] = ma.array(self.gsinV).flatten()[indexes]
                          #self.tab_interp['gcosU'] = ma.array(self.gcosU).flatten()[indexes]
                          #self.tab_interp['gcosV'] = ma.array(self.gcosV).flatten()[indexes]
                          self.tab_interp['gsint'] = np.sum(weights * np.array(self.gsinT).flatten()
                                       [indexes], axis=1) / np.sum(weights, axis=1)
                          #ma.array(self.gsinT).flatten()[indexes]
                          self.tab_interp['gcost'] = np.sum(weights * np.array(self.gcosT).flatten()
                                        [indexes], axis=1) / np.sum(weights, axis=1)
                          #ma.array(self.gcosT).flatten()[indexes]
                          self.compute = True
                          # ucorr0 = values_u0*gcost_interp - values_v0*gsint_interp
                          # vcorr0 = values_u0*gsint_interp + values_v0*gcost_interp
                          # ucorr15 = values_u15_interp*gcost_interp - values_v15_interp*gsint_interp
                          # vcorr15 = values_u15_interp*gsint_interp + values_v15_interp*gcost_interp
                      if len(np.shape(obs_value)) ==  3:
                          ## Case for surface drifters and profiles with the dimensions 1 depth 1 profile
                          try:
                              if param_dict['data_type'].lower() == 'drifter_filtr' or param_dict['data_type'].lower() == 'drifter':
                                 obs_value2 = np.array(obs_value)[var, :, :]
                              else:
                                  #obs_value2 = np.array(obs_value)[:,:,var]
                                  obs_value2 = np.array(obs_value)[:, var, :]
                                  self.log.debug(f'Case 1 depth 1 profile : {obs_value2}')

                              interp_values = np.where(np.array(obs_value2).flatten() == _FillValue,
                                                                self.missing_value, np.array(interp_values))
                          except BroadcastError as e:
                              raise(f'PB file modele {file_input} obs {data_file} Error {e}')
                          self.log.debug(f'Interp : {interp_values}')

                      elif len(np.shape(obs_value)) ==  2:
                          interp_values = np.where(np.array(obs_value).flatten() == _FillValue,
                                                            self.missing_value, np.array(interp_values))
                      ll_unique = True
                  elif key.lower() == "clim" and param_dict['data_type'].lower() == 'current' :
                      depthval = 0
                      index_time=find_index_month(date)-1
                      interp_values = self.interp_2D(weights, indexes,
                                                     file_input,
                                                     nb_ptsinterp,
                                                     varname, param_dict, key=key,
                                                     depth=depthval, fillvalue=_FillValue,
                                                     time=index_time, nblon=nlon, nblat=nlat,
                                                     lon_mod=lon_mod, lat_mod=lat_mod,
                                                     missing_value=self.missing_value,
                                                     same_grid=same_grid)
                      self.log.debug("Max value for the interpolation {}".format(np.nanmax(interp_values)))
                      ll_unique = True
                      ##
                  else :
                     self.log.debug("Profile case variable : {}".format(variable[var]))
                     self.log.debug(f"{depth=} {ind_max=} ")
                     try:
                        if param_dict['data_format'] in self.list_insitu:
                            obs_tab = None
                        else:
                            obs_tab = obs_value[:,var,:]
                        interp_values = self.interp_3D(tab_weight,
                                                        tab_indexes,
                                                        ind_max,
                                                        file_input, nb_ptsinterp,
                                                        varname, depth, ll_verif = param_dict['verif'],
                                                        obs = obs_tab,
                                                        dateval=date, lon=lon_obs, lat=lat_obs, light=ll_light,
                                                        clim=ll_clim, depth_mod=depth_mod, fillvalue=self.missing_value)
                     except Exception as e:
                         self.log.error(f"Size obs {np.shape(obs_value[:,var,:])}")
                         self.log.error(f"Pb with file {e} {depth} {ind_max} {file_input} Obs {data_file}")
                         sys.exit(1)

                     ll_json = param_dict['json']
                     if ll_json:
                         if len(np.shape(obs_value)) ==  3: obs_value2 = np.array(obs_value)[:,var,:]
                         for ind_prf in range(nb_obs2):
                            index_ok = np.where(np.array(obs_value2[ind_prf,:]) != _FillValue)
                            dir_out2 = './json/'
                            filename_json = dir_out2+str(date)+"_"+varname+"_profile_"+str(ind_prf)+".json"
                            tab_profile = {}
                            tab_profile['longitude'] = np.array(lon_obs[ind_prf]).tolist()
                            tab_profile['latitude'] = np.array(lat_obs[ind_prf]).tolist()
                            tab_profile['Insitu'] = list(zip(np.array(depth[ind_prf,index_ok]).tolist()[0], np.array(obs_value2[ind_prf,index_ok]).tolist()[0]))
                            tab_profile['Model'] = list(zip(np.array(depth[ind_prf,index_ok]).tolist()[0], np.array(interp_values[ind_prf,index_ok]).tolist()[0]))
                            Writer(self.log).write_json_profile(filename_json, tab_profile)
               else:
                   interp_values = np.ndarray(shape=(nb_obs, nb_profs),
                                         dtype=float, order='F')
                   interp_values[:, :] = self.missing_value


               if key[0:4] == 'fcst':
                   if len(key) > 4:
                       indice = int(key[4])
                   else:
                       indice = 0
                   self.log.debug("Fead forecast indice %i " % (indice))
                   if ll_unique :
                       try:
                          fcst_tab[:, var, indice, 0] = interp_values
                          if self.compute and var == len(variable)-1:
                             self.log.debug(f'Compute correction fcst {indice}')
                             fcst_tab[:, 0, indice, 0] = fcst_tab[:, 0, indice, 0] * \
                                self.tab_interp['gcost'] - fcst_tab[:, 1, indice, 0] * \
                                self.tab_interp['gsint']
                             fcst_tab[:, 1, indice, 0] = fcst_tab[:, 0, indice, 0]* \
                                 self.tab_interp['gsint'] + fcst_tab[:, 1, indice, 0]* \
                                 self.tab_interp['gcost']
                       except Exception as e:
                           self.log.debug(f"Error for the forecast variable {var} {indice} {data_file}")
                   else:
                       fcst_tab[:, var, indice, :] = interp_values
               elif key[0:4] == 'nwct':
                   indice = 0
                   self.log.debug("%s Persistence nwct indice  %i " %(key,indice))
                   if ll_unique :
                       pers_tab[:, var, indice, 0] = interp_values
                       if self.compute and var == len(variable)-1:
                          self.log.debug(f'Compute correction nwct {var}')
                          pers_tab[:, 0, indice, 0] = pers_tab[:, 0, indice, 0] * \
                             self.tab_interp['gcost'] - pers_tab[:, 1, indice, 0] * \
                             self.tab_interp['gsint']
                          pers_tab[:, 1, indice, 0] = pers_tab[:, 0, indice, 0]* \
                              self.tab_interp['gsint'] + pers_tab[:, 1, indice, 0]* \
                              self.tab_interp['gcost']
                   else:
                       pers_tab[:, var, indice, :] = interp_values
               elif key[0:4] == 'pers':
                   if len(key) > 4:
                       indice = int(key[4])
                   else:
                       indice = 0
                   self.log.debug("Persistence indice %i " % (indice))
                   if ll_unique :
                        pers_tab[:, var, indice, 0] = interp_values
                        if self.compute and var == len(variable)-1:
                           self.log.debug(f'Compute correction pers {indice}')
                           pers_tab[:, 0, indice, 0] = pers_tab[:, 0, indice, 0] * \
                              self.tab_interp['gcost'] - pers_tab[:, 1, indice, 0] * \
                              self.tab_interp['gsint']
                           pers_tab[:, 1, indice, 0] = pers_tab[:, 0, indice, 0]* \
                              self.tab_interp['gsint'] + pers_tab[:, 1, indice, 0]* \
                              self.tab_interp['gcost']
                   else:
                       pers_tab[:, var, indice, :] = interp_values
               elif key[0:4] == 'hdct':
                   self.log.debug(f'{var=}{varname=}')
                   if ll_unique :
                       self.log.debug(f'Case uniq {var} {np.shape(hdct_tab)}')
                       try:
                           hdct_tab[:, var, 0] = interp_values
                       except ValueError as e:
                           raise BroadcastError(f"{file_input} {data_file} Custom BroadcastError: {e}")
                       if self.compute and var == len(variable)-1:
                           self.log.debug('Compute correction hindcast')
                           hdct_tab[:, 0, 0] = hdct_tab[:, 0, 0]* \
                              self.tab_interp['gcost'] - hdct_tab[:, 1, 0]* \
                              self.tab_interp['gsint']
                           hdct_tab[:, 1, 0] = hdct_tab[:, 0, 0]* \
                              self.tab_interp['gsint'] + hdct_tab[:, 1, 0]* \
                              self.tab_interp['gcost']
                   else:
                       hdct_tab[:, var, :] = interp_values

               elif key[0:4] == 'clim':
                   if ll_unique:
                       clim_tab[:, var, 0] = interp_values
                       index_nan = np.isnan(interp_values)
                       self.log.debug('% of bad values for clim {}'.format((np.shape(interp_values[index_nan])[0]/np.shape(interp_values)[0]) * 100))
                       if ll_json:
                           lon_nan = lon_obs[index_nan]
                           lat_nan = lat_obs[index_nan]
                           zip_val = list(zip(lon_nan.tolist(),lat_nan.tolist()))
                           filename = "missing_clim_"+str(date)+".json"
                           with open(filename, 'w') as outfile:
                               json.dump(zip_val, outfile,indent=4)
                   else:
                       clim_tab[:, var, :] = interp_values
               elif key == 'smoc':
                  self.log.debug("Fead with smoc values")
                  if ll_unique :
                      smoc_tab[:, var, 0] = interp_values
                  else:
                      smoc_tab[:, var, :] = interp_values
               elif key.startswith('smoc_fcst'):
                  self.log.debug("Fead with smoc fcst values")
                  indice = int(key[9])
                  if ll_unique :
                      smoc_fcst_tab[:, var, indice, 0] = interp_values
                      self.log.debug("indice {}".format(indice))
                      self.log.debug(" Var {}".format(var))
                      self.log.debug("Values {}".format(smoc_fcst_tab[:, var, indice, 0]))
                  else:
                      smoc_fcst_tab[:, var, indice, :] = interp_values
               elif key.startswith('stokes_fcst'):
                  indice = int(key[11])
                  self.log.debug("Fead Stokes forecast indice %i " % (indice))
                  if ll_unique :
                      stokes_fcst_tab[:, var, indice, 0] = interp_values
                  else:
                      stockes_fcst_tab[:, var, indice, :] = interp_values
               elif key == 'stokes':
                  if ll_unique :
                      stokes_tab[:, var, 0] = interp_values
                  else:
                      stockes_tab[:, var, :] = interp_values
               elif key[0:4] == 'tide':
                  if ll_unique :
                      tides_tab[:, var, 0] = interp_values
                  else:
                       tides_tab[:, var, :] = interp_values
               elif key[0:5] == 'bathy':
                  self.log.debug('Key bathy {} :  {}'.format(key, interp_values))
                  bathy_tab[:, 0] = interp_values
               else:
                   self.log.debug(f'Key not found {key}')
                   sys.exit(1)
        ####
        if ll_best:
            self.log.debug(f"Value hindcast {hdct_tab}")
            self.log.debug(f"Value max hindcast {np.shape(hdct_tab)}")
            self.log.debug("Inside best data origin {}".format(param_dict['data_origin']))
            if param_dict['data_origin'] == "GLOBCOLOUR":
                hdct_tab = hdct_tab[:, 0, 0].reshape(
                    lat_obs.shape[0], lon_obs.shape[0])
            tab_results['best_estimate'] = hdct_tab
        if ll_fcst:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                fcst_tab = fcst_tab[:, 0, 0, 0].reshape(
                    lat_obs.shape[0], lon_obs.shape[0])
            tab_results['forecast'] = fcst_tab
        else:
            tab_results['forecast'] = None
        if ll_pers:
            tab_results['persistence'] = pers_tab
        else:
            tab_results['persistence'] = None

        if ll_clim:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                clim_tab = clim_tab[:, 0, 0].reshape(
                    lat_obs.shape[0], lon_obs.shape[0])
            tab_results['clim'] = clim_tab
        if ll_smoc: tab_results['smoc'] = smoc_tab
        if ll_smoc_fcst: tab_results['smoc_fcst'] = smoc_fcst_tab
        if ll_stokes: tab_results['stokes'] = stokes_tab
        if ll_stokes_fcst: tab_results['stokes_fcst'] = stokes_fcst_tab
        if ll_tides: tab_results['tides'] = tides_tab
        if ll_bathy: tab_results['bathy'] = bathy_tab
        if param_dict['Design_GODAE_file']:
            tab_results['observation'] = obs_value
            if 'varname_select' in param_dict.keys():
                tab_results['varname_select'] = param_dict['varname_select']
            tab_results['longitude'] = lon_obs
            tab_results['latitude'] = lat_obs
            tab_results['depth'] = depth
            if 'qc' in param_dict.keys():
                tab_results['qc'] = param_dict['qc']
            if 'LEVITUS_clim' in param_dict.keys():
                tab_results['LEVITUS_clim'] = param_dict['LEVITUS_clim']
        return tab_results, file_out

    def coloc_2D(self, lon_in, lon_out, lat_in, lat_out,
                 weight_file, nbpts_interp, log):
        """
        -------------------
        Coloc 2D
        Compute weight file with KDTree Method and store it in
        a pickle file
        Arguments
        --------------------
        lon_in : input longitude array
        lon_out : output longitude array
        lat_in : input latitude array
        lat_out : output latitude array
        weight_file : weight file
        nbpts_interp : number points for interpolation
            =>  1 = nearest
            =>  >1 IDW method
        log : logger object
        Returns
        --------------------
        WEIGHT : weight values
        inds_idw1 : index values in the grid
        """
        # Compute or not weight file
        if os.path.exists(weight_file):
            log.debug("load existing tree :%s " % (weight_file))
            if sys.version_info[0] >= 3:
                with open(weight_file, 'rb') as f:
                    zip_var = pickle.load(f)
                    d, inds_idw = list(zip(*zip_var))
            else:
                f = file(str(weight_file), 'r')
                zip_var = cPickle.load(f)
                d, inds_idw = zip(*zip_var)
            DIST = np.array(d)
            inds_idw1 = np.array(inds_idw)
            f.close
        else:
            log.debug("Create CKDTREE object")
            # Read input grid
            # Test size
            if len(lon_in.shape) > 1:
                X1, Y1 = lon_in, lat_in
            else:
                X1, Y1 = np.meshgrid(lon_in, lat_in)

            # Convert to cartesian
            xs, ys, zs = lon_lat_to_cartesian(X1.flatten(), Y1.flatten())
            # Read output grid
            X2, Y2 = lon_out, lat_out

            if isinstance(X2, np.float64) or isinstance(X2, np.float32):
                log.debug('X2 is a float')
            else:
                if len(X2)> 1:
                    global_step = float("{0:.2f}".format((X2[len(X2)-1]-X2[0])/(len(X2)-1)))
                    first_step = float("{0:.2f}".format(X2[1]-X2[0]))
                    log.debug('Step sizes %f %f ' % (global_step, first_step))
                else:
                    log.debug('Only one step')

            # 1D cases
            if  lon_out.ndim  == 0:
                log.debug('1D not regular')
                X2, Y2 = lon_out, lat_out
            elif lon_out.ndim < 2:
                if global_step == first_step:
                    # Regular
                    log.debug('1D regular => convert to meshgrid')
                    X2, Y2 = np.meshgrid(lon_out, lat_out)
                else:
                    # Irregular
                    log.debug('1D not regular')
                    X2, Y2 = lon_out, lat_out

            # Convert to cartesian
            xt, yt, zt = lon_lat_to_cartesian(X2.flatten(), Y2.flatten())
            if sys.version_info[0] >= 3:
                tree = cKDTree(list(zip(xs, ys, zs)))
                DIST, inds_idw1 = tree.query(
                    list(zip(xt, yt, zt)), k=nbpts_interp)
                with open(weight_file, 'wb') as f:
                    pickle.dump(list(zip(DIST, inds_idw1)),
                                f, pickle.HIGHEST_PROTOCOL)
            else:
                tree = cKDTree(zip(xs, ys, zs))
                DIST, inds_idw1 = tree.query(zip(xt, yt, zt), k=nbpts_interp)
                with open(weight_file, 'wb') as f:
                    cPickle.dump(zip(DIST, inds_idw1), f,
                                 protocol=cPickle.HIGHEST_PROTOCOL)
            f.close
        WEIGHT = 1.0 / DIST**2

        return WEIGHT, inds_idw1

    def test_lonlat(self, var_in, nblon, nblat):
        """
           Test if the matrix is in lon/lat instead of lat/lon
        """
        nsize1, nsize2 = np.shape(var_in)
        if nsize1 == nblon:
           ll_reshape = True
        else:
           ll_reshape = False
        return ll_reshape

    def interp_2D(self, weight, inds, file, nbpts_interp, variable, param_dict,\
            depth=0, time=0, key=None, fillvalue=None, nblon=None, nblat=None,
            lon_mod=None, lat_mod=None, missing_value=np.nan, same_grid=False):
        """
        -------------------
        2D interpolator
        Arguments
        --------------------
        weight_file : weight values
        inds : index values
        nbpts_interp : number points for interpolation
            =>  1 = nearest
            =>  >1 IDW method
        variable :  input_variable
        Returns
        --------------------
        interp tab : interpolated array
        """
        self.log.debug('Interp2D Read input file : {}'.format(file))
        self.log.debug('Variable : {}'.format(variable))
        try:
            dataset_in = xr.open_dataset(file,decode_times=False)
            var_in = dataset_in[variable]
        except:
            self.log.error("Missing File or variable {} in file {}".format(variable, file))
            raise
        ll_single = False
        if depth > 0.5 :
            ## Find the 2 points that enclose the depth value
            varname_depth = 'deptht'
            if variable == 'uo':
                varname_depth = 'depthu'
            elif variable == 'vo':
                varname_depth = 'depthv'
            depth_mod = dataset_in[varname_depth][:].values
            ind_depth1, ind_depth2 = self.getnearpos(depth, depth_mod)
            w1, w2 = self.getweight(depth_mod[ind_depth1], depth_mod[ind_depth2], depth)
            self.log.debug(f"Index of depth value {ind_depth1} {ind_depth2} {depth_mod[ind_depth1]} {depth_mod[ind_depth2]}")
            self.log.debug(f"weight {w1} {w2}")
        else:
            # Surface case
            ll_single = True
        if variable in self.list_ssh:
            cl_msshFile = param_dict['cl_msshFile']
            rp_mssh_shift = param_dict['rp_mssh_shift']
            self.log.debug(f'{cl_msshFile=}')
            dataset_mssh = xr.open_dataset(cl_msshFile)
            tab_mssh = dataset_mssh['mssh'].values

        if len(var_in.shape) == 3:
            if ll_single:
               var_in = var_in[time, :, :].values
            else:
               var_in1 = var_in[ind_depth1, :, :].values
               var_in2 = var_in[ind_depth2, :, :].values

        elif len(var_in.shape) == 4:
            if ll_single:
               var_in = var_in[time, 0, :, :].values
               ll_single = True
            else:
               var_in1 = var_in[time, ind_depth1, :, :].values
               var_in2 = var_in[time, ind_depth2, :, :].values
        if variable in self.list_ssh:
            var_in = np.where(var_in != fillvalue,  var_in - tab_mssh - rp_mssh_shift, var_in)
        if same_grid:
            ## The output grid is the same than the input grid
            tab_interp = np.array(var_in).flatten()
        else:
            if nbpts_interp > 1:
                # Distance weight interpolation
                self.log.debug(f"Distance weight interpolation {ll_single}")
                if ll_single :
                   self.log.debug('Dimension longitude {}'.format(nblon))
                   self.log.debug('Dimension latitude {}'.format(nblat))
                   ll_reshape = self.test_lonlat(var_in, nblon, nblat)
                   self.log.debug('Reshape {}'.format(ll_reshape))
                   if ll_reshape : var_in = np.transpose(var_in)
                   ## Modif cregnier
                   tab_interp = np.sum(weight * np.array(var_in).flatten()
                                       [inds], axis=1) / np.sum(weight, axis=1)
                else:
                   self.log.debug('depth > 0.5')

                   tab_interp_1 = np.sum(weight * np.array(var_in1).flatten()
                                       [inds], axis=1) / np.sum(weight, axis=1)
                   tab_interp_2 = np.sum(weight * np.array(var_in2).flatten()
                                       [inds], axis=1) / np.sum(weight, axis=1)
                   tab_interp = (w1 * tab_interp_1) + (w2 * tab_interp_2)
            else:
                # Nearest neighbour interpolation
                self.log.debug("Interp nearest")
                if ll_single :
                    tab_interp = ma.array(var_in).flatten()[inds]
                else:
                    tab_interp =  (w1 * ma.array(var_in1).flatten()[inds])+ (w2 * ma.array(var_in2).flatten()[inds])

        # Put nan to missing values
        tab_interp = np.where(np.isnan(tab_interp), missing_value, tab_interp)

        return tab_interp

    def compute_3D_weight(self, ind,var_in, inds,\
                       weight, ind_max, nbpts_interp):
        tab_ind = inds[ind,:,:]
        if nbpts_interp > 1:
            tab_interp_tmp = np.sum(weight[ind,:,:] * np.array(var_in[ind, :, :]).flatten()
                                       [tab_ind], axis=1) / np.sum(weight[ind,:,:], axis=1)
        else:
            ## Nearest neighbour case
            tab_interp_tmp = np.array(var_in[ind, :, :].values).flatten()[tab_ind]
        #self.log.debug('Depth loop : {}'.format(ind))
        return tab_interp_tmp

    def read_dims(self, dataset):
        dimensions = dataset.dims
        list_lon = ['x', 'X', 'lon', 'LON', 'lons', 'longitude', 'LONGITUDE']
        list_lat = ['y', 'Y', 'lat', 'LAT', 'LATS', 'latitude', 'LATITUDE']
        list_depth = [ 'deptht', 'depth', 'z', 'Z', 'DEPTH']
        try:
            tab_lon = { k: dimensions[k] for k in dimensions.keys() & set(list_lon)}
            tab_lat = { k: dimensions[k] for k in dimensions.keys() & set(list_lat)}
            tab_depth = { k:dimensions[k] for k in dimensions.keys() & set(list_depth)}
        except:
            self.log.error('lon lat or depth not defined')
            raise

        if tab_lon: nlons = list(tab_lon.values())[0]
        if tab_lat: nlats = list(tab_lat.values())[0]
        if tab_depth: ndepths = list(tab_depth.values())[0]
        depth_mod = dataset[list(tab_depth.keys())[0]][:].values

        return nlons, nlats, ndepths, depth_mod

    def interp_3D(self, weight, inds, ind_max, file, nbpts_interp, variable, depth,
                    time=0, ll_verif=False, obs=None, dateval=None, lon=None, lat=None,
                    depth_mod=None, light=False, clim=False, fillvalue=np.nan):
        """
           Interpolate profiles model values onto insitu vertical profiles
        """
        start = timer()
        ## Code allégé case
        if light:
            self.log.debug("Open lighout file")
            var_in, lon, lat = ReadModel.read_lightout(file)
        elif clim:
            tab_var_clim = {}
            tab_var_clim['votemper'] = 'temperature'
            tab_var_clim['vosaline'] = 'salinity'
            self.log.debug("Open clim file {}".format(file))
            #dataset_in = xr.open_dataset(file, decode_times=False)
            try:
                dataset_in = xr.open_mfdataset(file,chunks={'time_counter':1,'deptht':'auto','y':'auto','x':'auto'},parallel=True,combine='by_coords')
                var_in = dataset_in[variable][:, :, :].values
                nc_file = Dataset(file,'r')
                var_in = nc_file.variables[tab_var_clim[variable]][:, :, :]
            except:
                self.log.error("Missing variable {} in file {}".format(variable, file))
                raise
        else:
            try:
                dataset_in = xr.open_dataset(file, decode_times=False)
                #dataset_in = xr.open_mfdataset(file,parallel=True,combine='by_coords')
                nlons, nlats, ndepths, depth_mod = self.read_dims(dataset_in)
                var_in = dataset_in[variable][time, :, :, :].values
            except:
                self.log.error("Missing variable {} in file {}".format(variable, file))
                raise
        end = timer()
        self.log.debug('~~~~~~~~ Time elapsed read files : {} {}'.format
                        (str(end - start), " seconds ~~~~~~~~~~~~"))
        var_in = np.array(var_in)
        nb_obs, nb_profs = np.shape(depth)
        self.log.debug(f'Before computing {nb_obs=} {nb_profs=}{ind_max=}')
        start = timer()
        num_cores=10
        # Parallelize loop on levels
        with Parallel(n_jobs=num_cores, prefer="threads", verbose=10) as parallel:
            tab_interp_tmp  = parallel(delayed(self.compute_3D_weight)(ind, var_in,\
                                                                       inds, weight, ind_max, nbpts_interp) \
                                                                       for ind in range(ind_max))
        tab_interp_tmp = np.array(tab_interp_tmp)
        end = timer()
        self.log.debug('~~~~~~~~ Time elapsed loops on levels : %s %s' %
                        (str(end - start), " seconds ~~~~~~~~~~~~"))
        #if nb_profs > 1:
        values_interp = fillvalue*np.zeros((nb_obs, nb_profs))
        start = timer()
        for ind_prof in range (nb_obs):
            profondeur = depth[ind_prof, :]
            tab_mod_ma = tab_interp_tmp[:,ind_prof]
            fixture = vertical.Column(tab_mod_ma, depth_mod[0:ind_max])
            #self.log.debug('Profondeurs profiles {}'.format(profondeur[0:70]))
            #self.log.debug('Profondeurs modele {}'.format(depth_mod[0:ind_max]))
            val_interp = fixture.interpolate(profondeur)
            values_interp[ind_prof,:] = val_interp[:]
            if np.ma.isMaskedArray(val_interp):
                values_interp[ind_prof,:] = np.where(val_interp.mask, fillvalue, values_interp[ind_prof,:])
            #self.log.debug('Valeurs profile {}'.format(obs[:]))
            #self.log.debug('--------------------------------------------')
            if ll_verif:
                # Plot profiles
                dir_out = './img2/'
                dir_out2 = './img3/'
                label = "prof "+str(ind_prof)
                title = dateval+" "+variable+" "+label
                label1 = "Insitu"
                label2 = "Model"
                #self.log("Profile {}".format(ind_prof))
                #self.log('Profondeurs profiles {}'.format(profondeur[340:360]))
                #self.log('Valeur interp {}'.format(values_interp[ind_prof,340:360]))
                #self.log('Valeur modele {}'.format(tab_mod_ma[27:34]))
                #self.log('Profondeur modele {}'.format(depth_mod[27:34]))
                ll_compare = True
                prof_max = np.nanmax(profondeur)
                ind_prof_max = np.argmax(depth_mod[:])
                ind1, ind2 = self.getnearpos(prof_max, depth_mod)
                label1 = "Obs"
                label2 = "Interp"
                plot_2profiles_2(-profondeur[:], obs[ind_prof,:], -profondeur, val_interp[:], label1,\
                                label2, title=title, save=False,
                                output=dir_out2+dateval+"_compprof_"+variable+"_profile_num"+str(ind_prof),
                                var=variable)
                label1 = "Raw"
                label2 = "Interp"
                plot_2profiles_2(-depth_mod[0:ind2], tab_interp_tmp[0:ind2,ind_prof] ,-profondeur, values_interp[ind_prof,:], label1,\
                                  label2, title=title, save=False,
                                  output=dir_out2+dateval+"_interp_"+variable+"_profile_num"+str(ind_prof),
                                  var=variable)
                if ll_compare == True:
                    ## Read other profile
                    dir_class4 = "/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/data_CLASS4_GODAE/"
                    filename = glob(dir_class4+"*"+dateval+"*profile.nc")
                    label3 = "Model2"
                    if filename:
                        prof2, model_best, obs = read_GODAE_profile(variable, filename[0])
                        plot_3profiles(-profondeur, obs[ind_prof,:], values_interp[ind_prof,:],-prof2[ind_prof,:],
                                       model_best[ind_prof,:], label1,
                                       label2, label3, title=title, save=False,
                                       output=dir_out+dateval+"_comparaison_"+variable+"_profile_num"+str(ind_prof),
                                       var=variable)

            #self.log.debug('Valeurs modèle {}'.format(tab_interp_tmp[0:30,ind_prof]))
            #self.log.debug('Interp modèle onto profiles {} / {}'.format(ind_prof, nb_obs))
        end = timer()
        self.log.debug('~~~~~~~~ Time elapsed interp levels on profiles: %s %s' %
                        (str(end - start), " seconds ~~~~~~~~~~~~"))
        return values_interp
