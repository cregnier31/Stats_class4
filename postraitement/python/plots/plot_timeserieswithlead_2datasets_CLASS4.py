# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
#!/usr/bin/python
import matplotlib as mpl
from matplotlib import style
import numpy
#style.use('ggplot')
mpl.use('Agg')
from Class_timeseries import Plot_timeseries
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
sys.path.append('/home/cregnier/python/module/lib/python2.6/site-packages/')
from sytoolkit.sydate import SyDate
ZONE="ANT"
#ZONE="ARC"
dataset="AMSR2"
model="PSY4V3R1"
#model="PSY4V2R2"
frame1="best"
frame2="forecast"
frame3="persistence"
tval=".40"
#choice="mean"
date1="20130101-20170725"
date2="20161101-20171031"
date1="20161101-20171031"
date2=date1
period=date1
#period=date2
##date1="20150101-20161103"
##date2=date1
##date1="20161026-20170630"
###date2=date1
##date2="20150101-20161103"
###model="GIOPS"
filedir="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"
filename1=filedir+model+"/timeseries/best/Stats_contable_timeseries_"+ZONE+"_"+model+"_"+date1+"_seuil"+tval+"_"+frame1+".nc"
filename2=filedir+model+"/timeseries/forecast/Stats_contable_timeseries_"+ZONE+"_"+model+"_"+date2+"_seuil"+tval+"_"+frame2+".nc"
filename3=filedir+model+"/timeseries/persistence/Stats_contable_timeseries_"+ZONE+"_"+model+"_"+date2+"_seuil"+tval+"_"+frame3+".nc"
## Read file
## Read file
print filename1
nc1_file=netCDF4.Dataset(str(filename1),'r')
print "OK1 %s" %(str(filename1))
nc2_file=netCDF4.Dataset(str(filename2),'r')
print "OK2 %s" %(str(filename2))
nc3_file=netCDF4.Dataset(str(filename3),'r')
print "OK3 %s" %(str(filename3))
#nc_attrs, nc_dims, nc_vars = ncdump(nc_file)
#nc_attrs, nc_dims, nc_vars = ncdump(nc_file)
dims = [dim for dim in nc1_file.dimensions]
length_time1=len(nc1_file.dimensions['time'])
length_time2=len(nc2_file.dimensions['time'])
length_time3=len(nc3_file.dimensions['time'])
nb_echeances=len(nc3_file.dimensions['z'])
## Conversion in Days
time_tab= nc1_file.variables['time'][:]/86400
time_tab_2= nc2_file.variables['time'][:]/86400
time_tab_3= nc3_file.variables['time'][:]/86400
time_ref_1=[]
for timevar in time_tab:
    time2 = SyDate.fromjulian(int(timevar))
    year=str(time2)[0:4]
    month=str(time2)[4:6]
    day=str(time2)[6:8]
    time_ref_1.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
time_ref_2=[]
for timevar in time_tab_2:
    time2 = SyDate.fromjulian(int(timevar))
    year=str(time2)[0:4]
    month=str(time2)[4:6]
    day=str(time2)[6:8]
    time_ref_2.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
time_ref_3=[]
for timevar in time_tab_3:
    time3 = SyDate.fromjulian(int(timevar))
    year=str(time3)[0:4]
    month=str(time3)[4:6]
    day=str(time3)[6:8]
    time_ref_3.append(dt.datetime.strptime(str(time3),"%Y%m%d"))
##
if [ date1 == date2] :
    indice=0
else :
    indice=1300

print indice
meandiff_oper_dt1 = nc1_file.variables['mean_diff_timeserie'][:]
meandiff_oper_dt1=np.where(abs(meandiff_oper_dt1)>0.8,np.nan,meandiff_oper_dt1)
rmsdiff_oper_dt1= nc1_file.variables['rms_diff_timeserie'][:]
rmsdiff_oper_dt1=np.where(rmsdiff_oper_dt1>0.8,np.nan,rmsdiff_oper_dt1)
nb_values_oper_dt1=nc1_file.variables['sum_values_timeserie'][:]
PCT_dt1=nc1_file.variables['PCT_timeserie'][:]
PCW_dt1=nc1_file.variables['PCW_timeserie'][:]
PCI_dt1=nc1_file.variables['PCI_timeserie'][:]
BIAS_dt1=nc1_file.variables['BIAS_timeserie'][:]
Hitice_dt1=nc1_file.variables['Hitice_timeserie'][:]
Miss_dt1=nc1_file.variables['Miss_timeserie'][:]
FalseAlarm_dt1=nc1_file.variables['FalseAlarm_timeserie'][:]
HitWater_dt1=nc1_file.variables['Hitwater_timeserie'][:]



meandiff_oper_dt2 = nc2_file.variables['mean_diff_timeserie'][:,:]
meandiff_oper_dt2=np.where(abs(meandiff_oper_dt2)>0.7,np.nan,meandiff_oper_dt2)
rmsdiff_oper_dt2= nc2_file.variables['rms_diff_timeserie'][:,:]
PCT_dt2=nc2_file.variables['PCT_timeserie'][:,:]
PCW_dt2=nc2_file.variables['PCW_timeserie'][:,:]
#PCT_dt2=np.where(PCT_dt2<0.2,np.nan,PCT_dt2)
#PCW_dt2=np.where(PCW_dt2<0.2,np.nan,PCW_dt2)

rmsdiff_oper_dt2=np.where(rmsdiff_oper_dt2>0.8,np.nan,rmsdiff_oper_dt2)
print np.nanmax(rmsdiff_oper_dt2)
nb_values_oper_dt2=nc2_file.variables['sum_values_timeserie'][:,:]
PCI_dt2=nc2_file.variables['PCI_timeserie'][:,:]
#PCI_dt2=np.where(PCI_dt2<0.2,np.nan,PCI_dt2)
BIAS_dt2=nc2_file.variables['BIAS_timeserie'][:,:]
#BIAS_dt2=np.where(BIAS_dt2<0.2,np.nan,BIAS_dt2)
Hitice_dt2=nc2_file.variables['Hitice_timeserie'][:,:]
Miss_dt2=nc2_file.variables['Miss_timeserie'][:,:]
FalseAlarm_dt2=nc2_file.variables['FalseAlarm_timeserie'][:,:]
HitWater_dt2=nc2_file.variables['Hitwater_timeserie'][:,:]


meandiff_oper_dt3 = nc3_file.variables['mean_diff_timeserie'][:,:]
meandiff_oper_dt3=np.where(abs(meandiff_oper_dt3)>0.7,np.nan,meandiff_oper_dt3)
rmsdiff_oper_dt3= nc3_file.variables['rms_diff_timeserie'][:,:]
PCT_dt3=nc3_file.variables['PCT_timeserie'][:,:]
PCW_dt3=nc3_file.variables['PCW_timeserie'][:,:]
#PCT_dt3=np.where(PCT_dt3<0.2,np.nan,PCT_dt3)
#PCW_dt3=np.where(PCW_dt3<0.2,np.nan,PCW_dt3)
rmsdiff_oper_dt3=np.where(rmsdiff_oper_dt3>0.8,np.nan,rmsdiff_oper_dt3)
print np.nanmax(rmsdiff_oper_dt3)
nb_values_oper_dt3=nc3_file.variables['sum_values_timeserie'][:,:]
PCI_dt3=nc3_file.variables['PCI_timeserie'][:,:]
#PCI_dt3=np.where(PCI_dt3<0.2,np.nan,PCI_dt3)
BIAS_dt3=nc3_file.variables['BIAS_timeserie'][:,:]
#BIAS_dt3=np.where(BIAS_dt3<0.2,np.nan,BIAS_dt3)
Hitice_dt3=nc3_file.variables['Hitice_timeserie'][:,:]
Miss_dt3=nc3_file.variables['Miss_timeserie'][:,:]
FalseAlarm_dt3=nc3_file.variables['FalseAlarm_timeserie'][:,:]
HitWater_dt3=nc3_file.variables['Hitwater_timeserie'][:,:]

missing_val=np.nan

if ZONE == "ARC" :
    ymin=-0.3
    ymax=0.4
##    ymin=-0.7
##    ymax=0.7
else :
    ymin=-0.7
    ymax=0.7

dateval=str(dt.date.today()).replace('-','')
dir_plot='/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/OPER/PLOT/'+dateval+'/'
if not os.path.exists(dir_plot):
    os.makedirs(dir_plot)

title=ZONE+": RMS/Mean diff "+dataset+" ice conc thr "+tval+" vs "+model+" with lead time "+str(nb_echeances)+" days"
ylabel="Bias/RMS"
barlabel="AMSR data"
fileout=ZONE+"_Mean_RMS_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
#fileout=ZONE+"_Mean_RMS_timeseries_all_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead2TS(rmsdiff_oper_dt1[indice:],rmsdiff_oper_dt2[:,:],rmsdiff_oper_dt3[:,:],
                meandiff_oper_dt1[indice:],meandiff_oper_dt2[:,:],meandiff_oper_dt3[:,:],nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)
## Plot PCI
if ZONE == "ARC" :
    ymin=0.1
    ymax=1.0
else : 
   ymin=0.1
   ymax=1.0
ylabel="PCI"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
barlabel="AMSR data"
#fileout=ZONE+"_Mean_RMS_timeseries_all_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(PCI_dt1[indice:],PCI_dt2[:,:],PCI_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)
# Plot PCT
if ZONE == "ARC" :
    ymin=0.80
    ymax=1.0
else : 
   ymin=0.5
   ymax=1.0
ylabel="PCT"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
barlabel="AMSR data"
#fileout=ZONE+"_Mean_RMS_timeseries_all_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(PCT_dt1[indice:],PCT_dt2[:,:],PCT_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)
## Plot PCW
if ZONE == "ARC" :
    ymin=0.9
    ymax=1.0
else : 
   ymin=0.5
   ymax=1.0
ylabel="PCW"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
barlabel="AMSR data"
#fileout=ZONE+"_Mean_RMS_timeseries_all_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(PCW_dt1[indice:],PCW_dt2[:,:],PCW_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)

## Plot BIAS
if ZONE == "ARC" :
    ymin=0.9
    ymax=1.0
else : 
   ymin=0.5
   ymax=1.0
ylabel="BIAS"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
barlabel="AMSR data"
#fileout=ZONE+"_Mean_RMS_timeseries_all_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(BIAS_dt1[indice:],BIAS_dt2[:,:],BIAS_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)

#### Plot Hitice
ymin=0
ymax=np.nanmax(Hitice_dt3)*1.1
ylabel="Hitice"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(Hitice_dt1[indice:],Hitice_dt2[:,:],Hitice_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)
#### Plot HitWater
ymin=0
ymax=np.nanmax(HitWater_dt3)*1.1
ylabel="HitWater"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(HitWater_dt1[indice:],HitWater_dt2[:,:],HitWater_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)

#### Plot Miss
ymin=0
ymax=np.nanmax(Miss_dt3)*1.1
ylabel="Miss"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(Miss_dt1[indice:],Miss_dt2[:,:],Miss_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)

#### Plot FalseAlarm
ymin=0
ymax=np.nanmax(FalseAlarm_dt3)*1.1
ylabel="FalseAlarm"
title=ZONE+": "+ylabel+" "+dataset+" ice conc thr "+tval+" vs "+model
barlabel=dataset
fileout=ZONE+"_"+ylabel+"_timeseries_"+period+"_withleadtime_thresh"+tval+"_"+model+"_"+dataset+"_"+date1+"_"+tval+".png"
Plot_timeseries(dir_plot,ymin,ymax).plot_TimeSerieswithlead(FalseAlarm_dt1[indice:],FalseAlarm_dt2[:,:],FalseAlarm_dt3[:,:],
                nb_values_oper_dt1[indice:],time_ref_1[indice:],
                time_ref_2[:],time_ref_3[:],nb_echeances,title,ylabel,barlabel,fileout)
