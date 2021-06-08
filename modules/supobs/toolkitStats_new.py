# coding: utf8
import os,sys

import netCDF4
import numpy as np
import datetime as dt
from os.path import dirname
import arithm
sys.path.append(dirname(__file__)+'/../')
import utilities

#-----------------------------------------------------------------------------

def read_CL4obs(cl_fileIn) :

    """
Routine permettant de lire les contenus de fichiers CLASS4 au format GODAE.
> Usage : rla_val,cla_varname,rla_lons,rla_lats,rla_depth = read_CL4values(cl_fileIn,ccast=ccast)

> Inputs : cl_fileIn     path du fichier CLASS4

> Outputs : rla_val       tableau de la variable a lire
           rla_lons,      tableau des longitudes/latitudes/profondeurs des profils
           rla_lats,
           rla_depth
    """

    cla_varname = []
    nc   = netCDF4.Dataset(cl_fileIn,'r')
    try:
        cla_varname_read = nc.variables['varname'][:]
        cla_varname = utilities.pull_names(cla_varname_read)
    except:
        pass
        #print "Missing varname variable"
    try:
        rla_lons  = np.array(nc.variables['longitude'][:])
        rla_lats  = np.array(nc.variables['latitude'][:])
    except:
        print("Missing varname lon")
        print((" File %s " %(cl_fileIn)))
        sys.exit(1) 
    try:
        rla_depth = np.array(nc.variables['depth'][:])
    except:
        print ("Missing varname depth")
        rla_depth=np.zeros((len(rla_lons),1))
    nc.close()
    rla_depth[(rla_depth >= 99999.)] = np.nan
    rla_lons[(rla_lons >= 99999.)] = np.nan
    rla_lats[(rla_lats >= 99999.)] = np.nan


    return cla_varname,rla_lons,rla_lats,rla_depth


#------------------------------------------------------------------------------

def read_CL4obs_chloro(cl_fileIn) :

    """
Routine permettant de lire les contenus de fichiers CLASS4 au format GLOBCOLOUR.
    """

    nc = netCDF4.Dataset(cl_fileIn,'r')
    rla_lons  = np.array(nc.variables['lon'][:])
    rla_lats  = np.array(nc.variables['lat'][:])
    nc.close()

    if rla_lons.shape != rla_lats.shape :
        lon2D = np.zeros((rla_lats.size, rla_lons.size))
        lat2D = np.zeros((rla_lats.size, rla_lons.size))

        for numl,l in enumerate(rla_lats) :
            lat2D[numl,:] = l
        for numL,L in enumerate(rla_lons) :
            lon2D[:,numL] = L

    rla_lons_vect = np.reshape(lon2D,rla_lats.size*rla_lons.size)
    rla_lats_vect = np.reshape(lat2D,rla_lats.size*rla_lons.size)
    rla_depthobs = np.zeros((rla_lons_vect.size,1))

    return rla_lons_vect,rla_lats_vect, rla_depthobs

#------------------------------------------------------------------------------

def read_CL4_all_values(nc, run_name, cvar, filename) :

    """
Routine permettant de lire les contenus de fichiers CLASS4 (hindcast, fcst, obs, clim, persistence)
    """
    ll_miss = False
    try:
        rla_dset_init = nc.variables[run_name][:]
    except:
        print('Missing variable : {} file {}'.format(run_name, filename))
        rla_dset_init = np.nan
        ll_miss = True
    if type(rla_dset_init) != np.ndarray and not ll_miss:
        rla_dset_init = rla_dset_init.data
    if not ll_miss:
        try:
            missing_value =  nc.variables[run_name]._FillValue
            rla_dset_init[(rla_dset_init == missing_value)] = np.nan
        except:
            print ('Fillvalue missing var: {} filename: {}'.format(cvar,filename))
            raise


    if run_name == 'climatology':
        rla_dset_init[(rla_dset_init == 0.)] = np.nan
    if cvar in ['CHL','chl']:
        rla_dset_init[(rla_dset_init == 0.)] = np.nan
        rla_dset_init = np.log10(rla_dset_init)

    return rla_dset_init


#------------------------------------------------------------------------------

def char_period(cdate1,cdate2) :

    """
Returns a character-days list of the days contained in period given  \n
by the two input dates \n
output date format is YYYYMMDD \n\
warning : input date format should be YYYYMMDD
    """

    rdtdates = chardate2datetime([cdate1,cdate2])
    if rdtdates[0] == rdtdates[1] :
        return [cdate1]

    cda_dateout   = []
    rdt      = rdtdates[0]
    while rdt <= rdtdates[1] :
        cda_dateout.append(rdt.strftime('%Y%m%d'))
        rdt += dt.timedelta(1)

    return cda_dateout


#------------------------------------------------------------------------------

def datenow() :
    date_now = dt.datetime.now()
    if date_now.month == 1 :
        cl_start_date = str(date_now.year-1)+"1201"
        cl_end_date = str(date_now.year)+"0101"
    elif date_now.month < 10 :
        cl_start_date = str(date_now.year)+"0"+str(date_now.month-1)+"01"
        cl_end_date = str(date_now.year)+"0"+str(date_now.month)+"01"
    elif date_now.month == 10 :
        cl_start_date = str(date_now.year)+"0"+str(date_now.month-1)+"01"
        cl_end_date = str(date_now.year)+str(date_now.month)+"01"
    else :
        cl_start_date = str(date_now.year)+str(date_now.month-1)+"01"
        cl_end_date = str(date_now.year)+str(date_now.month)+"01"
    return cl_start_date, cl_end_date


#-----------------------------------------------------------------------------

def chardate2datetime(cdaylist):
        outime = []
        for cday in cdaylist :
                try :
                        dB = dt.datetime.strptime(cday,'%Y%m%d')
                except : pass
                try :
                        dB = dt.datetime.strptime(cday,'%d %m %Y')
                except : pass
                try :
                        dB = dt.datetime.strptime(cday,'%Y %m %d')
                except : pass

                try : outime.append(dB)
                except :
                        print('Unknown date format : %s' %cday)
                        sys.exit(1)
        return outime


#------------------------------------------------------------------------------

def find_indice(boite,zone) :

        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        ## Choix de la zone
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if   zone ==        'BALTIC':
                INDICE=np.where((boite >= 3110) & ( boite <= 3120))[0]
        elif zone ==        'NORDSEA':
                INDICE1=np.where((boite >= 3090 ) & ( boite <= 3100))[0]
                INDICE2=np.where(boite == 3190)[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'FACADE':
                INDICE1=np.where(boite == 3180)[0]
                INDICE2=np.where((boite >= 3200 ) & ( boite <= 3230))[0]
                INDICE3=np.where((boite >= 3330 ) & ( boite <= 3340))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3))
        elif zone ==         'ATL':
                INDICE=np.where((boite >= 2000 ) & ( boite < 4000))[0]
        elif zone ==         'NAT':
                INDICE1=np.where((boite >= 3000 ) & ( boite <= 3100))[0]
                INDICE2=np.where((boite >= 3120 ) & ( boite <= 3800))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'SAT':
                INDICE1=np.where((boite >= 2000 ) & ( boite <= 2050))[0]
                INDICE2=np.where((boite >= 2120 ) & ( boite <= 2360))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'MED':
                INDICE1=np.where((boite >= 1000 ) & ( boite <= 1180))[0]
                INDICE2=np.where((boite >= 1200 ) & ( boite <= 1220))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'IND':
                INDICE1=np.where((boite >= 6170 ) & ( boite <= 6770))[0]
                INDICE2=np.where((boite == 6000 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'NPA':
                INDICE=np.where((boite >= 5000 ) & ( boite < 6000))[0]
        elif zone ==         'SPA':
                INDICE=np.where((boite >= 4000 ) & ( boite <= 4720))[0]
        elif zone ==         'ACC':
                INDICE1=np.where((boite >= 4620 ) & ( boite <= 4900))[0]
                INDICE2=np.where((boite >= 2030 ) & ( boite <= 2110))[0]
                INDICE3=np.where((boite > 6000 ) & ( boite <= 6160))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3))
        elif zone ==         'ARC':
                INDICE1=np.where((boite >= 3000 ) & ( boite <= 3080))[0]
                INDICE2=np.where((boite >= 7000 ) & ( boite <= 7200))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'TAT':
                INDICE1=np.where((boite >= 2120 ) & ( boite <= 2310))[0]
                INDICE2=np.where((boite == 3460 ))[0]
                INDICE3=np.where((boite == 3480 ))[0]
                INDICE4=np.where((boite >= 3540 ) & ( boite <= 3790))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3,INDICE4))
        elif zone ==        'TAT_WEST':
                INDICE1=np.where((boite >= 2120 ) & ( boite <= 2130))[0]
                INDICE2=np.where(boite >= 2200)[0]
                INDICE3=np.where(boite >= 2210)[0]
                INDICE4=np.where((boite >= 2240 ) & ( boite <= 2250))[0]
                INDICE5=np.where((boite >= 2280 ) & ( boite <= 2290))[0]
                INDICE6=np.where(boite >= 3590)[0]
                INDICE7=np.where((boite >= 3610 ) & ( boite <= 3630))[0]
                INDICE8=np.where((boite >= 3660 ) & ( boite <= 3680))[0]
                INDICE9=np.where((boite >= 3710 ) & ( boite <= 3730))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3,\
                                        INDICE4,INDICE5,INDICE6,\
                                        INDICE7,INDICE8,INDICE9))
        elif zone ==        'TAT_EST':
                INDICE1=np.where((boite >= 2140 ) & ( boite <= 2190))[0]
                INDICE2=np.where(boite >= 2210)[0]
                INDICE3=np.where(boite >= 2230)[0]
                INDICE4=np.where((boite >= 2260 ) & ( boite <= 2270))[0]
                INDICE5=np.where((boite >= 2300 ) & ( boite <= 2310))[0]
                INDICE6=np.where(boite >= 3600)[0]
                INDICE7=np.where((boite >= 3640 ) & ( boite <= 3650))[0]
                INDICE8=np.where((boite >= 3690 ) & ( boite <= 3700))[0]
                INDICE9=np.where((boite >= 3740 ) & ( boite <= 3790))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3,\
                                        INDICE4,INDICE5,INDICE6,\
                                        INDICE7,INDICE8,INDICE9))
        elif zone ==       'MED_EST':
                INDICE1=np.where((boite >= 1080 ) & ( boite <= 1110))[0]
                INDICE2=np.where((boite >= 1130 )  ( boite <= 1500))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==       'MED_WEST':
                INDICE1=np.where((boite >= 1000 ) & ( boite <= 1070))[0]
                INDICE2=np.where(boite >= 1120)[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'TPA':
                INDICE1=np.where((boite >= 4000 ) & ( boite <= 4530))[0]
                INDICE2=np.where((boite >= 5440 ) & ( boite <= 5880))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'Golf_stream':
                INDICE=np.where((boite >= 3250 ) & ( boite <= 3280))[0]
        elif zone ==        'GLO':
                INDICE=np.where(boite >= 0)[0]
        elif zone ==        'ATL12':
                INDICE=np.where(boite >= 0)[0]
        elif zone ==        'IBIPL':
                INDICE1=np.where(( boite >= 1000 ) & ( boite <= 1040 ))[0]
                INDICE2=np.where(( boite >= 3050 ) & ( boite <= 3510 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'IBISR':
                INDICE1=np.where(( boite == 3090 ))[0]
                INDICE2=np.where(( boite >= 3200 ) & ( boite <= 3510 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'NORSE':
                INDICE=np.where((boite == 3100 ) | ( boite == 3190 ))[0]
        elif zone ==        'ECHAN':
                INDICE=np.where((boite == 3090 ) | ( boite == 3220 ))[0]
        elif zone ==        'IRISH':
                INDICE=np.where((boite == 3200 ) | ( boite == 3210 ))[0]
        elif zone ==        'ABYSS':
                INDICE1=np.where((boite == 3050 ) | ( boite == 3070 ))[0]
                INDICE2=np.where((boite == 3160 ) | ( boite == 3170 ))[0]
                INDICE3=np.where((boite == 3320 ) | ( boite == 3400 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3))
        elif zone ==        'GOBIS':
                INDICE=np.where((boite == 3330 ))[0]
        elif zone ==        'WSMED':
                INDICE=np.where(( boite >= 1000 ) & ( boite <= 1140 ))[0]
        elif zone ==        'ATLAN':
                INDICE=np.where(( boite >= 3050 ) & ( boite <= 3510 ))[0]
        elif zone ==        'ICANA':
                INDICE=np.where(( boite == 3510 ))[0]
        elif zone ==        'CADIZ':
                INDICE=np.where(( boite == 3410 ) | ( boite == 3420 ))[0]
        elif zone ==        'WIBSH':
                INDICE=np.where(( boite == 3340 ))[0]
        elif zone ==        'NORSH':
                INDICE1=np.where(( boite == 3090 ) | ( boite == 3100 ))[0]
                INDICE2=np.where(( boite >= 3180 ) & ( boite <= 3230 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'CHILI':
                INDICE=np.where((boite == 4610 ) | ( boite == 4680))[0]

        return INDICE


