import folium
import  vincent
import netCDF4
import sys,os,glob
import matplotlib.pyplot as plt
import numpy as np
from glob import glob as list_file
from sytoolkit.sydate_origin import SyDateOrigin
from sytoolkit.sydate import SyDate
## Charly REGNIER 
## November 2015


DAY_MIN="20160101"
DAY_MAX="20161231"
jdatemax=SyDate(DAY_MAX)
jdatemin=SyDate(DAY_MIN)
MOD_TYPE="PSY4V3R1"
MOD=MOD_TYPE[0:4]
## Defining the area
# South China Sea
zone="SCS"
lon_min=99
lon_max=130
lat_min=-3
lat_max=30

CL4_dir="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/data/select/SCS/"

## Restriction to DAY_MIN-DAY_MAX interval
list_CL4_files=[]
for file in list_file(CL4_dir+"*.nc") :
    filename=os.path.basename(file)
    prefix=filename[0:2]
    if prefix == 'CO' : 
        dateval=os.path.basename(file).split('_')[2]
    elif prefix == 'AR' : 
        dateval=os.path.basename(file).split('_')[4].split('.')[0]
    jdate=SyDate(str(dateval))
    if jdate >= jdatemin and jdate <= jdatemax :
        #print "Date OK %s" %(dateval)
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
## Enable function lat/lon popup
map_osm.lat_lng_popover()
map_osm
## Read values and search position 
il_file=0
nb_file=len(list_CL4_files)
type_list=['temp','psal']
print nb_file

for file in list_CL4_files :
  for type_var in type_list :
     list_values=[]
     #Read dataset
     nc  = netCDF4.Dataset(file,'r')
     VP_lon = nc.variables['LONGITUDE'][:] 
     VP_lat = nc.variables['LATITUDE'][:] 
     JULD=  nc.variables['JULD'][:]
     list_dcref= nc.variables['DC_REFERENCE'][:]
     list_platform=nc.variables['PLATFORM_NUMBER'][:]
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
     nb_val=len(list_dcref)
     charts={}
     locations={}
     for id_name in list_platform : ##
           #tab1=np.concatenate(list_dcref[ind])
           #tab2=np.concatenate(list_platform[ind])
           tab1=list_dcref[ind]
           tab2=list_platform[ind]
           #list_values.append(("".join(tab1[i] for i in range(len(tab1[:])))).strip())
           nb_val=tab1[:].count()
           nb_val2=tab2[:].count()
           dc_ref_value=str(("".join(tab1[i] for i in range(nb_val))).strip())
           plateform_number_value=str(("".join(tab2[i] for i in range(nb_val2))).strip())           
           ## Read values from netcdf and insert into a dictionnary
           valuetoplot={}
           lat=float(VP_lat[ind])
           lng=float(VP_lon[ind])
           if type_var == 'temp' :
             color_marker='Red'
             nb_sides=3
             lat=lat+0.005
           else :
             color_marker='Blue'
             nb_sides=4  
           if lat >= lat_min and lat <= lat_max and lng >= lon_min and lng <= lon_max :
               #print lat,lng, lon_min,lon_max,lat_min,lat_max
               ## Point inside the region, read the other parameters
               wtg_id="DC_"+dc_ref_value+"_PN_"+plateform_number_value
               prof_val=prof_VP[ind,:] 
               clim_tmp_val=clim_val[ind,:] 
               insitu_tmp_val=insitu_val[ind,:]
               hdcst_val=mod_var[ind,:]
               datevalue=JULD[ind]
               dateval=int(JULD[ind])  
               dateval_sys=SyDate.fromjulian(dateval)
               ## Find empty values
               mask_var_mod=np.ma.masked_values(hdcst_val,9.96e36)
               mask_var_prof=np.ma.masked_values(prof_val,0)
               count_var=mask_var_mod.count()
               count_prof=mask_var_prof.count()
               if count_prof > 1 and count_var > 1 :
                  ind_prof = np.where(prof_val[:] != 0)[0][-1]
                  if ind_prof != 1 : 
                      #Feed the dictionnary
                      valuetoplot['Depth']=prof_val[0:ind_prof+1].tolist()
                      valuetoplot["insitu_"+insitu_var]=insitu_tmp_val[0:ind_prof+1].tolist()
                      valuetoplot['Model']=hdcst_val[0:ind_prof+1].tolist()
                      valuetoplot['Clim WOA13']=clim_tmp_val[0:ind_prof+1].tolist()
                      #Create vincent chart objet for the plot to show in the popup
                      charts[wtg_id] = (vincent.Line_invert(valuetoplot,iter_idx='Depth',width=400, height=200))
                      charts[wtg_id].axis_titles(y='Depth', x='Values ('+str(SyDate.__str__(dateval_sys))+')')
                      charts[wtg_id].legend(title=insitu_var+'\n'+' '+str(wtg_id))
                      charts[wtg_id].axes[0].ticks = 6
                      #path = ''.join(['df_'+insitu_var+'_'+wtg_id, '.json'])
                      path = ''.join(['df_'+insitu_var+"_"+wtg_id, '.json'])
                      locations[wtg_id]=(lat,lng)
                      # Add polygon marker in the map with associated popup
                      charts[wtg_id].to_json(path)
                      map_osm.polygon_marker(location=locations[wtg_id],fill_color=color_marker,radius=5,num_sides=nb_sides,popup=(charts[wtg_id],path))

           ind=ind+1 

     #gc.collect()
     #del VP_lon[:],VP_lat[:],nc
     #del JULD[:],list_dcref[:],list_platform[:],mod_var[:,:],clim_val[:,:]
    # del insitu_val[:,:],prof_VP[:,:],prof_val[:],clim_tmp_val[:],insitu_tmp_val[:],hdcst_val[:]
    #print "Nb file OK %i / %i" %(il_file,nb_file)
     map_osm.create_map('CLASS4_Profiles_'+zone+'_'+MOD_TYPE+'_'+DAY_MIN+'_'+DAY_MAX+'_TEMP_PSAL.html')

  il_file=il_file+1
  #print "Nb file OK %i / %i" %(il_file,nb_file)

map_osm.render_iframe = True
map_osm
