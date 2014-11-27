PRO tracer_stats_gloCLASS4_pcolor,modele,fichier,fic_mask,filelist,$
                                  var1,var2,profondeur,variable,$
                                  zone,kind,dir_stats,OPER,date_title
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
   'gulf stream':BEGIN
      dom='zoom NATL12 1/12 mercator'
   ENDCASE
   'T':BEGIN
  	if ( modele eq "PSY2V3R1" )  THEN BEGIN
           dom='zoom NATL12 1/12 mercator'
	endif else begin
	;   dom='zoom global 1/4 mercator'
	   dom='zoom ORCA 1/4 mercator hires'
	;   dom='zoom BIG_JAPAN 1/4 mercator'
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
        rms_difftot=dblarr(nb_prof,24,il_nbox,nfichiers)
        mean_difftot=dblarr(nb_prof,24,il_nbox,nfichiers)
        indice_tot=dblarr(nb_prof,24,il_nbox,nfichiers) 
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
           rms_difftot(*,*,*,i)=rms_diff
	   mean_diff=ncdf_lec(file,iodir=dir_stats,var='mean_diff', /nostruct) & mean_diff=transpose(mean_diff)
	   mean_difftot(*,*,*,i)=mean_diff
           nb_valeurs=ncdf_lec(file,iodir=dir_stats,var='indice_box', /nostruct) & nb_valeurs=transpose(nb_valeurs)
           indice_tot(*,*,*,i)=nb_valeurs
           print,'file ok ::',file
	   clear,mean_diff,rms_diff
           i=i+1
        endwhile
        print, "Creation liste ok"
;;-----------------------------------------------------------------------------------------
;; Boucle sur les profondeurs 
;;------------------------------------------------------------------------------------------
;;        prof=10
prof=0L
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
		      'SMLEV'     :  GOTO, label
		      'TMLEV'     :  GOTO, label
                  ELSE: PRINT, 'nom_var',nom_var  
	          ENDCASE
                ENDELSE
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
               FOR il_ind1=0,il_nlon-1 DO BEGIN
                   FOR il_ind2=0,il_nlat-1 DO BEGIN
                       region(il_ind2,il_ind1)=field1(il_ind2,il_ind1)
                       region2=WHERE(boite(*) EQ region(il_ind2,il_ind1))
                       IF region2 NE -1 THEN BEGIN
                           ;val_rms(il_ind2,il_ind1)=rms_diff(prof,var,region2)
                           val_ind(il_ind2,il_ind1)= nb_valeurs(prof,var,region2)
			   ;val_mean(il_ind2,il_ind1)=mean_diff(prof,var,region2)
                           val_rms(il_ind2,il_ind1)=TOTAL(rms_difftot(prof,var,region2,*))
			   val_mean(il_ind2,il_ind1)=TOTAL(mean_difftot(prof,var,region2,*))
                           val_ind(il_ind2,il_ind1)=TOTAL(indice_tot(prof,var,region2,*))
                           val1(il_ind2,il_ind1)=SQRT(val_rms(il_ind2,il_ind1)/val_ind(il_ind2,il_ind1))
                           val2(il_ind2,il_ind1)=val_mean(il_ind2,il_ind1)/val_ind(il_ind2,il_ind1)
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
               nom_var=variable(var)
;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
       clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v,palette
       clear,ymin,ymax,xmin,xmax ;,strmin,strmax
      ; output='screen'
       output='A3 ps'
;       output='gif'
;       ishold=1
       domain=dom
       clear,titre,units
       titre='Class4 RMS Misfit '+ nom_var+' '+modele+' '+ profondeur(prof)+' '+date_title
       units='Rms misfit'
  ;     plot_2Dfield
       x1=lon
       x2=lat
       field=val1
       valcmax=MAX(val1,/NaN)
       valcmin=MIN(val1,/NaN)
       ; val_dc=valeurs_dc(indice_var,prof)
     	if ( indice_var EQ  1 ) THEN BEGIN 
         kindchoice=kind & cmin=0. & cmax=0.5 & dc=0.01
	endif
         if ( indice_var EQ  0 ) THEN BEGIN 
          kindchoice=kind & cmin=0. & cmax=2 & dc=0.05
         endif
      ;palette='ferret' ;
      kindchoice='no_iso stddev UserLevels publi' ;kind
      ishold=1
      print ,'PLOT 2D field'
      x1=lon
      x2=lat
      rms_diff1 =val1
      rms_diff2 =val1
      rms_diff3 =val1
      nb_val=val_ind
      ;tri=SORT(nb_val/1000)
      ;ndata = n_elements(nb_val)
      ;p25=nb_val[tri[25*ndata / 100 ]]
      ii=where(FINITE(nb_val,/NAN) EQ 0)
      nb_val2=nb_val(ii)
      p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
      ;;p25=p25*100
      p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
      ;;p75=p75*100
      il_indice1=WHERE(nb_val GT p25 ) ;; 1
      rms_diff1(il_indice1)=!values.f_nan
    ;;  il_indice2=WHERE(nb_val/1000 LT 1 OR nb_val/1000 GT 5)
      il_indice2=WHERE(nb_val LT p25 OR nb_val GT p75 )
      rms_diff2(il_indice2)=!values.f_nan
      ;;il_indice3=WHERE(nb_val/1000 LT 5)
      il_indice3=WHERE(nb_val LT p75 )
      rms_diff3(il_indice3)=!values.f_nan
      print,'percentile 25 ',p25
      print,'percentile 75 ',p75
     ; pcolor,TRANSPOSE(val1),cmin=valcmin, cmax=valcmax,DX1=dx, DX2=dy
    ;  domain='zoom Indian 1/12 mercator'
    ;  prep_output, [200,200] & my_colormap, 'stddev'	
      field(*,*)=!values.f_nan
      fmin=valcmin
      fmax=valcmax
      name_out='Rms_Misfit_Class4pcolor_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+zone+'_'+date_title
      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
      pcolor,rms_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
      pcolor,rms_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
      pcolor,rms_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
;      plot_2Dfield
;      pcolor,rms_diff1,lon,lat,cmin=0, cmax=2,DX1=1, DX2=1  
;      pcolor,rms_diff2,lon,lat,cmin=0, cmax=2,DX1=1, DX2=1
;      pcolor,rms_diff3,lon,lat,cmin=0, cmax=2,DX1=1, DX2=1
;
;      plot_2Dfield
;      pcolor,rms_diff1,lon,lat,cmin=0, cmax=2,DX1=0.75, DX2=0.75  
;      pcolor,rms_diff2,lon,lat,cmin=0, cmax=2,DX1=0.75, DX2=0.75
;      pcolor,rms_diff3,lon,lat,cmin=0, cmax=2,DX1=0.75, DX2=0.75
;
       black=  rgb2ind(000,000,000)
      CASE zone OF
        'A':BEGIN
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
	 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.10]
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
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
	 ;XYOUTS,0.2,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
	 ;XYOUTS,0.015,0.08,['!9B!3'], /norm, alignment=1.0, CHARSIZE=1.5, COLOR=black
	 ;XYOUTS,0.2,0.06,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
	 ;XYOUTS,0.01,0.06,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black
	 ;XYOUTS,0.2,0.04,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
	 ;XYOUTS,0.01,0.04,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.25, COLOR=black
         COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30, 0.15,0.90,0.20]
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
       ELSE:
       ENDCASE

;       pcolor,val1,lon,lat,DX1=dx, DX2=dy ,CMIN=valcmin,CMAX=valcmax ;, $
;       NLEVELS=ncolors, START_COLOR=start_color, END_COLOR=end_color
;       plot_2Dfield & pcolor, FIELD, X1, X2,DX1=dx, DX2=dy        
;      pcolor,field,x1,x2,DX1=dx, DX2=dy
       ; Sauvegarde de l'image obtenue
       ishold=0
       do_output,dirname_out+'RMS_Misfit_Class4pcolor_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+zone+'_'+date_title
       ;clear,longitude2,latitude2
;;
       clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
       clear,ymin,ymax,xmin,xmax ;,strmin,strmax
       output='gif'
       output='A3 ps'
       domain=dom
       clear,titre,units
       titre='Class4 Mean Diff '+ nom_var+' '+modele+' '+ profondeur(prof)+' '+date_title
       units='Mean Diff'
       x1=lon
       x2=lat
       field=val2
       valcmax=MAX(val2,/NaN)
       valcmin=MIN(val2,/NaN)
     	if ( indice_var EQ  1 ) THEN BEGIN 
          cmin=-0.5 & cmax=0.5 & dc=0.01
	endif
         if ( indice_var EQ  0 ) THEN BEGIN 
          cmin=-2. & cmax=2 & dc=0.05
         endif
      kindchoice='unknown difference no_iso UserLevels publi'
      palette='sla'
      units='Deg C'
      ishold=1
      print ,'PLOT 2D field'
      x1=lon
      x2=lat
      mean_diff1 =val2
      mean_diff2 =val2
      mean_diff3 =val2
      nb_val=val_ind
      ii=where(FINITE(nb_val,/NAN) EQ 0)
      nb_val2=nb_val(ii)
      p25=nb_val2( (SORT(nb_val2) ) (25 * N_ELEMENTS(nb_val2) / 100) ) 
      p75=nb_val2( (SORT(nb_val2) ) (75 * N_ELEMENTS(nb_val2) / 100) ) 
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
      name_out='Mean_Diff_Class4pcolor_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+zone+'_'+date_title
      plot_2Dfield,OUTPUT_FILE=dirname_out+name_out
      pcolor,mean_diff1,lon,lat,cmin=cmin, cmax=cmax,DX1=0.25, DX2=0.25 
      pcolor,mean_diff2,lon,lat,cmin=cmin, cmax=cmax,DX1=0.75, DX2=0.75
      pcolor,mean_diff3,lon,lat,cmin=cmin, cmax=cmax,DX1=1.5, DX2=1.5
      black=  rgb2ind(000,000,000)
      CASE zone OF
        'A':BEGIN
         ;COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3,0.03,0.7,0.06]
	 COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30,0.05,0.90,0.10]
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
        ; COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)', Position=[0.3, 0.08,0.7,0.11]
        ; XYOUTS,0.2,0.08,'nb_data >='+string(p75, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
        ; XYOUTS,0.015,0.08,['!9B!3'], /norm, alignment=1.0, CHARSIZE=1.5, COLOR=black
        ; XYOUTS,0.2,0.06,'nb_data >='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
        ; XYOUTS,0.01,0.06,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.75, COLOR=black
        ; XYOUTS,0.2,0.04,'nb_data <='+string(p25, FORMAT='(F9.2)'), /norm, alignment=1.0, CHARSIZE=1, COLOR=black
        ; XYOUTS,0.01,0.04,['!9B!3'], /norm, alignment=1.0, CHARSIZE=0.25, COLOR=black
         COLORBAR, bottom=1, color=black, Range=[cmin, cmax], Format='(F5.2)',CHARSIZE=1.8, Position=[0.30, 0.15,0.90,0.20]
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
       ELSE:
       ENDCASE
       ; Sauvegarde de l'image obtenue
       ishold=0
       do_output,dirname_out+'Mean_Diff_Class4pcolor_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+zone+'_'+date_title
       clear,longitude2,latitude2
    label:
    ENDFOR
   prof=prof+1
ENDWHILE 
END



