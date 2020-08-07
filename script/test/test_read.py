from netCDF4 import Dataset
filename = "/data/rd_exchange4/cregnier/CLASS4_OUTPUTS/class4_20200710_PSY4V3R1_orca12_profile.nc"
nc_fid = Dataset(filename, 'r+', 'NETCDF4')

