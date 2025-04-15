# Module with utilities
import numpy as np
import sys
import pandas as pd
import datetime as dt
import os, sys
import getopt
import shlex,subprocess
from datetime import datetime
import traceback
import logging
from loader_post import load_db
from datetime import datetime, timedelta
import yaml
from dateutil.relativedelta import relativedelta

__version__ = 0.2
__date__ = "Octobre 2021"
__author__ = "C.REGNIER"



def mkdir(path):
    '''
        Create a directory, and parents if needed
    '''
    if not os.path.exists(path):
        os.makedirs(path)

def yaml_loader(path):
    try:
        with open(path, 'r') as file:
            patterns = yaml.safe_load(file)
        return patterns
    except Exception as e:
        raise(f"Failed to load patterns from {path}: {e}")
        sys.exit(1)

def loader(options):
    '''
                Input parameters settings
    '''

    tab_options ={}
    list_typemod = ['BIO','PHYS']
    tab_options['typemod'] = list_typemod
    list_config = ['FOAM', 'GIOPS', 'CMCC', 'CGOFS', 'BLK', 'PSY3V3R3',
                   'HYCOM_RTOFS', 'PSY4V2R2', 'PSY4V3R1', 'BIOMER4',
                   'FREEBIORYS2', 'NERSC', 'BIOMER4V2','ENSMEAN', 'GLO12',
                   'GLO12V4', 'GLO4', 'FOAM12']
    tab_options['config'] = list_config
    list_mask = ['basin','basin_pol','box','bins2d','bins2d_arc','bins2d_ant','bins4d']
    tab_options['fmt_mask'] = list_mask
    list_bilan, list_ascii, list_dailyoff, list_percent =  (['on','off'], ) * 4
    tab_options['bilan'], tab_options['fmt_ascii'], tab_options['daily_off'], tab_options['percent'] =  (['on','off'], ) * 4
    tab_options['day1'] = []
    tab_options['day2'] = []
    list_nblevel = ['50','75']
    tab_options['nb_levels'] = list_nblevel
    tab_conf ={}
    list_options = ['config','day1','day2','typemod','fmt_mask','bilan','fmt_ascii','daily_off','percent','nb_levels']
    ## Initialize dictionnary with None values
    tab_conf = dict.fromkeys(list_options)
    tab_conf['debug'] = False
    try:
        # the keyword
        cla_opts = getopt.getopt(options,['empid='])
        if len(cla_opts[1]) < 4 or len(cla_opts[1]) > 10:
            usage(len(cla_opts[1]))
            sys.exit()
        for ind,var in enumerate(range(len(cla_opts[1]))):
            if cla_opts[1][ind] == '-l':
                tab_conf['debug'] = True
            else:
                tab_conf[list_options[ind]] = cla_opts[1][ind]
                generic_test(tab_options[list_options[ind]],cla_opts[1][ind],list_options[ind])
        test_days(tab_conf['day1'], tab_conf['day2'])
        if len(cla_opts[1]) == 4:
            usage1()
        if len(cla_opts[1]) == 5:
            usage2()
        if len(cla_opts[1]) == 6:
            usage3()
        if len(cla_opts[1]) == 7:
            usage4()
        if len(cla_opts[1]) == 8:
            usage5()
        if len(cla_opts[1]) == 9:
            usage6()
        if len(cla_opts[1]) == 10:
            usage7()

    except getopt.GetoptError as err:
        raise (f'Error {err} Missing options {keywords}')

    tab_conf['pbsworkdir'] = os.path.dirname(os.path.realpath(__file__))
    tab_conf['sub'] = tab_conf['pbsworkdir'] + '/../sub/'
    _DBFILE_ = tab_conf['pbsworkdir'] + "/../postraitement/python/compute_stats/cfg/global_params.cfg"
    db = load_db(_DBFILE_)
    tab_conf['dir_bin'] = db.get('PARAMS', 'py_env') + 'bin/'

    mkdir(tab_conf['sub'])

    return tab_conf

def generic_test(list_var,var,type_param):
    """
       Generic test for values
    """
    #print (f"{type_param=}")
    if type_param == 'day1' or type_param == 'day2':
        if not var: sys.exit(f'{type_param} is missing need {list_var}')
        isValiDate(var, type_param)
    else:
        if not var or var not in list_var: sys.exit(f'{type_param} is missing need {list_var}')


def convdatetime(var):
    """
       Convert date YYYYMMDD in a datetime value
    """
    try:
        year = var[0:4]
        month = var[4:6]
        day = var[6:8]
        datetime_val = datetime(int(year), int(month), int(day))
    except Exception as e:
        raise ValueError(f"Var {var} not a valid date for datetime , error {traceback.format_exc()}")
    return datetime_val

def test_days(day1, day2):
    """
        Test if a date2 > date 1
    """
    if convdatetime(day2) < convdatetime(day1): sys.exit(f"{day2} must be > at {day1}")

def isValiDate(var, type_param):
    """
        Test if a date is valid or not
    """
    isValiDate = True
    try:
        datevalue = convdatetime(var)
    except ValueError:
        isValiDate = False
        sys.exit(f"Value {var} for {type_param} not a valid date")

    return isValiDate

def generate_date_list(start, end):
    # Convert strings to datetime objects
    start_date = datetime.strptime(start, "%Y%m%d")
    end_date = datetime.strptime(end, "%Y%m%d")
    # Generate list of dates between start_date and end_date
    date_list = [(start_date + timedelta(days=x)).strftime("%Y%m%d") for x in range((end_date - start_date).days + 1)]
    return date_list


def create_launcher_multi(tab_conf, nbtasks='30', timecounter='06:00:00', batch='#SBATCH', nb_procs='2'):
    ## Create qsub job
    if tab_conf['fmt_mask'] == 'basin':
        typejob = 'timeserie'
    elif tab_conf['bilan'] != None:
        typejob = 'bilan'
    else:
        typejob = 'others'
    _DBFILE_ = tab_conf['pbsworkdir'] + "/../postraitement/python/compute_stats/cfg/environment_"+tab_conf['config']+".cfg"
    EXE = os.path.join(tab_conf['pbsworkdir'],'../postraitement/python/compute_stats/exe_compute_stats_CMEMS_areas_multiprocess_2.py')
    dir_bin  = tab_conf['dir_bin']
    day1  = tab_conf['day1']
    day2  = tab_conf['day2']
    datatype = tab_conf['typemod']
    fmt_mask = tab_conf['fmt_mask']
    bilan = tab_conf['bilan']
    fmt_ascii = tab_conf['fmt_ascii']
    daily_off = tab_conf['daily_off']
    percent = tab_conf['percent']
    nblevel = tab_conf['nb_levels']
    debug = tab_conf['debug']
    nb_process = int(nb_procs)*int(nbtasks)

    Jobfile = tab_conf['sub'] + 'Class4_post_' + typejob + '_'+ tab_conf['config'] + '_' +\
              tab_conf['day1'] + '_' + tab_conf['day2'] + '.sub'
    obFichier = open(Jobfile,'w+')
    obFichier.write('#!/usr/bin/env python'+'\n')
    obFichier.write(batch + ' -J '+'Class4_post_' + typejob + '_' + tab_conf['day1'] + '_' + tab_conf['day2'] + '\n')
    obFichier.write(batch + ' -e CLASS4_postjob_' + tab_conf['config'] + '_' +\
            tab_conf['day1'] + '_' + tab_conf['day2']+'_%j.e'+'\n')
    obFichier.write(batch + ' -o CLASS4_postjob_' + tab_conf['config'] + '_' +\
            tab_conf['day1'] + '_' + tab_conf['day2']+'_%j.o'+'\n')
    obFichier.write(batch + ' -p multi'+'\n')
    obFichier.write(batch + ' -N ' + nb_procs+'\n')
    obFichier.write(batch + ' -q qosmulti'+'\n')
    obFichier.write(batch + ' --exclusive'+'\n')
    obFichier.write(batch + ' --ntasks-per-node='+ nbtasks +'\n')
    obFichier.write(batch + ' --time='+ timecounter +'\n')
    obFichier.write('HDF5_USE_FILE_LOCKING = False'+'\n')
    obFichier.write('import os'+'\n')
    codexe = tab_conf['dir_bin']+"mpirun -np "+str(nb_process)+" "+tab_conf['dir_bin']+f"python {EXE} --day1={day1} --day2={day2} --cfg={_DBFILE_} --type={datatype} --fmt_mask={fmt_mask} --bilan={bilan} --fmt_ascii={fmt_ascii} --daily_off={daily_off} --percent={percent} --nblevel={nblevel} --debug={debug}"
    obFichier.write('codexe =' + "'" + codexe +"'"+'\n')
    obFichier.write('os.system(codexe)'+'\n')
    obFichier.close()

    return Jobfile


def launch_sbatch(Jobfile):

    SUBEXE="/usr/bin/sbatch"
    code_launch=f'{SUBEXE} {Jobfile}'
    args   = shlex.split(code_launch)
    #print(args)
    try :   subprocess.run(args)
    except :
        print (f'Launch {Jobfile} failed')
        sys.exit(1)

def usage1():
    print(" *************************** DEFAULT CASE **************************")
    print(" ")
    print("     Save stats computed at the daily time step over CMEMS areas    ")
    print("                     on netCDF format file                          ")
    print(" ")
    print(" ****************************************************************** ")

def usage2():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/basin_pol/box/bins2d/bins4d            ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage3():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( " ------------------------------------------------------------------------------")
    print( " " )

def usage4():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage5():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( "                                     &                                         ")
    print( "     -->   Activate/Deactivate save of stats at the daily time step  <--       ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage6():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( "                                     &                                         ")
    print( "     -->   Activate/Deactivate save of stats at the daily time step  <--       ")
    print( "                                     &                                         ")
    print( "     -->   Activate bias and percentile computation for temperature  <--       ")
    print( "                             and salinity                                      ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage7():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( "                                     &                                         ")
    print( "     -->   Activate/Deactivate save of stats at the daily time step  <--       ")
    print( "                                     &                                         ")
    print( "     -->   Activate bias and percentile computation for temperature  <--       ")
    print( "                             and salinity                                      ")
    print( "                                     &                                         ")
    print( "     -->   Change the number of considered levels to compute profile  <--      ")
    print( "                             T and S statistics                                ")
    print( " ------------------------------------------------------------------------------")
    print( " ")


def usage(nb_args):
    print ("              Incorrect number of Arguments"                 )
    print (f"   nb of arguments {nb_args}                           <-- ")
    print ("    arguments required                                  <-- ")
    print ("    Value1 = Config                                         ")
    print ("    Value2 = Day min                                        ")
    print ("    Value3 = Day max                                        ")
    print ("    Value4 = Type of data: BIO/PHYS"                         )
    print ("                                                            ")
    print (" -->              Optional argument                     <-- ")
    print ("    Value5 = Type of mask: basin/box/bins2d/bins4d          ")
    print ("    Value6 = Save global stats: on/off                      ")
    print ("    Value7 = Save stats on ASCII fmt files: on/off          ")
    print ("    Value8 = Save daily time step stats: on/off             ")
    print ("    Value9 = Compute misfit and percentile (profile): on/off")
    print ("    Value10 = Number of considered level profile            ")

def pull_names(name_data):
    """
        Convenient name retrieval function
    """
    names = []
    if isinstance(name_data, np.ma.masked_array):
        for letters in name_data:
            value = b''.join(letters.data).strip().decode("utf-8")
            #names.append(str(b''.join(letters.data)).strip())
            names.append(value)
    else:
        for letters in name_data:
            value = b''.join(letters).strip().decode("utf-8")
            names.append(value)
            #names.append(str(b''.join(letters)).strip())
    return names

def echeance(fcst, nf):
    """
       Find lead time
    """
    num_ech = np.where(fcst == nf)[0][0]
    if nf == 0:
        name_ech = 'Hindcast'
    else:
        name_ech = 'Forecast '+str(nf)+' hours'
    return num_ech, name_ech


def plot(iobs, rla_lonobs, rla_latobs, region, log):
    """
        Function to plot selected data
    """
    log.info("Plot region %s " %(region))
    area_names_arc = ['North Pole', 'Queen Elis Is', 'Beaufort Sea', 'Chuckchi Sea',
                      'Siberian Sea', 'Laptev Sea', 'Kara Sea', 'Barents Sea', 'Greenland Sea', 'Stheast Greenland', 'Bafin Bay',
                                                          'Hudson Bay', 'Labrador Sea', 'Bering Sea', 'Okhotsk Sea', ' Baltic Sea']
    area_names_ant = ['Weddel Sea', 'Southern Atlantic Ocean', 'Southern Indian Ocean', 'Southern West Pacific Ocean',
                      'Southern East Pacific Ocean', 'Ross Sea', 'Admundsen Sea', 'Bellingshausen Sea']

    rla_lonobs =  np.where(rla_lonobs>180,rla_lonobs-360,rla_lonobs)
    value = rla_lonobs[:].copy()
    value[:] = 1.0
    lon_inter = 20
    lat_inter = 20
    zone = "GLO"
    proj = "cyl_pac"
    if region in area_names_arc:
        proj = "npstere"
        zone = "Arctic2"
    if region in area_names_ant:
        zone = "Antarctic"
        proj = "spstere"
    #colormap = plt.cm.coolwarm
    #titre = 'Points in '+region+" with matplotlib meth"
    #outputfile = "Selected_points_"+region+".png"
    #colormap = plt.cm.coolwarm
    #cmin = 0
    #cmax = 1
    #dpi = 75
    #font = 16
    #dot_size = 2.0
    #log.info("Plot Map")
    #Plot_map(rla_lonobs[iobs].tolist(), rla_latobs[iobs].tolist(), zone, lon_inter, lat_inter, proj,\
    #        dpi, font).scatter_val(value[iobs].tolist(), colormap, cmin, cmax, dot_size, titre, outputfile)

def compute_last_day_month(y,m):
    return (dt.date(y+int(m/12),m%12+1,1)-dt.date(y,m,1)).days

def find_index_month(date):
    dateval = pd.to_datetime(date)
    index = dateval.month
    return index

def create_dict(date1, date2, lead_time, lead_int):
    list_keys = {}
    valeurj = date1
    list_keys_values = []
    list_uniq = ['best_estimate', 'climatology', 'bathymetrie']
    while valeurj >= date1  and valeurj <= date2:
        dateval = str(valeurj)
        for lead in lead_time:
            if lead in list_uniq:
                list_int = [0]
            else:
                list_int = lead_int
            for int_val in list_int:
                keyvalue = f'{dateval}-{lead}-{int_val}'
                list_keys_values.append(keyvalue)
        valeurj = valeurj.goforward(1)
    list_keys['keyvalues'] = list_keys_values
    return list_keys


from datetime import datetime, timedelta

def split_year_into_months(year):
    months = []
    for month in range(1, 13):
        first_day = datetime(year, month, 1)
        if month == 12:
            last_day = datetime(year + 1, 1, 1) - timedelta(days=1)
        else:
            last_day = datetime(year, month + 1, 1) - timedelta(days=1)
        months.append((first_day.strftime('%Y%m%d'), last_day.strftime('%Y%m%d')))
    return months

def date_range(start_date, end_date, increment, period):
    result = []
    nxt = start_date
    delta = relativedelta(**{period:increment})
    while nxt <= end_date:
        result.append(nxt)
        nxt += delta
    return result
