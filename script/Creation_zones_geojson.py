#!/usr/bin/env python
# Create Geojson file from pickle file

import os
import sys
import json
from os.path import dirname
sys.path.append(dirname(__file__)+'/../modules/')
import param.Def_param_bulletin as params
import pickle as cPickle
import numpy as np
from geojson import Point, Feature, FeatureCollection, dump
import re
from shapely.geometry.polygon import Polygon as ShapelyPolygon

dir_static = '/homelocal-px/px-116/sauvegarde/cregnier/statics/'

file_pi = dir_static+"mask_CMEMS_area_all_regions.p"
with open(file_pi, 'rb') as f:
    table_hull = cPickle.load(f, encoding="latin")

features_all = []
features = []
tab_region = {}
lon_glo = [-180.0 , 180.0, 180.0, -180.0]
lat_glo = [-80.0, -80.0, 90.0, 90.0]
coords = ShapelyPolygon(list(zip(lon_glo,lat_glo)))
region = 'Full Domain'
name_subZone = re.sub(' ', '-', region).lower()
features.append(Feature(geometry=coords, properties={"NAME": region,
                         'subZone': name_subZone}))


for key in table_hull.keys():
    p = table_hull[key].vertices
    lon = p[:,0].tolist()
    lat = p[:,1].tolist()
    coords = ShapelyPolygon(list(zip(lon, lat)))
    region = re.sub('_',' ',key)
    name_subZone = re.sub(' ', '-', region).lower()
    features.append(Feature(geometry=coords, properties={"NAME": region,
                            'subZone': name_subZone}))

json_out ='../postraitement/static/mask_GLOBAL_CMEMS_all_regions.geojson'
feature_collection = FeatureCollection(features)
with open(json_out, 'a+') as f:
    dump(feature_collection, f, indent=2, sort_keys=True)
#
