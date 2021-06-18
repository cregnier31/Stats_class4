import xarray as xr
from  glob import glob
import sys

input_dir="/scratch/work/regnierc/SORT/DAILY/PSY4Q/psy4qv3r1/"

forecast=['fcst1','fcst2','fcst3','fcst4','fcst5','fcst6','fcst7','fcst8','fcst9', 'nwct']
mfdataset_fcst = {}
dateval="202105"

for fc,fcst in enumerate(forecast):
   print (fc, fcst)
   liste_file=sorted(glob(input_dir+fcst+'/PSY4QV3R1_1hAV_'+dateval+'*nc'))
   print (sorted(liste_file))
   #if fc > 0 : sys.exit(1)
   mfdataset_fcst[str(fc)] = xr.open_mfdataset(liste_file, concat_dim='time_counter') #, autoclose=True)
   print ("Mfdataset fcst {} ok".format(fc))
   #for i,file in enumerate(liste_file):
   #   try:
   #      print ("Read {}".format(file))
   #      nc_file = xr.open_dataset(file)
   #      print ("Read Ok {} / {}".format(i,len(liste_file)))
   #   except IOError as e:
   #      print ("Problem with the file {} {}".format(file, e))
