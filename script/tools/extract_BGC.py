import os, sys
from os.path import dirname
sys.path.append(dirname(__file__)+'/../modules/')
from nco.nco import Nco
from glob import glob
from sydate import SyDate
import netCDF4
DIRDATA='/dataref/opr/DATA/INSITU/HYDRO/BGC_ARGO/'
DAILY_files=DIRDATA+'daily/'

lists_var = ["CHLA","DOWNWELLING_PAR","NITRATE","OXYGEN","PH_IN_SITU_TOTAL"]
dir2 = "20200623"
# Nco options
options = []
options.extend(['-h'])

for f, dir in enumerate(lists_var):
    list_file = glob(DIRDATA+dir+'/'+dir2+'/*.nc')
    for ind, file_bgc in enumerate(list_file):
        # Nco constructor
        nco = Nco()
        ## Read
        filename = os.path.basename(file_bgc)
        # data_type = filename.split(prefix)[1].split('_')[1]
        nc = netCDF4.Dataset(file_bgc, 'r')
        print (file_bgc)
        # Extract time variable
        variable = "JULD"
        dimension="N_PROF"
        v = nc.variables[variable][:]
        #time_origin=nc.variables['JULD'].getncattr('units')
        time_origin=1950
        date_all=[str(SyDate.fromjulian(int(valeurj),time_origin)) for valeurj in v]
        #date_all = [SyDate.fromjulian(int(valeurtmp)) for valeurtmp in v]
        for ind_date, date in enumerate(date_all): 
            file_out = "BGC_ARGO_"+dir+"_"+date+".nc"
            indexes = [i for i, x in enumerate(date_all) if x == date]
            print (len(indexes))
            if len(indexes) == 1:
                nco.ncks(input=file_bgc, output=DAILY_files+file_out, dimension=dimension+','+str(
                                                                                    indexes[0]), options=options)
            else:
                print ('Nb profiles > 0')
                for index in indexes:
                    file_out = "BGC_ARGO_"+dir+"-prof"+str(index)+"_"+date+".nc"
                    nco.ncks(input=file_bgc, output=DAILY_files+file_out, dimension=dimension+','+str(
                                                                                    index), options=options)
                #nco.ncks(input=file_bgc, output=DAILY_files+file_out, dimension=dimension+','+str(
                #                                                                    indexes[0])+','+str(indexes[-1]), options=options)
                #if len(indexes) >= 4:
                #    print ("Profiles > 4 values {}".format(filename))
                #    sys.exit(1)

        print ('Rep {} file {} OK'.format(dir,file_bgc))
#.log.info('Creation fileout : %s '%(file_out))
#                        ## Create output extracted file
#                                                                        if dirtmp+file_out not in liste_tot:
#
