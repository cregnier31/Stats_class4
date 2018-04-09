PRO tracer_skillscore_gloCLASS4_supobs_GODAE_2D,modele,fichier,fic_mask,filelist,$
                                  var1,var2,variable,zone,kind,dir_stats,date_title

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
; C.REGNIER  octobre   2013 Adaptation pour les stats 2D de SST et SLA 
;=========================================================================
@param
@param_class4


file2=fic_mask
file=fichier
nb_variables=N_ELEMENTS(variable)
print,zone
print,date_title
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
	print,'file :: ',dir_stats,file
        boite=ncdf_lec(file,iodir=dir_stats,var='box', /nostruct) & boite=transpose(boite)
        il_nlon=N_ELEMENTS(lon(1,*))
        il_nlat=N_ELEMENTS(lat(*,1))
        il_nbox=N_ELEMENTS(boite)	  
        i1=N_ELEMENTS(field1(1,*))
        i2=N_ELEMENTS(field1(*,1))
        nfichiers=N_ELEMENTS(filelist)
        print ,'Nombre de boites :: ',il_nbox
	;** Allocate tab
	print,'dimensions :: ',1,nb_variables,il_nbox,nfichiers
        rms_difftot=dblarr(1,nb_variables,il_nbox,nfichiers)
        indice_tot=dblarr(1,nb_variables,il_nbox,nfichiers) 
        print,'nb_var  :: ',nb_variables
        print,'nb_box  :: ',il_nbox  
	print,'nb_fichier  :: ',nfichiers

;; Lecture des rms 
        i=0L
        while i le nfichiers-1 do begin 
           file=filelist(i)
	   print ,'file',file
           rms_diff=ncdf_lec(file,iodir=dir_stats,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
	   print,dir_stats+file
           rms_difftot(*,*,*,i)=rms_diff^2
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
     prof=0L
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
                  'HDCST_SST' : BEGIN
		     varname='sst'
                     indice_var=0
                     xxl='DegC'
                     type_obs='hindcast'
		   ENDCASE
                  'HDCST_SLA' : BEGIN
		     varname='sla'
                     indice_var=2
                     xxl='m'
                     type_obs='hindcast'
		   ENDCASE
		  'HDCST_PSAL' : BEGIN 
		     varname='salinity'
                     indice_var=1
	             xxl='PSU'
                     type_obs='hindcast'
		   ENDCASE
	          'PERS1D_TEMP' : BEGIN	
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence1Day'
                   ENDCASE
	          'PERS1D_SST' : BEGIN	
                     varname='sst'
                     xxl='DegC'
                     type_obs='persistence1Day'
                   ENDCASE
	          'PERS1D_PSAL' : BEGIN	
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence1Day'
                   ENDCASE
		  'PERS1D_SLA' : BEGIN
                     varname='sla'
                     xxl='m'
                     type_obs='persistence1Day'
                   ENDCASE
		  'PERS3D_TEMP' : BEGIN
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence3Day'
                   ENDCASE
		  'PERS3D_SST' : BEGIN
                     varname='sst'
                     xxl='DegC'
                     type_obs='persistence3Day'
                   ENDCASE
		   'PERS3D_PSAL' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence3Day'
                   ENDCASE
                  'PERS3D_SLA' : BEGIN
                     varname='sla'
                     xxl='m'
                     type_obs='persistence3Day'
                   ENDCASE
                  'PERS5D_TEMP' : BEGIN
                     varname='temperature'
                     xxl='DegC'
                     type_obs='persistence5Day'
                   ENDCASE
                  'PERS5D_SST' : BEGIN
                     varname='sst'
                     xxl='DegC'
                     type_obs='persistence5Day'
                   ENDCASE
		  'PERS5D_PSAL' : BEGIN
                     varname='salinity'
                     xxl='PSU'
                     type_obs='persistence5Day'
                   ENDCASE
                  'PERS5D_SLA' : BEGIN
                     varname='sla'
                     xxl='m'
                     type_obs='persistence5Day'
                   ENDCASE
		  'FRCST1D_TEMP' : BEGIN
		     varname='temperature'
                     xxl='DegC'
                     type_obs='forecast1Day'
                   ENDCASE	       
		  'FRCST1D_SLA' : BEGIN
		     varname='sla'
                     xxl='m'
                     type_obs='forecast1Day'
                   ENDCASE
		  'FRCST1D_SST' : BEGIN
		     varname='sst'
                     xxl='°C'
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
		  'FRCST3D_SST' : BEGIN
		     varname='sst'
                     xxl='DegC'
                     type_obs='forecast3Day'
                   ENDCASE	       
		  'FRCST3D_SLA' : BEGIN
		     varname='sla'
                     xxl='m'
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
		  'FRCST5D_SST' : BEGIN
		     varname='sst'
                     xxl='DegC'
                     type_obs='forecast5Day'
                   ENDCASE	       
		  'FRCST5D_SLA' : BEGIN
		     varname='sla'
                     xxl='m'
                     type_obs='forecast5Day'
                   ENDCASE	       
		  'FRCST5D_PSAL' : BEGIN
		     varname='salinity'
                     xxl='PSU'
                     type_obs='forecast5Day'
                   ENDCASE	       
		   ELSE:
	        ENDCASE
               e3t=1
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
                            vect=WHERE(rms_difftot(0,var,region2,il_indice) GT 0)
			    IF (vect(0) NE -1) THEN BEGIN
                              val_rms_tmp=val_rms_tmp+rms_difftot(0,var,region2,il_indice)*e3t
                              val_nbval_tmp=val_nbval_tmp+indice_tot(0,var,region2,il_indice)
			      val_tot_e3t=val_tot_e3t+e3t
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
	       ii=where( val_ind LT 100 )
	       IF ( nom_var eq 'FRCST1D_SLA' or nom_var eq 'FRCST1D_SST')  THEN BEGIN
                  val_rmsF1=fltarr(il_nlat,il_nlon)
                  val_rmsF1=val1
                  if ( ii(0) ne -1) THEN val_rmsF1(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'FRCST3D_SLA' or nom_var eq 'FRCST3D_SST')  THEN BEGIN
                  val_rmsF3=fltarr(il_nlat,il_nlon)
                  val_rmsF3=val1	
		  if ( ii(0) ne -1) THEN val_rmsF3(ii)=!values.f_nan
               ENDIF 
               IF ( nom_var eq 'FRCST5D_SLA'  or nom_var eq 'FRCST5D_SST')  THEN BEGIN
                  val_rmsF5=fltarr(il_nlat,il_nlon)
                  val_rmsF5=val1
         	  if ( ii(0) ne -1) THEN val_rmsF5(ii)=!values.f_nan
               ENDIF
               IF ( nom_var eq 'PERS1D_SLA' or nom_var eq 'PERS1D_SST')  THEN BEGIN
                  val_rmsPERS1D=fltarr(il_nlat,il_nlon)            
                  val_rmsPERS1D=val1
		  if ( ii(0) ne -1) THEN val_rmsPERS1D(ii)=!values.f_nan
               ENDIF 
	       IF ( nom_var eq 'PERS3D_SLA' or nom_var eq 'PERS3D_SST')  THEN BEGIN
                  val_rmsPERS3D=fltarr(il_nlat,il_nlon)
                  val_rmsPERS3D=val1
                  if ( ii(0) ne -1) THEN val_rmsPERS3D(ii)=!values.f_nan
               ENDIF
	       IF ( nom_var eq 'PERS5D_SLA' or nom_var eq 'PERS5D_SST')  THEN BEGIN
                  val_rmsPERS5D=fltarr(il_nlat,il_nlon)
                  val_rmsPERS5D=val1
                  if ( ii(0) ne -1) THEN val_rmsPERS5D(ii)=!values.f_nan
               ENDIF


;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
               label:
            ENDFOR
           output1='A3 ps'
           xxl='SSP'

	   ;; Figure 1 1D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 1 Days Forecast '+varname+' '+modele+' '+date_title
           units='SSP'
	   x1=fltarr(il_nlat,il_nlon)
	   x2=fltarr(il_nlat,il_nlon)
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF1/val_rmsPERS1D)
           field=score_val
           ;; Sauvegarde fichier
           file=dirname_out+'skill_score1D_'+modele+'_'+varname+'_'+date_title+'.nc'
           TAB=score_val
           XGRID=lon
           YGRID=lat
           ZGRID=0
           choice='skill_score_1D_forecast_'+varname
           write_ncdf,file,TAB,XGRID,YGRID,ZGRID,1,choice
           ;;
           valcmax=MAX(field,/NaN)
           valcmin=MIN(field,/NaN)
           print ,"valcmax :: ",valcmax
           ;kind='no_iso temperature difference'
           kindchoice=kind & cmin=-0.5 & cmax=0.5 & dc=0.05
           ishold=1
           print ,'PLOT 2D field',kindchoice
           field(*,*)=!values.f_nan
           fmin=valcmin
           fmax=valcmax
	   name_out='Skillscore1D_'+modele+'_'+varname+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=1.0, DX2=1.0
           black=  rgb2ind(000,000,000)
	   ncolors=253
           CASE zone OF
              'A':BEGIN
                ;  COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
	         XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                 plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
	         XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                 plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'
              ENDCASE
              ELSE:
           ENDCASE
           ishold=1
           field(*,*)=!values.f_nan
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
	   
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
         ;  subst_str,name_out, 'temperature', 'tn'
         ;  subst_str,name_out, '-', '_'
	   SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
	   SPAWN,'rm '+dirname_out+name_out+'.ps'	
           clear,longitude2,latitude2


           ;; Figure 2 3D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 3 Days Forecast '+varname+' '+modele+' '+date_title
           units='SSP'
	   x1=fltarr(il_nlat,il_nlon)
	   x2=fltarr(il_nlat,il_nlon)
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF3/val_rmsPERS3D)
           field=score_val
	   ;; Sauvegarde fichier
           file=dirname_out+'skill_score3D_'+modele+'_'+varname+'_'+date_title+'.nc'
           TAB=score_val
           XGRID=lon
           YGRID=lat
           ZGRID=0
           choice='skill_score_3D_forecast_'+varname
           write_ncdf,file,TAB,XGRID,YGRID,ZGRID,1,choice
           ;;
           valcmax=MAX(field,/NaN)
           valcmin=MIN(field,/NaN)
           print ,"valcmax :: ",valcmax
           ;kind='no_iso temperature difference'
           ;kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           kindchoice=kind & cmin=-0.5 & cmax=0.5 & dc=0.1
           ishold=1
           print ,'PLOT 2D field',kindchoice
           field(*,*)=!values.f_nan
           fmin=valcmin
           fmax=valcmax
	   name_out='Skillscore3D_'+modele+'_'+varname+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=1.0, DX2=1.0
           black=  rgb2ind(000,000,000)
	   ncolors=253
           CASE zone OF
              'A':BEGIN
                ;  COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
	         XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                 plot_txt, 0.9, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
	         XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                 plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'
              ENDCASE
              ELSE:
           ENDCASE
           ishold=1
           field(*,*)=!values.f_nan
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
	   
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
         ;  subst_str,name_out, 'temperature', 'tn'
         ;  subst_str,name_out, '-', '_'
	   SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
	   SPAWN,'rm '+dirname_out+name_out+'.ps'	
           clear,longitude2,latitude2


           ;; Figure 3 5D Forecast
           clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,score_val
           clear,ymin,ymax,xmin,xmax,palette ;,strmin,strmax
           output=output1
           domain=dom
           clear,titre,units
           titre='Class4 SSP 5 Days Forecast '+varname+' '+modele+' '+date_title
           units='SSP'
           x1=lon
           x2=lat
           score_val=fltarr(il_nlat,il_nlon)
           score_val(*,*)=!values.f_nan
           score_val=1-(val_rmsF5/val_rmsPERS5D)
           field=score_val
	   ;; Sauvegarde fichier
           file=dirname_out+'skill_score5D_'+modele+'_'+varname+'_'+date_title+'.nc'
           TAB=score_val
           XGRID=lon
           YGRID=lat
           ZGRID=0
           choice='skill_score_5D_forecast_'+varname
           write_ncdf,file,TAB,XGRID,YGRID,ZGRID,1,choice
           ;;
           valcmax=MAX(field,/NaN)
           ;kindchoice=kind & cmin=-1. & cmax=1 & dc=0.1
           kindchoice=kind & cmin=-0.4 & cmax=0.4 & dc=0.05
           print ,'PLOT 2D field',kindchoice
           field(*,*)=!values.f_nan
           ishold=1
	   name_out='Skillscore5D_'+modele+'_'+varname+'_'+zone
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
           ishold=1
           pcolor,score_val,lon+2,lat,cmin=cmin, cmax=cmax,DX1=1.0, DX2=1.0
           black=  rgb2ind(000,000,000)
           ncolors=253
           CASE zone OF
              'A':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
                 COLORBAR, bottom=2,NCOLORS=ncolors,color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10,0.05,0.90,0.07]
	         XYOUTS,0.5,0.08,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                 plot_txt, 0.90, 0.08, '!3med value = '+coord2ch('real',  MEDIAN(score_val)), 1.2, black, 'normal'
              ENDCASE
              'T':BEGIN
                 ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
                 COLORBAR, bottom=2,NCOLORS=ncolors, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.10, 0.12,0.90,0.17]
	         XYOUTS,0.5,0.19,xxl, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=black
                 plot_txt, 0.8, 0.04, '!3median value = '+coord2ch('real',  MEDIAN(score_val)), 1.5, black, 'normal'        
              ENDCASE
           ENDCASE
           ishold=1
           field(*,*)=!values.f_nan
           plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
       ; Sauvegarde de l'image obtenue
           ishold=0
           do_output,dirname_out+name_out
         ;  subst_str,name_out, 'temperature', 'tn'
         ;  subst_str,name_out, '-', '_'
	   SPAWN,'convert -density 600 -rotate -90 -background white -flatten -resize 15% '+dirname_out+name_out+'.ps '+dirname_out+name_out+'.gif'
	   SPAWN,'rm '+dirname_out+name_out+'.ps'
           clear,longitude2,latitude2
           
END



