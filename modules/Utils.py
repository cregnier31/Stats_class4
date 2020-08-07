import numpy as np
import netCDF4
import sys
from sydate import SyDate
from dateutil.relativedelta import relativedelta

def lon_lat_to_cartesian(lon, lat, R = 1):
    """
     calculates lon, lat coordinates of a point on a sphere with
     radius R
    """
    lon_r = np.radians(lon)
    lat_r = np.radians(lat)
    x =  R * np.cos(lat_r) * np.cos(lon_r)
    y = R * np.cos(lat_r) * np.sin(lon_r)
    z = R * np.sin(lat_r)
    return x,y,z

def get_date_from_PGN(fileName):

    nc_file=netCDF4.Dataset(str(fileName),'r')
    try : 
        time_origin=nc_file.variables['time_counter'].getncattr('time_origin')
    except: 
        print ("not time origin")
        ## READ units and find date origin
        time_origin=nc_file.variables['time_counter'].getncattr('units').split('since')[1][1::]
    dateorigin=convertodate(time_origin)
    print (dateorigin)
    time_counter=nc_file.variables['time_counter'][:]
    print (time_counter)
    print (len(time_counter))
    list_date=[]
    for time in time_counter:
        datej=time/86400
        date_str=SyDate.fromjulian(int(datej),dateorigin)
        list_date.append(str(date_str))
    nc_file.close()
    return list_date

def date_range(start_date, end_date, increment, period):
    result = []
    nxt = start_date
    delta = relativedelta(**{period:increment})
    while nxt <= end_date:
        result.append(nxt)
        nxt += delta
    return result

def get_julian_date_from_PGN_hrly(fileName):

    nc_file=netCDF4.Dataset(str(fileName),'r')
    try : 
        time_origin=nc_file.variables['time_counter'].getncattr('time_origin')
    except: 
        print ("not time origin")
        ## READ units and find date origin
        time_origin=nc_file.variables['time_counter'].getncattr('units').split('since')[1][1::]
        schedule=nc_file.variables['time_counter'].getncattr('units').split('since')[0]
        print (time_origin)
        print (schedule)
    dateorigin=convertodate(time_origin)
    print (dateorigin)
    time_counter=nc_file.variables['time_counter'][:]
    print (time_counter)
    print (len(time_counter))
    list_date=[]
    if schedule.strip() == "hours" :
        pas=24.0
    elif schedule.strip() == "seconds" :
        pas=86400.0
    else :
        print ("Schedule not known")
        sys.exit(1)

    for time in time_counter:
        datej=time/pas
        date_str=SyDatenew.fromjulian(int(datej),dateorigin)
        datej_end=SyDate(str(date_str)).tojulian()+datej
        list_date.append(float(datej_end))
    nc_file.close()
    return list_date

def convertodate(dateval):
    year=dateval.split('-')[0]
    month=dateval.split('-')[1]
    day=dateval.split('-')[2].split(' ')[0]
    if len(day) < 2 :
        day='0'+day 
    if month == 'JAN' or month =='1' :
        month='01'
    elif month == 'FEB' or month =='2' :
        month='02'
    elif month == 'MAR' or month =='3' :
        month='03'
    elif month == 'APR' or month =='4' :
        month='04'
    elif month == 'MAY' or month =='5' :
        month='05'
    elif month == 'JUN' or month =='6' :
        month='06'
    elif month == 'JUL' or month =='7' :
        month='07'
    elif month == 'AUG' or month =='8' :
        month='08'
    elif month == 'SEP' or month =='9' :
        month='09'
    elif month == 'OCT' or month =='10' :
        month='10'
    elif month == 'NOV' or month =='11' :
        month='11'
    elif month == 'DEC' or month =='12' :
        month='12'
    return year+month+day


def returnmonth(month):

    month = month.upper()
    if month == 'JAN' or month =='1' :
        month='01'
    elif month == 'FEB' or month =='2' :
        month='02'
    elif month == 'MAR' or month =='3' :
        month='03'
    elif month == 'APR' or month =='4' :
        month='04'
    elif month == 'MAY' or month =='5' :
        month='05'
    elif month == 'JUN' or month =='6' :
        month='06'
    elif month == 'JUL' or month =='7' :
        month='07'
    elif month == 'AUG' or month =='8' :
        month='08'
    elif month == 'SEP' or month =='9' :
        month='09'
    elif month == 'OCT' or month =='10' :
        month='10'
    elif month == 'NOV' or month =='11' :
        month='11'
    elif month == 'DEC' or month =='12' :
        month='12'
    return month


