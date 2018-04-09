PRO tracer_suivi_meandiff,modele,fichier,fic_mask,profondeur,variable_name, $
                                 kind,filelist,dir_stats_MERC,days,valeurs_cmax,valeurs_cmax_sal,liste_zone,tab_choix,OPER
;==========================================================================
;##  Trace de l'evolution de la mean difference pour les fichiers class4
;
;    author: C REGNIER Novembre 2010 :: Creation
;
;==========================================================================

@param
@param_class4

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Definition des variables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file3=fic_mask
file=fichier
nb_prof=N_ELEMENTS(profondeur)
range_values=fltarr(2,nb_prof)
NB_VALEURS=3
NB_VALEURS2=3

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Lecture des boites
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
x1=ncdf_lec(file3,iodir=dir_mask,var='longitude', /nostruct) & x1=transpose(x1)
x2=ncdf_lec(file3,iodir=dir_mask,var='latitude', /nostruct) & x2=transpose(x2)
boite=ncdf_lec(file,iodir=dirin,var='box', /nostruct) & boite=transpose(boite)

FOR ind=0,N_ELEMENTS(tab_choix)-1 DO BEGIN 
   FOR ind2=0,N_ELEMENTS(liste_zone)-1 DO BEGIN 
      PRINT,'choix, ZONE :: ',tab_choix(ind),'   ',liste_zone(ind2) 
      var=tab_choix(ind)
      zone=liste_zone(ind2)
      if (var eq 'SAL') THEN BEGIN
         il_begin=1
         range_values=valeurs_cmax_sal
      endif else begin
         if (var eq 'TEMP') THEN BEGIN
            il_begin=0
            range_values=valeurs_cmax
         ENDIF
      ENDELSE

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Choix de la zone
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      CASE zone OF
 	 'BALTIC': BEGIN
	   FIND=WHERE(boite GE 3110 AND boite LE 3120,COUNT)
	 ENDCASE 
	 'NORDSEA':BEGIN
	   FIND1=WHERE(boite GE 3090 AND boite LE 3100,COUNT)
	   FIND2=WHERE(boite EQ 3190, COUNT)
	   FIND=[FIND1,FIND2]
	 ENDCASE
	 'FACADE':BEGIN
	    FIND1=WHERE(boite EQ 3180, COUNT)  
	    FIND2=WHERE(boite GE 3200 AND boite LE 3230,COUNT)
	    FIND3=WHERE(boite GE 3330 AND boite LE 3340,COUNT)
	    FIND=[FIND1,FIND2,FIND3]
	 ENDCASE	
         'ATL':BEGIN
      ;; Atlantique 2000 à 4000
            FIND=WHERE(boite GE 2000 AND boite LT 4000, COUNT)
         ENDCASE
         'NAT':BEGIN
      ;; Atlantique NORD 3000 à 4000
            FIND=WHERE(boite GE 3000 AND boite LT 4000, COUNT)
         ENDCASE
         'SAT':BEGIN
      ;; Atlantique SUD 2000 à 3000
            FIND=WHERE(boite GE 2000 AND boite LT 3000, COUNT)
         ENDCASE
         'MED':BEGIN
      ;; MED 1000 à 1220
            FIND=WHERE(boite GE 1000 AND boite LE 1220, COUNT)
         ENDCASE
         'IND':BEGIN
      ;; Indien de 6000 à 6770
      ;;      FIND=WHERE(boite GE 6000 AND boite LE 6770, COUNT)   
           FIND=WHERE(boite GE 6190 AND boite LE 6770, COUNT)   
         ENDCASE
         'NPA':BEGIN
      ;; Pacifique nord 5000 à 6000
            FIND=WHERE(boite GE 5000 AND boite LT 6000, COUNT)
         ENDCASE
         'SPA':BEGIN
      ;; Pacifique sud et trop de 4000  à 4730
            FIND=WHERE(boite GE 4000 AND boite LE 4730, COUNT)
         ENDCASE
         'ACC': BEGIN
      ;; 'ACC antartique 4770-4800'
          FIND1=WHERE(boite GE 4610 AND boite LE 4900, COUNT) ;; Pacifique
          FIND2=WHERE(boite GE 2050 AND boite LE 2110, COUNT) ;; Atlantique
          FIND3=WHERE(boite GE 6000 AND boite LE 6070, COUNT) ;; Indien
          FIND=[FIND1,FIND2,FIND3] 
       ENDCASE
         'ARC': BEGIN
      ;; 'ARC arctique 7000-7200 '
        ;;  FIND=WHERE(boite GE 7000 AND boite LE 7200, COUNT)
          FIND1=WHERE(boite GE 3000 AND boite LE 3200, COUNT) 
          FIND2=WHERE(boite GE 7000 AND boite LE 7200, COUNT)
	  FIND=[FIND1,FIND2]
       ENDCASE
         'TAT': BEGIN
      ;; TAT 2120-2360 ; 3440-3790 ; 30N-30S
      ;;    FIND1=WHERE(boite GE 2120 AND boite LE 2360, COUNT)
      ;;    FIND2=WHERE(boite GE 3440 AND boite LE 3790, COUNT)
      ;;    FIND=[FIND1,FIND2]
      ; TAT  20N-20S
          FIND1=WHERE(boite GE 2120 AND boite LE 2310, COUNT)
          FIND2=WHERE(boite GE 3590 AND boite LE 3790, COUNT)
          FIND=[FIND1,FIND2]
      
       ENDCASE
        'TPA': BEGIN
      ;; TPA 4000-4530 ; 5260-5880 ; 30N-30S
      ;;    FIND1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
      ;;    FIND2=WHERE(boite GE 5260 AND boite LE 5880, COUNT)
      ;;    FIND=[FIND1,FIND2]
          FIND1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
          FIND2=WHERE(boite GE 5430 AND boite LE 5880, COUNT)
          FIND=[FIND1,FIND2]
       ENDCASE
        'Golf_stream':BEGIN
      ;; golf stream
      ;FIND=WHERE(boite EQ 3310, COUNT)
      ;;FIND=WHERE(boite GE 3260 AND boite LE 3280, COUNT)   ENDCASE
         FIND=WHERE(boite GE 3250 AND boite LE 3280, COUNT)
        ENDCASE
        'GLO':BEGIN
      ;; GLOBAL
           FIND=WHERE(boite GE 0, COUNT)
        ENDCASE
        
         ELSE:
           ;print ,'Zone non reconnue'
           ;exit,/NO_CONFIRM
         ENDCASE
      
      indice_i=FIND(0)
      taille=N_ELEMENTS(FIND(*))
      indice_f=FIND(taille-1)
      nfichiers=N_ELEMENTS(filelist)
      ;print,'PROFS , fichiers' ,nb_prof,nfichiers
      i=0L
      meanval_difftot=dblarr(nb_prof,22,412,nfichiers)
      indice_tot=dblarr(nb_prof,22,412,nfichiers) ;intarr
      ;diff=fltarr(nfichiers-1)
      while i le nfichiers-1 do begin
        file=filelist(i)
        dirin=dir_stats_MERC
        meanval_diff=ncdf_lec(file,iodir=dirin,var='mean_diff', /nostruct) & meanval_diff=transpose(meanval_diff)
    ;;    meanval_difftot(*,*,*,i)=meanval_diff
        meanval_difftot(*,*,*,i)=meanval_diff(*,0:21,*,*)
        indice=ncdf_lec(file,iodir=dirin,var='indice_box', /nostruct) & indice=transpose(indice)
      ;;  indice_tot(*,*,*,i)=indice
        indice_tot(*,*,*,i)=indice(*,0:21,*,*)
      ;  diff(i)=indice_tot(*,*,*,i)-indice
        il_nbreg=N_ELEMENTS(meanval_diff(1,1,*))
       ;; il_nelem=N_ELEMENTS(meanval_diff(1,*,1))
        il_nelem=N_ELEMENTS(meanval_diff(1,*,1))-2
        il_nprof=N_ELEMENTS(meanval_diff(*,1,1))
        i=i+1
      endwhile
      vect_val=intarr(taille)
      ; On enleve PSAL et TEMP
      meanval=dblarr(nb_prof,il_nelem-2,nfichiers)
      meanval_cumul=dblarr(nb_prof,il_nelem-2,nfichiers)
      nbval_cumul=dblarr(nb_prof,il_nelem-2,nfichiers)
      val_meanval=0L
      val_meanval2=0L 
      val_nbval=0L
      meanval(*,*,*)=0L
      meanval_cumul(*,*,*)=0L
      nbval_cumul(*,*,*)=0L
      prof=0L 
      fichier=0L
      
      WHILE prof le N_ELEMENTS(profondeur)-1 DO BEGIN
         FOR fichier=0,nfichiers-1 DO BEGIN
            FOR il_ind2=2,il_nelem-1 DO BEGIN
            ;; Recherche des indices valides    
         ;      print,'indice :: ',indice_i,indice_f
           ;    vect_val=WHERE(meanval_difftot(prof,il_ind2,indice_i:indice_f,fichier) NE 0)
               vect_val=WHERE(meanval_difftot(prof,il_ind2,indice_i:indice_f,fichier) GT 0)
              ; PRINT,vect_val
            ;; Calcul de la meanval
               IF (vect_val(0) NE -1) THEN BEGIN
              ; PRINT,'Valeur :: ',prof,il_ind2,vect_val,indice_i,fichier
                val_meanval=TOTAL(meanval_difftot(prof,il_ind2,vect_val+indice_i,fichier)) / TOTAL(indice_tot(prof,il_ind2,vect_val+indice_i,fichier))
		val_meanval2=TOTAL(meanval_difftot(prof,il_ind2,vect_val+indice_i,fichier))
		val_nbval=TOTAL(indice_tot(prof,il_ind2,vect_val+indice_i,fichier))
	;	print ,'Val meanval ',val_meanval,prof,il_ind2,vect_val+indice_i,fichier,TOTAL(meanval_difftot(prof,il_ind2,vect_val+indice_i,fichier)),TOTAL(indice_tot(prof,il_ind2,vect_val+indice_i,fichier))
               meanval(prof,il_ind2-2,fichier)=val_meanval
	       meanval_cumul(prof,il_ind2-2,fichier)=val_meanval2
	       nbval_cumul(prof,il_ind2-2,fichier)=val_nbval
               ENDIF
            ENDFOR
            print,'fichier number :: ',fichier
         ENDFOR 
         prof=prof+1
      ENDWHILE 
      
      
      ; Valeurs des jours en jours juliens
      ndays=N_ELEMENTS(days)
      jours=fltarr(ndays)
      
      FOR il_ind=0,ndays-1 DO BEGIN
         chdate2jul,STRING(days(il_ind)) , yyyy, mm, dd, run1
         jours(il_ind)=run1
      ENDFOR
      
      ;; Definition des couleurs du tracé
      Def_colors
      common COLOR_BLOCK,black,grey,white,bleuey,cyan,green,gold,yellow,red,blue,salmon,aquam,brown,burly,gmt_land
      c1_bis=black  ;; noir
      c1=white  ;; noir
      c2=blue  ;; bleu
      c3=green ;; vert
      c4=red ;; vert
      c5=cyan
      c6=salmon
      c7=brown
      c8=grey
      c9=gold
      
      
      output='gif'
      prof=0L 
      tab_ASCII=fltarr(6,nfichiers)
      tab_ASCII_2=fltarr(6)
      ;; Boucle sur les profondeurs
      
      WHILE prof le nb_prof-1 DO BEGIN
	   tab_ASCII(*,*)=0L
           clear,ctot
           il_ind2=0L
	   il_ind3=0L
           il_ind=0L
           ctot=intarr(9,3)
           ctot(0,*)=c1
           if (prof ge 0) then ctot(0,*)=c1_bis
           ctot(1,*)=c2
           ctot(2,*)=c3
           ctot(3,*)=c4
           ctot(4,*)=c5
           ctot(5,*)=c6
           ctot(6,*)=c7
           ctot(7,*)=c8
           ctot(8,*)=c9
      ;; Boucle sur les variables 
           FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
              clear,numx1,numx2   
              numx1=jours
              numx2=meanval(prof,il_ind,*)
              titre='Mean diff '+var+' '+modele+' '+profondeur(prof)+ ' class4 '+zone
              xtitle='mean diff'
              clear,cmin,cmax
           ;   cmin=range_values(0,prof)
           ;   cmax=range_values(1,prof)
              i=WHERE(meanval EQ 0) & IF i(0) NE -1 THEN  meanval(i)=!VALUES.F_NAN
              if (var eq 'SAL') THEN BEGIN
                   cmin=MIN( meanval(prof,1:*:2,*),/NaN )
                   cmax=MAX( meanval(prof,1:*:2,*),/NaN )
		   if cmax GT 1.5 THEN cmax=1.5 
               endif else begin
              if (var eq 'TEMP') THEN BEGIN
                 cmin=MIN( meanval(prof,0:*:2,*),/NaN )
                 cmax=MAX( meanval(prof,0:*:2,*),/NaN )
		 if cmax GT 3 THEN cmax=3
               endif
              endelse
           	   
              xtitle2=boite(il_ind+2)
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
              ishold=1
              Number=WHERE(numx2(*) GT 0)
              ;Number=WHERE(numx2(*) NE 0)
              IF number(0)  NE -1 THEN BEGIN
              ;  PRINT ,'Variable Valide',variable_name(il_ind+2)  
                IF ( OPER eq "NO" )  THEN BEGIN 
                 ;  IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                 ;   and variable_name(il_ind+2) ne 'PERS3D_TEMP'  and variable_name(il_ind+2) ne 'PERS3D_PSAL' $
                 ;   and variable_name(il_ind+2) ne 'PERS6D_TEMP'  and variable_name(il_ind+2) ne 'PERS6D_PSAL' ) THEN BEGIN
                   IF (variable_name(il_ind+2) eq 'HDCST_TEMP' or variable_name(il_ind+2) eq 'HDCST_PSAL' or $
	         	variable_name(il_ind+2) eq 'SMARV' or variable_name(il_ind+2) eq 'TMARV' or $
			variable_name(il_ind+2) eq 'SMLEV' or variable_name(il_ind+2) eq 'TMLEV' ) THEN BEGIN
                      meanval_smooth=SMOOTH(MEDIAN(transpose(meanval(prof,il_ind,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                      ;numx2=meanval_smooth
                      numx2=meanval(prof,il_ind,*)
                      plot_serietemp_test,1.5,val4,PLOT_KIND=kind,NOTE2=variable_name(il_ind+2) ;,OVERPLOT=8
                      il_ind2=il_ind2+1
	   	      tab_ASCII(0,*)=TRANSPOSE(numx1)
	   	      tab_ASCII(il_ind2,*)=meanval(prof,il_ind,*) ; numx2
                   ENDIF
                ENDIF ELSE BEGIN
                   IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                    and variable_name(il_ind+2) ne 'PERS_TEMP'  and variable_name(il_ind+2) ne 'PERS_PSAL' ) THEN BEGIN
                 ;  IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' ) THEN BEGIN
                      ;meanval_smooth=SMOOTH(MEDIAN(transpose(meanval(prof,il_ind,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                      ;numx2=meanval_smooth
                      numx2=meanval(prof,il_ind,*)
                      plot_serietemp_test,1.5,val4,PLOT_KIND=kind,NOTE2=variable_name(il_ind+2) ;,OVERPLOT=8
                      il_ind2=il_ind2+1
                      print ,il_ind,il_ind2
		       IF (variable_name(il_ind+2) eq 'HDCST_TEMP' or variable_name(il_ind+2) eq 'HDCST_PSAL' $
	                 or variable_name(il_ind+2) eq 'FRCST3D_TEMP' or variable_name(il_ind+2) eq 'FRCST3D_PSAL' $
        	         or variable_name(il_ind+2) eq 'FRCST6D_TEMP' or variable_name(il_ind+2) eq 'FRCST6D_PSAL' $
			 or variable_name(il_ind+2) eq 'SMARV' or variable_name(il_ind+2) eq 'TMARV' $
		         or variable_name(il_ind+2) eq 'SMLEV' or variable_name(il_ind+2) eq 'TMLEV' ) THEN BEGIN
			 il_ind3=il_ind3+1
			 tab_ASCII(0,*)=TRANSPOSE(numx1)
			 print ,'INDICE :: ',il_ind3,variable_name(il_ind+2)
                         tab_ASCII(il_ind3,*)=meanval(prof,il_ind,*) ; numx2
			 tab_ASCII_2(il_ind3)=TOTAL(meanval_cumul(prof,il_ind,*))/TOTAL(nbval_cumul(prof,il_ind,*))
                      ENDIF 
                    ENDIF
                ENDELSE
             ENDIF ELSE BEGIN
              PRINT ,'Variable NON Valide',variable_name(il_ind+2)
             ENDELSE
           ENDFOR
	 ;  IF ( OPER eq "NO" )  THEN BEGIN
	     ;; write ASCII file
             iof=1
             err=0
	     file=dirname_out+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)+'.txt'  
	     OPENW, iof, file, ERROR=err
             print ,'Ecriture file ascii ',file,err 
             IF err EQ 0 THEN BEGIN
               PRINTF, iof, tab_ASCII, FORMAT='(F10.1, 1X ,F10.8,1X ,F10.8,1X ,F10.8,1X,F10.8,1X,F10.8)'
              ; PRINTF, iof, tab_ASCII, FORMAT='(F10.1, 1X ,F12.8,1X ,F12.8,1X ,F12.8)'
	     ENDIF
	     IF err EQ 0 THEN CLOSE, iof
	   IF ( OPER eq "YES" )  THEN BEGIN
	 ; ENDIF ELSE BEGIN
             ;; write ASCII file
             iof=1
             err=0
             file=dirname_out+'/File_ASCII/Fic_ASCII_PREVI_meanval_'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)+'.txt'
             OPENW, iof, file, ERROR=err
             print ,'Ecriture file ascii ',file,err
             IF err EQ 0 THEN BEGIN
               PRINTF, iof, tab_ASCII_2, FORMAT='(F10.1, 1X ,F10.8,1X ,F10.8,1X ,F10.8,1X,F10.8,1X,F10.8)'
              ; PRINTF, iof, tab_ASCII_2, FORMAT='(F10.1, 1X ,F10.8,1X ,F10.8,1X ,F10.8)'
             ENDIF
             IF err EQ 0 THEN CLOSE, iof
	  ;ENDELSE 
	   ENDIF
        ishold=0
        do_output,dirname_out+'/Serie_temp_meanval_'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)
        prof=prof+1
      ENDWHILE
   ENDFOR
ENDFOR 
END
