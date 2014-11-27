PRO tracer_skillscore_gloCLASS4,modele,fichier,fic_mask,filelist,$
                                  var1,var2,profondeur,variable,$
                                  zone,kind,dir_stats,OPER
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
;==========================================================================
@param
@param_class4


file2=fic_mask
file=fichier
nb_prof=N_ELEMENTS(profondeur)
print,zone
print,OPER
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
   'gulf stream':BEGIN
      dom='zoom NATL12 1/12 mercator'
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
	print,'file :: ',dir_stats,file
        boite=ncdf_lec(file,iodir=dir_stats,var='box', /nostruct) & boite=transpose(boite)
        print,'OK1',N_ELEMENTS(boite) 
        il_nlon=N_ELEMENTS(lon(1,*))
        il_nlat=N_ELEMENTS(lat(*,1))
        il_nbox=N_ELEMENTS(boite)	  
        i1=N_ELEMENTS(field1(1,*))
        i2=N_ELEMENTS(field1(*,1))
        nfichiers=N_ELEMENTS(filelist)
        print ,'Nombre de boites :: ',il_nbox
        rms_difftot=dblarr(nb_prof,24,il_nbox,nfichiers)
        indice_tot=dblarr(nb_prof,24,il_nbox,nfichiers) 
        ;rms_difftot=fltarr(nb_prof,22,il_nbox,nfichiers)
	;print,'taille : ',nb_prof,22,il_nbox,nfichiers
        ;indice_tot=fltarr(nb_prof,22,il_nbox,nfichiers) 
;intarr
;        mean=ncdf_lec(file,iodir=dir_stats,var='mean', /nostruct) & mean=transpose(mean)
;        mean_diff=ncdf_lec(file,iodir=dir_stats,var='mean_diff', /nostruct) & mean_diff=transpose(mean_diff)
;rms=ncdf_lec(file,iodir=dir_stats,var='rms', /nostruct) & rms=transpose(rms)
;        rms_diff=cdf_lec(file,iodir=dir_stats,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
;        nb_valeurs=ncdf_lec(file,iodir=dir_stats,var='indice_box', /nostruct) & nb_valeurs=transpose(nb_valeurs)

;; Lecture de mean et rms 
        i=0L
        while i le nfichiers-1 do begin 
           file=filelist(i)
           rms_diff=ncdf_lec(file,iodir=dir_stats,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
	   print ,'lecture',dir_stats+file
	   print , 'taille 2 ::',N_ELEMENTS(rms_diff(*,0,0)),N_ELEMENTS(rms_diff(0,*,0)),N_ELEMENTS(rms_diff(0,0,*))
           rms_difftot(*,*,*,i)=rms_diff
           nb_valeurs=ncdf_lec(file,iodir=dir_stats,var='indice_box', /nostruct) & nb_valeurs=transpose(nb_valeurs)
           indice_tot(*,*,*,i)=nb_valeurs
           print,'file ok ::',file
           i=i+1
        endwhile
        print, "Creation liste ok"
;;-----------------------------------------------------------------------------------------
;; Boucle sur les profondeurs 
;;------------------------------------------------------------------------------------------
      ;  prof=10
        prof=0
;; Boucle sur les niveaux
        WHILE prof le nb_prof -1  DO BEGIN
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
	       	IF ( OPER eq "NO" )  THEN BEGIN
		  CASE nom_var OF
       		     'FSTGS_TEMP' :  GOTO, label
		     'FSTGS_PSAL' :  GOTO, label       	
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
                      'PERS3D_TEMP':  GOTO, label
		      'PERS3D_PSAL':  GOTO, label
		      'PERS6D_TEMP':  GOTO, label
		      'PERS6D_PSAL':  GOTO, label
                      'ANA_PSAL':  GOTO, label	              
                      'ANA_TEMP':  GOTO, label
                      'HDCST_TEMP':  GOTO, label
                      'HDCST_PSAL':  GOTO, label
                  ELSE: PRINT, 'nom_var',nom_var  
	          ENDCASE
                ENDELSE
               clear,val_rms,val_ind,val1           
               val1=fltarr(il_nlat,il_nlon)
               val_rms=fltarr(il_nlat,il_nlon)
               
               val_ind=fltarr(il_nlat,il_nlon)
               nbval1=fltarr(il_nlat,il_nlon)
               region=fltarr(il_nlat,il_nlon)
		
               val_rms(*,*)=!values.f_nan
               val_ind(*,*)=!values.f_nan
               val1(*,*)=!values.f_nan
               FOR il_ind1=0,il_nlon-1 DO BEGIN
                   FOR il_ind2=0,il_nlat-1 DO BEGIN
                       region(il_ind2,il_ind1)=field1(il_ind2,il_ind1)
                       region2=WHERE(boite(*) EQ region(il_ind2,il_ind1))
                       IF region2 NE -1 THEN BEGIN
                             val_rms(il_ind2,il_ind1)=rms_diff(prof,var,region2)
                             val_ind(il_ind2,il_ind1)= nb_valeurs(prof,var,region2)
                             val_rms(il_ind2,il_ind1)=TOTAL(rms_difftot(prof,var,region2,*))
                             val_ind(il_ind2,il_ind1)=TOTAL(indice_tot(prof,var,region2,*))
                             ;val1(il_ind2,il_ind1)=SQRT(val_rms(il_ind2,il_ind1)/val_ind(il_ind2,il_ind1))
                             val1(il_ind2,il_ind1)=(val_rms(il_ind2,il_ind1)/val_ind(il_ind2,il_ind1))
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
	       ii=where( val_ind LT 100 )
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
               IF ( nom_var eq 'FRCST6D_TEMP')  THEN BEGIN
                  val_rmsF6_temp=fltarr(il_nlat,il_nlon)
                  val_rmsF6_temp=val1
	          if ( ii(0) ne -1) THEN  val_rmsF6_temp(ii)=!values.f_nan
               ENDIF 
               IF ( nom_var eq 'FRCST6D_PSAL')  THEN BEGIN
                  val_rmsF6_sal=fltarr(il_nlat,il_nlon)
                  val_rmsF6_sal=val1
	          if ( ii(0) ne -1) THEN  val_rmsF6_sal(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'PERS_TEMP')  THEN BEGIN
                  val_rmsPERS_temp=fltarr(il_nlat,il_nlon)            
                  val_rmsPERS_temp=val1
		  if ( ii(0) ne -1) THEN val_rmsPERS_temp(ii)=!values.f_nan
               ENDIF 
               IF ( nom_var eq 'PERS_PSAL')  THEN BEGIN
                  val_rmsPERS_sal=fltarr(il_nlat,il_nlon)
                  val_rmsPERS_sal=val1
		  if ( ii(0) ne -1) THEN val_rmsPERS_sal(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'TMLEV09')  THEN BEGIN
                  val_rmsTMLEV=fltarr(il_nlat,il_nlon)
                  val_rmsTMLEV=val1
		  if ( ii(0) ne -1) THEN val_rmsTMLEV(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'SMLEV09')  THEN BEGIN
                  val_rmsSMLEV=fltarr(il_nlat,il_nlon)
                  val_rmsSMLEV=val1
		  if ( ii(0) ne -1) THEN  val_rmsSMLEV(ii)=!values.f_nan
               ENDIF
;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
               label:
            ENDFOR
           output1='A3 ps'
           ;; Figure 1 3D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           ;output='logo gif'
           output='gif'
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 3 Days Forecast Temp '+modele+' '+ profondeur(prof)
           units='SSP'
	   x1=fltarr(il_nlat,il_nlon)
	   x2=fltarr(il_nlat,il_nlon)
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF3_temp/val_rmsPERS_temp)
           field=score_val
           valcmax=MAX(field,/NaN)
           valcmin=MIN(field,/NaN)
           print ,"valcmax :: ",valcmax
           ; val_dc=valeurs_dc(indice_var,prof)
           ;kind='no_iso temperature difference'
           kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           ishold=1
           print ,'PLOT 2D field',kindchoice
           field(*,*)=!values.f_nan
           fmin=valcmin
           fmax=valcmax
	   name_out='Skillscore3D_'+modele+'_temperature_'+profondeur(prof)+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                ;  COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.92, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.0, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'
              ENDCASE
              ELSE:
           ENDCASE
	   
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2
           ;; Figure 2 6D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 6 Days Forecast Temp '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF6_temp/val_rmsPERS_temp)
           field=score_val
           valcmax=MAX(field,/NaN)
           kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           print ,'PLOT 2D field',kindchoice
           field(*,*)=!values.f_nan
           ishold=1
	   name_out='Skillscore6D_'+modele+'_temperature_'+profondeur(prof)+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           ishold=1
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.92, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.0, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2
           ;; Figure 3 3D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           ;output='logo gif'
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 3 Days Forecast Salinity '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF3_sal/val_rmsPERS_sal)
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
           name_out='Skillscore3D_'+modele+'_salinity_'+profondeur(prof)+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.92, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.0, black, 'normal'
              ENDCASE
              'T':BEGIN
                ; COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE

       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2

  ;; Figure 4 6D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 6 Days Forecast Salinity '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF6_sal/val_rmsPERS_sal)
           field=score_val
           valcmax=MAX(field,/NaN)
           print ,"valcmax :: ",valcmax
           kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           ishold=1
           print ,'PLOT 2D field'
           field(*,*)=!values.f_nan
	   name_out='Skillscore6D_'+modele+'_salinity_'+profondeur(prof)+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.92, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.0, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;  Clim  ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
           ;; Figure 5 3D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           ;output='logo gif'
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 3 Days Forecast WOA05_Temp '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           ;score_val(*,*)=1
           ;score_val=score_val-(val_rmsF3_temp/val_rmsPERS_temp)
           score_val=1-(val_rmsF3_temp/val_rmsTMLEV)
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
	   name_out='Skillscore3D_'+modele+'_WOA05temperature_'+profondeur(prof)+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.90, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2

           ;; Figure 6 6D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 6 Days Forecast WOA05_Temp '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           ;score_val(*,*)=1
           ;score_val=score_val-(val_rmsF6_temp/val_rmsPERS_temp)
           score_val=1-(val_rmsF6_temp/val_rmsTMLEV)
           field=score_val
           valcmax=MAX(field,/NaN)
           print ,"valcmax :: ",valcmax
           kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           ishold=1
           print ,'PLOT 2D field'
           field(*,*)=!values.f_nan
	   name_out='Skillscore6D_'+modele+'_WOA05_temperature_'+profondeur(prof)+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.92, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.0, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2

           ;; Figure 7 3D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           ;output='logo gif'
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 3 Days Forecast WOA05_Salinity '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF3_sal/val_rmsSMLEV)
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
           name_out='Skillscore3D_'+modele+'_WOA05_salinity_'+profondeur(prof)+'_'+zone
	   plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.92, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.0, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2

  ;; Figure 8 6D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 6 Days Forecast WOA05_Salinity '+modele+' '+ profondeur(prof)
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF6_sal/val_rmsSMLEV)
           field=score_val
           valcmax=MAX(field,/NaN)
           print ,"valcmax :: ",valcmax
           kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           ishold=1
           print ,'PLOT 2D field'
           field(*,*)=!values.f_nan
	   name_out='Skillscore6D_'+modele+'_WOA05_salinity_'+profondeur(prof)+'_'+zone
	   plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=2, DX2=2
           black=  rgb2ind(000,000,000)
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20,0.05,0.80,0.10]
                 plot_txt, 0.90, 0.06, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
		 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.20, 0.15,0.80,0.20]
                 plot_txt, 0.8, 0.06, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
              ELSE:
           ENDCASE
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
           clear,longitude2,latitude2
   prof=prof+1
ENDWHILE 
END



