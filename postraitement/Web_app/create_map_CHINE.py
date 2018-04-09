import folium
import sys,os,glob
import  vincent
import netCDF4
import matplotlib.pyplot as plt
import numpy as np
from glob import glob as list_file
sys.path.append('/home/cregnier/python/module/lib/python2.6/site-packages/')
from sytoolkit.sydate_origin import SyDateOrigin
from sytoolkit.sydate import SyDate
## Charly REGNIER 
## Create leaflet map with foluim version  
## November 2015


DAY_MIN="20160101"
DAY_MAX="20161231"

jdatemax=SyDate(DAY_MAX)
jdatemin=SyDate(DAY_MIN)
MOD_TYPE="PSY4V3R1"
MOD=MOD_TYPE[0:4]
## Defining the area
## South Australia
zone="SCS"
lon_min=99
lon_max=130
lat_min=-3
lat_max=30

CL4_dir="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/data/select/SCS/"

## Restriction to DAY_MIN-DAY_MAX interval
list_CL4_files=[]
for file in list_file(CL4_dir+"*.nc") :
    dateval=os.path.basename(file).split('_')[0]
    jdate=SyDate(str(dateval))
    if jdate >= jdatemin and jdate <= jdatemax :
        print "Date OK %s" %(dateval)
        list_CL4_files.append(file)
        #sys.exit(1)
print len(list_CL4_files)

## Create basic Leaflet map from folium module 
reg_dir='DATA/'+zone
if not os.path.exists(reg_dir):
  os.makedirs(reg_dir)
os.chdir(reg_dir)

map_osm = folium.Map(location=[0,-30],zoom_start=5,width=1200,height=600,
                    tiles='OpenStreetMap')
                    #tiles='Mapbox bright')
## Enable function lat/lon popup
folium.LatLngPopup().add_to(map_osm)
## Read values and search position 
il_file=0
nb_file=len(list_CL4_files)
type_list=['temp','psal']
print nb_file

for file in list_CL4_files :
  print file
  filename=os.path.basename(file)
  camp=filename.split('_')[1]
  dateval=filename.split('_')[0]
  profile=filename.split('_')[2].split('.')[0]
  for type_var in type_list :
     list_values=[]
     #Read dataset
     nc  = netCDF4.Dataset(file,'r')
     VP_lon = nc.variables['LONGITUDE'][:] 
     VP_lat = nc.variables['LATITUDE'][:] 
     JULD=  nc.variables['JULD'][:]
     list_wmo= nc.variables['WMO_INST_TYPE'][:]
     insitu_var=type_var.upper()
     try : 
        mod_var=nc.variables['HDCST_'+insitu_var][:,:]
     except :
        continue
     if type_var == 'temp' :
        clim_var='TMLEV13'
     else :
        clim_var='SMLEV13'
     clim_val=nc.variables[clim_var][:,:]
     insitu_val=nc.variables[insitu_var][:,:]
     prof_VP=-(nc.variables['DEPH'][:,:])
     N_PROF = len(nc.dimensions['N_PROF']) 
     ind=0
     nb_val=len(list_wmo)
     charts={}
     locations={}
     color1="#0023ff"
     color2="#4d66ff"
     color3="#7c8eff"
     color4="#a1aeff"
     color5="#00ca31"
     color6="#08ff44"
     color7="#73ff95"
     color8="#b7ffc9"
     for id_name in list_wmo : ##
           tab1=list_wmo[ind]
           nb_val=tab1[:].count()
           dc_wmo=str(("".join(tab1[i] for i in range(nb_val))).strip())
           ## Read values from netcdf and insert into a dictionnary
           valuetoplot={}
           lat=float(VP_lat[ind])
           lng=float(VP_lon[ind])
           #print 'OK-6'
           if type_var == 'temp' :
             color_marker='Red'
             nb_sides=3
             lat=lat+0.005
           else :
               if camp == "REVIZEE-NEI" :
                  color_marker=color1
                  nb_sides=4 
               elif camp == "REVIZEE-NEII":
                  color_marker=color2
                  nb_sides=4 
               elif camp == "REVIZEE-NEIII":
                  color_marker=color3
                  nb_sides=4 
               elif camp == "REVIZEE-NEIV":
                  color_marker=color4
                  nb_sides=4 
               elif camp == "REVIZEE-NI":
                  color_marker=color5
                  nb_sides=4 
               elif camp == "REVIZEE-NII":
                  color_marker=color6
                  nb_sides=4 
               elif camp == "REVIZEE-NIII":
                  color_marker=color7
                  nb_sides=4 
               elif camp == "REVIZEE-NIV" :
                  color_marker=color8
                  nb_sides=4 
           #print 'OK-5'
           if lat >= lat_min and lat <= lat_max and lng >= lon_min and lng <= lon_max :
               #print lat,lng, lon_min,lon_max,lat_min,lat_max
               ## Point inside the region, read the other parameters
               wtg_id="WMO_"+dc_wmo+"_"+str(dateval)+"_"+str(profile)+"_"+str(camp)
               #print wtg_id
               prof_val=prof_VP[ind,:] 
               clim_tmp_val=clim_val[ind,:] 
               insitu_tmp_val=insitu_val[ind,:]
               hdcst_val=mod_var[ind,:]
               datevalue=JULD[ind]
               dateval=int(JULD[ind])  
               dateval_sys=SyDate.fromjulian(dateval)
               #print 'OK-4'
               ## Find empty values
               mask_var_mod=np.ma.masked_values(hdcst_val,9.96e36)
               mask_var_prof=np.ma.masked_values(prof_val,0)
               count_var=mask_var_mod.count()
               count_prof=mask_var_prof.count()
               #print 'OK-3'
               if count_prof > 1 and count_var > 1 :
                  ind_prof = np.where(prof_val[:] != 0)[0][-1]
                  #print 'OK-2'
                  if ind_prof != 1 : 
                      #Feed the dictionnary
                      #print 'OK-1'
                      valuetoplot['Depth']=prof_val[0:ind_prof+1].tolist()
                      valuetoplot["insitu_"+insitu_var]=insitu_tmp_val[0:ind_prof+1].tolist()
                      valuetoplot['Model']=hdcst_val[0:ind_prof+1].tolist()
                      valuetoplot['Clim WOA13']=clim_tmp_val[0:ind_prof+1].tolist()
                      #Create vincent chart objet for the plot to show in the popup
                      print "create chart"
                      charts[wtg_id] = (vincent.Line_invert(valuetoplot,iter_idx='Depth',width=400, height=200))
                      print 'Create chart OK'
                      charts[wtg_id].axis_titles(y='Depth', x='Values ('+str(SyDate.__str__(dateval_sys))+')')
                      charts[wtg_id].legend(title=insitu_var+'\n'+' '+str(wtg_id))
                      charts[wtg_id].axes[0].ticks = 6
                      #path = ''.join(['df_'+insitu_var+'_'+wtg_id, '.json'])
                      path = ''.join(['df_'+insitu_var+"_"+wtg_id, '.json'])
                      locations[wtg_id]=(lat,lng)
                      # Add polygon marker in the map with associated popup
                      charts[wtg_id].to_json(path)
                      vega=folium.Vega((charts[wtg_id].to_json(path)),width=350,height=200)
                      print 'OK1'
                      #fg=folium.FeatureGroup(name='Mesures_brasil')
                      popup1 = folium.Popup(max_width=350).add_child(vega)
                      #popup1 = folium.Popup(max_width=400,).add_child(folium.Vega(charts[wtg_id], width=500, height=250))
                      print 'OK2'
                      #fg.add_child(folium.RegularPolygonMarker(location=locations[wtg_id],fill_color=color_marker,radius=5,number_of_sides=nb_sides,popup=(charts[wtg_id],path)))
                      #folium.RegularPolygonMarker(location=locations[wtg_id],fill_color=color_marker,radius=5,number_of_sides=nb_sides,popup=(charts[wtg_id],path)).add_to(map_osm)
                      #folium.RegularPolygonMarker(location=locations[wtg_id],fill_color=color_marker,radius=5,number_of_sides=nb_sides,popup=popup1).add_to(map_osm)
                      polygon=folium.RegularPolygonMarker(location=locations[wtg_id],fill_color=color_marker,radius=5,number_of_sides=nb_sides,popup=popup1)
                      print 'OK2-1'
                      map_osm.add_children(polygon)
                      print 'OK3'
                     # map_osm.add_child(fg)
           ind=ind+1 
     #map_osm.add_child(folium.LayerControl())
     map_osm.create_map(path='CLASS4_Profiles_'+zone+'_'+MOD_TYPE+'_'+DAY_MIN+'_'+DAY_MAX+'_TEMP_PSAL.html')
  il_file=il_file+1
map_osm.render_iframe = True
map_osm
