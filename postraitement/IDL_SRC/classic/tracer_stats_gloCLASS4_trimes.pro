PRO tracer_stats_gloCLASS4_trimes,modele,fichier,fic_mask,filelist,$
                                  var1,var2,profondeur,variable,$
                                  zone,kind,dir_stats,OPER
;==========================================================================
;##  Trace des statistiques pour les fichers class4
;    pour un paramètre donné pour toutes les profondeurs
;    Marche pour les statistiques basées sur la grille maskbox.nc 
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
;;-------------------------------------------------
;; Liste de modeles en fonction de la zone
;;--------------------------------------------------
model_name=modele

CASE zone OF
   'A':BEGIN
      print,'Zone Atlantique'
      dom='zoom NATL12 1/12 mercator hires'
   ;   dom='zoom NATL12 raw nocont no_iso HR_orography' 
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
  	if ( modele eq "PSY2V4R2" )  THEN BEGIN
           dom='zoom NATL12 1/12 mercator'
	endif else begin
	   dom='zoom global 1/4 mercator'
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
        print,'OK1',N_ELEMENTS(boite) 
        il_nlon=N_ELEMENTS(lon(1,*))
        il_nlat=N_ELEMENTS(lat(*,1))
        il_nbox=N_ELEMENTS(boite)	  
        i1=N_ELEMENTS(field1(1,*))
        i2=N_ELEMENTS(field1(*,1))
        nfichiers=N_ELEMENTS(filelist)
        ;rms_difftot=dblarr(nb_prof,22,il_nbox,nfichiers)
        ;indice_tot=dblarr(nb_prof,22,il_nbox,nfichiers) 
        rms_difftot=fltarr(nb_prof,24,il_nbox,nfichiers)
        indice_tot=fltarr(nb_prof,24,il_nbox,nfichiers) 
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
           nb_valeurs=ncdf_lec(file,iodir=dir_stats,var='indice_box', /nostruct) & nb_valeurs=transpose(nb_valeurs)
           indice_tot(*,*,*,i)=nb_valeurs
           print,'file ok ::',file
           i=i+1
        endwhile
        print, "Creation liste ok"
;;-----------------------------------------------------------------------------------------
;; Boucle sur les profondeurs 
;;------------------------------------------------------------------------------------------
        prof=10
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
                             val1(il_ind2,il_ind1)=SQRT(val_rms(il_ind2,il_ind1)/val_ind(il_ind2,il_ind1))
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

;;-------------------------------------------------------------------------------------
;;      Tracé des images
;;------------------------------------------------------------------------------------
       clear,dc,output,cmin,cmax,fmin,fmax,field,kindchoice,v
       clear,ymin,ymax,xmin,xmax ;,strmin,strmax
       output='logo gif'
       domain=dom
       clear,titre,units
       titre='Class4 RMS Misfit '+ nom_var+' '+modele+' '+ profondeur(prof)
       units='Rms misfit'
       x1=lon
       x2=lat
       field=val1
       valcmax=MAX(val1,/NaN)
       print ,"valcmax :: ",valcmax
       ; val_dc=valeurs_dc(indice_var,prof)
     	if ( indice_var EQ  1 ) THEN BEGIN 
         kindchoice=kind & cmin=0. & cmax=0.5 & dc=0.01
	endif
         if ( indice_var EQ  0 ) THEN BEGIN 
          kindchoice=kind & cmin=0. & cmax=2 & dc=0.05
         endif
      ;palette='ferret' ;
       kindchoice=kind
       indice=WHERE(val1(*,*) NE !values.f_nan )
       ;  kindchoice='no_iso'
       ishold=1
       print ,'PLOT 2D field'
       plot_2Dfield
       ; Sauvegarde de l'image obtenue
       ishold=0
       do_output,dirname_out+'Misfit_Class4_'+modele+'_'+nom_var+'_'+profondeur(prof)+'_'+zone
   ;; 2EME image
       clear,cmin,cmax,fmin,fmax,field,kindchoice,v
       clear,ymin,ymax,xmin,xmax ;,strmin,strmax
       ishold=1
       output='gif'
       domain=dom
       clear,titre,units ;,strmin,strmax;;clear,titre,units,strmin,strmax
       titre='Nb values Class4 RMS Misfit (10**3) '+nom_var+'_'+modele+'_'+ profondeur(prof)
       indice2=WHERE(val_ind(*,*) NE !values.f_nan )
       field=val_ind/1000
       x1=lon
       x2=lat
       units='profil number'
       ;kindchoice=kind & cmin=0. & cmax=MAX(field,/NaN)  & dc=10000
       ;kindchoice=kind & cmin=0. & cmax=30 & dc=1
       kindchoice=kind & cmin=0 & cmax=10 & dc=1 & fmin=MIN(val_ind,/NaN)/1000 & fmax=MAX(val_ind,/NaN)/1000
       print,'MIN, MAX :: ',MIN(val_ind,/NaN)/1000,MAX(val_ind,/NaN)/1000
       plot_2Dfield
       ; Sauvegarde de l'image obtenue
       ishold=0
       do_output,dirname_out+'Val_Misfit_'+nom_var+'_'+modele+'_'+ profondeur(prof)+'_'+zone
       clear,longitude2,latitude2
    label:
    ENDFOR
   prof=prof+1
ENDWHILE 
END



