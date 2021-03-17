## Script to compare 2 solutions of class4
##
import os, sys
import numpy as np
from glob import glob
sys.path.append("../../modules")
from reader import read_GODAE_profile
from lib_pyt.Profile import plot_3profiles
import numpy.ma as ma

dateval = "20200901"

type_CL4 = "profile"
variable = "votemper"
dir_class4_1 = "/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/data_CLASS4_GODAE/"
dir_class4_2 = "/data/rd_exchange4/cregnier/CLASS4_OUTPUTS/tmp/"
dir_out = "/data/rd_exchange4/cregnier/CLASS4_OUTPUTS/comparaisons/"

filename1 = glob(dir_class4_1+"*"+dateval+"*"+type_CL4+".nc")
filename2 = glob(dir_class4_2+"*"+dateval+"*"+type_CL4+".nc")

prof_1, model_best_1, obs = read_GODAE_profile(variable, filename1[0])
prof_2, model_best_2, obs2 = read_GODAE_profile(variable, filename2[0])

prof = ma.array(prof_1)
model_best_ma = ma.array(model_best_2)
prof = ma.masked_where( np.isnan(prof), prof)
#prof_test = prof[600,:]
#prof_test = ma.masked_where( prof_test, prof_test) 
#prof_test = ma.masked_where(prof.mask == True, )
model_best_ma =  ma.masked_where( np.isnan(model_best_ma), model_best_ma)
#print (type(model_best_ma))
#print (prof)
#values_interp[ind_prof,:] = ma.masked_where(profondeur.mask == True, values_interp[ind_prof,:])

nb_profiles, nb_levels = np.shape(model_best_1)
label1 = "Obs"
label2 = "Oper"
label3 = "Dev"

print ('ok')
for ind_prof in range(nb_profiles):
    title = dateval+" Profile " +str(ind_prof)
    print (np.shape(prof_1), np.shape(obs), np.shape(model_best_1), np.shape(prof_2),  np.shape(model_best_2))
    if ind_prof == 70:
        print (model_best_1[ind_prof,:])
        print (model_best_2[ind_prof,:])
        print (-prof_1[ind_prof,0:50])
        print (-prof_2[ind_prof,0:50])

        plot_3profiles(-prof_1[ind_prof,:], obs[ind_prof,:], model_best_1[ind_prof,:],
                       -prof_2[ind_prof,:], model_best_2[ind_prof,:], label1,
                       label2, label3, title=title, save=False,
                       output=dir_out+dateval+"_comparaison_"+variable+"_profile_num"+str(ind_prof),
                       var=variable)

