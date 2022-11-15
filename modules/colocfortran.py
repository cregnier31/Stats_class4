## Class to create coloc files in fortran using oper code
## C.REGNIER Feb 2021
import os, sys, re
import shutil
from multiprocessing import Pool
from math import ceil
from glob import glob
from timeit import default_timer as timer
from sytoolkit.sydate import SyDate
import time
import subprocess,shlex
## local modules
from Writer import Writer
from NmlCreator import NmlCreator

class ColocFortran(object):
    """
        Class to create positions files and dat files with interpolated positions
        for a given model
    """
    def __init__(self, params,log):
        self.params = params
        self.direxec = params['direxec']
        self.config = params['cl_config']
        self.coords = params['coordinates']
        self.maskname = params['maskname']
        self.log = log
        ## Create coloc dir
        if not os.path.exists(self.params['coloc_rep']):
            try:
                os.makedirs(self.params['coloc_rep'])
            except OSError as exc:
                if exc.errno == errno.EEXIST and os.path.isdir(self.params['coloc_rep']):
                    pass

    def timeit(method):
        """
            Function to time the execution of a function
        """
        def timed(*args, **kw):
            ts = time.time()
            result = method(*args, **kw)
            te = time.time()
            if 'log_time' in kw:
                name = kw.get('log_name', method.__name__.upper())
                kw['log_time'][name] = int((te - ts) * 1000)
            else:
                print ('%r  %2.2f s' % \
                         (method.__name__, (te - ts)))
            return result

        return timed

    def run_coloc(self,args):
        """
          =============================================================================
           PART-4 - Colocations of positions with fortran
          =============================================================================
        """
        file_pos = args[0]
        code_lancement=self.direxec+'CLASS4_create_colocfile_ASCII_'+self.config+'.exe'+' '+'-g'+' '+self.coords+' '+\
                '-r'+' '+file_pos+' ' \
                +'-c'+' '+self.config+' '+'-m'+' '+self.maskname
        self.log.debug(code_lancement)
        exe = self.direxec+'CLASS4_create_colocfile_ASCII_'+self.config+'.exe'
        codexe = '%s -g %s -r %s -c %s -m %s' %(exe,self.coords,file_pos,self.config,self.maskname)
        args   = shlex.split(codexe)
        try :   subprocess.check_call(args)
        except subprocess.CalledProcessError as e:
            self.log.error('executable {} {} failed'.format(exe,e))
            raise

    @timeit
    def split_coloc(self, file, position):
            """
               Split the position files by procs to speedup the colocation with multiprocessing tool
            """
            ll_coloc=False
            # Write ASCII pos for Coloc
            file_pos_tmp=os.path.basename(file)
            file_pos_tmp=re.sub('.nc','.pos',file_pos_tmp)
            file_pos=self.params['coloc_rep']+file_pos_tmp
            outputBase = file_pos.split('.pos')[0]
            fileout=outputBase+'.dat'
            if os.path.isfile(fileout) :
                ll_coloc=True
                self.log.debug("coloc existe {}".format(fileout))
            if not ll_coloc :
                self.log.debug("coloc don't exist")
                Writer(self.log).write_ASCII(file_pos,position)
                #  splitLen = 1000000       # 500000 lines per file
                file_in=file_pos
                outputBase=re.sub("coloc","coloc/split",outputBase)
                ## Create output dir
                if not os.path.exists(outputBase):
                    try:
                        os.makedirs(outputBase)
                        self.log.debug('Création réussie du répertoire  {}'.format(outputBase))
                    except OSError as exc:
                        if exc.errno == errno.EEXIST and os.path.isdir(outputBase):
                            pass
                        else:
                            raise
                outputBase_orig = file_pos.split('.pos')[0]
                input=open(file_in,'r').read().split('\n')
                nb_pts=len(input)
                if nb_pts <=  self.params['nb_proc'] : 
                    nb_process=len(input)
                    splitLen=1
                else :
                    nb_process = self.params['nb_proc']
                    splitLen=int(ceil(nb_pts/nb_process))+1
                cpt=1
                self.log.debug("longueur {}".format(splitLen))
                for lines in range(0,len(input),splitLen):
                    # First, get the list slice
                    outputData = input[lines:lines+splitLen]
                    # Now open the output file, join the new slice with newlines
                    # and write it out. Then close the file.
                    output = open(outputBase +'_split'+ str(cpt) + '.pos', 'w')
                    self.log.debug("Output {} ok".format(output))
                    output.write('\n'.join(outputData))
                    output.close()
                    #self.log.info("lines cpt %i %i "%(lines,cpt))
                    cpt += 1
                #===========================================================================================
                # Colocation in multiprocessing
                #===========================================================================================
                self.log.debug("Multiprocessing ")
                self.log.debug("List file {} ".format(outputBase))
                list_files=glob(outputBase+"*split*.pos")
                self.log.info(list_files)
                mp_pool = Pool(nb_process)
                mp_pool.map(self.run_coloc, [ [x] for x in list_files ])
                ## Recombinaisons of .dat
                self.log.info("Coloc ok start recombination")
                ind=1
                ind_tot=1
                fileout=outputBase_orig+'.dat'
                self.log.debug("file out {} ".format(fileout))
                with open(fileout, 'w') as outFile:
                    for i in range(1,nb_process+1):
                        filename=outputBase +'_split'+ str(ind) + '.dat'
                        if os.path.isfile(filename) :
                           input=open(filename,'r').read()
                           outFile.write(input)
                        ind=ind+1
                self.log.info("Recombination OK")
                # Cleanup
                for filename in glob(outputBase+"*split*"): 
                    os.remove(filename)

            if self.params['write_geojson']  :
               # Store input position and coloc position to plot the results in a GIS like qGis 
               # Input
               ## Store only ext files for extract area
               type_f=os.path.basename(file).split('_')[2]
               length=position.size
               if length > 1 :
                  self.log.info("Store geojson positions %s " %(type_f))
                  selector.store_pos(position,type_f,file_db)
               else :
                  self.log.error("No position to store %s " %(type_f))
               # Coloc
               file_coloc=os.path.basename(file).split('.')[0]+'.dat'
               coloc_pos=Loader.factory('DAT').read_pos(self.params['coloc_rep']+file_coloc)
               length=coloc_pos.size
               if length > 1 :
                 self.log.info("Store geojson positions db2 %i " %(length))


    def interp_fortran(self):
        """
           Interpolate 3D profiles with fortran code
        """
        ## Create output dir and log dirs
        if not os.path.exists(self.params['nml_dir']):
            try:
                os.makedirs(self.params['nml_dir'])
            except OSError as exc:
                if exc.errno == errno.EEXIST and os.path.isdir(self.params['nml_dir']):
                    pass
        if not os.path.exists(self.params['dir_log']):
            try:
                os.makedirs(self.params['dir_log'])
            except OSError as exc:
                if exc.errno == errno.EEXIST and os.path.isdir(self.params['dir_log']):
                    pass

        self.log.debug('Namelist dir {}'.format(self.params['nml_dir']))
        ll_mssh=None
        if self.params['data_type']  == "SLA":
            ll_mssh='.true.'
            if self.params['comp_mssh'] == 1:
                ll_compute='.true.'
            else :
                ll_compute='.false.'
        else:
            ll_mssh='.false.'
            ll_compute='.false.'

        valeurj = self.params['date1']
        self.log.info('Data origin {} '.format(self.params['data_origin']))
        while valeurj >= self.params['date1']and valeurj <= self.params['date2'] :
            self.log.info('Interp day  {} '.format(SyDate(str(valeurj))))
            dateval=str(SyDate(str(valeurj)))
            nml=os.path.join(self.params['nml_dir'],'interpolate_3D_%s_%s_%s.nml' %(self.params['data_type'].upper(),\
                    self.params['cl_config'],dateval))
            valeurj=valeurj.goforward(1)
            for time in self.params['lead_time'] :
                self.log.info('Lead Time {}'.format(time))
                lead_fin = []
                lead_new=self.params['lead_int']
                if self.params['cl_typemod'].lower() == "allege" or \
                        self.params['cl_typemod'].lower() == "allege_new" \
                        or self.params['cl_typemod'].lower() == "allege_now":
                    sort_rep = self.params['dirmodel_light']
                else:
                    sort_rep = self.params['dirmodel']
                cl_config_use = self.params['cl_config']
                if  time == 'forecast':
                    lead_new = [time[0]+time[4]+time[6:8]+element for element in lead_new ]
                    lead_fin = lead_new
                elif time == 'persistence' :
                    if [x for x in lead_time if 'best_weekly' in x]:
                        lead_fin = ['pers']
                    else :
                        lead_tmp = ['nwct']
                        lead_new = [time[:4]+element for element in lead_new[1:] ]
                        lead_tmp.extend(lead_new)
                        lead_fin = lead_tmp
                elif time == 'best_estimate' or time == 'best_estimate_RTR' :
                    cl_config_use = re.sub('Q','',self.params['cl_config'])
                    lead_fin = ['hdct']
                elif time == 'best_weekly' :
                    lead_fin = ['hdct','nwct']
                elif time == 'CLIM_WOA05' :
                    dirclim4 = self.params['db'].get('climato','DIRCLIM4')
                    lead_fin = ['clim4']
                    sort_rep = dirclim4
                elif time == 'CLIM_WOA09' :
                    dirclim1 = self.params['db'].get('climato','DIRCLIM1')
                    lead_fin = ['clim1']
                    sort_rep = dirclim1
                elif time == 'CLIM_ARV11' :
                    dirclim2 = self.params['db'].get('climato','DIRCLIM2')
                    lead_fin = ['clim2']
                    sort_rep = dirclim2
                elif time == 'CLIM_WOA13' :
                    dirclim3 = self.params['db'].get('climato','DIRLEV')
                    lead_fin = ['clim3']
                    sort_rep = dirclim3
                elif time == 'CLIM_WOA18_8594' or time == 'CLIM_WOA18_95A4' or time == 'CLIM_WOA18_A5B7':
                    dirclim3 = self.params['db'].get('climato','DIRLEV')
                    lead_fin = ['clim3']
                    sort_rep = dirclim3
                elif time == 'CLIM_MED' :
                    dirclim = self.params['db'].get('climato','DIRCLIM')
                    lead_fin = ['clim']
                    sort_rep = dirclim
                else :
                   self.log.error('interp_fortran Lead time {} not expected ' .format(time))
                if self.params['data_type'] ==  "AMSR" :
                    exe = 'CLASS4_spatial_interpolation_'+self.params['data_origin']+'_AMSR.exe'
                else :
                    exe = 'CLASS4_spatial_interpolation_'+self.params['data_origin']+'.exe'
                exe = os.path.join(self.params['direxec'],exe)
                if self.params['data_origin'] == 'CORIOLIS' :
                    nml=os.path.join(self.params['nml_dir'],'interpolate_3D_%s_%s_%s_%s.nml' %(self.params['data_type'].upper(),self.params['cl_config'],time,dateval))
                    self.log.debug('Case corio')
                    self.log.debug(f"{self.params['cl_typemod']=}")
                    self.log.debug(f"{sort_rep=}")
                    NmlCreator(self.params['cl_msshFile'],ll_mssh,ll_compute,self.params['rp_mssh_shift']).factory(self.params['data_origin'])\
                              .run(nml,cl_config_use,self.params['daily_pref'],self.params['data_type'],\
                              time,sort_rep,self.params['coloc_rep'],self.params['dirwork'],time,dateval,self.params['gridtemp'],\
                              self.params['gridsal'],self.params['cl_schedule'],self.params['type_run'],self.params['coordinates'],\
                              self.params['cl_typemod'], self.params['cl_conf'])
                    if not os.path.exists(exe) :
                        self.log.error('Did not find executable {}'.format(exe))
                        sys.exit(1)
                    codexe = '%s -r %s -c %s -m %s -l %s' %(exe,dateval,nml,cl_config_use,self.params['dir_log'])
                    args   = shlex.split(codexe)
                    try :   subprocess.check_call(args)
                    except :
                        self.log.error('executable {} failed'.format(exe))
                        sys.exit(1)
                ## Case GODAE
                if self.params['data_origin'] == 'GODAE':
                    ##  Create namelist
                    self.log.info('Create namelist')
                    for filename in glob(self.params['dirwork']+"*"+dateval+"*.nc") :
                        NmlCreator(self.params['cl_msshFile'],ll_mssh,ll_compute,self.params['rp_mssh_shift']).factory(self.params['data_origin'])\
                                .run(nml,cl_config_use,self.params['daily_pref'],self.params['data_type'] , \
                                time,dirmodel,self.params['coloc_rep'],filename,lead_fin,dateval,self.params['gridtemp'],\
                                self.params['gridsal'])

                        ## Launch Interpolation
                        if not os.path.exists(exe) :
                            self.error('Did not find executable {}'.format(exe))
                            sys.exit(1)
                        codexe = '%s -r %s -c %s -m %s' %(exe,dateval,nml,cl_config_use)
                        args   = shlex.split(codexe)
                        try :   subprocess.check_call(args)
                        except :
                            self.log.error('executable {} failed'.format(exe))
                            sys.exit(1)
                        ## Design File
                        config_d=re.sub("V","QV",self.params['cl_config'])
                        Design().factory(self.params['data_origin']).run(filename,dateval,self.params['contact'],\
                                config_d,self.params['model_type'].lower(),self.params['inst'],\
                                self.params['version'],self.param['desc'])
            ## Move file in the correct repertory
            for filename in glob(self.params['dirwork']+"*"+dateval+"*.nc") :
                self.log.debug('File ok {}'.format(filename))
                self.log.debug('Dateval {}'.format(dateval))
                code_convert=self.params['dirwork']+'/convert.ksh '+filename
                os.system(code_convert)

                if os.path.exists(self.params['diroutput']+os.path.basename(filename)):
                    os.remove(self.params['diroutput']+os.path.basename(filename))
                shutil.move(filename,self.params['diroutput'])




    def runNext(self):
        """
           Launch the next run
        """
        DAYMAX=self.params['daymax']
        self.log.info("Max date :  {}".format(DAYMAX))

        if DAYMAX :
           dayvalmax=SyDate(DAYMAX)
           schedule=self.params['db'].get('GLOBAL','SCHEDULE')
           if schedule == "MONTHLY" :
              date_next=self.params['date1'].goforward(31)
           elif schedule == "WEEKLY" :
             date_next=SyDate(self.params['cl_daterun']).goforward(7)
           elif schedule == "DAILY" :
             self.log.info('Daterun {}'.format(self.params['cl_daterun']))
             date_next=SyDate(self.params['cl_daterun'] ).goforward(1)
           else :
             self.log.error("Schedule not found {}".format(schedule))
             sys.exit(1)
           self.log.debug("Schedule %s" %(schedule))
           if  date_next < dayvalmax :
              if schedule == "MONTHLY" :
                  cl_date=SyDate.__str__(date_next)[0:6]
                  cl_date2=SyDate.__str__(dayvalmax)[0:6]
                  self.log.info("Launch date :  {}".format(cl_date))
                  self.log.info("Launch params :  {} {} {} {}".format(self.params['cl_config'],cl_date2,self.params['nb_proc'],self.params['cl_src']))
                  code_lancement=self.params['dirhome']+'script/launch/Launcher_KARA_cycle_CORA-fortran.ksh '+self.params['cl_config']+\
                          ' ' + cl_date + ' ' + cl_date2 + ' ' + str(self.params['nb_proc']) + ' '+self.params['cl_src'] + \
                          ' ' + str(dayvalmax) + ' ' + self.params['cl_typemod'].lower()

                  self.log.info("Code lancement {}".format(code_lancement))
              elif schedule == "WEEKLY" :
                  cl_daterun=SyDate.__str__(date_next)
                  cl_date2=SyDate.__str__(dayvalmax)
                  self.log.info("Launch run :  {}".format(cl_daterun))
                  code_lancement=self.params['dirhome']+'script/Launcher_KARA_cycle_CORA.ksh '+self.params['cl_config']+'  '+cl_daterun+' '+cl_date2+' '+self.params['nb_proc']
              elif schedule == "DAILY" :
                  cl_daterun=SyDate.__str__(date_next)
                  cl_date2=SyDate.__str__(dayvalmax)
                  self.log.info("Launch run :  {}".format(cl_daterun))
                  code_lancement=self.params['dirhome']+'script/Launcher_KARA_cycle_CORIO.ksh '+self.params['cl_config']+'  '+cl_daterun+' '+cl_date2+' '+self.params['nb_proc']
              else :
                  log.error("Schedule not found %s" %(schedule))
              try:
                   os.system(code_lancement)
                   self.log.info("Lancement date run {} ok ".format(cl_date))
                   self.log.info("Lancement date run {} ".format(code_lancement))
              except:
                 self.log.error('Probleme execution')
                 sys.exit(1)
              sys.exit(1)

           else :
               self.log.error('Dépassement:  JNEXT {} / JMAX {} '.format(SyDate.__str__(date_next),str(dayvalmax)))
               sys.exit(1)

