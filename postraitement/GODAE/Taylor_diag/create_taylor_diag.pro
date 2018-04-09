PRO create_taylor_diag,zone,profondeur,modele,var,dir_in,date1,date2

print,zone,profondeur,modele,var
print,dir_in
file1=dir_in+"Global_stats"+modele+"_"+zone+"_"+date1+"_"+date2+"_"+var+"_"+profondeur+".txt"
data=READ_ASCII( file1, /VERBOSE ) & matrix = data.field01

n_var=N_ELEMENTS(matrix)
n_var2=n_var/2
tab_rms=fltarr(n_var2)
tab_mean=fltarr(n_var2)
il_ind=0L
il_ind3=0L

variable_name=strarr(n_var2)
variable_name[0]= 'BEST'
variable_name[1]= 'FRCST1D'
variable_name[2]= 'FRCST3D'
variable_name[3]= 'FRCST5D'
variable_name[4]= 'PERS1D'
variable_name[5]= 'PERS3D'
variable_name[6]= 'PERS5D'

for il_ind=0,n_var-2,2  DO BEGIN & $
 il_ind2=il_ind+1 & $
 tab_rms[il_ind3]=matrix[il_ind] & $
 tab_mean[il_ind3]=matrix[il_ind2] &$ 
 il_ind3=il_ind3+1 &$
endfor
; Set up variables for the plot. Normally, these values would be 
; passed into the program as positional and keyword parameters.
labels = variable_name            
ref_rms = 1.0                                                
rms_max = MAX(tab_rms)*1.1
print,labels
   
; Draw the Taylor Diagram.                                          
   cgTaylorDiagram, tab_rms,tab_mean, REF_STDDEV=ref_rms, STDDEV_MAX=rms_max, $
       RMS_INCREMENT=0.20, RMS_FORMAT='(F0.2)', LABELS=labels       
  
END
