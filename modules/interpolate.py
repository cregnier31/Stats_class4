import sys, os
import numpy as np
from scipy.spatial import cKDTree
from timeit import default_timer as timer
from numba import jit
if sys.version_info[0] >= 3:
    import pickle
else:
    import cPickle

def lon_lat_to_cartesian(lon, lat, R = 1):
    """
     calculates lon, lat coordinates of a point on a sphere with
     radius R
    """
    lon_r = np.radians(lon)
    lat_r = np.radians(lat)
    x =  R * np.cos(lat_r) * np.cos(lon_r)
    y = R * np.cos(lat_r) * np.sin(lon_r)
    z = R * np.sin(lat_r)
    return x,y,z


#@jit
def search_orca_4pts(inds_idw1, lon_in, lat_in):
    """
    -------------------
    Function to recompose flatten indexwith 4 points inside lon lat orca grid
    -------------------
    """
    ilat = np.zeros(np.shape(inds_idw1))
    ilon = np.zeros(np.shape(inds_idw1))
    nb_indices, nb_pts = np.shape(inds_idw1)
    for j in range(int(nb_pts)):
       for i, ind in enumerate(inds_idw1[:,j]):
           inds = np.where(lon_in == lon_in.flatten()[ind])
           if np.size(inds[0][:]) > 1:
               w = np.where(lat_in[inds] == lat_in.flatten()[ind])
               ilat[i,j] = inds[0][w][0]
               ilon[i,j] = inds[1][w][0]
           else:
               ilat[i,j] = inds[0]
               ilon[i,j] = inds[1]
           print (" i ok {}".format(i))
       print (" j ok {}".format(j))
    return ilat, ilon


#@jit
def search_orca(inds_idw1, lon_in, lat_in):
    """
    -------------------
    Function to recompose flatten index inside lon lat orca grid
    -------------------
    """
    #ilat = []
    #ilon = []
    ilat = np.zeros(np.shape(inds_idw1))
    ilon = np.zeros(np.shape(inds_idw1))

    for i, ind in enumerate(inds_idw1):
        inds = np.where(lon_in == lon_in.flatten()[ind])
        if np.size(inds[0][:]) > 1:
            w = np.where(lat_in[inds] == lat_in.flatten()[ind])
            ilat[i] = inds[0][w][0]
            ilon[i] = inds[1][w][0]
        else:
            ilat[i] = inds[0]
            ilon[i] = inds[1]

    return ilat, ilon

#@jit
def search_regular(inds_idw1, lon_in, lat_in):

    ilat = np.zeros(np.shape(inds_idw1))
    ilon = np.zeros(np.shape(inds_idw1))
    X, Y = np.meshgrid(lon_in, lat_in)

    for i, ind in enumerate(inds_idw1):
        inds = np.where(X == X.flatten()[ind])
        if np.size(inds[0][:]) > 1:
            w = np.where(Y[inds] == Y.flatten()[ind])
            ilat[i] = inds[0][w][0]
            ilon[i] = inds[1][w][0]
        else:
            ilat[i] = inds[0]
            ilon[i] = inds[1]
    return ilat, ilon
#        inds = np.where(lon_in == X.flatten()[ind])
#        print (inds)
#        if np.size(inds[0][:]) > 1:
#            w = np.where(lat_in[inds] == Y.flatten()[ind])
#            ilat[i] = inds[0][w][0]
#            ilon[i] = inds[1][w][0]
#        else:
#            ilat[i] = inds[0][0]
#            ilon[i] = inds[1][0]
#
    return ilat, ilon

# Compute or not weight file

def coloc_2D(lon_in, lon_out, lat_in, lat_out,
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
    nbpts_interp : number points for interpolation
        =>  1 = nearest
        =>  >1 IDW method
    log : logger object
    Returns
    --------------------
    WEIGHT : weight values
    inds_idw1 : index values in the grid
    """
    #@jit
    def search(inds_idw1, lon_in, lat_in):
        ilat = []
        ilon = []
        for ind in inds_idw1:
            #print ind, len(inds_idw1)
            inds = np.where(lon_in == lon_in.flatten()[ind]) 
            if np.size(inds[0][:]) > 1:
                w = np.where(lat_in[inds] == lat_in.flatten()[ind])
                ilat.append(inds[0][w][0])
                ilon.append(inds[1][w][0])
            else:
                ilat.append(inds[0][0])
                ilon.append(inds[1][0])

        return ilat, ilon 
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
        # Read input grid
        # Test size
        if len(lon_in.shape) > 1:
            X1, Y1 = lon_in, lat_in
            log.debug('lon lat not mesh')
        else:
            log.debug('convert to meshgrid')
            X1, Y1 = np.meshgrid(lon_in, lat_in)
        # Convert to cartesian
        log.debug('Convert to cartesian')
        xs, ys, zs = lon_lat_to_cartesian(X1.flatten(), Y1.flatten())
        # Read output grid
        X2, Y2 = lon_out, lat_out
        if isinstance(X2, np.float64) or isinstance(X2, np.float32):
            log.debug('X2 is a float')
        else:
            if len(X2)> 1:
                global_step = (X2[len(X2)-1]-X2[0])/(len(X2)-1)
                first_step = X2[1]-X2[0]
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
        log.debug('Convert to cartesian out')
        xt, yt, zt = lon_lat_to_cartesian(X2.flatten(), Y2.flatten())
        if sys.version_info[0] >= 3:
            tree = cKDTree(list(zip(xs, ys, zs)))
            DIST, inds_idw1 = tree.query(
                list(zip(xt, yt, zt)), k=nbpts_interp)
            with open(weight_file, 'wb') as f:
                pickle.dump(list(zip(DIST, inds_idw1)),
                            f, pickle.HIGHEST_PROTOCOL)
        else:
            log.debug('Create tree')
            start = timer()
            tree = cKDTree(zip(xs, ys, zs))
            end = timer()
            log.debug('~~~~~~~~ Time elapsed : %s %s' %
                           (str(end - start), " seconds ~~~~~~~~~~~~"))
            log.debug('Query tree')
            start = timer()
            DIST, inds_idw1 = tree.query(zip(xt, yt, zt), k=nbpts_interp)
            log.debug('Query tree OK')
            end = timer()
            log.debug('~~~~~~~~ Time elapsed : %s %s' %
                         (str(end - start), " seconds ~~~~~~~~~~~~"))
            with open(weight_file, 'wb') as f:
                cPickle.dump(zip(DIST, inds_idw1), f,
                             protocol=cPickle.HIGHEST_PROTOCOL)
#    log.info('search ilon ilat')
#    start = timer()
#    ilat, ilon = search(inds_idw1, lon_in, lat_in)
#    end = timer()
#    log.info('~~~~~~~~ Time elapsed search : %s %s' %
#                (str(end - start), " seconds ~~~~~~~~~~~~"))
#    ilat = []
#    ilon = []
#    for ind in inds_idw1:
#        inds = np.where(lon_in == lon_in.flatten()[ind]) 
#        if np.size(inds[0][:]) > 1:
#            w = np.where(lat_in[inds] == lat_in.flatten()[ind])
#            ilat.append(inds[0][w][0])
#            ilon.append(inds[1][w][0])
#        else:
#            ilat.append(inds[0][0])
#            ilon.append(inds[1][0])

#    return ilat, ilon, DIST
    return inds_idw1, DIST

