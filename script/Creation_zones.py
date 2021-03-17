#!/usr/bin/env python
# Create Json file from pickle file

import os
import sys
import json
from os.path import dirname
sys.path.append(dirname(__file__)+'/../modules/')
import param.Def_param_bulletin as params
import pickle as cPickle
import numpy as np
import re
dir_static = '/homelocal-px/px-116/sauvegarde/cregnier/statics/'

file_pi = dir_static+"mask_CMEMS_area_all_regions.p"
#f = open(file_pi, 'rb')
#table_hull = cPickle.load(f)
with open(file_pi, 'rb') as f:
    table_hull = cPickle.load(f, encoding="latin")
tab_region = {}

lon_glo = [-180.0 , 180.0, 180.0, -180.0]
lat_glo = [-80.0, -80.0, 90.0, 90.0]

coords = list(zip(lon_glo, lat_glo))
tab_region['Full Domain'] = coords

for key in table_hull.keys():
    #print ('Region {} value {}'.format(key, type(table_hull[key])))
    p = table_hull[key].vertices
    lon = p[:,0]
    lat = p[:,1]
    coords = list(zip(lon, lat))
    key2 = re.sub('_',' ',key)
    tab_region[key2] = coords
json_out ='../postraitement/static/mask_GLOBAL_CMEMS_all_regions.json'
with open(json_out, 'w') as outfile:
    json.dump(tab_region, outfile,indent=4)#, sort_keys=True)
