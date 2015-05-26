from __future__ import generators
import os,sys,string,shutil,glob,re
import numpy as np
import logging
import tarfile
from sytoolkit.sydate import SyDate
from nco import Nco
from Logger import Logger                                                                                                   

#######################################################################
## Class NmlCreator to create namelist : it depends on input type file
## Creation C.REGNIER Juillet 2014
#######################################################################

class NmlCreator(object) :
    """ Factory extract file depending on type """
    def __init__(self,mssh_file,\
		      ll_mssh,mssh_shift,**kwargs):
	self.mssh_file=mssh_file
	self.ll_mssh=ll_mssh
	self.mssh_shift=mssh_shift

    def factory(self,type):
        if type == "CORIOLIS": return NmlCreator_CORIOLIS(self.mssh_file,self.ll_mssh,self.mssh_shift)
        if type == "IAOOS": return NmlCreator_IAOOS(self.mssh_file,self.ll_mssh,self.mssh_shift)
        if type == "GODAE" : return NmlCreator_GODAE(self.mssh_file,self.ll_mssh,self.mssh_shift)

class NmlCreator_GODAE(NmlCreator):
     def __init__(self,mssh_file,ll_mssh,mssh_shift,**kwargs):
        super(NmlCreator,self).__init__(**kwargs)
        self.mssh_file=mssh_file
        self.ll_mssh=ll_mssh
        self.mssh_shift=mssh_shift
     def run(self,nml,modele,mean_type,type_data,outputVarname,\
	     dirmodel,dircoloc,filename,listdir,dateval,gridtemp,gridsal):
        # =============== 
        # LOGGER
        # ===============
        log=Logger("NmlCreator_GODAE").run(2)
        # ===============
        if type_data != "SLA" and  type_data != "SST" and type_data != "profile" and type_data != "aice":
	    print "Data %s not known %s !!! "
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
	       print file
	       list_file.append(str(file))
	  elif type_data == 'profile' :
	    for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_"+gridtemp+"*.nc") : 
	       list_file_T.append(file)
	       list_file_S.append(re.sub(gridtemp,gridsal,file))
	  elif type_data == 'aice' :
	    for file in glob.glob(dirmodel+directory+"/"+modele+"_"+mean_type+"_"+dateval+"*_icemod*.nc") :
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
        obFichier.write('rl_mssh_shift    = '+str(self.mssh_shift)+'\n')
        obFichier.write('il_nbfile        = '+str(nbfile)+'\n')
        obFichier.write('/'+'\n')
        for file in list_file :
            obFichier.write(str(file)+'\n')
        obFichier.close()
  	

class NmlCreator_IAOOS(NmlCreator):
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
 	   print "monthly values"
           daterun=dateval[0:6]
	   template=dirmodel+searchdir+'/'+modele+'*'+daterun+'_'+gridtemp+'.nc'
        elif type_run == 'free' or  type_run == 'OPER' :
           print modele,daterun,gridtemp
           template=dirmodel+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'
	else :
           template=dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'

	output_varname_T=prefix_var+'_'+input_varname_T
        output_varname_S=prefix_var+'_'+input_varname_S
        log.info('listdir %s '%(listdir[0:4])) 
	if listdir[0:4] == 'CLIM' :
           log.info('Passe la') 
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
	elif listdir == 'CLIM_MED' :
	   output_varname_T='TMMED'
	   output_varname_S='SMMED'
           model_varname_T='votemper'
           model_varname_S='vosaline'
	## List model
        #for file in glob.glob(dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc') : 
        log.info('Template %s' %(template)) 
	## Add test to see missing values
	cl_file = glob.glob(template)
        if len(cl_file) != 1 :
           log.error('Found %i files corresponding to %s while expecting 1' %(len(cl_file),listdir))
           sys.exit(1)
        ##
        for file in glob.glob(template) : 
          fic_temp=file
	  if listdir[0:4] != 'CLIM' :
             fic_psal=re.sub(gridtemp,gridsal,fic_temp)
	  else :
	     fic_psal=fic_temp
        log.info('Fichier temp %s' %(fic_temp)) 
        log.info('Fichier psal %s' %(fic_psal)) 
	nbfile=len(glob.glob(output+"*"+str(dateval)+"*.txt"))
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
        obFichier.write('cl_imput_type = ASCII'+'\n')
        obFichier.write('il_nbfile = '+str(nbfile)+'\n')
        obFichier.write('/'+'\n')
        for fichier2 in glob.glob(output+"*"+str(dateval)+"*.txt") :
             obFichier.write(fichier2+'\n')
        obFichier.close()

class NmlCreator_CORIOLIS(NmlCreator):
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
 	   print "monthly values"
           daterun=dateval[0:6]
	   template=dirmodel+searchdir+'/'+modele+'*'+daterun+'_'+gridtemp+'.nc'
        elif type_run == 'free' :
           print modele,daterun,gridtemp
           template=dirmodel+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'
	else :
           template=dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc'

	output_varname_T=prefix_var+'_'+input_varname_T
        output_varname_S=prefix_var+'_'+input_varname_S
        log.info('listdir %s '%(listdir[0:4])) 
	if listdir[0:4] == 'CLIM' :
           log.info('Passe la') 
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
	elif listdir == 'CLIM_MED' :
	   output_varname_T='TMMED'
	   output_varname_S='SMMED'
           model_varname_T='votemper'
           model_varname_S='vosaline'
	## List model
        #for file in glob.glob(dirmodel+searchdir+'/'+modele+'*'+daterun+'*'+gridtemp+'*.nc') : 
        log.info('Template %s' %(template)) 
	## Add test to see missing values
	cl_file = glob.glob(template)
        if len(cl_file) != 1 :
           log.error('Found %i files corresponding to %s while expecting 1' %(len(cl_file),listdir))
           sys.exit(1)
        ##
        for file in glob.glob(template) : 
          fic_temp=file
	  if listdir[0:4] != 'CLIM' :
             fic_psal=re.sub(gridtemp,gridsal,fic_temp)
	  else :
	     fic_psal=fic_temp
        log.info('Fichier temp %s' %(fic_temp)) 
        log.info('Fichier psal %s' %(fic_psal)) 
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
        obFichier.write('/'+'\n')
        for fichier2 in glob.glob(output+"*"+str(dateval)+"*.nc") :
             obFichier.write(fichier2+'\n')
        obFichier.close()
