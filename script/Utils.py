import numpy as np
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


