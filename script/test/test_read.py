from netCDF4 import Dataset

dir_static='/utmp/smer/regnierc/staticinput/'
fic_coordinates=dir_static+'mask_PSY4V3_deg.nc'
nc = Dataset(fic_coordinates,'r')
variables = nc.variables
print (variables.keys())
list_lon = ['x', 'X', 'lon', 'LON', 'lons', 'longitude', 'LONGITUDE', 'nav_lon']
list_lat = ['y', 'Y', 'lat', 'LAT', 'LATS', 'latitude', 'LATITUDE', 'nav_lat']
list_depth = [ 'deptht', 'depth', 'z', 'Z', 'DEPTH','nav_lev']
try:
    lon_name = [ k for k in variables.keys() & set(list_lon)]
    lat_name = [ k  for k in variables.keys() & set(list_lat)]
    depth_name = [ k for k in variables.keys() & set(list_depth)]
    print ('Lon {} Lat {} Depth {}'.format(lon_name,lat_name,depth_name))
except:
    print('lon lat or depth not defined')
    raise


