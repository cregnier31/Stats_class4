from glob import glob as gb
from netCDF4 import Dataset
import netCDF4
import numpy as np
import sys
MODEL="GLORYS2V4"

file='test_char.nc'
nc= netCDF4.Dataset(file,'w')
nc.createDimension('string_length8',8) 
nc.createDimension('numvars',10) 
#print nc.createVariable('varname','c',('numvars','string_length8'))
#sys.exit(1)
nc.createVariable('varname','c',('numvars','string_length8'))
nc.variables['varname'][0]='ileadfra'
nc.variables['varname'][1]='ileadfrt'
nc.close
sys.exit(1)

for file in gb(dir_data+"*test.nc"): 
    print file
    nc_fid = Dataset(file, 'r+')
    nc_var = nc_fid.createVariable('PARAMETERINT10', 'c',('L_PARAMETERINT','C_PARAMETERINT'))
    #var=nc_fid.variables['PARAMETERINT'][:]
    print type(nc_var)
    nc_vars = [var for var in nc_fid.variables]  # list of nc variables
    list_var=[]
    ind=0
    for var in nc_fid.variables : 
        if var == 'HDCST_TEMP' or  var == 'HDCST_PSAL' or var == 'TMLEV13' or var == 'SMLEV13':
            print str(var)
            list_var.append(str(var))
            nc_var[ind]=var
            #parameterint[ind]="{0:12s}".format(var)
            ind+=1
   # nc_var[0]=''
    #nc_var[:]=netCDF4.stringtochar(np.array(list_var))
    #print parameterint.shape
    #print parameterint
    #nc_fid.variables['PARAMETERINT'][:] = parameterint[:]
    nc_fid.close()
