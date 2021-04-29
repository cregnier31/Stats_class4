# coding: utf8
import os,fnmatch,sys,string,shutil,glob,re
import numpy as np
import logging
import tarfile
from sytoolkit.sydate import SyDate
from nco.nco import Nco
from Logger import Logger

#######################################################################
## Class NmlCreator to create namelist : it depends on input type file
## Creation C.REGNIER Juillet 2014
#######################################################################

class NmlCreator(object) :

    """ Factory for the creation of different namelists """

    def __init__(self,mssh_file,\
        ll_mssh,ll_compute,mssh_shift,**kwargs):
        self.mssh_file=mssh_file
        self.ll_mssh=ll_mssh
        self.ll_compute=ll_compute
        self.mssh_shift=mssh_shift

    def factory(self,type):
        if type == "CORIOLIS": return NmlCreator_CORIOLIS(self.mssh_file,self.ll_mssh,self.ll_compute,self.mssh_shift)
        if type == "CORIOLIS_RAW": return NmlCreator_CORIOLIS(self.mssh_file,self.ll_mssh,self.ll_compute,self.mssh_shift)
        if type == "IAOOS": return NmlCreator_IAOOS(self.mssh_file,self.ll_mssh,self.mssh_shift)
        if type == "GODAE" : return NmlCreator_GODAE(self.mssh_file,self.ll_mssh,self.ll_compute,self.mssh_shift)

class NmlCreator_GODAE(NmlCreator):

    """ Class for GODAE namelists """

    def __init__(self,mssh_file,ll_mssh,ll_compute,mssh_shift,**kwargs):
        super(NmlCreator,self).__init__(**kwargs)
        self.mssh_file=mssh_file
        self.ll_mssh=ll_mssh
        self.ll_compute=ll_compute
        self.mssh_shift=mssh_shift

    def run(self,nml,modele,mean_type,type_data,outputVarname,\
        dirmodel,dircoloc,filename,listdir,dateval,gridtemp,gridsal):
        # =============== 
        # LOGGER
        # ===============
        log=Logger("NmlCreator_GODAE").run(2)
        # ===============
        if type_data != "SLA" and  type_data != "SST" and type_data != "profile" and type_data != "aice" and type_data != "AMSR" :
            print("Data %s not known %s !!! ")
            sys.exit(1)
        if type_data == "profile" :
            il_nvar=2
        else : 
            il_nvar=1
        inputVarname='observation'
        file_coloc=os.path.basename(filename)
        file_coloc=re.sub('.nc','.dat',file_coloc)
        cl_colocfile=dircoloc+file_coloc
        if outputVarname == 'best_estimate' :
            dirmodel=dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
        else :
            dirmodel=dirmodel+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
        #log.info('Research %s' %(dirmodel)) 
        # Creation of list
        list_file=[]
        list_file_T=[]
        list_file_S=[]
        for directory in listdir :
            log.info('directory %s' %(directory)) 
            if type_data == 'SLA' :
                for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_grid2D*.nc") :
                    list_file.append(str(file))
            elif type_data == 'SST' :
                for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_"+gridtemp+"*.nc"):
                    list_file.append(str(file))
            elif type_data == 'profile' :
                for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_"+gridtemp+"*.nc") : 
                    list_file_T.append(file)
                    list_file_S.append(re.sub(gridtemp,gridsal,file))
            elif type_data == 'aice' or  type_data == 'AMSR' :
                #for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_icemod*.nc") :
                for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_ileadfra*.nc") :
                    list_file.append(str(file))

        if type_data == 'profile'  :
            list_file=list_file_T
            list_file.extend(list_file_S)
        nbfile=len(list_file)
        if nbfile == 0 : 
            log.error('Found %i files corresponding to %s %s while expecting 1' %(nbfile,type_data,directory))
            sys.exit(1)
        ##
        ## Write namelist file
        obFichier=open(nml,'w')
        obFichier.write('&interpolate_3D\n')
        obFichier.write('cl_inputFile     = '+"'"+filename+"'"+'\n')
        obFichier.write('cl_msshFile      = '+"'"+self.mssh_file+"'"+'\n')
        obFichier.write('cl_colocFile     = '+"'"+cl_colocfile+"'"+'\n')
        obFichier.write('cl_inputVarname  = '+"'"+inputVarname+"'"+'\n')
        obFichier.write('cl_outputVarname = '+"'"+outputVarname+"'"+'\n')
        obFichier.write('il_ncast         = '+str(len(listdir))+'\n')
        obFichier.write('il_nvar          = '+str(il_nvar)+'\n')
        obFichier.write('ll_mssh          = '+self.ll_mssh+'\n')
        #obFichier.write('ll_compute       = '+self.ll_compute+'\n')
        obFichier.write('rl_mssh_shift    = '+str(self.mssh_shift)+'\n')
        obFichier.write('il_nbfile        = '+str(nbfile)+'\n')
        obFichier.write('/'+'\n')
        for file in list_file :
            obFichier.write(str(file)+'\n')
        obFichier.close()


class NmlCreator_IAOOS(NmlCreator):

    """ Class for IAOOS dataset """

    def __init__(self,mssh_file,ll_mssh,mssh_shift,**kwargs):
        super(NmlCreator,self).__init__(**kwargs)
        self.mssh_file=mssh_file
        self.ll_mssh=ll_mssh
        self.mssh_shift=mssh_shift
    def run(self,nml,modele,mean_type,type_data,outputVarname, \
          dirmodel,dircoloc,output,listdir,dateval,gridtemp,gridsal,schedule,type_run):
        # =============== 
        # LOGGER
        # ===============
        log=Logger("NmlCreator_IAOOS").run(2)
        # ===============
        if type_data  !=  'IAOOS' : 
            log.error("IAOOS files only !!!!")
            sys.exit(1)
        daterun=dateval
        model_varname_T="votemper"
        model_varname_S="vosaline"
        input_varname_T="TEMP"
        input_varname_S="PSAL"
        yearval=dateval[0:4]
        searchdir=listdir
        if listdir == 'hdct' or listdir == 'best_estimate' :
            prefix_var='HDCST'
        elif listdir == 'nwct' :
            prefix_var='ANA'
        elif listdir == 'fcst3' :
            prefix_var='FRCST3D'
        elif listdir == 'fcst6' :
            prefix_var='FRCST6D'
        elif listdir == 'pers' :
            prefix_var='PERS'
        else :
            prefix_var=listdir
        if schedule == 'm' : 
            searchdir="MONTHLY_"+yearval
            daterun=dateval[0:6]
            template=dirmodel+searchdir+'/'+modele+'*'+daterun+'_'+gridtemp+'.nc'
        elif type_run == 'free' :
            template=dirmodel+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'
        elif type_run =='OPER' :
            template=dirmodel+'/'+modele+'_1dAV_'+daterun+'*'+gridtemp+'*.nc'
        else :
            template=dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'

        output_varname_T=prefix_var+'_'+input_varname_T
        output_varname_S=prefix_var+'_'+input_varname_S
        log.debug('listdir %s '%(listdir[0:4])) 
        if listdir[0:4] == 'CLIM' :
            daterun=dateval[0:6]
            monthval=dateval[4:6]
            searchdir=dirmodel
            template=searchdir+'*M'+monthval+'*.nc'
            model_varname_T="temperature"
            model_varname_S="salinity"
        if listdir == 'CLIM_WOA09' :
            output_varname_T='TMLEV09'
            output_varname_S='SMLEV09'   
        elif listdir == 'CLIM_WOA05' :
            output_varname_T='TMLEV05'
            output_varname_S='SMLEV05'   
        elif listdir == 'CLIM_ARV11' :
            output_varname_T='TMARV11'
            output_varname_S='SMARV11'
        elif listdir == 'CLIM_WOA13' :
            output_varname_T='TMLEV13'
            output_varname_S='SMLEV13'
            template_temp=searchdir+'*M'+monthval+'*temp*.nc'
            template_sal=searchdir+'*M'+monthval+'*sal*.nc'
            model_varname_T="temperature"
            model_varname_S="vosaline"
        elif listdir == 'CLIM_MED' :
            output_varname_T='TMMED'
            output_varname_S='SMMED'
            model_varname_T='votemper'
            model_varname_S='vosaline'
        ## List model
        #for file in glob.glob(dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc') : 
        log.debug('Template %s' %(template)) 
        for filename in glob.glob(template) : 
            if listdir[0:4] != 'CLIM' :
                fic_temp=filename
                template_temp=template
                fic_psal=re.sub(gridtemp,gridsal,fic_temp)
            else :
                if ( len( glob.glob(template)) == 2 ) : 
                    #log.info('Cas climato ') 
                    if fnmatch.fnmatch(filename,"*temp*"):
                        fic_temp=filename
                    if fnmatch.fnmatch(filename,"*sal*"):
                        fic_psal=filename
                else :
                    template_temp=template
                    fic_temp=filename
                    fic_psal=filename
        ## Add test to see missing values
        cl_file = glob.glob(template_temp)
        if len(cl_file) != 1 :
            log.error('Found %i files corresponding to %s while expecting 1' %(len(cl_file),listdir))
            sys.exit(1)
        ##
        log.debug('Fichier temp %s' %(fic_temp)) 
        log.debug('Fichier psal %s' %(fic_psal)) 
        nbfile=len(glob.glob(output+"*_"+str(dateval)+"*.txt"))
        # Write Namelist
        obFichier=open(nml,'w')
        obFichier.write('&interpolate_3D\n')
        obFichier.write('cl_modelFileT = '+"'"+fic_temp+"'"+'\n')
        obFichier.write('cl_modelFileS = '+"'"+fic_psal+"'"+'\n')
        obFichier.write('cl_colocRep = '+"'"+dircoloc+"'"+'\n')
        obFichier.write('cl_inputVarname_T = '+"'"+input_varname_T+"'"+'\n')
        obFichier.write('cl_inputVarname_S = '+"'"+input_varname_S+"'"+'\n')
        obFichier.write('cl_modelVarname_T = '+"'"+model_varname_T+"'"+'\n')
        obFichier.write('cl_modelVarname_S = '+"'"+model_varname_S+"'"+'\n')
        obFichier.write('cl_outputVarname_T = '+"'"+output_varname_T+"'"+'\n')
        obFichier.write('cl_outputVarname_S = '+"'"+output_varname_S+"'"+'\n')
        obFichier.write('cl_input_type = ASCII'+'\n')
        obFichier.write('il_nbfile = '+str(nbfile)+'\n')
        obFichier.write('/'+'\n')
        for fichier2 in glob.glob(output+"*_"+str(dateval)+"*.txt") :
            obFichier.write(fichier2+'\n')
        obFichier.close()


class NmlCreator_CORIOLIS(NmlCreator):

    """ Class for CORIOLIS dataset """

    def __init__(self,mssh_file,ll_mssh,ll_compute,mssh_shift,**kwargs):
        super(NmlCreator,self).__init__(**kwargs)
        self.mssh_file=mssh_file
        self.ll_mssh=ll_mssh
        self.mssh_shift=mssh_shift
   # def search_lighout(self,date,dirin,type_run,listdir):

    def run(self,nml,modele,mean_type,type_data,outputVarname, \
        dirmodel,dircoloc,output,listdir,dateval,gridtemp,gridsal,schedule,type_run,mesh_file,type_file=None):
        # ===============
        # LOGGER
        # ===============
        log=Logger("NmlCreator_CORIOLIS").run(2)
        # ===============
        if type_data  !=  'profile' :
            log.error("CORIOLIS files are only profiles !!!!")
            sys.exit(1)
        model_varname_T="votemper"
        model_varname_S="vosaline"
        input_varname_T="TEMP"
        input_varname_S="PSAL"
        daterun=dateval
        yearval=dateval[0:4]
        searchdir=listdir
        ll_lightout=False
        if listdir == 'hdct' or listdir == 'best_estimate' :
            prefix_var='HDCST'
        elif listdir == 'nwct' :
            prefix_var='ANA'
        elif listdir == 'fcst3' :
            prefix_var='FRCST3D'
        elif listdir == 'fcst6' :
            prefix_var='FRCST6D'
        elif listdir == 'pers' :
            prefix_var='PERS'
        else :
            prefix_var=listdir
        if schedule == 'm' :
            searchdir="MONTHLY_"+yearval
            daterun=dateval[0:6]
            if type_file == 'allege' :
                type_out='END'
                ## Find next daterun
                jdatemin=SyDate(dateval)
                daytogo=2-jdatemin.weekday()
                if daytogo > 0 :
                    first_date=jdatemin.goforward(daytogo)
                else :
                    if type_run == 'RTR' or type_run == 'REA':
                        nbdate=7
                    elif type_run == 'HINDCAST' or type_run == 'OPER':
                        nbdate=14
                    daytogo2=nbdate+daytogo
                    first_date=jdatemin.goforward(daytogo2)
                   # first_date=jdatemin.gobackward(-daytogo)
                daterun=first_date
                if type_run == 'RTR' or type_run == 'REA':
                    date1=daterun.gobackward(7)
                    date2=daterun
                elif type_run == 'HINDCAST' or type_run == 'OPER':
                    date1=daterun.gobackward(14)
                    date2=daterun.gobackward(7)
                if type_run == 'OPER':
                    type_run_tmp = 'hindcast'
                elif type_run == 'RTR' or type_run == 'REA':
                    type_run_tmp = type_run.lower()
                else:
                    log.error("Type run not known {}".format())
                    sys.exit(1)

                template=dirmodel+'ALLEGES_'+type_run_tmp+'_'+str(date1)+'_'+str(date2)+'_R'+str(daterun)+'/'+type_out+'/'+gridtemp+'N.B.d*.50.0'
                ll_lightout=True
            else :
                #template=dirmodel+searchdir+'/'+modele+'*'+daterun+'_'+gridtemp+'.nc'
                template=dirmodel+'/'+modele+'*'+daterun+'_'+gridtemp+'.nc'
        elif type_run == 'free' :
            template=dirmodel+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'
        else :
            log.debug("schedule daily")
            if type_file == 'allege' :
                type_out='END'
                log.debug("lightout type")
                ## Find next daterun
                jdatemin=SyDate(dateval)
                daytogo=2-jdatemin.weekday()
                if daytogo > 0:
                    first_date=jdatemin.goforward(daytogo)
                else :
                    if type_run == 'RTR' or type_run == 'REA':
                        nbdate=7
                    elif type_run == 'HINDCAST' or type_run == 'OPER':
                        nbdate=14
                    daytogo2=nbdate+daytogo
                    first_date=jdatemin.goforward(daytogo2)
                   # first_date=jdatemin.gobackward(-daytogo)
                daterun=first_date
                if type_run == 'RTR' or  type_run == 'REA':
                    date1=daterun.gobackward(7)
                    date2=daterun
                elif type_run == 'HINDCAST' or  type_run == 'OPER':
                    date1=daterun.gobackward(14)
                    date2=daterun.gobackward(7)
                if type_run == 'OPER':
                    type_run_tmp = 'hindcast'
                elif type_run == 'RTR' or type_run == 'REA':
                    type_run_tmp = type_run.lower()
                else:
                    log.error("Type run not known {}".format())
                    sys.exit(1)
                template=dirmodel+'ALLEGES_'+type_run_tmp+'_'+str(date1)+'_'+str(date2)+'_R'+str(daterun)+'/'+type_out+'/'+gridtemp+'N.B.d*.50.0'
                ll_lightout=True
            else :
                if type_run == "REA":
                    YEAR = daterun[0:2]
                    template=dirmodel+YEAR+'*/*/'+modele+'_1dAV_'+daterun+'*'+gridtemp+'*.nc'
                elif type_run == "OPER":
                    template = dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/hdct/"+modele+"_1dAV_"+daterun+"*"+gridtemp+"*.nc"
                elif type_run == "OPER2":
                    template = dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
                else:
                    #template=dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'
                    template=dirmodel+'/'+modele+'_'+daterun+'*'+gridtemp+'*.nc'

        output_varname_T=prefix_var+'_'+input_varname_T
        output_varname_S=prefix_var+'_'+input_varname_S
        log.info('listdir %s '%(listdir[0:4])) 
        if listdir[0:4] == 'CLIM' :
            daterun=dateval[0:6]
            monthval=dateval[4:6]
            searchdir=dirmodel
            template=searchdir+'*M'+monthval+'*.nc'
            model_varname_T="temperature"
            model_varname_S="salinity"
        if listdir == 'CLIM_WOA09' :
            output_varname_T='TMLEV09'
            output_varname_S='SMLEV09'
        elif listdir == 'CLIM_WOA05' :
            output_varname_T='TMLEV05'
            output_varname_S='SMLEV05'
        elif listdir == 'CLIM_ARV11' :
            output_varname_T='TMARV11'
            output_varname_S='SMARV11'
        elif listdir == 'CLIM_WOA13' :
            ll_lightout=False
            template=searchdir+'*M'+monthval+'*_TEMP.nc'
            #template=searchdir+'*M'+monthval+'*_tempinsitu.nc'
            output_varname_T='TMLEV13'
            output_varname_S='SMLEV13'
            model_varname_T="temperature"
            #model_varname_S="vosaline"
            model_varname_S="salinity"
        elif listdir == 'CLIM_MED' :
            output_varname_T='TMMED'
            output_varname_S='SMMED'
            model_varname_T='votemper'
            model_varname_S='vosaline'
        ## List model
        #for file in glob.glob(dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc') : 
        log.debug('Template %s' %(template))
        fic_temp = []
        fic_psal = []
        for file in glob.glob(template):
            fic_temp=file
            log.debug('File {}'.format(file))
            if listdir[0:4] != 'CLIM' :
                if type_file == 'allege' :
                    fic_psal=re.sub(gridtemp+"N.B",gridsal+"N.B",fic_temp)
                else :
                    log.debug('gridtemp {} gridsal {}'.format(gridtemp,gridsal))
                    fic_psal=re.sub(gridtemp,gridsal,fic_temp)
            else :
                if listdir == 'CLIM_WOA13' :
                    fic_psal=re.sub('TEMP','PSAL',fic_temp)
                    #fic_psal=re.sub('tempinsitu','sal',fic_temp)
                else :
                    log.debug('Dans le else')
                    fic_psal=fic_temp
        if not fic_temp or not fic_psal :
            log.error("Files doesn't exist ")
            log.error(template)
            sys.exit(1)

        log.debug('Fichier temp %s' %(fic_temp)) 
        log.debug('Fichier psal %s' %(fic_psal)) 
        ## Add test to see missing values
        ##cl_file = glob.glob(template)
        ##if ( len( glob.glob(template)) == 2 ) : 
        ##     #log.info('Cas climato ') 
        ##     if fnmatch.fnmatch(filename,"*temp*"):
        ##         fic_temp=filename
        ##     if fnmatch.fnmatch(filename,"*sal*"):
        ##         fic_psal=filename
        ## else :
        ##     template_temp=template
        ##     fic_temp=filename
        ##     fic_psal=filename
        ## Add test to see missing values
        ##if len(cl_file) != 1 :
        ##    log.error('Found %i files corresponding to %s while expecting 1' %(len(cl_file),listdir))
        ##    sys.exit(1)
        ##
        nbfile=len(glob.glob(output+"*"+str(dateval)+"*.nc"))
        # Write Namelist
        obFichier=open(nml,'w')
        obFichier.write('&interpolate_3D\n')
        obFichier.write('cl_modelFileT = '+"'"+fic_temp+"'"+'\n')
        obFichier.write('cl_modelFileS = '+"'"+fic_psal+"'"+'\n')
        obFichier.write('cl_colocRep = '+"'"+dircoloc+"'"+'\n')
        obFichier.write('cl_inputVarname_T = '+"'"+input_varname_T+"'"+'\n')
        obFichier.write('cl_inputVarname_S = '+"'"+input_varname_S+"'"+'\n')
        obFichier.write('cl_modelVarname_T = '+"'"+model_varname_T+"'"+'\n')
        obFichier.write('cl_modelVarname_S = '+"'"+model_varname_S+"'"+'\n')
        obFichier.write('cl_outputVarname_T = '+"'"+output_varname_T+"'"+'\n')
        obFichier.write('cl_outputVarname_S = '+"'"+output_varname_S+"'"+'\n')
        obFichier.write('il_nbfile = '+str(nbfile)+'\n')
        obFichier.write("cl_input_type = 'NETCDF'"+'\n')
        if  ll_lightout : 
            obFichier.write('cl_input_typemod = '+"'"+type_file+"'"+'\n')
        else :
            type_file='NETCDF'
            obFichier.write('cl_input_typemod = '+"'"+type_file+"'"+'\n')
        obFichier.write('cl_meshfile = '+"'"+mesh_file+"'"+'\n')
        obFichier.write('/'+'\n')
        for fichier2 in glob.glob(output+"*"+str(dateval)+"*.nc") :
            obFichier.write(fichier2+'\n')
        obFichier.close()
