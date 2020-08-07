PRO tracer_stats_MLD_CLASS4,modele,fichier,fic_mask,filelist,$
                                   var1,var2,variable,$
                                   liste_zone,kind,dir_stats,OPER,date_title

;==========================================================================
;##  Trace des statistiques de la MLD pour les fichers class4
;    pour un paramètre donné 
;    author: C REGNIER Aout 2012
;=========================================================================
@param
@param_class4


  file2=fic_mask
  file=fichier

;;-------------------------------------------------
;; Lecture du fichier mask et boite
;;-------------------------------------------------
  print,'Mask::',dir_mask
  lon=ncdf_lec(file2,iodir=dir_mask,var='longitude', /nostruct) & lon=transpose(lon)
  lat=ncdf_lec(file2,iodir=dir_mask,var='latitude', /nostruct) & lat=transpose(lat)
  field1=ncdf_lec(file2,iodir=dir_mask,var='mask', /nostruct)& field1=transpose(field1)
  boite=ncdf_lec(file,iodir=dir_stats,var='box', /nostruct) & boite=transpose(boite)
  il_nlon=N_ELEMENTS(lon(1,*))
  il_nlat=N_ELEMENTS(lat(*,1))
  il_nbox=N_ELEMENTS(boite)	  
  i1=N_ELEMENTS(field1(1,*))
  i2=N_ELEMENTS(field1(*,1))
  nfichiers=N_ELEMENTS(filelist)
  ;; recentrage
  lat=lat-1
  lon=lon+1
;;-------------------------------------------------
;; Liste de modeles en fonction de la zone
;;--------------------------------------------------
  model_name=modele

FOR ind2=0,N_ELEMENTS(liste_zone)-1 DO BEGIN
  PRINT,'choix, ZONE :: ',liste_zone(ind2)
  zone=liste_zone(ind2)
  print,zone
  CASE zone OF
     'A':BEGIN
        print,'Zone Atlantique'
        dom='zoom NATL12 1/12 mercator'
	namezone='NAT' 
     ENDCASE
     'P':BEGIN
        dom='zoom  Pacific 1/12 mercator'
     ENDCASE
     'I':BEGIN
        dom='zoom Indian 1/12 mercator'
     ENDCASE
     'MED':BEGIN
        zone='A'
        dom='zoom Medit 1/12'
     ENDCASE
     'gulf stream':BEGIN
        dom='zoom NATL12 1/12 mercator'
     ENDCASE
     'JAP': BEGIN
        dom='zoom BIG_JAPAN 1/4 mercator'
     ENDCASE
     'T':BEGIN
        if ( modele eq "PSY2V3R1" )  THEN BEGIN
           dom='zoom NATL12 1/12 mercator'
        endif else begin
                                ;   dom='zoom global 1/4 mercator'
           dom='zoom ORCA 1/4 mercator hires'
        endelse
	namezone='GLO' 
    ENDCASE
     'N':BEGIN
        dom='zoom AZORES 1/4 mercator'
     ENDCASE
     ELSE:
  ENDCASE

;;------------------------------------------------------------------
;; Boucle sur la liste des modeles en fonction de la zone choisie
;;------------------------------------------------------------------


  ;** Allocate tab
  MLD_insitu_cumul=dblarr(26,il_nbox,nfichiers)
  MLD_model_cumul=dblarr(26,il_nbox,nfichiers)
  MLP_insitu_cumul=dblarr(26,il_nbox,nfichiers)
  MLP_model_cumul=dblarr(26,il_nbox,nfichiers)

  nb_val_mod_cumul=intarr(26,il_nbox,nfichiers)
  nb_val_data_cumul=intarr(26,il_nbox,nfichiers)
  nb_val_mod_cumul_MLP=intarr(26,il_nbox,nfichiers)
  nb_val_data_cumul_MLP=intarr(26,il_nbox,nfichiers)

  mean_cumul_MLDlayer_insitu=dblarr(26,il_nbox,nfichiers)	
  rms_cumul_MLDlayer_insitu=dblarr(26,il_nbox,nfichiers)
  mean_cumul_MLPlayer_insitu=dblarr(26,il_nbox,nfichiers)	
  rms_cumul_MLPlayer_insitu=dblarr(26,il_nbox,nfichiers)
  
  mean_cumul_MLDlayer_mod=dblarr(26,il_nbox,nfichiers)
  rms_cumul_MLDlayer_mod=dblarr(26,il_nbox,nfichiers)
  mean_cumul_MLPlayer_mod=dblarr(26,il_nbox,nfichiers)
  rms_cumul_MLPlayer_mod=dblarr(26,il_nbox,nfichiers)

  nb_val_mod_MLD_cumul=intarr(26,il_nbox,nfichiers)
  nb_val_data_MLD_cumul=dblarr(26,il_nbox,nfichiers)			
  nb_val_mod_MLP_cumul=intarr(26,il_nbox,nfichiers)
  nb_val_data_MLP_cumul=dblarr(26,il_nbox,nfichiers)			

  Diff_MLD_tot=dblarr(26,il_nbox,nfichiers)
  Diff_MLD_error_tot=dblarr(26,il_nbox,nfichiers)
  Diff_MLD_sum_tot=intarr(26,il_nbox,nfichiers)
  Diff_MLP_tot=dblarr(26,il_nbox,nfichiers)
  Diff_MLP_error_tot=dblarr(26,il_nbox,nfichiers)
  Diff_MLP_sum_tot=intarr(26,il_nbox,nfichiers)
  
;; Lecture de mean et rms 
  i=0L
  while i le nfichiers-1 do begin 
     file=filelist(i)
     print,'file : ',file
     MLD_insitu=ncdf_lec(file,iodir=dir_stats,var='MLD_data_cumul', /nostruct) & MLD_insitu=transpose(MLD_insitu)
     MLD_insitu_cumul(*,*,i)=MLD_insitu
     MLP_insitu=ncdf_lec(file,iodir=dir_stats,var='MLP_data_cumul', /nostruct) & MLP_insitu=transpose(MLP_insitu)
     MLP_insitu_cumul(*,*,i)=MLP_insitu
     MLD_model=ncdf_lec(file,iodir=dir_stats,var='MLD_mod_cumul', /nostruct) & MLD_model=transpose(MLD_model)
     MLD_model_cumul(*,*,i)=MLD_model
     MLP_model=ncdf_lec(file,iodir=dir_stats,var='MLP_mod_cumul', /nostruct) & MLP_model=transpose(MLP_model)
     MLP_model_cumul(*,*,i)=MLP_model
     nb_val_data=ncdf_lec(file,iodir=dir_stats,var='nb_MLD_data_cumul', /nostruct) & nb_val_data=transpose(nb_val_data)
     nb_val_data_cumul(*,*,i)=nb_val_data
     nb_val_data_MLP=ncdf_lec(file,iodir=dir_stats,var='nb_MLP_data_cumul', /nostruct) & nb_val_data_MLP=transpose(nb_val_data_MLP)
     nb_val_data_cumul_MLP(*,*,i)=nb_val_data_MLP
     nb_val_mod=ncdf_lec(file,iodir=dir_stats,var='nb_MLD_mod_cumul', /nostruct) & nb_val_mod=transpose(nb_val_mod)
     nb_val_mod_cumul(*,*,i)=nb_val_mod
     nb_val_mod_MLP=ncdf_lec(file,iodir=dir_stats,var='nb_MLP_mod_cumul', /nostruct) & nb_val_mod_MLP=transpose(nb_val_mod_MLP)
     nb_val_mod_cumul_MLP(*,*,i)=nb_val_mod_MLP
     mean_MLDlayer_insitu=ncdf_lec(file,iodir=dir_stats,var='mean_cumul_MLDlayer_insitu', /nostruct) & mean_MLDlayer_insitu =transpose(mean_MLDlayer_insitu)
     mean_cumul_MLDlayer_insitu(*,*,i)=mean_MLDlayer_insitu
     rms_MLDlayer_insitu=ncdf_lec(file,iodir=dir_stats,var='rms_cumul_MLDlayer_insitu', /nostruct) & rms_MLDlayer_insitu =transpose(rms_MLDlayer_insitu)
     rms_cumul_MLDlayer_insitu(*,*,i)=rms_MLDlayer_insitu
     mean_MLPlayer_insitu=ncdf_lec(file,iodir=dir_stats,var='mean_cumul_MLPlayer_insitu', /nostruct) & mean_MLPlayer_insitu =transpose(mean_MLPlayer_insitu)
     mean_cumul_MLPlayer_insitu(*,*,i)=mean_MLPlayer_insitu
     rms_MLPlayer_insitu=ncdf_lec(file,iodir=dir_stats,var='rms_cumul_MLPlayer_insitu', /nostruct) & rms_MLPlayer_insitu =transpose(rms_MLPlayer_insitu)
     rms_cumul_MLPlayer_insitu(*,*,i)=rms_MLPlayer_insitu

     mean_MLDlayer_mod=ncdf_lec(file,iodir=dir_stats,var='mean_cumul_MLDlayer_mod', /nostruct) & mean_MLDlayer_mod =transpose(mean_MLDlayer_mod)
     mean_cumul_MLDlayer_mod(*,*,i)=mean_MLDlayer_mod
     mean_MLPlayer_mod=ncdf_lec(file,iodir=dir_stats,var='mean_cumul_MLPlayer_mod', /nostruct) & mean_MLPlayer_mod =transpose(mean_MLPlayer_mod)
     mean_cumul_MLPlayer_mod(*,*,i)=mean_MLPlayer_mod
     rms_MLDlayer_mod=ncdf_lec(file,iodir=dir_stats,var='rms_cumul_MLDlayer_mod', /nostruct) & rms_MLDlayer_mod =transpose(rms_MLDlayer_mod)
     rms_cumul_MLDlayer_mod(*,*,i)=rms_MLDlayer_mod
     rms_MLPlayer_mod=ncdf_lec(file,iodir=dir_stats,var='rms_cumul_MLPlayer_mod', /nostruct) & rms_MLPlayer_mod =transpose(rms_MLPlayer_mod)
     rms_cumul_MLPlayer_mod(*,*,i)=rms_MLPlayer_mod
     nbval_cumul_MLDlayer_data=ncdf_lec(file,iodir=dir_stats,var='nbval_cumul_MLDlayer_data', /nostruct) & nbval_cumul_MLDlayer_data=transpose(nbval_cumul_MLDlayer_data)	
     nb_val_data_MLD_cumul(*,*,i)=nbval_cumul_MLDlayer_data
     nbval_cumul_MLPlayer_data=ncdf_lec(file,iodir=dir_stats,var='nbval_cumul_MLPlayer_data', /nostruct) & nbval_cumul_MLPlayer_data=transpose(nbval_cumul_MLPlayer_data)	
     nb_val_data_MLP_cumul(*,*,i)=nbval_cumul_MLPlayer_data
     nbval_cumul_MLDlayer_mod=ncdf_lec(file,iodir=dir_stats,var='nbval_cumul_MLDlayer_mod', /nostruct) & nbval_cumul_MLDlayer_mod=transpose(nbval_cumul_MLDlayer_mod)
     nb_val_mod_MLD_cumul(*,*,i)=nbval_cumul_MLDlayer_mod
     nbval_cumul_MLPlayer_mod=ncdf_lec(file,iodir=dir_stats,var='nbval_cumul_MLPlayer_mod', /nostruct) & nbval_cumul_MLPlayer_mod=transpose(nbval_cumul_MLPlayer_mod)
     nb_val_mod_MLP_cumul(*,*,i)=nbval_cumul_MLPlayer_mod
     Diff_MLD=ncdf_lec(file,iodir=dir_stats,var='Diff_MLD_cumul', /nostruct) & Diff_MLD=transpose(Diff_MLD)
     Diff_MLD_tot(*,*,i)=Diff_MLD	  
     Diff_MLP=ncdf_lec(file,iodir=dir_stats,var='Diff_MLP_cumul', /nostruct) & Diff_MLP=transpose(Diff_MLP)
     Diff_MLP_tot(*,*,i)=Diff_MLP	  
     Diff_MLD_error=ncdf_lec(file,iodir=dir_stats,var='Diff_MLD_error_cumul' , /nostruct) & Diff_MLD_error=transpose(Diff_MLD_error)
     Diff_MLD_error_tot(*,*,i)=Diff_MLD_error
     Diff_MLP_error=ncdf_lec(file,iodir=dir_stats,var='Diff_MLP_error_cumul' , /nostruct) & Diff_MLP_error=transpose(Diff_MLP_error)
     Diff_MLP_error_tot(*,*,i)=Diff_MLP_error
     Diff_MLD_sum=ncdf_lec(file,iodir=dir_stats,var='Diff_MLD_sum', /nostruct) & Diff_MLD_sum=transpose(Diff_MLD_sum)
     Diff_MLD_sum_tot(*,*,i)=Diff_MLD_sum
     Diff_MLP_sum=ncdf_lec(file,iodir=dir_stats,var='Diff_MLP_sum', /nostruct) & Diff_MLP_sum=transpose(Diff_MLP_sum)
     Diff_MLP_sum_tot(*,*,i)=Diff_MLP_sum
     
     clear,MLD_insitu,MLD_model,nb_val_data,nb_val_mod
     clear,MLP_insitu,MLP_model,nb_val_data_MLP,nb_val_mod_MLP
     clear,mean_MLDlayer_insitu,rms_MLDlayer_insitu
     clear,mean_MLPlayer_insitu,rms_MLPlayer_insitu
     clear,mean_MLDlayer_mod,rms_MLDlayer_mod,nbval_cumul_MLDlayer_data
     clear,mean_MLPlayer_mod,rms_MLPlayer_mod,nbval_cumul_MLPlayer_data
     clear,nbval_cumul_MLDlayer_mod,Diff_MLD,Diff_MLD_error,Diff_MLD_sum
     clear,nbval_cumul_MLPlayer_mod,Diff_MLP,Diff_MLP_error,Diff_MLP_sum
     i=i+1
  endwhile
  print, "Creation liste ok"

;;-----------------------------------------------------------------------------------------
;; Boucle sur les variables
;;------------------------------------------------------------------------------------------
  FOR var=var1,var2  DO BEGIN
     
;; Test si la variable est la temperature ou la salinité
;; Paire :: temperature, impaire : salinité
     test_pair=var mod 2
     IF test_pair EQ 0 THEN BEGIN
        indice_var=0
        IF modele EQ 'WOA05' THEN BEGIN
           parametre='TEMPLEV'
        ENDIF ELSE BEGIN 
           parametre='TEMP'
        ENDELSE
        print,'Variable temperature'
     ENDIF ELSE BEGIN
        indice_var=1
        print,'Variable salinité'
        IF modele EQ 'WOA05' THEN BEGIN
           parametre='SALLEV'
        ENDIF ELSE BEGIN 
           parametre='SAL'
        ENDELSE
     ENDELSE
     
     nom_var=variable(var)
     print,nom_var
     STOP     
     IF ( OPER eq "NO" )  THEN BEGIN
        CASE nom_var OF
           'FSTGS_TEMP' :  GOTO, label
           'FSTGS_PSAL' :  GOTO, label       	
           'PERS3D_TEMP':  GOTO, label
           'PERS3D_PSAL':  GOTO, label
           'PERS6D_TEMP':  GOTO, label
           'PERS6D_PSAL':  GOTO, label
           'PERS_TEMP':  GOTO, label
           'PERS_PSAL':  GOTO, label
           'FRCST3D_PSAL':  GOTO, label	              
           'FRCST3D_TEMP':  GOTO, label
           'FRCST6D_PSAL':  GOTO, label	              
           'FRCST6D_TEMP':  GOTO, label
           'ANA_PSAL':  GOTO, label	              
           'ANA_TEMP':  GOTO, label
           'SMLEV09'     :  GOTO, label
           'TMLEV09'     :  GOTO, label
           ELSE: PRINT, 'nom_var',nom_var  
        ENDCASE
     ENDIF ELSE BEGIN
        CASE nom_var OF
           'FSTGS_TEMP' :  GOTO, label
           'FSTGS_PSAL' :  GOTO, label        
           'PERS_TEMP':  GOTO, label
           'PERS_PSAL':  GOTO, label
           'PERS3D_TEMP':  GOTO, label
           'PERS3D_PSAL':  GOTO, label
           'PERS6D_TEMP':  GOTO, label
           'PERS6D_PSAL':  GOTO, label
                                ; 'SMLEV'     :  GOTO, label
           ;; 'TMLEV'     :  GOTO, label
           'FRCST1D_TEMP' :  GOTO, label
           'FRCST1D_PSAL' :  GOTO, label
           'FRCST5D_TEMP' :  GOTO, label
           'FRCST5D_PSAL' :  GOTO, label
           ELSE: PRINT, 'nom_var',nom_var  
        ENDCASE
     ENDELSE
     CASE nom_var OF
        'HDCST_TEMP' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='hindcast'
        ENDCASE
        'HDCST_PSAL' : BEGIN 
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='hindcast'
        ENDCASE
        'ANA_TEMP' : BEGIN	
           varname='temperature'
           varname_title='T'
           varname_title='S'
           xxl='DegC'
           type_obs='nowcast'
        ENDCASE
        'ANA_PSAL' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='nowcast'
        ENDCASE
        'PERS_TEMP' : BEGIN	
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='persistence'
        ENDCASE
        'PERS_PSAL' : BEGIN	
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='persistence'
        ENDCASE
        'FRCST1D_TEMP' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='forecast1Day'
        ENDCASE	       
        'FRCST1D_PSAL' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='forecast1Day'
        ENDCASE	       
        'FRCST3D_TEMP' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='forecast3Day'
        ENDCASE	       
        'FRCST3D_PSAL' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='forecast3Day'
        ENDCASE	       
        'FRCST5D_TEMP' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='forecast5Day'
        ENDCASE	       
        'FRCST5D_PSAL' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='forecast5Day'
        ENDCASE	       
        'FRCST6D_TEMP' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='forecast6Day'
        ENDCASE	       
        'FRCST6D_PSAL' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='forecast6Day'
        ENDCASE	       
        'TMARV' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='Clim_ARIVO'
        ENDCASE	       
        'SMARV' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='Clim_ARIVO'
        ENDCASE	       
        'TMLEV' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='Clim_WOA05'
        ENDCASE	       
        'SMLEV' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='Clim_WOA05'
        ENDCASE	       
        'TMLEV09' : BEGIN
           varname='temperature'
           varname_title='T'
           xxl='DegC'
           type_obs='Clim_WOA09'
        ENDCASE	       
        'SMLEV09' : BEGIN
           varname='salinity'
           varname_title='S'
           xxl='PSU'
           type_obs='Clim_WOA09'
        ENDCASE	       
        ELSE:
     ENDCASE

     clear,val_rms,val_ind,val1_insitu,val2_insitu,val1_mod,val2_mod,val_mean           
     val_rms_insitu=fltarr(il_nlat,il_nlon)
     val_rms_insitu_MLP=fltarr(il_nlat,il_nlon)
     val_mean_insitu=fltarr(il_nlat,il_nlon)
     val_mean_insitu_MLP=fltarr(il_nlat,il_nlon)
     val_rms_mod=fltarr(il_nlat,il_nlon)
     val_rms_mod_MLP=fltarr(il_nlat,il_nlon)    
     val_mean_mod=fltarr(il_nlat,il_nlon)
     val_mean_mod_MLP=fltarr(il_nlat,il_nlon)
     val1_insitu=fltarr(il_nlat,il_nlon)
     val1_insitu_MLP=fltarr(il_nlat,il_nlon)
     val2_insitu=fltarr(il_nlat,il_nlon)
     val2_insitu_MLP=fltarr(il_nlat,il_nlon)
     val1_mod=fltarr(il_nlat,il_nlon)
     val1_mod_MLP=fltarr(il_nlat,il_nlon)
     val2_mod=fltarr(il_nlat,il_nlon)
     val2_mod_MLP=fltarr(il_nlat,il_nlon)
     Difference_MLD=fltarr(il_nlat,il_nlon)
     Difference_MLD_error=fltarr(il_nlat,il_nlon)
     Difference_MLP=fltarr(il_nlat,il_nlon)
     Difference_MLP_error=fltarr(il_nlat,il_nlon)
     val_ind_insitu=fltarr(il_nlat,il_nlon)
     val_ind_insitu_MLP=fltarr(il_nlat,il_nlon)
     val_ind_mod=fltarr(il_nlat,il_nlon)
     val_ind_mod_MLP=fltarr(il_nlat,il_nlon)
     val_mld_insitu=fltarr(il_nlat,il_nlon)
     val_mlp_insitu=fltarr(il_nlat,il_nlon)
     val_mld_mod=fltarr(il_nlat,il_nlon)
     val_mlp_mod=fltarr(il_nlat,il_nlon)
     nb_val_MLD_insitu=fltarr(il_nlat,il_nlon)
     nb_val_MLP_insitu=fltarr(il_nlat,il_nlon)
     nb_val_MLD_mod=fltarr(il_nlat,il_nlon)
     nb_val_MLP_mod=fltarr(il_nlat,il_nlon)
     nb_val_MLD=fltarr(il_nlat,il_nlon)
     nb_val_MLP=fltarr(il_nlat,il_nlon)

     nbval1=fltarr(il_nlat,il_nlon)
     region=fltarr(il_nlat,il_nlon)

     ;; Initialisation
     val_rms_insitu(*,*)=!values.f_nan
     val_rms_insitu_MLP(*,*)=!values.f_nan
     val_mean_insitu(*,*)=!values.f_nan
     val_mean_insitu_MLP(*,*)=!values.f_nan
     val_rms_mod(*,*)=!values.f_nan
     val_rms_mod_MLP(*,*)=!values.f_nan
     val_mean_mod(*,*)=!values.f_nan
     val_mean_mod_MLP(*,*)=!values.f_nan
     val1_insitu(*,*)=!values.f_nan
     val1_insitu_MLP(*,*)=!values.f_nan
     val2_insitu(*,*)=!values.f_nan
     val2_insitu_MLP(*,*)=!values.f_nan
     val1_mod(*,*)=!values.f_nan
     val1_mod_MLP(*,*)=!values.f_nan
     val2_mod(*,*)=!values.f_nan
     val2_mod_MLP(*,*)=!values.f_nan
     Difference_MLD(*,*)=!values.f_nan
     Difference_MLD_error(*,*)=!values.f_nan
     Difference_MLP(*,*)=!values.f_nan
     Difference_MLP_error(*,*)=!values.f_nan
     val_ind_insitu(*,*)=!values.f_nan
     val_ind_insitu_MLP(*,*)=!values.f_nan
     val_ind_mod(*,*)=!values.f_nan
     val_ind_mod_MLP(*,*)=!values.f_nan
     val_mld_insitu(*,*)=!values.f_nan
     val_mlp_insitu(*,*)=!values.f_nan
     val_mld_mod(*,*)=!values.f_nan
     val_mlp_mod(*,*)=!values.f_nan
     nb_val_MLD(*,*)=!values.f_nan
     nb_val_MLP(*,*)=!values.f_nan
     nb_val_MLD_mod(*,*)=!values.f_nan	
     nb_val_MLP_mod(*,*)=!values.f_nan	
     nb_val_MLD_insitu(*,*)=!values.f_nan	
     nb_val_MLP_insitu(*,*)=!values.f_nan
     
     FOR il_ind1=0,il_nlon-1 DO BEGIN
        FOR il_ind2=0,il_nlat-1 DO BEGIN
           region(il_ind2,il_ind1)=field1(il_ind2,il_ind1)
           region2=WHERE(boite(*) EQ region(il_ind2,il_ind1))
           IF region2 NE -1 THEN BEGIN
              ;** Calcul de la rms et de la difference modèle-obs dans la couche de mélange calculée sur la MLD insitu
              val_ind_insitu(il_ind2,il_ind1)=TOTAL(nb_val_data_MLD_cumul(var,region2,*))
              val_rms_insitu(il_ind2,il_ind1)=TOTAL(rms_cumul_MLDlayer_insitu(var,region2,*))
              val_mean_insitu(il_ind2,il_ind1)=TOTAL(mean_cumul_MLDlayer_insitu(var,region2,*))
              IF  val_ind_insitu(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 val_ind_insitu(il_ind2,il_ind1)=!values.f_nan
                 val1_insitu(il_ind2,il_ind1)=!values.f_nan
                 val2_insitu(il_ind2,il_ind1)=!values.f_nan
              ENDIF	ELSE BEGIN
                 val1_insitu(il_ind2,il_ind1)=SQRT(val_rms_insitu(il_ind2,il_ind1)/val_ind_insitu(il_ind2,il_ind1))
                 val2_insitu(il_ind2,il_ind1)=val_mean_insitu(il_ind2,il_ind1)/val_ind_insitu(il_ind2,il_ind1)
              ENDELSE	
              ;** Calcul de la rms et de la difference modèle-obs dans la couche de mélange calculée sur la MLP insitu
              val_ind_insitu_MLP(il_ind2,il_ind1)=TOTAL(nb_val_data_MLP_cumul(var,region2,*))
              val_rms_insitu_MLP(il_ind2,il_ind1)=TOTAL(rms_cumul_MLPlayer_insitu(var,region2,*))
              val_mean_insitu_MLP(il_ind2,il_ind1)=TOTAL(mean_cumul_MLPlayer_insitu(var,region2,*))
              IF  val_ind_insitu_MLP(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 val_ind_insitu_MLP(il_ind2,il_ind1)=!values.f_nan
                 val1_insitu_MLP(il_ind2,il_ind1)=!values.f_nan
                 val2_insitu_MLP(il_ind2,il_ind1)=!values.f_nan
              ENDIF	ELSE BEGIN
                 val1_insitu_MLP(il_ind2,il_ind1)=SQRT(val_rms_insitu_MLP(il_ind2,il_ind1)/val_ind_insitu_MLP(il_ind2,il_ind1))
                 val2_insitu_MLP(il_ind2,il_ind1)=val_mean_insitu_MLP(il_ind2,il_ind1)/val_ind_insitu_MLP(il_ind2,il_ind1)
              ENDELSE	

              ;** Calcul de la rms et de la difference modèle-obs dans la couche de mélange calculée sur la MLD modèle
              val_rms_mod(il_ind2,il_ind1)=TOTAL(rms_cumul_MLDlayer_mod(var,region2,*))
              val_mean_mod(il_ind2,il_ind1)=TOTAL(mean_cumul_MLDlayer_mod(var,region2,*))
              val_ind_mod(il_ind2,il_ind1)=TOTAL(nb_val_mod_MLD_cumul(var,region2,*))
              IF  val_ind_mod(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 val_ind_mod(il_ind2,il_ind1)=!values.f_nan
                 val1_mod(il_ind2,il_ind1)=!values.f_nan	
                 val2_mod(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 val1_mod(il_ind2,il_ind1)=SQRT(val_rms_mod(il_ind2,il_ind1)/val_ind_mod(il_ind2,il_ind1))
                 val2_mod(il_ind2,il_ind1)=val_mean_mod(il_ind2,il_ind1)/val_ind_mod(il_ind2,il_ind1)
              ENDELSE	

              ;** Calcul de la rms et de la difference modèle-obs dans la couche de mélange calculée sur la MLP modèle
              val_rms_mod_MLP(il_ind2,il_ind1)=TOTAL(rms_cumul_MLPlayer_mod(var,region2,*))
              val_mean_mod_MLP(il_ind2,il_ind1)=TOTAL(mean_cumul_MLPlayer_mod(var,region2,*))
              val_ind_mod_MLP(il_ind2,il_ind1)=TOTAL(nb_val_mod_MLP_cumul(var,region2,*))
              IF  val_ind_mod_MLP(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 val_ind_mod_MLP(il_ind2,il_ind1)=!values.f_nan
                 val1_mod_MLP(il_ind2,il_ind1)=!values.f_nan	
                 val2_mod_MLP(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 val1_mod_MLP(il_ind2,il_ind1)=SQRT(val_rms_mod_MLP(il_ind2,il_ind1)/val_ind_mod_MLP(il_ind2,il_ind1))
                 val2_mod_MLP(il_ind2,il_ind1)=val_mean_mod_MLP(il_ind2,il_ind1)/val_ind_mod_MLP(il_ind2,il_ind1)
              ENDELSE	

              ;* Calcul de la valeur de la MLP insitu dans chaque boîte
              nb_val_MLP_insitu(il_ind2,il_ind1)=TOTAL(nb_val_data_cumul_MLP(var,region2,*))
              IF  nb_val_MLP_insitu(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 nb_val_MLP_insitu(il_ind2,il_ind1)=!values.f_nan
                 val_mlp_insitu(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 val_mlp_insitu(il_ind2,il_ind1)=TOTAL(MLP_insitu_cumul(var,region2,*))/nb_val_MLP_insitu(il_ind2,il_ind1)
              ENDELSE
              
                                ;* Calcul de la valeur de la MLD insitu dans chaque boîte
              nb_val_MLD_insitu(il_ind2,il_ind1)=TOTAL(nb_val_data_cumul(var,region2,*))
              IF  nb_val_MLD_insitu(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 nb_val_MLD_insitu(il_ind2,il_ind1)=!values.f_nan
                 val_mld_insitu(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 val_mld_insitu(il_ind2,il_ind1)=TOTAL(MLD_insitu_cumul(var,region2,*))/nb_val_MLD_insitu(il_ind2,il_ind1)
              ENDELSE
                                ;ii=where(FINITE(val_mld_insitu(il_ind2,il_ind1),/NAN) EQ 0)
                                ;IF (ii(0) NE -1) THEN BEGIN
                                ;  print,'nb_val_MLD_insitu :: ',nb_val_MLD_insitu(il_ind2,il_ind1)
                                ;  print,'val_mld_insitu  :: ',val_mld_insitu(il_ind2,il_ind1)
                                ;ENDIF

                                ;* Calcul de la valeur de la MLD modèle dans chaque boîte
              nb_val_MLD_mod(il_ind2,il_ind1)=TOTAL(nb_val_mod_cumul(var,region2,*))
              IF  nb_val_MLD_mod(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 nb_val_MLD_mod(il_ind2,il_ind1)=!values.f_nan
                 val_mld_mod(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 val_mld_mod(il_ind2,il_ind1)=TOTAL(MLD_model_cumul(var,region2,*))/nb_val_MLD_mod(il_ind2,il_ind1)
              ENDELSE
                                ;ii=where(FINITE(val_mld_mod(il_ind2,il_ind1),/NAN) EQ 0)
                                ;IF (ii(0) NE -1) THEN BEGIN 
                                ; print,'nb_val_MLD_mod :: ',nb_val_MLD_mod(il_ind2,il_ind1)
                                ; print,'val_mld_mod :: ',val_mld_mod(il_ind2,il_ind1)
                                ;ENDIF

                                ;* Calcul de la MLP modele dans chaque boite
              nb_val_MLP_mod(il_ind2,il_ind1)=TOTAL(nb_val_mod_cumul_MLP(var,region2,*))
              IF  nb_val_MLP_mod(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 nb_val_MLP_mod(il_ind2,il_ind1)=!values.f_nan
                 val_mlp_mod(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 val_mlp_mod(il_ind2,il_ind1)=TOTAL(MLP_model_cumul(var,region2,*))/nb_val_MLP_mod(il_ind2,il_ind1)
              ENDELSE

                                ;* Calcul de la différence et de l'erreur entre la MLD modèle et la MLD insitu
              nb_val_MLD(il_ind2,il_ind1)=TOTAL(Diff_MLD_sum_tot(var,region2,*))
              IF nb_val_MLD(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 nb_val_MLD(il_ind2,il_ind1)=!values.f_nan
                 Difference_MLD(il_ind2,il_ind1)=!values.f_nan
                 Difference_MLD_error(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 Difference_MLD(il_ind2,il_ind1)=TOTAL(Diff_MLD_tot(var,region2,*))/nb_val_MLD(il_ind2,il_ind1)
                 Difference_MLD_error(il_ind2,il_ind1)=TOTAL(Diff_MLD_error_tot(var,region2,*))/nb_val_MLD(il_ind2,il_ind1)
              ENDELSE
                                ;ii=where(FINITE(Difference_MLD(il_ind2,il_ind1),/NAN) EQ 0)
                                ;IF (ii(0) NE -1) THEN BEGIN
                                ; print,'nb_val_MLD :: ',nb_val_MLD(il_ind2,il_ind1)
                                ; print,'Difference_MLD :: ',Difference_MLD(il_ind2,il_ind1)
                                ;ENDIF
                                ;ii=where(FINITE(Difference_MLD(il_ind2,il_ind1),/NAN) EQ 1 AND FINITE(val_mld_mod(il_ind2,il_ind1),/NAN) EQ 0 AND FINITE(val_mld_insitu(il_ind2,il_ind1),/NAN) EQ 0)
              ;;ii=where(FINITE(val_mld_insitu(il_ind2,il_ind1),/NAN) EQ 0 AND FINITE(val_mld_mod(il_ind2,il_ind1),/NAN) EQ 1 )
              ii=where(FINITE(val_mld_mod(il_ind2,il_ind1),/NAN) EQ 0 AND FINITE(Difference_MLD(il_ind2,il_ind1),/NAN) EQ 1 )
                                ;  ii=where(FINITE(val_mld_insitu(il_ind2,il_ind1),/NAN) EQ 0 AND FINITE(Difference_MLD(il_ind2,il_ind1),/NAN) EQ 1 )
              ii=where(FINITE(val_mld_mod(il_ind2,il_ind1),/NAN) EQ 0 AND FINITE(nb_val_MLD_mod(il_ind2,il_ind1),/NAN) EQ 1 )
              IF (ii(0) NE -1) THEN BEGIN
                 print,'nb_val_MLD_mod :: ',nb_val_MLD_mod(il_ind2,il_ind1)
                 print,'val_mld_mod :: ',val_mld_mod(il_ind2,il_ind1)
                 ;;    print,'nb_val_MLD_insitu :: ',nb_val_MLD_insitu(il_ind2,il_ind1)
                 ;;     print,'val_mld_insitu  :: ',val_mld_insitu(il_ind2,il_ind1)
                 ;;    print,'nb_val_MLD :: ',nb_val_MLD(il_ind2,il_ind1)
                 print,'Difference_MLD :: ',Difference_MLD(il_ind2,il_ind1)
              ENDIF
                                ;* Calcul de la différence et de l'erreur entre la MLP modèle et la MLP insitu
              nb_val_MLP(il_ind2,il_ind1)=TOTAL(Diff_MLP_sum_tot(var,region2,*))
              IF nb_val_MLP(il_ind2,il_ind1) EQ 0 THEN BEGIN
                 nb_val_MLP(il_ind2,il_ind1)=!values.f_nan
                 Difference_MLP(il_ind2,il_ind1)=!values.f_nan
                 Difference_MLP_error(il_ind2,il_ind1)=!values.f_nan
              ENDIF ELSE BEGIN
                 Difference_MLP(il_ind2,il_ind1)=TOTAL(Diff_MLP_tot(var,region2,*))/nb_val_MLP(il_ind2,il_ind1)
                 Difference_MLP_error(il_ind2,il_ind1)=TOTAL(Diff_MLP_error_tot(var,region2,*))/nb_val_MLP(il_ind2,il_ind1)
              ENDELSE
              
           ENDIF ELSE BEGIN
              val1_insitu(il_ind2,il_ind1)=!values.f_nan
              val1_insitu_MLP(il_ind2,il_ind1)=!values.f_nan
              val2_insitu(il_ind2,il_ind1)=!values.f_nan
              val2_insitu_MLP(il_ind2,il_ind1)=!values.f_nan
              val_ind_insitu(il_ind2,il_ind1)=!values.f_nan
              val_ind_insitu_MLP(il_ind2,il_ind1)=!values.f_nan
              val1_mod(il_ind2,il_ind1)=!values.f_nan
              val1_mod_MLP(il_ind2,il_ind1)=!values.f_nan
              val2_mod(il_ind2,il_ind1)=!values.f_nan
              val2_mod_MLP(il_ind2,il_ind1)=!values.f_nan
              val_ind_mod(il_ind2,il_ind1)=!values.f_nan
              val_ind_mod_MLP(il_ind2,il_ind1)=!values.f_nan
              nb_val_MLD_insitu(il_ind2,il_ind1)=!values.f_nan
              nb_val_MLD_mod(il_ind2,il_ind1)=!values.f_nan
              nb_val_MLP_insitu(il_ind2,il_ind1)=!values.f_nan
              nb_val_MLP_mod(il_ind2,il_ind1)=!values.f_nan
              val_mld_insitu(il_ind2,il_ind1)=!values.f_nan
              val_mld_mod(il_ind2,il_ind1)=!values.f_nan
              val_mlp_insitu(il_ind2,il_ind1)=!values.f_nan
              val_mlp_mod(il_ind2,il_ind1)=!values.f_nan
              Difference_MLD(il_ind2,il_ind1)=!values.f_nan
              Difference_MLD_error(il_ind2,il_ind1)=!values.f_nan
              nb_val_MLD(il_ind2,il_ind1)=!values.f_nan
              nb_val_MLP(il_ind2,il_ind1)=!values.f_nan
              Difference_MLP(il_ind2,il_ind1)=!values.f_nan
              Difference_MLP_error(il_ind2,il_ind1)=!values.f_nan
           ENDELSE
        ENDFOR
     ENDFOR
;; Test               
     ii=where(FINITE(val_mld_insitu,/NAN) EQ 0)
     IF (ii(0) NE -1) THEN BEGIN
        print,'Nombre d éléments insitu :: ',N_ELEMENTS(ii)
     ENDIF
     ii2=where(FINITE(nb_val_MLD_insitu,/NAN) EQ 0)
     IF (ii2(0) NE -1) THEN BEGIN
        print,'Nombre d éléments nb insitu :: ',N_ELEMENTS(ii2)
     ENDIF
     ii=where(FINITE(val_mld_mod,/NAN) EQ 0)
     IF (ii(0) NE -1) THEN BEGIN
        print,'Nombre d éléments Modele :: ',N_ELEMENTS(ii)
     ENDIF
     ii2=where(FINITE(nb_val_MLD_mod,/NAN) EQ 0)
     IF (ii2(0) NE -1) THEN BEGIN
        print,'Nombre d éléments nb Modele :: ',N_ELEMENTS(ii2)
     ENDIF
     ii=where(FINITE(Difference_MLD,/NAN) EQ 0)
     IF (ii(0) NE -1) THEN BEGIN
        print,'Nombre d éléments diff :: ',N_ELEMENTS(ii)
     ENDIF
     ii2=where(FINITE(nb_val_MLD,/NAN) EQ 0)
     IF (ii2(0) NE -1) THEN BEGIN
        print,'Nombre d éléments nb  diff :: ',N_ELEMENTS(ii2)
     ENDIF
     nom_var=variable(var)


;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
     
     namezone=zone
     dom='zoom'+namezone+' 1/4 fancy' 
     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
     clear,ymin,ymax,xmin,xmax  ;,strmin,strmax
     output='screen gif'
     ;output='A3 ps'
     domain=dom
     clear,titre,units
     titre='('+type_obs+'-obs) RMS '+varname+' error inside observed MLD: ' +modele+' '+date_title
     units='Rms misfit'
     field=val1_insitu
     valcmax=MAX(field,/NaN)
     valcmin=MIN(field,/NaN)
     if ( indice_var EQ  1 ) THEN BEGIN 
                                ;kindchoice=kind 
        cmin=0. & cmax=0.5 & dc=0.01
     endif
     if ( indice_var EQ  0 ) THEN BEGIN 
                                ;  kindchoice=kind
        cmin=0. & cmax=2 & dc=0.05
     endif
     kindchoice='no_iso stddev UserLevels publi'
     palette='stddev'
     x1=lon
     x2=lat
     rms_diff1 =val1_insitu
     rms_diff2 =val1_insitu
     rms_diff3 =val1_insitu
     nb_val=val_ind_insitu
     ii=where(FINITE(nb_val,/NAN) EQ 0)
     nb_val2=nb_val(ii)
     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
     il_indice1=WHERE(nb_val GE p25 ) ;; 1
     rms_diff1(il_indice1)=!values.f_nan
     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
     rms_diff2(il_indice2)=!values.f_nan
     il_indice3=WHERE(nb_val LE p75 )
     rms_diff3(il_indice3)=!values.f_nan
     print,'percentile 25 ',p25
     print,'percentile 75 ',p75
     field(*,*)=!values.f_nan
     fmin=valcmin
     fmax=valcmax
     ishold=1
     ;name_out='RmsMisfit_Class4pcolor_'+modele+'_'+nom_var+'_MLD_insitu_'+zone+'_'+date_title
     name_out=modele+'_'+varname_title+'_'+nom_var+'_RmsMisfitMLDobs_'+namezone+'_'+date_title
     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
     pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
     pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
     pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1, DX2=1
     MAP_GRID, LABEL=1, LATS=lat,LATLAB=7, LONLAB=-2.5,LONDEL=2, LONS=lon, ORIENTATION=0,  color=black,  GLINETHICK=1,GLINESTYLE=0
     STOP

     black=  rgb2ind(256,000,000)
             CASE zone OF
        'A':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
           XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE
        'T':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
           XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1	
           le_sign='!9'+ STRING("308B) 
           XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
           !P.font=0	
           XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1	
           le_sign='!9'+ STRING("308B) 
           XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
           !P.font=0
           XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1	
           le_sign='!9'+ STRING("308B) 
           XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
        ENDCASE
        'N':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
           XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE 
        'JAP': BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE
        ELSE:
     ENDCASE
     ishold=1
     field(*,*)=!values.f_nan
     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
                                ; Sauvegarde de l'image obtenue
     ishold=0
     do_output,dirname_out+name_out
     subst_str,name_out, '-', '_'
     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
     SPAWN,'rm '+dirname_out+name_out+'.ps'
     
     clear,longitude2,latitude2
                                ;le_sign = '!3' + STRING(197B) + '!X' ;(to use octal notation)
     ;; Plot Mean DIFF 
     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
     clear,ymin,ymax,xmin,xmax,palette,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2 ;,strmin,strmax
                                ;output='gif'
     output='A3 ps'
     domain=dom
     clear,titre,units
     titre='('+type_obs+'-obs) MEAN '+varname+' error inside observed MLD : ' +modele+' '+date_title
     units='Mean Diff'
     field=val2_insitu
     valcmax=MAX(field,/NaN)
     valcmin=MIN(field,/NaN)
     if ( indice_var EQ  1 ) THEN BEGIN
        cmin=-0.5 & cmax=0.5 & dc=0.01
     endif
     if ( indice_var EQ  0 ) THEN BEGIN
        cmin=-1 & cmax=1 & dc=0.025
     endif
     kindchoice='unknown difference no_iso UserLevels publi' 
     palette='sla'
     units='Deg C'
     x1=lon
     x2=lat
     mean_diff1 =val2_insitu 
     mean_diff2 =val2_insitu
     mean_diff3 =val2_insitu
     nb_val=val_ind_insitu
     ii=where(FINITE(nb_val,/NAN) EQ 0)
     nb_val2=nb_val(ii)
     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) )
     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) )
     il_indice1=WHERE(nb_val GE p25 ) ;; 1
     mean_diff1(il_indice1)=!values.f_nan
     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
     mean_diff2(il_indice2)=!values.f_nan
     il_indice3=WHERE(nb_val LE p75 )
     mean_diff3(il_indice3)=!values.f_nan
     print,'percentile 25 ',p25
     print,'percentile 75 ',p75
     field(*,*)=!values.f_nan
     fmin=valcmin
     fmax=valcmax
     ishold=1
     name_out='MeanDiff_Class4pcolor_'+modele+'_'+nom_var+'_MLD_insitu_layer_'+zone+'_'+date_title
     name_out=modele+'_'+varname_title+'_'+nom_var+'_MeanDiffMLDobs_'+namezone+'_'+date_title
     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
     pcolor,mean_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25
     pcolor,mean_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
     pcolor,mean_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
     black=  rgb2ind(000,000,000)
     CASE zone OF
        'A':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE
        'T':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
           XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE
        'N':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
           XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE
        'JAP':BEGIN
           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
           !P.font=0
           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
           !P.font=0
           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
           DEVICE, SET_FONT='Symbol', /TT_FONT
           !P.font=1
           le_sign='!9'+ STRING("308B)
           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
        ENDCASE
        ELSE:
     ENDCASE
     ;; GIF output
     ;; XYOUTS,0.2,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
     ;; XYOUTS,0.015,0.08,['!9B!3'], /norm, alignment=1.0, CHARSIZE=1.5, COLOR=black
     ;; XYOUTS,0.2,0.06,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
     ;; XYOUTS,0.01,0.06,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black
     ;; XYOUTS,0.2,0.04,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
     ;; XYOUTS,0.01,0.04,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.25, COLOR=black
     ishold=1
     field(*,*)=!values.f_nan
     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
                                ; Sauvegarde de l'image obtenue
     ishold=0
     do_output,dirname_out+name_out
     subst_str,name_out, '-', '_'
     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
     SPAWN,'rm '+dirname_out+name_out+'.ps'
     clear,longitude2,latitude2

; Model
     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
     clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2 ;,strmin,strmax
     output=' screen gif'
;     output='A3 ps'
     domain=dom
     clear,titre,units
     titre='('+type_obs+'-obs) RMS '+varname+' error inside model MLD ' +modele+' '+date_title
     units='Rms misfit'
     field=val1_mod
     valcmax=MAX(field,/NaN)
     valcmin=MIN(field,/NaN)
     if ( indice_var EQ  1 ) THEN BEGIN 
                                ;kindchoice=kind 
        cmin=0. & cmax=0.5 & dc=0.01
     endif
     if ( indice_var EQ  0 ) THEN BEGIN 
                                ;  kindchoice=kind
        cmin=0. & cmax=2 & dc=0.05
     endif
     kindchoice='no_iso stddev UserLevels publi'
     palette='stddev'
     x1=lon
     x2=lat
     rms_diff1 =val1_mod 
     rms_diff2 =val1_mod
     rms_diff3 =val1_mod
     nb_val=val_ind_mod
     ii=where(FINITE(nb_val,/NAN) EQ 0)
     nb_val2=nb_val(ii)
     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
     il_indice1=WHERE(nb_val GE p25 ) ;; 1
     rms_diff1(il_indice1)=!values.f_nan
     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
     rms_diff2(il_indice2)=!values.f_nan
     il_indice3=WHERE(nb_val LE p75 )
     rms_diff3(il_indice3)=!values.f_nan
     print,'percentile 25 ',p25
     print,'percentile 75 ',p75
     field(*,*)=!values.f_nan
     fmin=valcmin
     fmax=valcmax
     ishold=1
     name_out='RmsMisfit_Class4pcolor_'+modele+'_'+nom_var+'_MLD_mod_'+zone+'_'+date_title
     name_out=modele+'_'+varname_title+'_'+nom_var+'_RmsMisfitMLDmod_'+namezone+'_'+date_title
     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
     pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
     pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
     pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.3, DX2=1.3
     black=  rgb2ind(000,000,000)
     MAP_GRID, LABEL=1, LATS=lat,LATLAB=7, LONLAB=-2.5, LONDEL=1, LONS=0, ORIENTATION=0,  color=black, GLINESTYLE=2
     STOP
     COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
     XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
     XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.0, COLOR=black,FONT=0
     DEVICE, SET_FONT='Symbol', /TT_FONT
     !P.font=1
     le_sign='!9'+ STRING("308B)
     XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
     !P.font=0
     XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.0, COLOR=black,FONT=0
     DEVICE, SET_FONT='Symbol', /TT_FONT
     !P.font=1
     le_sign='!9'+ STRING("308B)
     XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
     !P.font=0
     XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.0, COLOR=black,FONT=0
     DEVICE, SET_FONT='Symbol', /TT_FONT
     !P.font=1
     le_sign='!9'+ STRING("308B)
     XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
     ishold=1
     field(*,*)=!values.f_nan
     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
                                ; Sauvegarde de l'image obtenue
     ishold=0
     do_output,dirname_out+name_out
     subst_str,name_out, '-', '_'
     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
     SPAWN,'rm '+dirname_out+name_out+'.ps'
     
     clear,longitude2,latitude2
                                ;le_sign = '!3' + STRING(197B) + '!X' ;(to use octal notation)
;;     ;; Plot Mean DIFF 
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
;;     clear,ymin,ymax,xmin,xmax,palette,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2 ;,strmin,strmax
;;                                ;output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='('+type_obs+'-obs) MEAN '+varname+' error inside observed MLD : ' +modele+' '+date_title
;;     units='Mean Diff'
;;     field=val2_insitu
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     if ( indice_var EQ  1 ) THEN BEGIN
;;        cmin=-0.5 & cmax=0.5 & dc=0.01
;;     endif
;;     if ( indice_var EQ  0 ) THEN BEGIN
;;        cmin=-1 & cmax=1 & dc=0.025
;;     endif
;;     kindchoice='unknown difference no_iso UserLevels publi' 
;;     palette='sla'
;;     units='Deg C'
;;     x1=lon
;;     x2=lat
;;     mean_diff1 =val2_insitu 
;;     mean_diff2 =val2_insitu
;;     mean_diff3 =val2_insitu
;;     nb_val=val_ind_insitu
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     nb_val2=nb_val(ii)
;;     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) )
;;     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) )
;;     il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;     mean_diff1(il_indice1)=!values.f_nan
;;     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;     mean_diff2(il_indice2)=!values.f_nan
;;     il_indice3=WHERE(nb_val LE p75 )
;;     mean_diff3(il_indice3)=!values.f_nan
;;     print,'percentile 25 ',p25
;;     print,'percentile 75 ',p75
;;     field(*,*)=!values.f_nan
;;     fmin=valcmin
;;     fmax=valcmax
;;     ishold=1
;;     name_out='MeanDiff_Class4pcolor_'+modele+'_'+nom_var+'_MLD_insitu_layer_'+zone+'_'+date_title
;;     name_out=modele+'_'+varname_title+'_'+nom_var+'_MeanDiffMLDobs_'+namezone+'_'+date_title
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;     pcolor,mean_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25
;;     pcolor,mean_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;     pcolor,mean_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;     black=  rgb2ind(000,000,000)
;;     CASE zone OF
;;        'A':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        'T':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;           XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        'N':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;           XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        'JAP':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        ELSE:
;;     ENDCASE
;;     ;; GIF output
;;     ;; XYOUTS,0.2,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
;;     ;; XYOUTS,0.015,0.08,['!9B!3'], /norm, alignment=1.0, CHARSIZE=1.5, COLOR=black
;;     ;; XYOUTS,0.2,0.06,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
;;     ;; XYOUTS,0.01,0.06,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black
;;     ;; XYOUTS,0.2,0.04,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
;;     ;; XYOUTS,0.01,0.04,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.25, COLOR=black
;;     ishold=1
;;     field(*,*)=!values.f_nan
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;     ishold=0
;;     do_output,dirname_out+name_out
;;     subst_str,name_out, '-', '_'
;;     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;     SPAWN,'rm '+dirname_out+name_out+'.ps'
;;     clear,longitude2,latitude2
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;!!!  MLP RMS diff
;;;;;;;  insitu
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;     clear,ymin,ymax,xmin,xmax  ;,strmin,strmax
;;     output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='('+type_obs+'-obs) RMS '+varname+' error inside model MLP : ' +modele+' '+date_title
;;     units='Rms misfit'
;;     field=val1_insitu_MLP
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     if ( indice_var EQ  1 ) THEN BEGIN 
;;                                ;kindchoice=kind 
;;        cmin=0. & cmax=0.5 & dc=0.01
;;     endif
;;     if ( indice_var EQ  0 ) THEN BEGIN 
;;                                ;  kindchoice=kind
;;        cmin=0. & cmax=2 & dc=0.05
;;     endif
;;     kindchoice='no_iso stddev UserLevels publi'
;;     palette='stddev'
;;     x1=lon
;;     x2=lat
;;     rms_diff1 =field
;;     rms_diff2 =field
;;     rms_diff3 =field
;;     nb_val=val_ind_insitu_MLP
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     IF (ii(0) NE -1) THEN BEGIN
;;        nb_val2=nb_val(ii)
;;        p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;        p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;        il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;        rms_diff1(il_indice1)=!values.f_nan
;;        il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;        rms_diff2(il_indice2)=!values.f_nan
;;        il_indice3=WHERE(nb_val LE p75 )
;;        rms_diff3(il_indice3)=!values.f_nan
;;        print,'percentile 25 ',p25
;;        print,'percentile 75 ',p75
;;        field(*,*)=!values.f_nan
;;        fmin=valcmin
;;        fmax=valcmax
;;        ishold=1
;;        name_out='RmsMisfit_Class4pcolor_'+modele+'_'+nom_var+'_MLP_insitu_'+zone+'_'+date_title
;;        name_out=modele+'_'+varname_title+'_'+nom_var+'_RmsMisfitMLPobs_'+namezone+'_'+date_title
;;        plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;        pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;        pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;        pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;        black=  rgb2ind(000,000,000)
;;        CASE zone OF
;;           'A':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;              XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           'T':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;              XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1	
;;              le_sign='!9'+ STRING("308B) 
;;              XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;              !P.font=0	
;;              XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1	
;;              le_sign='!9'+ STRING("308B) 
;;              XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;              !P.font=0
;;              XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1	
;;              le_sign='!9'+ STRING("308B) 
;;              XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;           ENDCASE
;;           'N':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;              XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE 
;;           'JAP': BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;              XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           ELSE:
;;        ENDCASE
;;        ishold=1
;;        field(*,*)=!values.f_nan
;;        plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                   ; Sauvegarde de l'image obtenue
;;        ishold=0
;;        do_output,dirname_out+name_out
;;        subst_str,name_out, '-', '_'
;;        SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;        SPAWN,'rm '+dirname_out+name_out+'.ps'
;;     ENDIF 
;;     ;; Plot Mean DIFF 
;;     clear,longitude2,latitude2
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
;;     clear,ymin,ymax,xmin,xmax,palette,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2 ;,strmin,strmax
;;                                ;output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='('+type_obs+'-obs) MEAN '+varname+' error inside observed MLP: ' +modele+' '+date_title
;;     units='Mean Diff'
;;     field=val2_insitu_MLP
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     if ( indice_var EQ  1 ) THEN BEGIN
;;        cmin=-0.5 & cmax=0.5 & dc=0.01
;;     endif
;;     if ( indice_var EQ  0 ) THEN BEGIN
;;        cmin=-1 & cmax=1 & dc=0.025
;;     endif
;;     kindchoice='unknown difference no_iso UserLevels publi' 
;;     palette='sla'
;;     units='Deg C'
;;     x1=lon
;;     x2=lat
;;     mean_diff1 =field
;;     mean_diff2 =field
;;     mean_diff3 =field
;;     nb_val=val_ind_insitu_MLP
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     IF (ii(0) NE -1) THEN BEGIN
;;        nb_val2=nb_val(ii)
;;        p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) )
;;        p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) )
;;        il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;        mean_diff1(il_indice1)=!values.f_nan
;;        il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;        mean_diff2(il_indice2)=!values.f_nan
;;        il_indice3=WHERE(nb_val LE p75 )
;;        mean_diff3(il_indice3)=!values.f_nan
;;        print,'percentile 25 ',p25
;;        print,'percentile 75 ',p75
;;        field(*,*)=!values.f_nan
;;        fmin=valcmin
;;        fmax=valcmax
;;        ishold=1
;;        name_out='MeanDiff_Class4pcolor_'+modele+'_'+nom_var+'_MLP_insitu_layer_'+zone+'_'+date_title
;;        name_out=modele+'_'+varname_title+'_'+nom_var+'_MeanDiffMLPobs_'+namezone+'_'+date_title
;;        plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;        pcolor,mean_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25
;;        pcolor,mean_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;        pcolor,mean_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;        black=  rgb2ind(000,000,000)
;;        CASE zone OF
;;           'A':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;              XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           'T':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;              XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           'N':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;              XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           'JAP':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;              XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           ELSE:
;;        ENDCASE
;;        ;; GIF output
;;        ;; XYOUTS,0.2,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
;;        ;; XYOUTS,0.015,0.08,['!9B!3'], /norm, alignment=1.0, CHARSIZE=1.5, COLOR=black
;;        ;; XYOUTS,0.2,0.06,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
;;        ;; XYOUTS,0.01,0.06,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black
;;        ;; XYOUTS,0.2,0.04,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
;;        ;; XYOUTS,0.01,0.04,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.25, COLOR=black
;;        ishold=1
;;        field(*,*)=!values.f_nan
;;        plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                   ; Sauvegarde de l'image obtenue
;;        ishold=0
;;        do_output,dirname_out+name_out
;;        subst_str,name_out, '-', '_'
;;        SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;        SPAWN,'rm '+dirname_out+name_out+'.ps'
;;        clear,longitude2,latitude2
;;     ENDIF
;;;;;;;!!!!!!!!!!!!!!!!!!!!!!!!!!
;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;; Plot MLD Layer
;;     ;; insitu
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;     clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2
;;     clear,rms_diff3,nb_val,nb_val2 
;;     output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='MLD observed '+date_title
;;     units='m'
;;     field=val_mld_insitu
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     cmin=0. & cmax=500. & dc=10.
;;     xxl='m'
;;     kindchoice='no_iso mld UserLevels publi'
;;     palette='mld'
;;     x1=lon
;;     x2=lat
;;     rms_diff1=val_mld_insitu
;;     rms_diff2=val_mld_insitu
;;     rms_diff3=val_mld_insitu
;;     nb_val=nb_val_MLD_insitu
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     nb_val2=nb_val(ii)
;;     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;     il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;     rms_diff1(il_indice1)=!values.f_nan
;;     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;     rms_diff2(il_indice2)=!values.f_nan
;;     il_indice3=WHERE(nb_val LE p75 )
;;     rms_diff3(il_indice3)=!values.f_nan
;;     print,'percentile 25 ',p25
;;     print,'percentile 75 ',p75
;;     field(*,*)=!values.f_nan
;;     fmin=valcmin
;;     fmax=valcmax
;;     ishold=1
;;     name_out='MLD_insitu_Class4pcolor_'+modele+'_'+nom_var+'_'+zone+'_'+date_title
;;     name_out=modele+'_'+nom_var+'_MLDobs_'+namezone+'_'+date_title
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;     pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;     pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;     pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;     black=  rgb2ind(000,000,000)
;;     CASE zone OF
;;        'A':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;           XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        'T':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;           XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;           !P.font=0	
;;           XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;           !P.font=0
;;           XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;        ENDCASE
;;        'N':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;           XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE 
;;        'JAP': BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        ELSE:
;;     ENDCASE
;;     ishold=1
;;     field(*,*)=!values.f_nan
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;     ishold=0
;;     do_output,dirname_out+name_out
;;     subst_str,name_out, '-', '_'
;;     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;     SPAWN,'rm '+dirname_out+name_out+'.ps'
;;;; Difference MLD
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;     clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2
;;     output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='('+type_obs+'-obs) MLD differences '+varname+' '+date_title
;;                                ;titre='MLD differences '+date_title
;;     units='m'
;;     field=Difference_MLD
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     cmin=-100. & cmax=100. & dc=5.
;;     kindchoice='no_iso unknown difference UserLevels publi'
;;     xxl='m'
;;     x1=lon
;;     x2=lat
;;     rms_diff1=Difference_MLD
;;     rms_diff2=Difference_MLD
;;     rms_diff3=Difference_MLD
;;     nb_val=nb_val_MLD
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     nb_val2=nb_val(ii)
;;     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;     il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;     rms_diff1(il_indice1)=!values.f_nan
;;     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;     rms_diff2(il_indice2)=!values.f_nan
;;     il_indice3=WHERE(nb_val LE p75 )
;;     rms_diff3(il_indice3)=!values.f_nan
;;     print,'percentile 25 ',p25
;;     print,'percentile 75 ',p75
;;     field(*,*)=!values.f_nan
;;     fmin=valcmin
;;     fmax=valcmax
;;     ishold=1
;;     name_out='MLD_Diff_Class4pcolor_'+modele+'_'+nom_var+'_'+zone+'_'+date_title
;;     name_out=modele+'_'+nom_var+'_MLDdiff_'+namezone+'_'+date_title
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;     pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;     pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;     pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;     black=  rgb2ind(000,000,000)
;;     CASE zone OF
;;        'A':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;           XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        'T':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;           XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;           !P.font=0	
;;           XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;           !P.font=0
;;           XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;        ENDCASE
;;        'N':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;           XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE 
;;        'JAP': BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        ELSE:
;;     ENDCASE
;;     ishold=1
;;     field(*,*)=!values.f_nan
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;     ishold=0
;;     do_output,dirname_out+name_out
;;     subst_str,name_out, '-', '_'
;;     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;     SPAWN,'rm '+dirname_out+name_out+'.ps'
;;     ;;
;;     ;; MLD error
;;     ;;
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;     clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2
;;     output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='MLD errors '+date_title
;;     titre='('+type_obs+'-obs) MLD errors '+varname+' '+date_title
;;     units='m'
;;     field=Difference_MLD_error
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     cmin=-100 & cmax=100 & dc=5.
;;     kindchoice='no_iso unknown difference UserLevels publi'
;;     xxl='m'
;;     x1=lon
;;     x2=lat
;;     rms_diff1=Difference_MLD_error
;;     rms_diff2=Difference_MLD_error
;;     rms_diff3=Difference_MLD_error
;;     ii=WHERE( nb_val_MLD EQ 0 ) 
;;     IF (ii(0) NE -1) THEN nb_val_MLD(ii)=!values.f_nan
;;     nb_val=nb_val_MLD
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     nb_val2=nb_val(ii)
;;     p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;     p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;     il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;     rms_diff1(il_indice1)=!values.f_nan
;;     il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;     rms_diff2(il_indice2)=!values.f_nan
;;     il_indice3=WHERE(nb_val LE p75 )
;;     rms_diff3(il_indice3)=!values.f_nan
;;     print,'percentile 25 ',p25
;;     print,'percentile 75 ',p75
;;     field(*,*)=!values.f_nan
;;     fmin=valcmin
;;     fmax=valcmax
;;     ishold=1
;;     name_out='MLD_error_Class4pcolor_'+modele+'_'+nom_var+'_'+zone+'_'+date_title
;;     name_out=modele+'_'+nom_var+'_MLDerr_'+namezone+'_'+date_title
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;     pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;     pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;     pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;     black=  rgb2ind(000,000,000)
;;     CASE zone OF
;;        'A':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;           XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        'T':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;           XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;           !P.font=0	
;;           XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;           !P.font=0
;;           XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1	
;;           le_sign='!9'+ STRING("308B) 
;;           XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;        ENDCASE
;;        'N':BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;           XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE 
;;        'JAP': BEGIN
;;           COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;           XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;           XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;           !P.font=0
;;           XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;           DEVICE, SET_FONT='Symbol', /TT_FONT
;;           !P.font=1
;;           le_sign='!9'+ STRING("308B)
;;           XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;        ENDCASE
;;        ELSE:
;;     ENDCASE
;;     ishold=1
;;     field(*,*)=!values.f_nan
;;     plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;     ishold=0
;;     do_output,dirname_out+name_out
;;     subst_str,name_out, '-', '_'
;;     SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;     SPAWN,'rm '+dirname_out+name_out+'.ps'
;;
;;
;;;; Plot MLP Layer
;;     ;; insitu
;;     clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;     clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2
;;     clear,rms_diff3,nb_val,nb_val2 
;;     output='gif'
;;     output='A3 ps'
;;     domain=dom
;;     clear,titre,units
;;     titre='MLP observed '+date_title
;;     units='m'
;;     field=val_mlp_insitu
;;     valcmax=MAX(field,/NaN)
;;     valcmin=MIN(field,/NaN)
;;     cmin=0. & cmax=500. & dc=10.
;;     xxl='m'
;;     kindchoice='no_iso mld UserLevels publi'
;;     palette='mld'
;;     x1=lon
;;     x2=lat
;;     rms_diff1=field
;;     rms_diff2=field
;;     rms_diff3=field
;;     nb_val=nb_val_MLP_insitu
;;     ii=where(FINITE(nb_val,/NAN) EQ 0)
;;     IF (ii(0)  NE -1) THEN BEGIN
;;        nb_val2=nb_val(ii)
;;        p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;        p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;        il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;        rms_diff1(il_indice1)=!values.f_nan
;;        il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;        rms_diff2(il_indice2)=!values.f_nan
;;        il_indice3=WHERE(nb_val LE p75 )
;;        rms_diff3(il_indice3)=!values.f_nan
;;        print,'percentile 25 ',p25
;;        print,'percentile 75 ',p75
;;        field(*,*)=!values.f_nan
;;        fmin=valcmin
;;        fmax=valcmax
;;        ishold=1
;;        name_out='MLP_insitu_Class4pcolor_'+modele+'_'+nom_var+'_'+zone+'_'+date_title
;;        name_out=modele+'_'+nom_var+'_MLPobs_'+namezone+'_'+date_title
;;        plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;        pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;        pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;        pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;        black=  rgb2ind(000,000,000)
;;        CASE zone OF
;;           'A':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;              XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           'T':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;              XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1	
;;              le_sign='!9'+ STRING("308B) 
;;              XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;              !P.font=0	
;;              XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1	
;;              le_sign='!9'+ STRING("308B) 
;;              XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;              !P.font=0
;;              XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1	
;;              le_sign='!9'+ STRING("308B) 
;;              XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;           ENDCASE
;;           'N':BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;              XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE 
;;           'JAP': BEGIN
;;              COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;              XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;              XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;              !P.font=0
;;              XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;              DEVICE, SET_FONT='Symbol', /TT_FONT
;;              !P.font=1
;;              le_sign='!9'+ STRING("308B)
;;              XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;           ENDCASE
;;           ELSE:
;;        ENDCASE
;;        ishold=1
;;        field(*,*)=!values.f_nan
;;        plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;        ishold=0
;;        do_output,dirname_out+name_out
;;        subst_str,name_out, '-', '_'
;;        SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;        SPAWN,'rm '+dirname_out+name_out+'.ps'
;;     ENDIF
;;;; Difference MLP
;;        clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;        clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2
;;        output='gif'
;;        output='A3 ps'
;;        domain=dom
;;        clear,titre,units
;;        titre='('+type_obs+'-obs) MLP differences '+varname+' '+date_title
;;                                ;titre='MLP differences '+date_title
;;        units='m'
;;        field=Difference_MLP
;;        valcmax=MAX(field,/NaN)
;;        valcmin=MIN(field,/NaN)
;;        cmin=-100. & cmax=100. & dc=5.
;;        kindchoice='no_iso unknown difference UserLevels publi'
;;        xxl='m'
;;        x1=lon
;;        x2=lat
;;        rms_diff1=field 
;;        rms_diff2=field
;;        rms_diff3=field
;;        nb_val=nb_val_MLP
;;        ii=where(FINITE(nb_val,/NAN) EQ 0)
;;        IF (ii(0) NE -1) THEN BEGIN
;;           nb_val2=nb_val(ii)
;;           p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;           p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;           il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;           rms_diff1(il_indice1)=!values.f_nan
;;           il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;           rms_diff2(il_indice2)=!values.f_nan
;;           il_indice3=WHERE(nb_val LE p75 )
;;           rms_diff3(il_indice3)=!values.f_nan
;;           print,'percentile 25 ',p25
;;           print,'percentile 75 ',p75
;;           field(*,*)=!values.f_nan
;;           fmin=valcmin
;;           fmax=valcmax
;;           ishold=1
;;           name_out='MLP_Diff_Class4pcolor_'+modele+'_'+nom_var+'_'+zone+'_'+date_title
;;           name_out=modele+'_'+nom_var+'_MLPdiff_'+namezone+'_'+date_title
;;           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;           pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;           pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;           pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;           black=  rgb2ind(000,000,000)
;;           CASE zone OF
;;              'A':BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;                 XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;              ENDCASE
;;              'T':BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;                 XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1	
;;                 le_sign='!9'+ STRING("308B) 
;;                 XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;                 !P.font=0	
;;                 XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1	
;;                 le_sign='!9'+ STRING("308B) 
;;                 XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;                 !P.font=0
;;                 XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1	
;;                 le_sign='!9'+ STRING("308B) 
;;                 XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;              ENDCASE
;;              'N':BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;                 XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;              ENDCASE 
;;              'JAP': BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;                 XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;              ENDCASE
;;              ELSE:
;;           ENDCASE
;;           ishold=1
;;           field(*,*)=!values.f_nan
;;           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;           ishold=0
;;           do_output,dirname_out+name_out
;;           subst_str,name_out, '-', '_'
;;           SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;           SPAWN,'rm '+dirname_out+name_out+'.ps'
;;        ENDIF
;;        ;;
;;        ;; MLP error
;;        ;;
;;        clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
;;        clear,ymin,ymax,xmin,xmax,rms_diff1,rms_diff2,rms_diff3,nb_val,nb_val2
;;        output='gif'
;;        output='A3 ps'
;;        domain=dom
;;        clear,titre,units
;;        titre='MLP errors '+date_title
;;        titre='('+type_obs+'-obs) MLP errors '+varname+' '+date_title
;;        units='m'
;;        field=Difference_MLP_error
;;        valcmax=MAX(field,/NaN)
;;        valcmin=MIN(field,/NaN)
;;        cmin=-100 & cmax=100 & dc=5.
;;        kindchoice='no_iso unknown difference UserLevels publi'
;;        xxl='m'
;;        x1=lon
;;        x2=lat
;;        rms_diff1=field 
;;        rms_diff2=field
;;        rms_diff3=field
;;        ii=WHERE( nb_val_MLP EQ 0 ) 
;;        IF (ii(0) NE -1) THEN nb_val_MLP(ii)=!values.f_nan
;;        nb_val=nb_val_MLP
;;        ii=where(FINITE(nb_val,/NAN) EQ 0)
;;        IF (ii(0) NE -1) THEN BEGIN
;;           nb_val2=nb_val(ii)
;;           p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
;;           p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
;;           il_indice1=WHERE(nb_val GE p25 ) ;; 1
;;           rms_diff1(il_indice1)=!values.f_nan
;;           il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
;;           rms_diff2(il_indice2)=!values.f_nan
;;           il_indice3=WHERE(nb_val LE p75 )
;;           rms_diff3(il_indice3)=!values.f_nan
;;           print,'percentile 25 ',p25
;;           print,'percentile 75 ',p75
;;           field(*,*)=!values.f_nan
;;           fmin=valcmin
;;           fmax=valcmax
;;           ishold=1
;;           name_out='MLP_error_Class4pcolor_'+modele+'_'+nom_var+'_'+zone+'_'+date_title
;;           name_out=modele+'_'+nom_var+'_MLPerr_'+namezone+'_'+date_title
;;           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;           pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
;;           pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
;;           pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;;           black=  rgb2ind(000,000,000)
;;           CASE zone OF
;;              'A':BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
;;                 XYOUTS,0.6,0.09,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.08,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.08,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.08,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;              ENDCASE
;;              'T':BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
;;                 XYOUTS,0.6,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.20,0.18,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1	
;;                 le_sign='!9'+ STRING("308B) 
;;                 XYOUTS,0.065,0.18,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1 
;;                 !P.font=0	
;;                 XYOUTS,0.20,0.14,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1	
;;                 le_sign='!9'+ STRING("308B) 
;;                 XYOUTS,0.0625,0.14,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1 
;;                 !P.font=0
;;                 XYOUTS,0.20,0.10,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1	
;;                 le_sign='!9'+ STRING("308B) 
;;                 XYOUTS,0.06,0.10,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1 
;;              ENDCASE
;;              'N':BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
;;                 XYOUTS,0.6,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;              ENDCASE 
;;              'JAP': BEGIN
;;                 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F7.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
;;                 XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
;;                 XYOUTS,0.22,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
;;                 !P.font=0
;;                 XYOUTS,0.22,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
;;                 DEVICE, SET_FONT='Symbol', /TT_FONT
;;                 !P.font=1
;;                 le_sign='!9'+ STRING("308B)
;;                 XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
;;              ENDCASE
;;              ELSE:
;;           ENDCASE
;;           ishold=1
;;           field(*,*)=!values.f_nan
;;           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
;;                                ; Sauvegarde de l'image obtenue
;;           ishold=0
;;           do_output,dirname_out+name_out
;;           subst_str,name_out, '-', '_'
;;           SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
;;           SPAWN,'rm '+dirname_out+name_out+'.ps'
;;        ENDIF      
        label:
     ENDFOR
   ENDFOR
  END
