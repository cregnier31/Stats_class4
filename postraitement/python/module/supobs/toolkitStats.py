# coding: utf8
import os,sys
import netCDF4
import numpy as np
import datetime as dt
sys.path.append('/home/cregnier/DEV/TEP_CLASS4_GODAE/postraitement/CL4_GODAE_LIB/TOOLS_py')
import arithm

#------------------------------------------------------------------------------------------------------------------------------------------
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

        nc   = netCDF4.Dataset(cl_fileIn,'r')
	cla_varname_read = nc.variables['varname'][:]
        rla_lons  = nc.variables['longitude'][:]
        rla_lats  = nc.variables['latitude'][:]
        rla_depth = nc.variables['depth'][:]
        if np.shape(rla_depth)[1] > 1:
            rla_depth = rla_depth.data
        nc.close()

#if type(rla_observation_init) != np.ndarray:
#                rla_observation_init = rla_observation_init.data

        rla_lons  = np.ma.filled(np.ma.masked_array(rla_lons,(rla_lons >= 99999.)),fill_value=np.nan)
        rla_lats  = np.ma.filled(np.ma.masked_array(rla_lats,(rla_lats >= 99999.)),fill_value=np.nan)
        rla_depth = np.ma.filled(np.ma.masked_array(rla_depth,(rla_depth >= 99999.)),fill_value=np.nan)
   
        cla_varname = []
        for cvarn in cla_varname_read : cla_varname.append(''.join(cvarn))

        return cla_varname,rla_lons,rla_lats,rla_depth


#------------------------------------------------------------------------------------------------------------------------------------------
def read_CL4obs_chloro(cl_fileIn) :

        """
Routine permettant de lire les contenus de fichiers CLASS4 au format GLOBCOLOUR.
	"""

	nc = netCDF4.Dataset(cl_fileIn,'r')
        rla_lons  = nc.variables['lon'][:]
        rla_lats  = nc.variables['lat'][:]
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

#------------------------------------------------------------------------------------------------------------------------------------------

def char_period(cdate1,cdate2) :
	"""
Returns a character-days list of the days contained in period given by the two input dates \n\
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
		


#----------------------------------------------------------------
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
                        print 'Unknown date format : %s' %cday
                        sys.exit(1)
        return outime
	

#------------------------------------------------------------------------------------------------------------------------------------------

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
              ## Atlantique 2000 a 4000
                INDICE=np.where((boite >= 2000 ) & ( boite < 4000))[0]
        elif zone ==         'NAT': 
              ## Atlantique NORD 3000 a 4000
                INDICE1=np.where((boite >= 3000 ) & ( boite <= 3100))[0]
                INDICE2=np.where((boite >= 3120 ) & ( boite <= 3800))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'SAT': 
               ## Atlantique SUD 2000 a 3000 jusqu a 55S
                INDICE1=np.where((boite >= 2000 ) & ( boite <= 2050))[0]
                INDICE2=np.where((boite >= 2120 ) & ( boite <= 2360))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'MED': 
             ## MED 1000 a 1220
                INDICE1=np.where((boite >= 1000 ) & ( boite <= 1180))[0]
                INDICE2=np.where((boite >= 1200 ) & ( boite <= 1220))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'IND': 
              ## Indien de 6000 a 6770
                INDICE=np.where((boite >= 6190 ) & ( boite <= 6770))[0]
        elif zone ==         'NPA': 
              ## Pacifique nord 5000 a 6000
                INDICE=np.where((boite >= 5000 ) & ( boite < 6000))[0]
        elif zone ==         'SPA': 
              ## Pacifique sud et trop de 4000  a 4730
                INDICE=np.where((boite >= 4000 ) & ( boite <= 4720))[0]
        elif zone ==         'ACC':  
              ## 'ACC antartique 4770-4800'
                #INDICE1=np.where((boite >= 4610 ) & ( boite <= 4900))[0] ## Pacifique
                INDICE1=np.where((boite >= 4620 ) & ( boite <= 4900))[0] ## Pacifique
                #INDICE2=np.where((boite >= 2050 ) & ( boite <= 2110))[0] ## Atlantique
                INDICE2=np.where((boite >= 2030 ) & ( boite <= 2110))[0] ## Atlantique
                #INDICE3=np.where((boite >= 6000 ) & ( boite <= 6070))[0] ## Indien
                INDICE3=np.where((boite >= 6000 ) & ( boite <= 6100))[0] ## Indien
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3))
        elif zone ==         'ARC':  
              ## 'ARC arctique 7000-7200 '
                #INDICE1=np.where((boite >= 3000 ) & ( boite <= 3200))[0]
                INDICE1=np.where((boite >= 3000 ) & ( boite <= 3080))[0]
                INDICE2=np.where((boite >= 7000 ) & ( boite <= 7200))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==         'TAT':  
              # TAT  20N-20S
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
              ## TPA 4000-4530 # 5260-5880 # 30N-30S
                INDICE1=np.where((boite >= 4000 ) & ( boite <= 4530))[0]
                INDICE2=np.where((boite >= 5440 ) & ( boite <= 5880))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'Golf_stream': 
              ## golf stream
                INDICE=np.where((boite >= 3250 ) & ( boite <= 3280))[0]
        elif zone ==        'GLO': 
              ## GLOBAL
                INDICE=np.where(boite >= 0)[0]
        elif zone ==        'ATL12': 
              ## GLOBAL ATL12
                INDICE=np.where(boite >= 0)[0]
	elif zone ==        'IBIPL':
              ## IBIPL Atlantique NORD Est 3000 a 4000 et Med Occid
                INDICE1=np.where(( boite >= 1000 ) & ( boite <= 1040 ))[0]
                INDICE2=np.where(( boite >= 3050 ) & ( boite <= 3510 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'IBISR':
              ## IBISR zone delivree MyOcean
                INDICE1=np.where(( boite == 3090 ))[0]
                INDICE2=np.where(( boite >= 3200 ) & ( boite <= 3510 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
        elif zone ==        'NORSE':
              ## NORSE  North Sea
                INDICE=np.where((boite == 3100 ) | ( boite == 3190 ))[0]
        elif zone ==        'ECHAN':
              ## ECHAN  Channel
                INDICE=np.where((boite == 3090 ) | ( boite == 3220 ))[0]
        elif zone ==        'IRISH':
              ## IRISH irish Sea
                INDICE=np.where((boite == 3200 ) | ( boite == 3210 ))[0]
        elif zone ==        'ABYSS':
              ## ABYSS plaine abyssale
                INDICE1=np.where((boite == 3050 ) | ( boite == 3070 ))[0]
                INDICE2=np.where((boite == 3160 ) | ( boite == 3170 ))[0]
                INDICE3=np.where((boite == 3320 ) | ( boite == 3400 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2,INDICE3))

	elif zone ==        'GOBIS':
              ## GOBIS Bay of Biscay
                INDICE=np.where((boite == 3330 ))[0]
        elif zone ==        'WSMED':
              ## WSMED med Sea
                INDICE=np.where(( boite >= 1000 ) & ( boite <= 1140 ))[0]
        elif zone ==        'ATLAN':
              ## WSMED med Sea
                INDICE=np.where(( boite >= 3050 ) & ( boite <= 3510 ))[0]
        elif zone ==        'ICANA':
              ## ICANA Canary Islands
                INDICE=np.where(( boite == 3510 ))[0]
        elif zone ==        'CADIZ':
              ## CADIZ gulf of Cadiz
                INDICE=np.where(( boite == 3410 ) | ( boite == 3420 ))[0]
        elif zone ==        'WIBSH':
              ## WIBSH western Iberia shelf
                INDICE=np.where(( boite == 3340 ))[0]
        elif zone ==        'NORSH':
              ## NORSH north shelf
                INDICE1=np.where(( boite == 3090 ) | ( boite == 3100 ))[0]
                INDICE2=np.where(( boite >= 3180 ) & ( boite <= 3230 ))[0]
                INDICE=np.concatenate((INDICE1,INDICE2))
	elif zone ==        'CHILI':
                INDICE=np.where((boite == 4610 ) | ( boite == 4680))[0]
        
        return INDICE


