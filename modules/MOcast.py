
import sys,os
import datetime

#----------------------------------------------------------------
def chardate2datetime(cdaylist):
    outime = []
    for cday in cdaylist :
        try :
                dB = datetime.datetime.strptime(cday,'%Y%m%d')
        except : pass
        try :
                dB = datetime.datetime.strptime(cday,'%d %m %Y')
        except : pass
        try :
                dB = datetime.datetime.strptime(cday,'%Y %m %d')
        except : pass
        try : outime.append(dB)
        except :
            print('Unknown date format : %s' %cday)
            sys.exit(1)
    return outime


#----------------------------------------------------------------
def datediff(cday1,cday2):
    """Calcule la diff day2-day1 de deux dates yyyymmdd """
    try :
        dB = datetime.datetime.strptime(cday1,'%Y%m%d')
        dF = datetime.datetime.strptime(cday2,'%Y%m%d')
    except : pass
    try :
        dB = datetime.datetime.strptime(cday1,'%d %m %Y')
        dF = datetime.datetime.strptime(cday2,'%d %m %Y')
    except : pass
    try :
        dB = datetime.datetime.strptime(cday1,'%Y %m %d')
        dF = datetime.datetime.strptime(cday2,'%Y %m %d')
    except : pass
    try : dB,dF
    except :
        print('Unknown date format')
        sys.exit(1)
    idelta = dF.toordinal() - dB.toordinal()
    return idelta

#----------------------------------------------------------------
def readMOformat(cl_fileIn) :

    try :
            dFile = cl_fileIn.split('_')[2]
            if len(dFile) != 8 :
                    print('Problem reading file format')
                    sys.exit(1)
            dRun = cl_fileIn.split('_')[5]
            if not dRun.startswith('R') :
                    print('Problem reading file format')
                    sys.exit(1)
            else :
                    dRun = dRun[1:9]
    except :
            print('Problem reading file format')
            sys.exit(1)
    return dFile, dRun

#----------------------------------------------------------------
def isCast(cl_fileIn,cast='Hindcast') :
    """ 
    Returns true if input file matches specified cast (default hindcast), else false. 
    cast possibilities (capital letters may be used) :
        - Hindcast or hind
        - Nowcast or now
        - Forecast or fore
        - Forecast1 or fore1
        - Forecast2 or fore2

    nb : file should have MO format (E.g PSY3V3R1_1dAV_20130130_20130131_gridU_R20130229.nc)

    author : LZawadzki
    """

    cast = cast.lower().strip()
    dFile,dRun = readMOformat(cl_fileIn)

    idiff = datediff(dFile,dRun)
    if cast in ['hindcast','hind'] :
        if idiff in range(8,15) : return True
        else : return False
    elif cast in ['nowcast','now'] :
        if idiff in range(1,8) : return True
        else : return False
    elif cast in ['forecast','fore'] :
        if idiff in range(-13,1) : return True
        else : return False
    elif cast in ['forecast1','fore1'] :
        if idiff in range(-6,1) : return True
        else : return False
    elif cast in ['forecast2','fore2'] :
        if idiff in range(-13,-6) : return True
        else : return False
    else :
        print('unknown cast option')
        sys.exit(1)

#----------------------------------------------------------------
