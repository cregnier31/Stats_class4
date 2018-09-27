#/usr/bin/python

"""
DESCRIPTION
Ce programme interpole les variables provenant d'une grille " GRID_INPUT" (reguliere ou irreguliere) sur une nouvelle grille " GRID_OUTPUT" (reguliere). 

Interpolation BILINEAIRE; fonction ' interpolate.RectBivariateSpline(in_data['latitude'][:], in_data['longitude'][:], vardata[:], kx=1, ky=1, s=0)'
Les valeurs de kx=1, ky=1, s=0, sont Ã©quivalents Ã  faire une interpolation bilinaire

Sortie: fichier netcdf 

REFERENCES

BUGS  
"""


import os, sys
import glob
from numpy.matlib import repmat
import numpy as np
import scipy
import Scientific.IO.NetCDF as nc
import datetime
from pylab import *
import matplotlib.colors as colors
import datetime
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import MA

from scipy import interpolate


##########################################################################
# Globals
##########################################################################

__author__='O.H'
fill_value_default = np.float32(1.e34)
VAR='PSAL'

##########################################################################
# Main
##########################################################################

def main():

    # FICHIER A INTERPOLER
    data_dir='/home/data/'
    filename=sys.argv[1]

    print 'Reading File:... ' + filename
    filename2 = data_dir + filename

    # GRILLE SORTIE 
    filepath_gridoutput='/data/file1.nc'

    # FICHIER DE SORTIE
    outfile_name = 'interp_'+filename
    print outfile_name

    # LECTURE GRILLE SORTIE  
    output_grid=output_grid_params(filepath_gridoutput)

    # INTERPOLATION BILINEAR
    depth=0
    out_data=interp_bilinear_reggrid_Netcdf(filename2,output_grid,depth)

    # ECRITURE NOUVEAU FICHIER NETCDF
    writeOutputPHYS(outfile_name,out_data,output_grid)


##########################################################################
# Functions
##########################################################################

def init_grid_params(filepath_gridinit):
    '''
    READING INPUT COORDINATES - INITIAL GRID - REGULAR GRID
    '''

    init_grid = {}.fromkeys( ['in_lon','in_lat', 'nbloninit', 'nblatinit'] )

    nc_d=nc.NetCDFFile(filepath_gridinit,'r')
    lon=np.array(nc_d.variables['longitude'][:])
    lat=np.array(nc_d.variables['latitude'][:])
    nc_d.close()

    init_grid['nbloninit'] =len(lon)
    init_grid['nblatinit'] =len(lat)

    #grid coordinates
    in_lon=np.float32(lon)
    in_lat=np.float32(lat)

    Xlon = repmat(in_lon,len(in_lat), 1)
    Xlat=  repmat(in_lat,len(in_lon), 1)
    init_grid['in_lon']= np.reshape(Xlon,(init_grid['nbloninit']*init_grid['nblatinit'],1))
    init_grid['in_lat']= np.reshape(transpose(Xlat),(init_grid['nblatinit']*init_grid['nbloninit'],1))

    return init_grid

def output_grid_params(filepath_gridoutput):
    '''
    reading output coordinates (regular grid) 
    '''
    output_grid = {}.fromkeys( ['newlat','newlon', 'nblon', 'nblat','target_lon','target_lat'] )

    # READING LON, LAT IN REGULAR GRID
    nc2=nc.NetCDFFile(filepath_gridoutput,'r')

    lats = array ( nc2.variables['lat'][:]) #[jmin:jmax:]  )
    lons = array ( nc2.variables['lon'][:]) #[imin:imax:] )

    output_grid['newlon']=(np.array(lons))
    output_grid['newlat']=(np.array(lats))

    output_grid['nblon']=len(output_grid['newlon'])
    output_grid['nblat']=len(output_grid['newlat'])

    Xlon = repmat(output_grid['newlon'],output_grid['nblat'], 1);
    output_grid['target_lon'] = np.reshape(Xlon, (output_grid['nblat']*output_grid['nblon'], 1))
    Ylat = repmat(output_grid['newlat'], output_grid['nblon'], 1 );
    output_grid['target_lat']  = np.reshape(transpose(Ylat),(output_grid['nblat']*output_grid['nblon'], 1) )
    nc2.close()

    return output_grid

def interp_bilinear_reggrid_Netcdf(inputdata_name, output_grid,depth):
    """ 
    DESCRIPTION
        INTERPOLATION DE CHAQUE VARIABLE POUR CHAQUE NIVEAU
    INPUT
        inputdata_name: fichier a interpoler
        output_grid : grille sur laquelle on veut interpoler les cartes
        depth= niveau de profondeur sur lequel on veut travailler 
    """

    print inputdata_name
    nc1=nc.NetCDFFile(inputdata_name,'r')

    ##### 
    in_data = {}.fromkeys( [VAR,'latitude','longitude'] )
    in_data['longitude'] = (np.array(nc1.variables['longitude'][:]))
    in_data['latitude'] = (np.array(nc1.variables['latitude'][:]))
    in_data[VAR] = (np.array(nc1.variables[VAR][0,depth,:,:]))
    nc1.close()

    #### VARIABLES 
    maskrhoinit = np.where(squeeze(in_data[VAR][:]) > -10,1.,0.)
    maskrhoinit = np.where(squeeze(in_data[VAR][:]) < 10,1.,0.)

    in_data[VAR]= np.where((in_data[VAR][:]) > -10, in_data[VAR],1.e34)
    in_data[VAR]= np.where((in_data[VAR][:]) < 10, in_data[VAR],1.e34)
   # print MA.maximum(in_data[VAR])
   # print MA.minimum(in_data[VAR])
   # print in_data[VAR].shape

    # VISU MASK    
    #imshow(flipud(maskrhoinit))
    #show()
    out_data = {}.fromkeys(in_data.keys())
    for key in in_data.keys():
        if key==VAR:
            output=zeros((1,output_grid['nblat'],output_grid['nblon']))
            vardata = squeeze(in_data[VAR])
            # avec les valeurs kx=1, ky=1, s=0 ----> ca correspond a une interpolation bilineaire
            ingrid = interpolate.RectBivariateSpline(in_data['latitude'][:], in_data['longitude'][:], vardata[:], kx=1, ky=1, s=0) #vecteur
            outgrid = ingrid(output_grid['newlat'],output_grid['newlon'])
            # print output_grid['nblat']
            # print output_grid['nblon']
            output[0,:,:]= (outgrid)
            out_data[key] = output
            # print out_data[key].shape

    return out_data


def writeOutputPHYS(outfile_name,out_data,output_grid):
    '''
    Write interpolated netcdf output
    '''
    print 'Now writing output netcdf... '
    out_nc =nc.NetCDFFile(outfile_name, 'w')
    out_nc.createDimension('lon', output_grid['nblon'])
    out_nc.createDimension('lat', output_grid['nblat'])
    out_nc.createDimension('time', None)

    lats = out_nc.createVariable('lat','f',('lat',))
    lons = out_nc.createVariable('lon','f',('lon',))

    lats.units = 'degrees_north'
    lons.units = 'degrees_east'

    lons.assignValue(np.float32(output_grid['newlon']))
    lats.assignValue(np.float32((output_grid['newlat'])))

    out_data[VAR]=np.where(out_data[VAR]>50,1.e34,out_data[VAR])
    tt = out_nc.createVariable(VAR,'f',('time','lat','lon'))
    tt.assignValue(np.float32(out_data[VAR]))
    tt._FillValue=fill_value_default
    out_nc.close()



if __name__ == '__main__':
    main()
