import os
import sys
import configparser as ConfigParser
import numpy as np
#import define_config
#import param.Def_param_bulletin as params
#import supobs
# Serialization
import pickle as cPickle

__author__      = "C.REGNIER"
__version__ = 0.1
__Date__ = "February 2019"


def load_db(_DBFILE_):
    """
        Function to load env files
        inputs:
        _DBFILE_: cfg file
        return:
        db: configparser class
    """
    db = ConfigParser.ConfigParser()
    db.read(os.path.expanduser(_DBFILE_))
    if not db.sections():
        print ("Error reading configuration file %s" % _DBFILE_)
        sys.exit(1)
    return db


def read_input_files(params_conf):
    """
        Function to read input layers file
        and serialized colocated positions
        inputs:
        params_conf: dictionnary with input parameters
        returns:
        rla_surface: output surface layer
        rla_layers: output layers
        table_hull: serialized colocated shapes
    """
    # *********************  read depth/level file  *********************
    rla_surface = [0., 0.]
    rla_layers = []
    if params_conf['cexp'] == 'PHYS':
        fileid = open(params_conf['cl_layerFile'])
        for line in fileid:
            lt = line.split()
            rla_layers.append(float(lt[0]))
        fileid.close()
    if params_conf['cexp'] == 'BIO':
        rla_layers = [0., 0.]
    # *********************  Read serialized file  *********************
    if params_conf['fmt_mask'] == "basin":
        file_pi = params_conf['dir_static']+"mask_CMEMS_area_all_regions.p"
        #f = open(file_pi, 'rb')
        #table_hull = cPickle.load(f)
        with open(file_pi, 'rb') as f:
            table_hull = cPickle.load(f, encoding="latin")

    elif params_conf['fmt_mask'] == "basin_pol":
        file_pi = params_conf['dir_static'] + \
            "mask_CMEMS_area_all_polar_NS_regions.p"
        #f = open(file_pi, 'rb')
        #table_hull = cPickle.load(f)
        with open(file_pi, 'rb') as f:
            table_hull = cPickle.load(f, encoding="latin")
    else:
        table_hull = None

    return rla_surface, rla_layers, table_hull


def load_param(db_file):

    params_conf = {}
    params_conf['db'] = load_db(db_file)
    params_conf['ZONE'] = params_conf['db'].get(
        'GLOBAL', 'ZONE')
    params_conf['SUFFIX'] = params_conf['db'].get(
        'GLOBAL', 'SUFFIX')
    params_conf['var_u'] = params_conf['db'].get(
        'GLOBAL', 'var_u')
    params_conf['var_v'] = params_conf['db'].get(
        'GLOBAL', 'var_v')
    params_conf['nb_ptsinterp'] = params_conf['db'].get(
        'GLOBAL', 'nb_ptsinterp')
    params_conf['system'] = params_conf['db'].get(
        'GLOBAL', 'system')
    params_conf['systemh'] = params_conf['db'].get(
        'GLOBAL', 'systemh')
    params_conf['nb_fcst'] = params_conf['db'].get(
        'GLOBAL', 'nb_fcst')
    params_conf['nb_fcst_smoc'] = params_conf['db'].get(
        'GLOBAL', 'nb_fcst_smoc')
    params_conf['nb_pers'] = params_conf['db'].get(
        'GLOBAL', 'nb_pers')
    params_conf['model'] = params_conf['db'].get(
        'GLOBAL', 'model')
    params_conf['DIRDATA'] = params_conf['db'].get(
        'input_dir', 'DIRDATA')
    params_conf['DIRDATA_filtr'] = params_conf['db'].get(
        'input_dir', 'DIRDATA_filtr')
    params_conf['TYPE'] = params_conf['db'].get(
        'input_dir', 'TYPE')
    params_conf['dirdata_smoc'] = params_conf['db'].get(
        'input_dir', 'dirdata_smoc')
    params_conf['dirdata_mod'] = params_conf['db'].get(
        'input_dir', 'dirdata_mod')
    params_conf['dirdata_mod_weekly'] = params_conf['db'].get(
        'input_dir', 'dirdata_mod_weekly')
    params_conf['path_data'] = params_conf['db'].get(
        'output_dir', 'path_data')
    params_conf['DIR_INTERP'] = params_conf['db'].get(
        'output_dir', 'DIR_INTERP')
    params_conf['dirout'] = params_conf['db'].get(
        'output_dir', 'dirout')
    params_conf['coordinates'] = params_conf['db'].get(
        'static', 'coordinates')
    params_conf['coordinates_reg'] = params_conf['db'].get(
        'static', 'coordinates_reg')
    params_conf['coordinates_clim'] = params_conf['db'].get(
        'static', 'coordinates_clim')
    try:
        params_conf['coordinates_zgr'] = params_conf['db'].get('static', 'coordinates_zgr')
    except Exception:
        params_conf['coordinates_zgr'] = ""
    try:
        params_conf['coordinates_hgr'] = params_conf['db'].get('static', 'coordinates_hgr')
    except Exception:
        params_conf['coordinates_hgr'] = ""

    return params_conf


def stat_mod_obs(stat, num_col, amask, nobs, mean_obs, rms_obs, mean_prod, rms_prod, rmse, cor, tab_prof, yout):

    if num_col == 0:
        for ncol in range(yout):
            stat[ncol, :, 1, amask] = mean_obs
            stat[ncol, :, 2, amask] = np.square(rms_obs)

    stat[num_col, :, 0, amask] = nobs
    stat[num_col, :, 3, amask] = mean_prod
    stat[num_col, :, 4, amask] = np.square(rms_prod)
    stat[num_col, :, 5, amask] = np.square(rmse)
    stat[num_col, :, 6, amask] = cor

    num_col += 1
    return stat, num_col


# -----------------------------------------------------------------------------------------------------------------

def stat_obs_glob(stat, yout, ilayer, mean, rms):
    for ncol in range(yout):
        stat[ncol, ilayer, 1] = mean
        stat[ncol, ilayer, 2] = np.square(rms)
    return stat


# -----------------------------------------------------------------------------------------------------------------

def stat_mod_glob(stat, num_col, ilayer, nobs, mean, rms, rmse, cor):
    stat[num_col, ilayer, 0] = nobs
    stat[num_col, ilayer, 3] = mean
    stat[num_col, ilayer, 4] = np.square(rms)
    stat[num_col, ilayer, 5] = np.square(rmse)
    stat[num_col, ilayer, 6] = cor
    num_col += 1

    return stat, num_col


# -----------------------------------------------------------------------------------------------------------------

def stat_mod_glob2(stat, num_col, ilayer, nobs, mean, rms, rmse, cor, meandiff, rmsdiff):
    stat[num_col, ilayer, 0] = nobs
    stat[num_col, ilayer, 3] = mean
    stat[num_col, ilayer, 4] = np.square(rms)
    stat[num_col, ilayer, 5] = np.square(rmse)
    stat[num_col, ilayer, 6] = cor
    stat[num_col, ilayer, 7] = meandiff
    stat[num_col, ilayer, 8] = rmsdiff
    num_col += 1

    return stat, num_col


# -----------------------------------------------------------------------------------------------------------------
