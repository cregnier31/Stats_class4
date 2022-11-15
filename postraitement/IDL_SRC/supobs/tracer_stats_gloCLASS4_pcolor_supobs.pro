PRO tracer_stats_gloCLASS4_pcolor_supobs,modele,fic_mask, $
			         filelist,var1,var2,$
                                  zone,kind,dir_stats,OPER,date_title,tab_prof,tab_cmax,NETCDF=ind_netcdf,TYPE_OBS=type_data
				  
;==========================================================================
;##  Trace des statistiques pour les fichers class4
;    pour un paramètre donné pour toutes les profondeurs
;
;    author: C REGNIER Septembre 2007
;    modif   C.REGNIER  Fevrier 2007  : parametrisation des tout les
;    elements du tracé
;             C.REGNIER Mars 2007 : tracés en fonctions de la zone et
;             choix du critere
; c.REGNIER  Mai       2009 Bulletin trimestriel : tracé des
;                      statistiques pour le bulletin trimestriel 
; 
; c.REGNIER  Fevrier   2010 Rajout des stats sur une liste de fichiers
; C.REGNIER  Janvier   2011 Adaptation pour les stats superobs
; C.REGNIER  Decembre  2013 Adaptation aux nouveaux fichiers stats
;=========================================================================
@param
@param_class4

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Definition des variables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print,filelist
n_files=N_ELEMENTS(filelist)
fichier1=filelist(n_files-1)
file2=fic_mask
file=fichier1
print,file
nb_prof=N_ELEMENTS(tab_prof)
ind_plot_nc=0
IF Keyword_Set(ind_netcdf) THEN BEGIN
    ind_plot_nc=ind_netcdf
ENDIF
IF (ind_plot_nc EQ 1) THEN BEGIN
    print,'Save fichier netcdf'
ENDIF
;; Reconstitution profondeur
print,nb_prof
profondeur=strarr(nb_prof)
FOR ind=0,nb_prof-2 DO BEGIN
  profondeur(ind)=strtrim(STRING(UINT(tab_prof(ind))),1)+'-'+strtrim(STRING(UINT(tab_prof(ind+1))),1)+'m'
  print,'Valeur :: ',profondeur(ind)
ENDFOR
profondeur(nb_prof-1)=strtrim(STRING(UINT(tab_prof(0))),1)+'-'+strtrim(STRING(UINT(tab_prof(nb_prof-1))),1)+'m'
range_values=fltarr(2,nb_prof)

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Lecture des boites
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;dir_mask='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/static/'
x1=ncdf_lec(file2,iodir=dir_mask,var='longitude', /nostruct) & x1=transpose(x1)
x2=ncdf_lec(file2,iodir=dir_mask,var='latitude', /nostruct) & x2=transpose(x2)
boite=ncdf_lec(file,iodir=dirin,var='box', /nostruct) & boite=transpose(boite)
variable_name=ncdf_lec(file,iodir=dirin,var='param_stats', /nostruct) & variable_name=STRING(variable_name)
tab_prof_model=ncdf_lec(file,iodir=dirin,var='deptht', /nostruct) & tab_prof_model=transpose(tab_prof_model)
tab_e3t=ncdf_lec(file,iodir=dirin,var='e3t_0', /nostruct) & tab_e3t=transpose(tab_e3t)

nb_prof_model=N_ELEMENTS(tab_prof_model)
nb_variables=N_ELEMENTS(variable_name)

;;-------------------------------------------------
;; Liste de modeles en fonction de la zone
;;--------------------------------------------------
model_name=modele
CASE zone OF
   'A':BEGIN
      print,'Zone Atlantique'
      dom='zoom NATL12 1/12 mercator'
      typezone='A'
   ENDCASE
   'ARC':BEGIN
      print,'Zone Artic'
      dom='zoom Subarctic 1/12 '
      typezone='ARC'
   ENDCASE
   'ANT':BEGIN
      print,'Zone Antarctic'
      dom='zoom Subantarctic 1/12 '
      typezone='A'
   ENDCASE
   'P':BEGIN
      dom='zoom  Pacific 1/12 mercator'
   ENDCASE
   'I':BEGIN
      dom='zoom Indian 1/12 mercator'
      typezone='Indian'
   ENDCASE
   'MED':BEGIN
      zone='A'
      typezone='Medit'
      dom='zoom Medit 1/12'
   ENDCASE
   'gulf stream':BEGIN
      dom='zoom NATL12 1/12 mercator'
   ENDCASE
   'West_Africa': BEGIN
     zone='WESTAF'
     dom='zoom West_Africa 1/4 mercator'
     typezone='West_Africa'
   ENDCASE
   'GUI': BEGIN
      zone='N'
      typezone='Atl_Trop_Gui'
      dom='zoom Medit 1/12'
     dom='zoom Atl_Trop_Guinee 1/4 mercator'
   ENDCASE
   'T':BEGIN
	   dom='zoom ORCA 1/4 mercator hires'
           typezone='T'
   ENDCASE
   'N':BEGIN
	 dom='zoom AZORES 1/4 mercator'
   ENDCASE
   'C': BEGIN
        dom='zoom South_China_Sea2 1/12 mercator'
        typezone='SCS_domain'
   ENDCASE
   ELSE:
ENDCASE

;;------------------------------------------------------------------
;; Boucle sur la liste des modeles en fonction de la zone choisie
;;------------------------------------------------------------------

;; Lecture du fichier mask et boite
        print,'Mask::',dir_mask
        lon=ncdf_lec(file2,iodir=dir_mask,var='longitude', /nostruct) & lon=transpose(lon)
        lat=ncdf_lec(file2,iodir=dir_mask,var='latitude', /nostruct) & lat=transpose(lat)
        field1=ncdf_lec(file2,iodir=dir_mask,var='mask', /nostruct)& field1=transpose(field1)
	print,'file :: ',dir_stats,file
        boite=ncdf_lec(file,iodir=dir_stats,var='box', /nostruct) & boite=transpose(boite)
       
        il_nlon=N_ELEMENTS(lon(1,*))
        il_nlat=N_ELEMENTS(lat(*,1))
        il_nbox=N_ELEMENTS(boite)	  
        i1=N_ELEMENTS(field1(1,*))
        i2=N_ELEMENTS(field1(*,1))
        nfichiers=N_ELEMENTS(filelist)

	;** Allocate tab
        rms_difftot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers)
        mean_difftot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers)
        indice_tot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers) 
        tab_indice_ini=intarr(nb_prof)
        tab_indice_fin=intarr(nb_prof)	  
        print,'nb_prof :: ',nb_prof
         

; Rercherche des indice pour les boites
      indice2=0
      FOR indice=1,nb_prof-1 DO BEGIN
	FIND2=WHERE(tab_prof_model GE tab_prof(indice-1) AND tab_prof_model LT tab_prof(indice), COUNT)
	indice_ini=FIND2(0)
	indice_fin=FIND2(N_ELEMENTS(FIND2)-1)
	tab_indice_ini(indice2)=indice_ini
	tab_indice_fin(indice2)=indice_fin
	print ,'intervalle :: ',tab_prof(indice-1),tab_prof(indice)
	print ,'Indices :: ',tab_indice_ini(indice2),tab_indice_fin(indice2)
	print,'Profondeur modele :',tab_prof_model(tab_indice_ini(indice2)),tab_prof_model(tab_indice_fin(indice2))
	print,'indice :',tab_indice_ini(indice2),tab_indice_fin(indice2)
	print,'Pronfondeur : ',profondeur(indice2)
	print,'indice2 :',indice2
	indice2=indice2+1
      ENDFOR
      ;; Dernière case du tableau => toute la colonne d'eau
      tab_indice_ini(indice2)=0
      tab_indice_fin(indice2)=tab_indice_fin(indice2-1)
      print,'indice :',tab_indice_ini(indice2),tab_indice_fin(indice2)
      print,'Pronfondeur : ',profondeur(indice2)

;; Lecture de mean et rms 
        i=0L
        while i le nfichiers-1 do begin 
           file=filelist(i)
           rms_diff=ncdf_lec(file,iodir=dir_stats,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
	   n_values=N_ELEMENTS(rms_diff(0,*,0))
	   print,"n_values :: ",n_values
           rms_difftot(*,*,*,i)=rms_diff
	   
           mean_diff=ncdf_lec(file,iodir=dir_stats,var='mean_diff', /nostruct) & mean_diff=transpose(mean_diff)
	   mean_difftot(*,*,*,i)=mean_diff
           nb_valeurs=ncdf_lec(file,iodir=dir_stats,var='indice_box', /nostruct) & nb_valeurs=transpose(nb_valeurs)
           indice_tot(*,*,*,i)=nb_valeurs
           print,'file ok ::',file
           clear,indice,rms_diff,mean_diff
           i=i+1
        endwhile
        print, "Creation liste ok"

;; Normalisation par le nombre d'obs par boite
        ii=WHERE(indice_tot(*,*,*,*) GT 0)
        IF (ii(0) NE -1) THEN BEGIN 
           rms_difftot(ii)=rms_difftot(ii)/indice_tot(ii)
	   mean_difftot(ii)=mean_difftot(ii)/indice_tot(ii)
        ENDIF
        print, "Normalisation ok"

;;-----------------------------------------------------------------------------------------
;; Boucle sur les profondeurs 
;;------------------------------------------------------------------------------------------
prof=0L
;variable_name_new=strarr(4)
;nvar=N_ELEMENTS(variable_name)
;variable_name_new=variable_name(nvar-4:nvar-1)
;; Boucle sur les niveaux
        WHILE prof le nb_prof -1  DO BEGIN
            FOR var=var1,var2  DO BEGIN
            ;FOR var=0,3  DO BEGIN
                
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
		nom_var=strtrim(variable_name(var))
;		nom_var=strtrim(variable_name_new(var))
		print,nom_var  
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
                     xxl='DegC'
                     type_obs='hindcast_'+modele
                   ENDCASE
		  'HDCST_PSAL' : BEGIN 
		     varname='salinity'
	             xxl='PSU'
                     type_obs='hindcast_'+modele
		   ENDCASE
                  'ANA_TEMP' : BEGIN	
		     varname='temperature'
                     xxl='DegC'
                     type_obs='nowcast'
                   ENDCASE
		   'ANA_PSAL' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='nowcast'
                   ENDCASE
	           'PERS_TEMP' : BEGIN	
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence'
                   ENDCASE
	           'PERS_PSAL' : BEGIN	
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence'
                   ENDCASE
		   'FRCST1D_TEMP' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='forecast1Day'
                   ENDCASE	       
		   'FRCST1D_PSAL' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='forecast1Day'
                   ENDCASE	       
		   'FRCST3D_TEMP' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='forecast3Day'
                   ENDCASE	       
		   'FRCST3D_PSAL' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='forecast3Day'
                   ENDCASE	       
		   'FRCST5D_TEMP' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='forecast5Day'
                   ENDCASE	       
		   'FRCST5D_PSAL' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='forecast5Day'
                   ENDCASE	       
		   'FRCST6D_TEMP' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='forecast6Day'
                   ENDCASE	       
		   'FRCST6D_PSAL' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='forecast6Day'
                   ENDCASE	       
		   'TMARV11' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_ARIVO11'
                   ENDCASE	       
		   'SMARV11' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='Clim_ARIVO11'
                   ENDCASE	       
		   'TMLEV18' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_WOA18'
                   ENDCASE	       
		   'SMLEV18' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='Clim_WOA18'
                   ENDCASE	       
		   'TMLEV09' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_WOA09'
                   ENDCASE	       
		   'SMLEV09' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='Clim_WOA09'
                   ENDCASE	      
		   'TMLEV13' : BEGIN
                     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_WOA13'
		   ENDCASE
		   'TMMED' : BEGIN
                     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_MEDATLAS'
                   ENDCASE
                   'SMLEV13' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='Clim_WOA13'
                   ENDCASE
                   'SMMED' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='Clim_MEDATLAS'
                   ENDCASE
 
		   ELSE:
	        ENDCASE

               clear,val_rms,val_ind,val1,val_mean           
               val1=fltarr(il_nlat,il_nlon)
               val2=fltarr(il_nlat,il_nlon)
               val_rms=fltarr(il_nlat,il_nlon)
	       val_mean=fltarr(il_nlat,il_nlon)
               val_ind=fltarr(il_nlat,il_nlon)
               nbval1=fltarr(il_nlat,il_nlon)
               region=fltarr(il_nlat,il_nlon)
		
               val_rms(*,*)=!values.f_nan
	       val_mean(*,*)=!values.f_nan
               val_ind(*,*)=!values.f_nan
               val1(*,*)=!values.f_nan
               val2(*,*)=!values.f_nan
               FOR il_ind1=0,il_nlon-1 DO BEGIN
                   FOR il_ind2=0,il_nlat-1 DO BEGIN
                       region(il_ind2,il_ind1)=field1(il_ind2,il_ind1)
                       region2=WHERE(boite(*) EQ region(il_ind2,il_ind1))
                       IF region2 NE -1 THEN BEGIN
			  val_rms_tmp=0L
			  val_mean_tmp=0L
			  val_nbval_tmp=0L
		          val_tot_e3t=0L
			  val_rms_new=0L
			  val_mean_new=0L
			  il_var=0
			  FOR il_indice=0,nfichiers-1 do begin
                            vect=WHERE(rms_difftot(tab_indice_ini(prof):tab_indice_fin(prof),var,region2,il_indice) GT 0)
			    IF (vect(0) NE -1) THEN BEGIN
                              val_rms_tmp=val_rms_tmp+TOTAL(rms_difftot(vect+tab_indice_ini(prof),var,region2,il_indice)*tab_e3t(vect+tab_indice_ini(prof)))

                              val_mean_tmp=val_mean_tmp+TOTAL(mean_difftot(vect+tab_indice_ini(prof),var,region2,il_indice)*tab_e3t(vect+tab_indice_ini(prof)))
			      val_tot_e3t=val_tot_e3t+TOTAL(tab_e3t(vect+tab_indice_ini(prof)))
                              val_nbval_tmp=val_nbval_tmp+TOTAL(indice_tot(vect+tab_indice_ini(prof),var,region2,il_indice))
		            ENDIF 
			    il_var=il_var+1
			  ENDFOR
			  val_rms_new=SQRT(val_rms_tmp/val_tot_e3t)
			  val_mean_new=val_mean_tmp/val_tot_e3t
			  val_nbval_tmp=val_nbval_tmp
                          val_rms(il_ind2,il_ind1)=val_rms_new
			  val_mean(il_ind2,il_ind1)=val_mean_new
			  val_ind(il_ind2,il_ind1)=val_nbval_tmp			  
                          val1(il_ind2,il_ind1)=val_rms(il_ind2,il_ind1)
			  val2(il_ind2,il_ind1)=val_mean(il_ind2,il_ind1)
                          IF  val_ind(il_ind2,il_ind1) EQ 0 THEN BEGIN
                              val_ind(il_ind2,il_ind1)=!values.f_nan
                          ENDIF
                        ENDIF ELSE BEGIN
                           val1(il_ind2,il_ind1)=!values.f_nan
                           val2(il_ind2,il_ind1)=!values.f_nan
                           val_ind(il_ind2,il_ind1)=!values.f_nan
                       ENDELSE
                   ENDFOR
               ENDFOR
              ; nom_var=strtrim(variable_name(var))
;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
;;     Ecriture du resultat sous forme netcdf
       IF (ind_plot_nc EQ 1) THEN BEGIN
          ;; Ecriture fichier
          file=dirname_out+'stats_rms_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+date_title+'.nc'
          TAB=val1
          XGRID=lon
          YGRID=lat
          ZGRID=0
          choice='rms_'+nom_var
          write_ncdf,file,TAB,XGRID,YGRID,ZGRID,1,choice
          print, 'write file',file
          file=dirname_out+'stats_mean_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+date_title+'.nc'
          clear,choice
          TAB2=-val2
          XGRID=lon
          YGRID=lat
          ZGRID=0
          choice='mean_'+nom_var
          write_ncdf,file,TAB2,XGRID,YGRID,ZGRID,1,choice
          ;;
          file=dirname_out+'nb_data_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+date_title+'.nc'
          clear,choice
          TAB2=val_ind
          XGRID=lon
          YGRID=lat
          ZGRID=0
          choice='nb_data_'+nom_var
          write_ncdf,file,TAB2,XGRID,YGRID,ZGRID,1,choice
       ENDIF
       clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
       clear,ymin,ymax,xmin,xmax ;,strmin,strmax
       output='gif'
       output='A3 ps'
       domain=dom
       clear,titre,units
       titre='('+type_obs+'-obs '+type_data+') RMS '+varname+' : '+ profondeur(prof)+' '+date_title
       units='Rms misfit'
       ii=WHERE( val1 EQ 0 ) 
       IF (ii(0) NE -1) THEN val1(ii)=!values.f_nan
       field=val1
       valcmax=MAX(field,/NaN)
       valcmin=MIN(field,/NaN)
       if ( indice_var EQ  1 ) THEN BEGIN 
         ;kindchoice=kind 
	 cmin=0. & cmax=0.5 & dc=0.01
       ;  cmin=0 & cmax=tab_cmax(1,prof) &  dc=0.01
	; cmin=0. & cmax=0.25 & dc=0.01
       endif
       if ( indice_var EQ  0 ) THEN BEGIN 
       ;  kindchoice=kind
         cmin=0. & cmax=2 & dc=0.05
     ;    cmin=0. & cmax=2 & dc=0.05
       ;  cmin=0 & cmax=tab_cmax(0,prof) &  dc=0.05
      ;   cmin=0. & cmax=1.5 & dc=0.025
       endif
      kindchoice='no_iso stddev UserLevels publi'
      palette='stddev'
      x1=lon
      x2=lat
      rms_diff1 =val1
      rms_diff2 =val1
      rms_diff3 =val1
      ii=WHERE( val_ind EQ 0 ) 
      IF (ii(0) NE -1) THEN val_ind(ii)=!values.f_nan
      nb_val=val_ind
      ii=where(FINITE(nb_val,/NAN) EQ 0)
      nb_val2=nb_val(ii)
      p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
      p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
      p75=nb_val2( (SORT(nb_val2) ) (50 * N_ELEMENTS(nb_val2) / 100) ) 
      il_indice1=WHERE(nb_val GT p25 ) ;; 1
      rms_diff1(il_indice1)=!values.f_nan
      il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
      rms_diff2(il_indice2)=!values.f_nan
      il_indice3=WHERE(nb_val LT p75 )
      rms_diff3(il_indice3)=!values.f_nan
      print,'percentile 25 ',p25
      print,'percentile 75 ',p75
      field(*,*)=!values.f_nan
      fmin=valcmin
      fmax=valcmax
      ishold=1
      name_out='rmsMisfit_Class4pcolor_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+typezone+'_'+date_title
      subst_str,name_out, '-', '_'
      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
      pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
      pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
      pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.0, DX2=1.0
      black=  rgb2ind(000,000,000)
      ncolors=253
      CASE zone OF
        'A':BEGIN
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.06,0.90,0.08]
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
        'ARC':BEGIN
         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8 , Position=[0.30,0.06,0.90,0.08]
	 XYOUTS,0.6,0.1,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
         XYOUTS,0.24,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
         DEVICE, SET_FONT='Symbol', /TT_FONT
         !P.font=1
         le_sign='!9'+ STRING("308B)
         XYOUTS,0.06,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
         !P.font=0
         XYOUTS,0.24,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
         DEVICE, SET_FONT='Symbol', /TT_FONT
         !P.font=1
         le_sign='!9'+ STRING("308B)
         XYOUTS,0.06,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
         !P.font=0
         XYOUTS,0.24,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
         DEVICE, SET_FONT='Symbol', /TT_FONT
         !P.font=1
         le_sign='!9'+ STRING("308B)
         XYOUTS,0.06,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
       ENDCASE
        'T':BEGIN
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.25, 0.08,0.75,0.13]
         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
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
	 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
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
        'C': BEGIN   ;; C
	 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
         XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
         XYOUTS,0.24,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
         DEVICE, SET_FONT='Symbol', /TT_FONT
         !P.font=1
         le_sign='!9'+ STRING("308B)
         XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
         !P.font=0
         XYOUTS,0.24,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
         DEVICE, SET_FONT='Symbol', /TT_FONT
         !P.font=1
         le_sign='!9'+ STRING("308B)
         XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
         !P.font=0
         XYOUTS,0.24,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
         DEVICE, SET_FONT='Symbol', /TT_FONT
         !P.font=1
         le_sign='!9'+ STRING("308B)
         XYOUTS,0.05,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
       ENDCASE
       ELSE:
       ENDCASE
       ishold=1
       field(*,*)=!values.f_nan
       subst_str,name_out, '-', '_'
       plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
       ; Sauvegarde de l'image obtenue
       ishold=0
       do_output,dirname_out+name_out
       SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
       SPAWN,'rm '+dirname_out+name_out+'.ps'
      clear,longitude2,latitude2
      ;le_sign = '!3' + STRING(197B) + '!X' ;(to use octal notation)
      ;; Plot Mean DIFF 
      clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
      clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
      ;output='gif'
      output='A3 ps'
      domain=dom
      clear,titre,units
      ;titre='('+type_obs+'-obs) MEAN '+varname+' : ' +modele+' '+ profondeur(prof)+' '+date_title
      ;; Matrice originelle en modele-obs : on passe en Obs -modele 
      titre='( obs '+type_data+' - '+type_obs+') MEAN '+varname+' : ' +modele+' '+ profondeur(prof)+' '+date_title
      units='Mean Diff'
      ii=WHERE( val2 EQ 0 )
      IF (ii(0) NE -1) THEN val2(ii)=!values.f_nan
      field=-val2
      valcmax=MAX(field,/NaN)
      valcmin=MIN(field,/NaN)
      if ( indice_var EQ  1 ) THEN BEGIN
        cmin=-0.5 & cmax=0.5 & dc=0.01
        ; cmin=-tab_cmax(1,prof) & cmax=tab_cmax(1,prof) &  dc=0.01
    ;    cmin=-0.25 & cmax=0.25 & dc=0.005
      endif
      if ( indice_var EQ  0 ) THEN BEGIN
        ;cmin=-1 & cmax=1 & dc=0.025
       ; cmin=-2 & cmax=2 & dc=0.05
       ;  cmin=-tab_cmax(0,prof) & cmax=tab_cmax(0,prof) &  dc=0.05
        cmin=-1 & cmax=1 & dc=0.025
      endif
      kindchoice='unknown difference no_iso UserLevels publi' 
      palette='sla'
      units='Deg C'
      x1=lon
      x2=lat
      mean_diff1 =-val2
      mean_diff2 =-val2
      mean_diff3 =-val2
      ii=WHERE( val_ind EQ 0 )
      IF (ii(0) NE -1) THEN val_ind(ii)=!values.f_nan
      nb_val=val_ind
      ii=where(FINITE(nb_val,/NAN) EQ 0)
      nb_val2=nb_val(ii)
      p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) )
      p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) )
      p75=nb_val2( (SORT(nb_val2) ) (50 * N_ELEMENTS(nb_val2) / 100) )
      il_indice1=WHERE(nb_val GT p25 ) ;; 1
      mean_diff1(il_indice1)=!values.f_nan
      il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
      mean_diff2(il_indice2)=!values.f_nan
      il_indice3=WHERE(nb_val LT p75 )
      mean_diff3(il_indice3)=!values.f_nan
      print,'percentile 25 ',p25
      print,'percentile 75 ',p75
      field(*,*)=!values.f_nan
      fmin=valcmin
      fmax=valcmax
      ishold=1
      name_out='meanDiff_Class4pcolor_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+typezone+'_'+date_title
      subst_str,name_out, '-', '_'
      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
      pcolor,mean_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25
      pcolor,mean_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
      pcolor,mean_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.0, DX2=1.0
      black=  rgb2ind(000,000,000)
      ncolors=253
      CASE zone OF
        'A':BEGIN
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.3,0.03,0.7,0.06]
          COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
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
        'ARC':BEGIN
          COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8 , Position=[0.30,0.06,0.90,0.08]
	  XYOUTS,0.6,0.1,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
          XYOUTS,0.24,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
          DEVICE, SET_FONT='Symbol', /TT_FONT
          !P.font=1
          le_sign='!9'+ STRING("308B)
          XYOUTS,0.06,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
          !P.font=0
          XYOUTS,0.24,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
          DEVICE, SET_FONT='Symbol', /TT_FONT
          !P.font=1
          le_sign='!9'+ STRING("308B)
          XYOUTS,0.06,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
          !P.font=0
          XYOUTS,0.24,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
          DEVICE, SET_FONT='Symbol', /TT_FONT
          !P.font=1
          le_sign='!9'+ STRING("308B)
          XYOUTS,0.06,0.02,le_sign, /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black,FONT=1
       ENDCASE
        'T':BEGIN
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.3, 0.08,0.7,0.11]
         ; COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.25, 0.08,0.75,0.13]
         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30, 0.12,0.90,0.17]
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
	  COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.07,0.90,0.09]
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
       'C':BEGIN    ;; C
	  COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.07]
          XYOUTS,0.6,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
          XYOUTS,0.24,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
          DEVICE, SET_FONT='Symbol', /TT_FONT
          !P.font=1
          le_sign='!9'+ STRING("308B)
          XYOUTS,0.05,0.08,le_sign, /norm, alignment=1.0, CHARSIZE=1.75, COLOR=black ;,FONT=1
          !P.font=0
          XYOUTS,0.24,0.05,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
          DEVICE, SET_FONT='Symbol', /TT_FONT
          !P.font=1
          le_sign='!9'+ STRING("308B)
          XYOUTS,0.05,0.05,le_sign, /norm, alignment=1.0, CHARSIZE=1.25, COLOR=black,FONT=1
          !P.font=0
          XYOUTS,0.24,0.02,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1.2, COLOR=black,FONT=0
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
       subst_str,name_out, '-', '_'
       plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
       ; Sauvegarde de l'image obtenue
       ishold=0
       do_output,dirname_out+name_out
       ;subst_str,name_out, '-', '_'
       SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
       SPAWN,'rm '+dirname_out+name_out+'.ps'
       clear,longitude2,latitude2
    label:
    ENDFOR
   prof=prof+1
ENDWHILE 
END



