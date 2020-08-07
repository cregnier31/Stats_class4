import os
import re
import sys
import numpy as np
import numpy.ma as ma
from scipy.spatial import cKDTree
import xarray as xr
import vertical
from Utils import *
from Loader import Loader
from collections import OrderedDict
from Interp_kdtree import interp_KDtree
from interpolate import search_orca, search_orca_4pts
from scipy.interpolate import InterpolatedUnivariateSpline, interp1d

if sys.version_info[0] >= 3:
    import pickle
else:
    import cPickle


class Interpolator(object):
    """
        Interpolator Class File : Interpolation with KDtree method
    """

    def __init__(self, log):
        self.log = log
        self.missing_value = 1.e35

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

        if w1 + w2 > 1 :
           print ("Pb with weight files {} {}".format(w1, w2))
           sys.exit(1)
        return w1, w2


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
        fcst = {k for k, v in list_input_file.items() if "fcst" in k}
        pers = {k for k, v in list_input_file.items() if "pers" in k}
        return len(best), len(fcst), len(pers), len(clim)

    def read_and_interp(self, data_file, list_input_file, param_dict):
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
        nb_best, nb_fcst, nb_pers, nb_clim = self.check_dimensions(
            list_input_file)
        self.log.info("Dimensions best : {} fcst : {} pers : {} clim : {}"
                      .format(nb_best, nb_fcst, nb_pers, nb_clim))
        nb_ptsinterp = param_dict['nb_points']
        # Read input obs value
        self.log.info(param_dict['data_format'])
        lon_obs, lat_obs, obs_value, nb_obs, depth, _FillValue = Loader.factory(
            param_dict['data_format']).read_pos_and_value(data_file)
        ll_best = False
        nb_obs2, nb_profs = np.shape(depth)
        self.log.info("Number of observations : {} ".format(nb_obs))
        variable = param_dict['varname']
        self.log.info("Variables : {} ".format(variable))
        if nb_best > 0:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                hdct_tab = np.ndarray(shape=(nb_obs, 1, 1), dtype=float, order='F')
            else :
                hdct_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs), dtype=float, order='F')
            hdct_tab[:, :, :] = self.missing_value
            ll_best = True
        ll_fcst = False
        if nb_fcst > 0:
            fcst_tab = np.ndarray(shape=(nb_obs, len(variable), nb_fcst, nb_profs),
                                  dtype=float, order='F')
            fcst_tab[:, :, :, :] = self.missing_value
            ll_fcst = True
        ll_pers = False
        if nb_pers > 0:
            pers_tab = np.ndarray(shape=(nb_obs, len(variable), nb_pers+1, nb_profs),
                                  dtype=float, order='F')
            pers_tab[:, :, :, :] = self.missing_value
            ll_pers = True
        if nb_clim > 0:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                clim_tab = np.ndarray(shape=(nb_obs, 1, 1),
                           dtype=float, order='F')
            else:
                clim_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs),
                                      dtype=float, order='F')
            clim_tab[:, :, :] = self.missing_value
            ll_clim = True
        self.log.info('Number obs to coloc {} '.format(nb_obs))
        file_coloc_tmp = os.path.basename(data_file)
        file_out = file_coloc_tmp
        # Loop on lead times
        ll_coloc = False
        for i, key in enumerate(list_input_file.keys()):
            # Create weight file
            if key.lower() == "clim" and param_dict['data_type'].lower() == 'chloro':
                ll_coloc = False
                lon_mod, lat_mod = Loader.factory(
                    'NC_CLIM').read_pos(param_dict['coord_clim'])
                file_coloc_tmp = re.sub('.nc', '_Kdtree_CLIM_' +
                                        param_dict['cl_typemod'].upper()+'_idw' +
                                        str(nb_ptsinterp) + 'pt.p', file_out)
                variable = []
                variable.append(param_dict['varname'][0].upper()+'_mean')
            else:
                self.log.info("Lead time "+key)
                if param_dict['coordinates']:
                    if param_dict['cl_typemod'].lower() == "pgn":
                        lon_mod, lat_mod = Loader.factory('PGN_coords').\
                            read_pos(param_dict['coordinates'])
                        self.log.info('Read coords PGN OK ')
                    elif param_dict['cl_typemod'].lower() == "allege":
                        lon_mod, lat_mod = Loader.factory('alleges_coords').\
                            read_pos(param_dict['coordinates'])
                        self.log.info('Read coords Alleges OK ')
                    else:
                        self.log.error("Type mod not known")
                else:
                    self.log.error("No coordinates files")
                    # TODO read lon/lat from first file
                    sys.exit(1)
                variable = param_dict['varname']
                file_coloc_tmp = re.sub('.nc', '_Kdtree_' +
                                        param_dict['cl_typemod'].upper()+'_idw' +
                                        str(nb_ptsinterp) + 'pt.p', file_out)
            weight_file = param_dict['coloc_rep'] + file_coloc_tmp
            self.log.info("Weight_file : {} ".format(weight_file))
            # Coloc file
            if not ll_coloc:
                TreeObj = interp_KDtree()
                d1, indexes = TreeObj.tree_and_query(lon_mod, lat_mod,
                                                          lon_obs, lat_obs, nb_ptsinterp,\
                                                          weight_file=weight_file,save=False)
                weights = TreeObj.get_weight(d1)

                ll_coloc = True

            # Interp model file for different lead times
            self.log.info('Variable to interpolate %s ' %
                          (param_dict['varname']))
            tab_results = {}
            list_file = []
            list_file = list_input_file[key]
            self.log.info("Variable {}".format(variable))
            self.log.info("Work on {} variables".format(len(variable)))
            ## loop on variable
            for var in range(len(variable)):
               ## Get the correct file
               varname = variable[var]
               file_input = list_input_file[key][var]
               ll_unique = False
               if len(np.unique(depth)) == 1:
                   self.log.info("Unique depth for all the observations")
                   if len(np.shape(depth)) == 1 : 
                       depthval = depth[0]
                   elif len(np.shape(depth)) == 2 :
                       depthval = depth[0,0]
                   else:
                       self.log.error("Case not known")
                       sys.exit(1)
                   interp_values = self.interp_2D(weights, indexes,
                                                  file_input,
                                                  nb_ptsinterp,
                                                  varname, depth=depthval)
                   interp_values = np.where(np.array(obs_value.flatten()) == _FillValue,
                                                     _FillValue, np.array(interp_values))
                   ll_unique = True
               else :
                  self.log.info("Profile case variable : {}".format(variable[var]))
                  interp_values = self.interp_3D(weights, indexes,
                                                  file_input,
                                                  nb_ptsinterp,
                                                  varname, depth)
                  if len(np.shape(obs_value)) ==  3: obs_value = np.array(obs_value)[:,var,:]
                  interp_values = np.where(np.array(obs_value) == _FillValue,
                                                     self.missing_value, np.array(interp_values))
               if key[0:4] == 'fcst':
                   if len(key) > 4:
                       indice = int(key[4])
                   else:
                       indice = 0
                   self.log.info("Fead forecast indice %i " % (indice))
                   if ll_unique :
                       fcst_tab[:, var, indice, 0] = interp_values
                   else:
                       fcst_tab[:, var, indice, :] = interp_values
               elif key[0:4] == 'nwct':
                   indice = 0
                   self.log.info("%s Persistence indice  %i " %(key,indice))
                   if ll_unique :
                       pers_tab[:, var, indice, 0] = interp_values
                   else:
                       pers_tab[:, var, indice, :] = interp_values
               elif key[0:4] == 'pers':
                   if len(key) > 4:
                       indice = int(key[4])
                   else:
                       indice = 0
                   self.log.info("Persistence indice %i " % (indice))
                   if ll_unique :
                        pers_tab[:, var, indice, 0] = interp_values
                   else:
                       pers_tab[:, var, indice, :] = interp_values
               elif key[0:4] == 'hdct':
                   if ll_unique :
                       hdct_tab[:, var, 0] = interp_values
                   else:
                       hdct_tab[:, var, :] = interp_values
               elif key[0:4] == 'clim':
                   if ll_unique:
                       clim_tab[:, var, 0] = interp_values
                   else:
                       clim_tab[:, var, :] = interp_values
        ####
        if ll_best:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                hdct_tab = hdct_tab[:, 0, 0].reshape(
                    lat_obs.shape[0], lon_obs.shape[0])
            tab_results['best'] = hdct_tab
        if ll_fcst:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                fcst_tab = fcst_tab[:, 0, 0, 0].reshape(
                    lat_obs.shape[0], lon_obs.shape[0])
            tab_results['forecast'] = fcst_tab
        if ll_pers:
            tab_results['persistence'] = pers_tab
        if ll_clim:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                clim_tab = clim_tab[:, 0, 0].reshape(
                    lat_obs.shape[0], lon_obs.shape[0])
            tab_results['clim'] = clim_tab
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
            log.info("load existing tree :%s " % (weight_file))
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
            log.info("Create CKDTREE object")
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

    def interp_2D(self, weight, inds, file, nbpts_interp, variable, depth=0, time=0):
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
        self.log.info('Read input file : {}'.format(file))
        self.log.info('Variable : {}'.format(variable))
        dataset_in = xr.open_dataset(file)
        var_in = dataset_in[variable]
        ll_single = False
        if depth > 0.5 :
            ## Find the 2 points that enclose the depth value
            depth_mod = dataset_in['deptht'][:].values
            ind_depth1, ind_depth2 = self.getnearpos(depth, depth_mod)
            w1, w2 = self.getweight(depth_mod[ind_depth1], depth_mod[ind_depth2], depth)
            self.log.info("Index of depth value {} {} {} {}".format(ind_depth1, ind_depth2, depth_mod[ind_depth1], depth_mod[ind_depth2]))
        else:
            # Surface case
            ll_single = True

        if len(var_in.shape) == 3:
            if ll_single:
               var_in = var_in[0, :, :].values
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

        if nbpts_interp > 1:
            # Distance weight interpolation
            self.log.info("Distance weight interpolation")
            if ll_single :
               tab_interp = np.sum(weight * np.array(var_in).flatten()
                                   [inds], axis=1) / np.sum(weight, axis=1)
            else:
               tab_interp_1 = np.sum(weight * np.array(var_in1).flatten()
                                   [inds], axis=1) / np.sum(weight, axis=1)
               tab_interp_2 = np.sum(weight * np.array(var_in2).flatten()
                                   [inds], axis=1) / np.sum(weight, axis=1)
               tab_interp = (w1 * tab_interp_1) + (w2 * tab_interp_2)
        else:
            # Nearest neighbour interpolation
            self.log.info("Interp nearest")
            if ll_single :
                tab_interp = ma.array(var_in).flatten()[inds]
            else:
                tab_interp =  (w1 * ma.array(var_in1).flatten()[inds])+ (w2 * ma.array(var_in2).flatten()[inds])

        #tab_interp = np.expand_dims(tab_interp[:], axis=1)
        return tab_interp

    def interp_3D(self, weight, inds, file, nbpts_interp, variable, depth, time=0):
        """
           Interpolate profiles model values onto insitu vertical profiles
        """
        dataset_in = xr.open_dataset(file)
        var_in = dataset_in[variable]
        nb_obs, nb_profs = np.shape(depth)
        depth_mod = dataset_in['deptht'][:].values
        nb_obs, nb_pts =  np.shape(weight)
        maxdepth =  np.nanmax(depth)
        self.log.debug('maxdepth {}'.format(maxdepth))
        ind_depth = self.getneardepth(depth_mod, maxdepth)
        tab_interp_tmp = np.nan*np.zeros((ind_depth+1, nb_obs))
        tab_prof_tmp = np.nan*np.zeros((ind_depth+1, nb_obs))
        self.log.debug('Size {}'.format(np.shape(tab_interp_tmp)))
        ## Loop on levels
        for ind in range(len(depth_mod)):
            tab_interp_tmp[ind, :]  = np.sum(weight * np.array(var_in[time, ind, :, :].values).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
        values_interp = np.nan*np.zeros((nb_obs, nb_profs))
        for ind_prof in range (nb_obs):
            profondeur = depth[ind_prof, :]
            fixture = vertical.Column(tab_interp_tmp[:,ind_prof], depth_mod[:])
            self.log.debug('Profondeurs profiles {}'.format(profondeur[0:300]))
            self.log.debug('Profondeurs modele {}'.format(depth_mod[0:30]))
            values_interp[ind_prof,:] = fixture.interpolate(profondeur)
            self.log.debug('--------------------------------------------')
            #self.log.debug('Valeurs profile {}'.format(obs_values[0:300]))
            if ind_prof == 0 : print (values_interp[ind_prof,:])
            self.log.debug('Valeurs modèle {}'.format(tab_interp_tmp[0:30,ind_prof]))
            self.log.debug('Interp modèle onto profiles {} / {}'.format(ind_prof, nb_obs))
        return values_interp
