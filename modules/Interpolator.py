import os
import re
import sys
import numpy as np
import numpy.ma as ma
from scipy.spatial import cKDTree
import xarray as xr
import vertical
from Utils import *
from utils import find_index_month
from Loader import Loader
from collections import OrderedDict
from Interp_kdtree import interp_KDtree
from interpolate import search_orca, search_orca_4pts
from scipy.interpolate import InterpolatedUnivariateSpline, interp1d
from lib_pyt.Profile import plot_2profiles, plot_3profiles, plot_2profiles_2
import matplotlib.pyplot as plt
from matplotlib import style
from Writer import Writer
from glob import glob
from reader import read_GODAE_profile

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

    def read_and_interp(self, data_file, list_input_file, param_dict, date=None):
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
        nb_best, nb_fcst, nb_pers, nb_clim = self.check_dimensions(
            list_input_file)
        self.log.info("Dimensions best : {} fcst : {} pers : {} clim : {}"
                      .format(nb_best, nb_fcst, nb_pers, nb_clim))
        nb_ptsinterp = param_dict['nb_points']
        # Read input obs value
        self.log.info(param_dict['data_format'])
        #print (param_dict['data_format'])
        lon_obs, lat_obs, obs_value, nb_obs, depth, _FillValue = Loader.factory(
            param_dict['data_format']).read_pos_and_value(data_file)

        ll_best = False
        nb_obs2, nb_profs = np.shape(depth)
        self.log.info("Number of observations {} Profondeurs {}".format(nb_obs2, nb_profs))
        variable = param_dict['varname']
        self.log.info("Variables : {} ".format(variable))
        if nb_best > 0:
            if param_dict['data_origin'] == "GLOBCOLOUR":
                hdct_tab = np.ndarray(shape=(nb_obs, 1, 1), dtype=float, order='F')
            else :
                hdct_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs), dtype=float, order='F')
            hdct_tab[:, :, :] = self.missing_value
            self.log.info("Taille hdct_tab {}".format(np.shape(hdct_tab)))
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
                clim_tab[:, :, :] = self.missing_value
            elif param_dict['data_type'].lower() == "drifter_filtr":
                clim_tab = np.ndarray(shape=(nb_obs, len(variable)),dtype=float, order='F')
                clim_tab[:, :] = self.missing_value
            else:
                clim_tab = np.ndarray(shape=(nb_obs, len(variable), nb_profs),
                                      dtype=float, order='F')
                clim_tab[:, :, :] = self.missing_value
            ll_clim = True
        self.log.info('Number obs to coloc {} '.format(nb_obs2))
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
            elif key.lower() == "clim" and param_dict['data_type'].lower() == 'drifter_filtr':
                ll_coloc = False
                lon_mod, lat_mod = Loader.factory(
                    'NC_CLIM').read_pos(param_dict['coord_clim'])
                variable = ['U', 'V']
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
                TreeObj = interp_KDtree(level=self.log.level)
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
               try:
                  file_input = list_input_file[key][var]
               except :
                   self.log.error("Error {} Missing file for key {} var {}".format(sys.exc_info()[0], key, var))
                   sys.exit(1)
               ll_unique = False
               if len(np.unique(depth)) == 1:
                   self.log.info("Unique depth for all the observations")
                   if len(np.shape(depth)) == 1 :
                       depthval = depth[0]
                   elif len(np.shape(depth)) == 2 :
                       depthval = depth[0,0]
                   else:
                       self.log.error("Case not known")
                   index_time=0
                   if key.lower() == "clim" and param_dict['data_type'].lower() == 'drifter_filtr':  
                       depthval = 0
                       index_time=find_index_month(date)
                   interp_values = self.interp_2D(weights, indexes,
                                                  file_input,
                                                  nb_ptsinterp,
                                                  varname, param_dict, key=key, 
                                                  depth=depthval, fillvalue=_FillValue,
                                                  time=index_time)
                   interp_values = np.where(np.array(obs_value).flatten() == _FillValue,
                                                     _FillValue, np.array(interp_values))
                   interp_values = np.where(interp_values == np.nan, self.missing_value, interp_values)

                   ll_unique = True
               else :
                  self.log.info("Profile case variable : {}".format(variable[var]))
                  interp_values = self.interp_3D(weights, indexes,
                                                  file_input,
                                                  nb_ptsinterp,
                                                  varname, depth, ll_verif = param_dict['verif'],
                                                  obs = obs_value[:,var,:],
                                                  dateval=date, lon=lon_obs, lat=lat_obs, fillvalue=self.missing_value)
                  if len(np.shape(obs_value)) ==  3: obs_value2 = np.array(obs_value)[:,var,:]
                  interp_values = np.where(np.array(obs_value2) == _FillValue,
                                                     self.missing_value, np.array(interp_values))
                  ll_json = param_dict['json']
                  if ll_json:
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
                       if param_dict['data_type'].lower() == "drifter_filtr":
                           clim_tab[:, var] = interp_values
                       else:
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

    def interp_2D(self, weight, inds, file, nbpts_interp, variable, param_dict,\
            depth=0, time=0, key=None, fillvalue=None):
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

        if variable == "sossheig":
            cl_msshFile = param_dict['cl_msshFile']
            rp_mssh_shift = param_dict['rp_mssh_shift']
            dataset_mssh = xr.open_dataset(cl_msshFile)
            tab_mssh = dataset_mssh['mssh'].values

        if len(var_in.shape) == 3:
            if ll_single:
               var_in = var_in[time, :, :].values
               print ('time {}'.format(time))
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

        if variable == "sossheig":
            var_in = np.where(var_in != fillvalue,  var_in - tab_mssh - rp_mssh_shift, var_in)

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

    def interp_3D(self, weight, inds, file, nbpts_interp, variable, depth,
                    time=0, ll_verif=False, obs=None, dateval=None, lon=None, lat=None, fillvalue=np.nan):
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
        ind_tot = len(depth_mod)
        #tab_interp_tmp = np.nan*np.zeros((ind_tot, nb_obs))
        tab_interp_tmp = fillvalue*np.zeros((ind_tot, nb_obs))
        #tab_prof_tmp = np.nan*np.zeros((ind_tot, nb_obs))
        self.log.debug('Size {}'.format(np.shape(tab_interp_tmp)))
        ## Loop on levels
        for ind in range(ind_tot):
            tab_interp_tmp[ind, :] = np.sum(weight * np.array(var_in[time, ind, :, :].values).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
        values_interp = fillvalue*np.zeros((nb_obs, nb_profs))
        #values_interp = ma.array((nb_obs, nb_profs))
        obs2 = obs[~obs.mask]
#        values_interp = values_interp[~values_interp.mask]

        for ind_prof in range (nb_obs):
            profondeur = depth[ind_prof, :]
            tab_mod_ma = tab_interp_tmp[:,ind_prof]
            fixture = vertical.Column(tab_mod_ma, depth_mod[:])
            self.log.debug('Profondeurs profiles {}'.format(profondeur[0:300]))
            self.log.debug('Profondeurs modele {}'.format(depth_mod[0:30]))
            val_interp = fixture.interpolate(profondeur)
            values_interp[ind_prof,:] = val_interp[:]
            if np.ma.isMaskedArray(val_interp):
                values_interp[ind_prof,:] = np.where(val_interp.mask, fillvalue, values_interp[ind_prof,:])
            self.log.debug('Valeurs profile {}'.format(obs[:]))
            self.log.debug('--------------------------------------------')
            if ll_verif: 
                ## Profiles to test 20200901  155 526 564
                # Plot profiles
                dir_out = './img2/'
                dir_out2 = './img3/'
                label = "prof "+str(ind_prof)
                title = dateval+" "+variable+" "+label
                label1 = "Insitu"
                label2 = "Model"
                #print ("Profile {}".format(ind_prof))
                #print ('Profondeurs profiles {}'.format(profondeur[0:70]))
                #print ('Valeur interp {}'.format(values_interp[ind_prof,0:70]))
                #print ('Valeur modee {}'.format(tab_mod_ma))
                ll_compare = True
                prof_max = np.nanmax(profondeur)
                ind_prof_max = np.argmax(depth_mod[:])
                ind1, ind2 = self.getnearpos(prof_max, depth_mod)
                label1 = "Obs"
                label2 = "Interp"
                plot_2profiles_2(-profondeur[:], obs[ind_prof,:], -profondeur, val_interp[:], label1,\
                                label2, title=title, save=True,
                                output=dir_out2+dateval+"_compprof_"+variable+"_profile_num"+str(ind_prof),
                                var=variable)
                label1 = "Raw"
                label2 = "Interp"
                plot_2profiles_2(-depth_mod[0:ind2], tab_interp_tmp[0:ind2,ind_prof] ,-profondeur, values_interp[ind_prof,:], label1,\
                                  label2, title=title, save=True,
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
                                       label2, label3, title=title, save=True,
                                       output=dir_out+dateval+"_comparaison_"+variable+"_profile_num"+str(ind_prof),
                                       var=variable)
                #plot_2profiles_2(-depth_mod[0:ind2], tab_interp_tmp[0:ind2,ind_prof] ,-profondeur, values_interp[ind_prof,:], label1,\
                #                    label2, title=title, save=False,
                #                    output=dir_out+dateval+"_interp_"+variable+"_profile_num"+str(ind_prof),
                #                    var=variable)

            self.log.debug('Valeurs modèle {}'.format(tab_interp_tmp[0:30,ind_prof]))
            self.log.debug('Interp modèle onto profiles {} / {}'.format(ind_prof, nb_obs))
        return values_interp
