from __future__ import generators                                                                                    
import os,sys,string,shutil,glob,re
import numpy as np
import logging
import tarfile
from sydate import SyDate
from nco.nco import Nco
import datetime as dt

##############################################################
## C.REGNIER Juillet 2014
## Class Designer to design the output file : change global attributs, etc
##############################################################

class Designer_file(object) :
    """ Factory extract file depending on type """
    def factory(self,type):
        #return eval(type + "()")
        if type == "CORIOLIS" : return Designer_coriolis()
        if type == "GODAE" : return Designer_GODAE()


class Designer_GODAE(Designer_file):

    def run(self,filename,dateval,contact,system,mode_type,institution,version,desc):
        ## Nco constructor
        nco = Nco()
        list_value=[]
        list_value.append(str(dt.datetime.strptime(dateval,'%Y%m%d')))
        list_value.append(str(dt.datetime.today()))
        list_value.append(contact)
        list_value.append(system)
        list_value.append(mode_type)
        list_value.append(institution)
        list_value.append(version)
        list_value.append(desc) 
        # Change global attribute
        list_varname=['validity_time','creation_date','contact','system','configuration','institution','version','best_estimate_description']
        il_ind=0
        print( list_value)
        print( list_varname)
        for varname in list_varname: 
            value=list_value[il_ind]
            options=[]
            options.extend(['-h','-O','-a',str(varname)+',global,o,c,"'+value+'"'])
            nco.ncatted(input=filename,output=filename,options=options)
            il_ind=il_ind+1
