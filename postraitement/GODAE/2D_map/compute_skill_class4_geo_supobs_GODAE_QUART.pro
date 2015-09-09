PRO compute_skill_class4_geo_supobs_GODAE_QUART,DIR_INPUT=dir_input,DIR_OUT=output_dir,MODEL=modele,YEAR=annee,QUART=quart,ZONE=zone
;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; C.REGNIER  October   2013 Plot 2D bins maps for GODAE intercomparison
;-----------------------------------------------------------------------
; extension du path
!PATH =  Expand_Path('+/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/IDL_SRC/param') + ';' + $
         Expand_Path('+/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/IDL_SRC/plot') + ';' + $
         !PATH
;!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+';'+expand_path('+/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/IDL_SRC/param')+';'+expand_path('+/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/IDL_SRC/plot')+';'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@param_class4
dirin=dir_input
fic_out_card=output_dir
print,dirin
; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;; Definition des variables
;.compile Def_param_bulletin
;; Chargement des paramètres globaux
Def_param_bulletin
COMMON param_CLASS4,variable_name,valeurs_cmax,$
        valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,$
        liste_TEST,listemodele,liste_zone_GLOMyo,profondeur3,$
        profondeur4,liste_zone_PSY2_SHOM,tab_prof,tab_model,$
        tab_e3t,tab_prof_2,variable_name_2,variable_name_3,$
        variable_name_4,tab_prof_3,profondeur5,file_mask,file_save

; Choix des  parametres
var1=1
var2=8

variables=strarr(4)
variables(0)='TEMP'
variables(1)='PSAL'
variables(2)='SLA'
variables(3)='SST'
zone=zone

;; choix du type de tracé
kind='no_iso stddev UserLevels'
;kind='temperature difference'
clear,titre,units

;; Compilation & Execution
;;; Boites binsxdeg
print ,'-----------------------------------'
print ,'Calcul des stats boites 4deg pour les variables
print ,'-----------------------------------'

FOR ind=0,N_ELEMENTS(variables)-1 DO BEGIN   
   tab_prof=fltarr(2)
   tab_prof(0)=0
   tab_prof(1)=500
   profondeur=strarr(1)
   profondeur(0)='0-500m'
   trim=quart
   year=annee
   dirin=dir_input
   fic_out_card=output_dir
   variable=variables(ind)
   CASE variable OF                             & $
    	 'TEMP': BEGIN                       & $
   	      type_var='profile_votemper'       & $
   	 END                                 & $ 
   	 'PSAL':BEGIN                        & $
              type_var='profile_vosaline'       & $
   	 END                                 & $
   	 'SLA':BEGIN                         & $
              type_var='sossheig'               & $
   	 END      	                     & $ 
   	 'SST':BEGIN                         & $ 
              type_var='SST'                    & $ 
   	 END     	                     & $ 
   ENDCASE
   SPAWN,'ls '+dirin+ ' | grep '+type_var+' | grep  rms_diff_bins4deg_R'+year,filelist 
   fichier=filelist(0)
   print, fichier
   variable_name=strarr(9)
   variable_name(0)=variable
   variable_name(1)='HDCST_'+variable
   variable_name(2)='FRCST1D_'+variable
   variable_name(3)='FRCST3D_'+variable
   variable_name(4)='FRCST5D_'+variable
   variable_name(5)='PERS1D_'+variable
   variable_name(6)='PERS3D_'+variable
   variable_name(7)='PERS5D_'+variable
   variable_name(8)='CLIM_'+variable
   variable_name_type=variable_name
   print,variable_name_type
   print, filelist
   month=""
   datetrim=year+"_"+quart
   date_title=datetrim
   fichier_mask4='mask_bins4deg.nc'  
   dir_mask='/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/static/'
   CASE variable OF              & $
     'TEMP' : BEGIN                & $
             print,variable        & $
             fichier_mask4='mask_bins4deg.nc'  & $
             fichier=filelist(0)  & $
             dirname_out=fic_out_card+"T_S/"+datetrim+"/skill/" & $
             tracer_skillscore_gloCLASS4_supobs_GODAE,modele,fichier,fichier_mask4,filelist,var1,var2, $   
                                                        profondeur,variable_name_type,zone,kind,dirin,date_title, $
                                   			     tab_prof,tab_model,tab_e3t& $
             fichier_mask4='mask_bins4deg.nc'  & $
             fichier=filelist(0)  & $
             print, fichier & $
             dirin=dir_input & $
             dir_mask='/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/static/' & $
             tracer_skillscore_gloCLASS4_supobs_GODAE_CLIM,modele,fichier,fichier_mask4,filelist,var1,var2, $
                                                        profondeur,variable_name_type,zone,kind,dirin,date_title, $
                                                        tab_prof,tab_model,tab_e3t                                          & $
           END                   & $
     'PSAL' : BEGIN                  & $
             print,'PSAL'         & $
             dirname_out=fic_out_card+"T_S/"+datetrim+"/skill/" & $
             fichier_mask4='mask_bins4deg.nc'  & $
             fichier=filelist(0)  & $
             tracer_skillscore_gloCLASS4_supobs_GODAE,modele,fichier,fichier_mask4,filelist,var1,var2, $   
                                                        profondeur,variable_name_type,zone,kind,dirin,date_title, $
                                  			     tab_prof,tab_model,tab_e3t  & $
             fichier_mask4='mask_bins4deg.nc'  & $
             fichier=filelist(0)  & $
             dirin=dir_input & $
             dir_mask='/home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/static/' & $
             tracer_skillscore_gloCLASS4_supobs_GODAE_CLIM,modele,fichier,fichier_mask4,filelist,var1,var2, $
                                                     profondeur,variable_name_type,zone,kind,dirin,date_title, $
                                                     tab_prof,tab_model,tab_e3t                                          & $
           END       & $
     'SLA' : BEGIN     & $
             profondeur(0)='' & $
             print,variable         & $
             dirname_out=fic_out_card+"SLA/"+datetrim+"/skill/" & $
             fichier_mask4='mask_bins4deg.nc'  & $
             fichier=filelist(0)  & $
   	     tracer_skillscore_gloCLASS4_supobs_GODAE_2D,modele,fichier,fichier_mask4,filelist, $
                                                           var1,var2,variable_name,               $
                                                           zone,kind,dirin,date_title   & $
           END                   & $
     'SST' : BEGIN                  & $
             profondeur(0)='' & $
             print,variable         & $
             dirname_out=fic_out_card+"SST/"+datetrim+"/skill/" & $
             fichier_mask4='mask_bins4deg.nc'  & $
             fichier=filelist(0)  & $
   	     tracer_skillscore_gloCLASS4_supobs_GODAE_2D,modele,fichier,fichier_mask4,filelist, $
                                                           var1,var2,variable_name,               $
                                                           zone,kind,dirin,date_title  & $
           END                & $
   ENDCASE
ENDFOR
END
