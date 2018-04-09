PRO tracer_skillscore_gloCLASS4_supobs_GODAE_CLIM,modele,fichier,fic_mask,filelist,$
                                  var1,var2,profondeur,variable,$
                                  zone,kind,dir_stats,date_title,$
				  tab_prof,tab_prof_model,tab_e3t
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
;==========================================================================
@param
@param_class4

clear,file2,file
file2=fic_mask
file=fichier
nb_prof=N_ELEMENTS(tab_prof)
nb_prof_model=N_ELEMENTS(tab_prof_model)
nb_variables=N_ELEMENTS(variable)
print,zone,nb_prof
;;-------------------------------------------------
;; Liste de modeles en fonction de la zone
;;--------------------------------------------------
model_name=modele

CASE zone OF
   'A':BEGIN
      print,'Zone Atlantique'
      dom='zoom NATL12 1/12 mercator'
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
   'JAP': BEGIN
     dom='zoom BIG_JAPAN 1/4 mercator'
   ENDCASE
   'gulf stream':BEGIN
      dom='zoom NATL12 1/12 mercator'
   ENDCASE
   'N':BEGIN
     dom='zoom AZORES 1/4 mercator'
   ENDCASE
   'T':BEGIN
  	if ( modele eq "PSY2V3R1" )  THEN BEGIN
           dom='zoom NATL12 1/12 mercator'
	endif else begin
	   ;dom='zoom global 1/4 mercator'
           dom='zoom ORCA 1/4 mercator hires'
	endelse
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
	print,'file :: ',file
        print,'Stats dir :: ',dir_stats
        boite=ncdf_lec(file,iodir=dir_stats,var='box', /nostruct) & boite=transpose(boite)
        il_nlon=N_ELEMENTS(lon(1,*))
        il_nlat=N_ELEMENTS(lat(*,1))
        il_nbox=N_ELEMENTS(boite)	  
        i1=N_ELEMENTS(field1(1,*))
        i2=N_ELEMENTS(field1(*,1))
        nfichiers=N_ELEMENTS(filelist)
        print ,'Nombre de boites :: ',il_nbox
	;** Allocate tab
        rms_difftot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers)
        indice_tot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers) 
        tab_indice_ini=intarr(nb_prof)
        tab_indice_fin=intarr(nb_prof)	  
        print,'Dimensions :: ',nb_prof,il_nbox,nfichiers

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

;; Lecture des rms 
        i=0L
        while i le nfichiers-1 do begin 
           file=filelist(i)
	   print ,'file',file
           rms_diff=ncdf_lec(file,iodir=dir_stats,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
	   print ,'lecture',dir_stats
	   ;print ,'lecture',dir_stats+file
	   ;print , 'taille 2 ::',N_ELEMENTS(rms_diff(*,0,0)),N_ELEMENTS(rms_diff(0,*,0)),N_ELEMENTS(rms_diff(0,0,*))
           rms_difftot(*,*,*,i)=rms_diff
           nb_valeurs=ncdf_lec(file,iodir=dir_stats,var='indice_box', /nostruct) & nb_valeurs=transpose(nb_valeurs)
           indice_tot(*,*,*,i)=nb_valeurs
	   clear,rms_diff
           print,'file ok ::',file
           i=i+1
        endwhile
        print, "Creation liste ok"

;;-----------------------------------------------------------------------------------------
;; Boucle sur les profondeurs 
;;------------------------------------------------------------------------------------------
        prof=0
;; Boucle sur les niveaux
        WHILE prof le nb_prof -2  DO BEGIN
           FOR var=var1,var2  DO BEGIN
;; Test si la variable est la temperature ou la salinité
;; Paire :: temperature, impaire : salinité
		nom_var=variable(var)     
		print ,'Variable :: ',nom_var
		CASE nom_var OF
                  'HDCST_TEMP' : BEGIN
		     varname='temperature'
                     indice_var=0
                     xxl='DegC'
                     type_obs='hindcast'
                   ENDCASE
		  'HDCST_PSAL' : BEGIN 
		     varname='salinity'
                     indice_var=1
	             xxl='PSU'
                     type_obs='hindcast'
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
	           'PERS1D_TEMP' : BEGIN	
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence1Day'
                   ENDCASE
		   'PERS3D_TEMP' : BEGIN
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence3Day'
                    ENDCASE
                   'PERS5D_TEMP' : BEGIN
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence=5Day'
                   ENDCASE
	           'PERS1D_PSAL' : BEGIN	
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence1Day'
                   ENDCASE
		   'PERS3D_PSAL' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence3Day'
                   ENDCASE
		  'PERS5D_PSAL' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence5Day'
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
		   'CLIM_TEMP' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_temp_levitus'
                     indice_clim=0
                   ENDCASE	       
		   'CLIM_PSAL' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='Clim_sal_levitus'
                     indice_clim=1
                   ENDCASE	       
		   'CLIM_SLA' : BEGIN
		     varname=''
                     xxl='DegC'
                     type_obs='Clim_SLA'
                   ENDCASE	       
		   'CLIM_SST' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='Clim_SST'
                   ENDCASE	       
		   ELSE:
	        ENDCASE

               clear,val_rms,val_ind,val1           
               val1=fltarr(il_nlat,il_nlon)
               val_rms=fltarr(il_nlat,il_nlon)
               val_ind=fltarr(il_nlat,il_nlon)
               nbval1=fltarr(il_nlat,il_nlon)
               region=fltarr(il_nlat,il_nlon)
	       ;; Initialisation	
               val_rms(*,*)=!values.f_nan
               val_ind(*,*)=!values.f_nan
               val1(*,*)=!values.f_nan
               FOR il_ind1=0,il_nlon-1 DO BEGIN
                   FOR il_ind2=0,il_nlat-1 DO BEGIN
                       region(il_ind2,il_ind1)=field1(il_ind2,il_ind1)
                       region2=WHERE(boite(*) EQ region(il_ind2,il_ind1))
                        IF region2 NE -1 THEN BEGIN
			  val_rms_tmp=0L
			  val_nbval_tmp=0L
		          val_tot_e3t=0L
			  val_rms_new=0L
			  il_var=0
			  FOR il_indice=0,nfichiers-1 do begin
                            vect=WHERE(rms_difftot(tab_indice_ini(prof):tab_indice_fin(prof),var,region2,il_indice) GT 0)
			    IF (vect(0) NE -1) THEN BEGIN
                              val_rms_tmp=val_rms_tmp+TOTAL(rms_difftot(vect+tab_indice_ini(prof),var,region2,il_indice)*tab_e3t(vect+tab_indice_ini(prof)))
			      val_tot_e3t=val_tot_e3t+TOTAL(tab_e3t(vect+tab_indice_ini(prof)))
                              val_nbval_tmp=val_nbval_tmp+TOTAL(indice_tot(vect+tab_indice_ini(prof),var,region2,il_indice))
		            ENDIF 
			    il_var=il_var+1
			  ENDFOR
			  val_rms_new=SQRT(val_rms_tmp/val_tot_e3t)
			  val_nbval_tmp=val_nbval_tmp
                          val_rms(il_ind2,il_ind1)=val_rms_new
			  val_ind(il_ind2,il_ind1)=val_nbval_tmp			  
                          val1(il_ind2,il_ind1)=val_rms(il_ind2,il_ind1)
                          IF  val_ind(il_ind2,il_ind1) EQ 0 THEN BEGIN
                              val_ind(il_ind2,il_ind1)=!values.f_nan
                          ENDIF
                        ENDIF ELSE BEGIN
                           val1(il_ind2,il_ind1)=!values.f_nan
                           val_ind(il_ind2,il_ind1)=!values.f_nan
                       ENDELSE
                    ENDFOR
                ENDFOR
               nom_var=variable(var)
	       ii=where( val_ind LT 30 )
	       IF ( nom_var eq 'FRCST1D_TEMP')  THEN BEGIN
                  val_rmsF1_temp=fltarr(il_nlat,il_nlon)
                  val_rmsF1_temp=val1
                  if ( ii(0) ne -1) THEN val_rmsF1_temp(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'FRCST1D_PSAL')  THEN BEGIN
                  val_rmsF1_sal=fltarr(il_nlat,il_nlon)
                  val_rmsF1_sal=val1
                  if ( ii(0) ne -1) THEN val_rmsF1_sal(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'FRCST3D_TEMP')  THEN BEGIN
                  val_rmsF3_temp=fltarr(il_nlat,il_nlon)
                  val_rmsF3_temp=val1	
		  if ( ii(0) ne -1) THEN val_rmsF3_temp(ii)=!values.f_nan
               ENDIF 
               IF ( nom_var eq 'FRCST3D_PSAL')  THEN BEGIN
                  val_rmsF3_sal=fltarr(il_nlat,il_nlon)
                  val_rmsF3_sal=val1
         	  if ( ii(0) ne -1) THEN val_rmsF3_sal(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'FRCST5D_TEMP')  THEN BEGIN
                  val_rmsF5_temp=fltarr(il_nlat,il_nlon)
                  val_rmsF5_temp=val1
	          if ( ii(0) ne -1) THEN  val_rmsF5_temp(ii)=!values.f_nan
               ENDIF 
               IF ( nom_var eq 'FRCST5D_PSAL')  THEN BEGIN
                  val_rmsF5_sal=fltarr(il_nlat,il_nlon)
                  val_rmsF5_sal=val1
	          if ( ii(0) ne -1) THEN  val_rmsF5_sal(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'PERS1D_TEMP')  THEN BEGIN
                  val_rmsPERS1D_temp=fltarr(il_nlat,il_nlon)            
                  val_rmsPERS1D_temp=val1
		  if ( ii(0) ne -1) THEN val_rmsPERS1D_temp(ii)=!values.f_nan
               ENDIF 
               IF ( nom_var eq 'PERS1D_PSAL')  THEN BEGIN
                  val_rmsPERS1D_sal=fltarr(il_nlat,il_nlon)
                  val_rmsPERS1D_sal=val1
		  if ( ii(0) ne -1) THEN val_rmsPERS1D_sal(ii)=!values.f_nan
               ENDIF
	       IF ( nom_var eq 'PERS3D_TEMP')  THEN BEGIN
                  val_rmsPERS3D_temp=fltarr(il_nlat,il_nlon)
                  val_rmsPERS3D_temp=val1
                  if ( ii(0) ne -1) THEN val_rmsPERS3D_temp(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'PERS3D_PSAL')  THEN BEGIN
                  val_rmsPERS3D_sal=fltarr(il_nlat,il_nlon)
                  val_rmsPERS3D_sal=val1
                  if ( ii(0) ne -1) THEN val_rmsPERS3D_sal(ii)=!values.f_nan
               ENDIF
	       IF ( nom_var eq 'PERS5D_TEMP')  THEN BEGIN
                  val_rmsPERS5D_temp=fltarr(il_nlat,il_nlon)
                  val_rmsPERS5D_temp=val1
                  if ( ii(0) ne -1) THEN val_rmsPERS5D_temp(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'PERS5D_PSAL')  THEN BEGIN
                  val_rmsPERS5D_sal=fltarr(il_nlat,il_nlon)
                  val_rmsPERS5D_sal=val1
                  if ( ii(0) ne -1) THEN val_rmsPERS5D_sal(ii)=!values.f_nan
               ENDIF
	       IF ( nom_var eq 'CLIM_TEMP')  THEN BEGIN 
	          val_rmsCLIMTEMP=fltarr(il_nlat,il_nlon)
		  val_rmsCLIMTEMP=val1 
		  if ( ii(0) ne -1) THEN  val_rmsCLIMTEMP(ii)=!values.f_nan
	       ENDIF
	       IF ( nom_var eq 'CLIM_PSAL')  THEN BEGIN 
	          val_rmsCLIMPSAL=fltarr(il_nlat,il_nlon)
		  val_rmsCLIMPSAL=val1 
		  if ( ii(0) ne -1) THEN  val_rmsCLIMPSAL(ii)=!values.f_nan
	       ENDIF
	       IF ( nom_var eq 'CLIM_SST')  THEN BEGIN 
	          val_rmsCLIMSST=fltarr(il_nlat,il_nlon)
		  val_rmsCLIMSST=val1 
		  if ( ii(0) ne -1) THEN  val_rmsCLIMSST(ii)=!values.f_nan
	       ENDIF
	       IF ( nom_var eq 'CLIM_SLA')  THEN BEGIN 
	          val_rmsCLIMSLA=fltarr(il_nlat,il_nlon)
		  val_rmsCLIMSLA=val1 
		  if ( ii(0) ne -1) THEN  val_rmsCLIMSLA(ii)=!values.f_nan
	       ENDIF
;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
               label:
            ENDFOR
           output1='A3 ps'
           xxl='SSP'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;  Clim  ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
           IF (  indice_clim eq 0 ) THEN BEGIN 
	      ;; Figure 1 1D Forecast
              clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
              clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
              ;output='logo gif'
              output=output1
              domain=dom
              clear,titre,units
              titre='Class4 SSP 1 Day Forecast CLIM_Temp '+modele+' '+ profondeur(prof)+' '+date_title
              units='SSP'
              x1=lon
              x2=lat
              score_val=fltarr(il_nlat,il_nlon)
              score_val=1-(val_rmsF1_temp/val_rmsCLIMTEMP)
              field=score_val
              valcmax=MAX(field,/NaN)
              valcmin=MIN(field,/NaN)
              print ,"valcmax :: ",valcmax
              ; val_dc=valeurs_dc(indice_var,prof)
              kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
              ishold=1
              print ,'PLOT 2D field'
              field(*,*)=!values.f_nan
              fmin=valcmin
              fmax=valcmax
              name_out='Skillscore1D_'+modele+'_CLIM_temperature_'+profondeur(prof)+'_'+zone
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
	      black=  rgb2ind(000,000,000)
              NCOLORS=ncolors
              CASE zone OF
                 'A':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'T':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
                    XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'
                 ENDCASE
                 'JAP': BEGIN
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'N':BEGIN
                   COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.07,0.90,0.9]
                   XYOUTS,0.5,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                   plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 ELSE:
              ENDCASE
              ishold=1
              field(*,*)=!values.f_nan
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              ishold=0
              do_output,dirname_out+name_out
              subst_str,name_out, 'temperature', 'tn'
              subst_str,name_out, '-', '_'
              SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
              SPAWN,'rm '+dirname_out+name_out+'.ps'
              clear,longitude2,latitude2


              ;; Figure 1 3D Forecast
              clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
              clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
              ;output='logo gif'
              output=output1
              domain=dom
              clear,titre,units
              titre='Class4 SSP 3 Days Forecast CLIM_Temp '+modele+' '+ profondeur(prof)+' '+date_title
              units='SSP'
              x1=lon
              x2=lat
              score_val=fltarr(il_nlat,il_nlon)
              score_val=1-(val_rmsF3_temp/val_rmsCLIMTEMP)
              field=score_val
              valcmax=MAX(field,/NaN)
              valcmin=MIN(field,/NaN)
              print ,"valcmax :: ",valcmax
              ; val_dc=valeurs_dc(indice_var,prof)
              kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
              ishold=1
              print ,'PLOT 2D field'
              field(*,*)=!values.f_nan
              fmin=valcmin
              fmax=valcmax
	      name_out='Skillscore3D_'+modele+'_CLIM_temperature_'+profondeur(prof)+'_'+zone
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
              black=  rgb2ind(000,000,000)
	      NCOLORS=ncolors
              CASE zone OF
                 'A':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
	            XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'T':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
	            XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
                 ENDCASE
	         'JAP': BEGIN
 	            COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
	         ENDCASE
	         'N':BEGIN
                   COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.07,0.90,0.9]
                   XYOUTS,0.5,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                   plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 ELSE:
              ENDCASE
              ishold=1
              field(*,*)=!values.f_nan
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
             ; Sauvegarde de l'image obtenue
              ishold=0
              do_output,dirname_out+name_out
              subst_str,name_out, 'temperature', 'tn'
              subst_str,name_out, '-', '_'
              SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
              SPAWN,'rm '+dirname_out+name_out+'.ps'
              clear,longitude2,latitude2

              ;; Figure 2 5D Forecast
              clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
              clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
              output=output1
              domain=dom
              clear,titre,units
              titre='Class4 SSP 5 Days Forecast CLIM_Temp '+modele+' '+ profondeur(prof)+' '+date_title
              units='SSP'
              x1=lon
              x2=lat
              score_val=fltarr(il_nlat,il_nlon)
              score_val=1-(val_rmsF5_temp/val_rmsCLIMTEMP)
              field=score_val
              valcmax=MAX(field,/NaN)
              print ,"valcmax :: ",valcmax
              kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
              ishold=1
              print ,'PLOT 2D field'
              field(*,*)=!values.f_nan
              name_out='Skillscore5D_'+modele+'_CLIM_temperature_'+profondeur(prof)+'_'+zone
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
              black=  rgb2ind(000,000,000)
              NCOLORS=ncolors
              CASE zone OF
                 'A':BEGIN
                    ;COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'T':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
                    XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
                 ENDCASE
                 'JAP':BEGIN
                    COLORBAR, bottom=2, NCOLORS=ncolors,color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'N':BEGIN
                   COLORBAR, bottom=2, NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.07,0.90,0.9]
                   XYOUTS,0.5,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                   plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 ELSE:
              ENDCASE
              ishold=1
              field(*,*)=!values.f_nan
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
             ; Sauvegarde de l'image obtenue
              ishold=0
              do_output,dirname_out+name_out
              subst_str,name_out, 'temperature', 'tn'
              subst_str,name_out, '-', '_'
              SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
              SPAWN,'rm '+dirname_out+name_out+'.ps'
              clear,longitude2,latitude2
           ENDIF ELSE BEGIN
              ;; Figure 4 1D Forecast
              clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
              clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
              output=output1
              domain=dom
              clear,titre,units
              titre='Class4 SSP 1 Day Forecast CLIM_Salinity '+modele+' '+ profondeur(prof)+' '+date_title
              units='SSP'
              x1=lon
              x2=lat
              score_val=fltarr(il_nlat,il_nlon)
              score_val(*,*)=!values.f_nan
              score_val=1-(val_rmsF1_sal/val_rmsCLIMPSAL)
              field=score_val
              valcmax=MAX(field,/NaN)
              valcmin=MIN(field,/NaN)	      
              print ,"valcmax :: ",valcmax
              ; val_dc=valeurs_dc(indice_var,prof)
              kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
              ishold=1
              print ,'PLOT 2D field'
              field(*,*)=!values.f_nan
              fmin=valcmin
              fmax=valcmax
              name_out='Skillscore1D_'+modele+'_CLIM_salinity_'+profondeur(prof)+'_'+zone
   	      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
              black=  rgb2ind(000,000,000)
   	      NCOLORS=ncolors
              CASE zone OF
                 'A':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
   	         XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.080, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'T':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
   	         XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
                 ENDCASE
   	      'JAP':BEGIN
   	         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.080, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
   	      'N':BEGIN
                   COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.07,0.90,0.9]
                   XYOUTS,0.5,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                   plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 ELSE:
              ENDCASE
              ishold=1
              field(*,*)=!values.f_nan
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
          ; Sauvegarde de l'image obtenue
              ishold=0
              do_output,dirname_out+name_out
              subst_str,name_out, 'salinity', 'sn'
              subst_str,name_out, '-', '_'
   	      SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
   	      SPAWN,'rm '+dirname_out+name_out+'.ps'
              clear,longitude2,latitude2
              ;; Figure 5 3D Forecast
              clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
              clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
              output=output1
              domain=dom
              clear,titre,units
              titre='Class4 SSP 3 Days Forecast CLIM_Salinity '+modele+' '+ profondeur(prof)+' '+date_title
              units='SSP'
              x1=lon
              x2=lat
              score_val=fltarr(il_nlat,il_nlon)
              score_val(*,*)=!values.f_nan
              score_val=1-(val_rmsF3_sal/val_rmsCLIMPSAL)
              field=score_val
              valcmax=MAX(field,/NaN)
              print ,"valcmax :: ",valcmax
              kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
              ishold=1
              print ,'PLOT 2D field'
              field(*,*)=!values.f_nan
   	      name_out='Skillscore3D_'+modele+'_CLIM_salinity_'+profondeur(prof)+'_'+zone
   	      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
              black=  rgb2ind(000,000,000)
   	      NCOLORS=ncolors
              CASE zone OF
                 'A':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
   	         XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'T':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
   	         XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
                 ENDCASE
   	      'JAP':BEGIN
   	         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
   	      'N':BEGIN
                   COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.07,0.90,0.9]
                   XYOUTS,0.5,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                   plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 ELSE:
              ENDCASE
              ishold=1
              field(*,*)=!values.f_nan
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              ; Sauvegarde de l'image obtenue
              ishold=0
              do_output,dirname_out+name_out
              subst_str,name_out, 'salinity', 'sn'
              subst_str,name_out, '-', '_'
   	      SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
   	      SPAWN,'rm '+dirname_out+name_out+'.ps'
              clear,longitude2,latitude2
              ;; Figure 6 5D Forecast
              clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
              clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
              output=output1
              domain=dom
              clear,titre,units
              titre='Class4 SSP 5 Days Forecast CLIM_Salinity '+modele+' '+ profondeur(prof)+' '+date_title
              units='SSP'
              x1=lon
              x2=lat
              score_val=fltarr(il_nlat,il_nlon)
              score_val(*,*)=!values.f_nan
              score_val=1-(val_rmsF5_sal/val_rmsCLIMPSAL)
              field=score_val
              valcmax=MAX(field,/NaN)
              print ,"valcmax :: ",valcmax
              kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
              ishold=1
              print ,'PLOT 2D field'
              field(*,*)=!values.f_nan
   	      name_out='Skillscore5D_'+modele+'_CLIM_salinity_'+profondeur(prof)+'_'+zone
   	      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
              black=  rgb2ind(000,000,000)
   	      NCOLORS=ncolors
              CASE zone OF
                 'A':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
   	         XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 'T':BEGIN
                    ;COLORBAR, bottom=2, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                    COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
   	         XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
                 ENDCASE
   	      'JAP':BEGIN
   	         COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
                    XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                    plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
   	      'N':BEGIN
                   COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.07,0.90,0.9]
                   XYOUTS,0.5,0.10,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                   plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
                 ENDCASE
                 ELSE:
              ENDCASE
              ishold=1
              field(*,*)=!values.f_nan
              plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
              ; Sauvegarde de l'image obtenue
              ishold=0
              do_output,dirname_out+name_out
              subst_str,name_out, 'salinity', 'sn'
              subst_str,name_out, '-', '_'
   	      SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
   	      SPAWN,'rm '+dirname_out+name_out+'.ps'
              clear,longitude2,latitude2
   ENDELSE
   prof=prof+1
ENDWHILE 
END



