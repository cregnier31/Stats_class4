import os
import re
import sys
import numpy as np
import numpy.ma as ma
from scipy.spatial import cKDTree
import xarray as xr
from Utils import *
from Loader import Loader
from collections import OrderedDict

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

    def check_dimensions(self, list_input_file):
        """
        Check the existence and the dimensions of different lead times
        Parameters
        --------------------
        list_input_file : dictionnary with all the files to interp
        """
        best = {k for k, v in list_input_file.iteritems() if "hdct" in k}
        clim = {k for k, v in list_input_file.iteritems() if "clim" in k}
        fcst = {k for k, v in list_input_file.iteritems() if "fcst" in k}
        pers = {k for k, v in list_input_file.iteritems() if "pers" in k}
        return len(best), len(fcst), len(pers), len(clim)

    def read_and_interp(self, data_file, list_input_file, param_dict):
        """
        Read and Interp data files
        Read input file, compute coloc value and interp with KDtree
        Parameters
        --------------------
        data_file : input data file
        list_input_file : list of input files to interp
        param_dict : dictionnary with all the parameters
        """
        # Initialisation
        ll_clim = False
        nb_best, nb_fcst, nb_pers, nb_clim = self.check_dimensions(
            list_input_file)
        self.log.info("Dimensions best : %i fcst : %i pers : %i clim : %i"
                      % (nb_best, nb_fcst, nb_pers, nb_clim))
        nb_ptsinterp = param_dict['nb_points']
        # Read input obs value
        lon_obs, lat_obs, obs_value, nb_obs, _FillValue = Loader.factory(
            param_dict['data_format']).read_pos_and_value(data_file)
        ll_best = False
        if nb_best > 0:
            hdct_tab = np.ndarray(shape=(nb_obs, 1, 1), dtype=float, order='F')
            hdct_tab[:, :, :] = 9999.
            ll_best = True
        ll_fcst = False
        if nb_fcst > 0:
            fcst_tab = np.ndarray(shape=(nb_obs, 1, nb_fcst, 1),
                                  dtype=float, order='F')
            fcst_tab[:, :, :, :] = 9999.
            ll_fcst = True
        ll_pers = False
        if nb_pers > 0:
            pers_tab = np.ndarray(shape=(nb_obs, 1, nb_pers+1, 1),
                                  dtype=float, order='F')
            pers_tab[:, :, :, :] = 9999.
            ll_pers = True
        if nb_clim > 0:
            clim_tab = np.ndarray(shape=(nb_obs, 1, 1),
                                  dtype=float, order='F')
            clim_tab[:, :, :] = 9999.
            ll_clim = True
        self.log.info('Number obs to coloc %i ' % (nb_obs))
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
                variable = param_dict['varname']+'_mean'
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
                    # list_input_file[0]
                    sys.exit(1)
                variable = param_dict['varname']
                file_coloc_tmp = re.sub('.nc', '_Kdtree_' +
                                        param_dict['cl_typemod'].upper()+'_idw' +
                                        str(nb_ptsinterp) + 'pt.p', file_out)
            weight_file = param_dict['coloc_rep'] + file_coloc_tmp
            self.log.info("Weight_file : %s " % (weight_file))
            # Coloc file
            if not ll_coloc:
                weights, indexes = self.coloc_2D(lon_mod, lon_obs,
                                                 lat_mod, lat_obs, weight_file,
                                                 nb_ptsinterp, self.log)
                ll_coloc = True
            # Interp model file for different lead times
            self.log.info('Variable to interpolate %s ' %
                          (param_dict['varname']))
            tab_results = {}
            interp_values = self.interp_2D(weights, indexes,
                                           list_input_file[key][0],
                                           nb_ptsinterp,
                                           variable)
            interp_values = np.where(np.array(obs_value.flatten()) == _FillValue,
                                     _FillValue, np.array(interp_values))
            if key[0:4] == 'fcst':
                if len(key) > 4:
                    indice = int(key[4])
                else:
                    indice = 0
                self.log.info("Fead forecast indice %i " % (indice))
                fcst_tab[:, 0, indice, 0] = interp_values[:]
            elif key[0:4] == 'nwct':
                indice = 0
                self.log.info("%s Persistence indice  %i " %(key,indice))
                pers_tab[:, 0, indice, 0] = interp_values[:]
            elif key[0:4] == 'pers':
                if len(key) > 4:
                    indice = int(key[4])
                else:
                    indice = 0
                self.log.info("Persistence indice %i " % (indice))
                pers_tab[:, 0, indice, 0] = interp_values[:]
            elif key[0:4] == 'hdct':
                hdct_tab[:, 0, 0] = interp_values[:]
            elif key[0:4] == 'clim':
                clim_tab[:, 0, 0] = interp_values[:]
        if ll_best:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                hdct_tab = hdct_tab[:, 0, 0].reshape(
                    lon_obs.shape[0], lat_obs.shape[0])
            tab_results['best'] = hdct_tab
        if ll_fcst:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                fcst_tab = fcst_tab[:, 0, 0, 0].reshape(
                    lon_obs.shape[0], lat_obs.shape[0])
            tab_results['forecast'] = fcst_tab
        if ll_pers:
            tab_results['persistence'] = pers_tab
        if ll_clim:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                clim_tab = clim_tab[:, 0, 0].reshape(
                    lon_obs.shape[0], lat_obs.shape[0])
            tab_results['clim'] = clim_tab
        return tab_results, file_out

    def coloc_2D(self, lon_in, lon_out, lat_in, lat_out,
                 weight_file, nbpts_interp, log):
        """
        -------------------
        Coloc 2D
        Compute weight file with KDTree Method and store it in
        a pickle file
        Parameters
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
        return WEIGHT, inds_idw1
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
            global_step = (X2[len(X2)-1]-X2[0])/(len(X2)-1)
            first_step = X2[1]-X2[0]
            log.info("Step sizes %f %f " % (global_step, first_step))
            # 1D cases
            if lon_out.ndim < 2:
                if global_step == first_step:
                    # Regular
                    log.info("1D regular => convert to meshgrid")
                    X2, Y2 = np.meshgrid(lon_out, lat_out)
                else:
                    # Irregular
                    log.info("1D not regular")
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
        Parameters
        --------------------
        weight_file : weight values
        inds : index values
        nbpts_interp : number points for interpolation
            =>  1 = nearest
            =>  >1 IDW method
        variable :  input_variable
        return interp tab
        """
        self.log.info('Read input file : %s' % (file))
        self.log.info('Variable : %s' % (variable))
        dataset_in = xr.open_dataset(file)
        var_in = dataset_in[variable]
        if len(var_in.shape) == 3:
            var_in = var_in[depth, :, :].values
        elif len(var_in.shape) == 4:
            var_in = var_in[time, depth, :, :].values
        if nbpts_interp > 1:
            self.log.info("Distance weight interpolation")
            tab_interp = np.sum(weight * np.array(var_in).flatten()
                                [inds], axis=1) / np.sum(weight, axis=1)
        else:
            # Nearest neighbour interpolation
            self.log.info("Interp nearest")
            tab_interp = ma.array(var_in).flatten()[inds]
        return tab_interp
