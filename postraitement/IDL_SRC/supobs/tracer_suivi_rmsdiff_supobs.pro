PRO tracer_suivi_rmsdiff_supobs,modele,fic_mask, $
                               kind,filelist,dir_stats_MERC,days,valeurs_cmax,$
			       valeurs_cmax_sal,liste_zone,tab_choix,OPER,tab_prof,$
			       lissage,NB_VALEURS,NB_VALEURS2,type_data=type_data

;==========================================================================
;##  Trace de l'evolution de la rms difference pour les fichiers class4
;
;    author: C REGNIER Septembre 2007
;    author: C REGNIER Mai 2009 :: Compute rms diff for differentes
;    echeances et differents runs
;    author: C REGNIER Janvier 2010 :: corrections to adapt the number of prof
;    author: C REGNIER Aout 2010 :: 
;    author: C.REGNIER Juin 2011 :: ajout des zones baltic, NordSea et Facade
;    author: C.REGNIER Janvier 2013 :: ajout de la routine find et correction sur les indices sélectionnés dans FIND
;    author: C.REGNIER  Decembre  2013 ::Adaptation aux nouveaux fichiers stats

;;   Dans ce code un poids plus grand est donné aux boîtes qui ont le plus de données et qui ont donc une représentativité plus grande
;
;==========================================================================

@param
@param_class4

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Definition des variables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print,filelist
nfichiers=N_ELEMENTS(filelist)
fichier1=filelist(nfichiers-1)
file3=fic_mask
print,'Fichier MASK :: ',file3
print, 'dir_output :: ',dirname_out
file=fichier1
nb_prof=N_ELEMENTS(tab_prof)
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
x1=ncdf_lec(file3,iodir=dir_mask,var='longitude', /nostruct) & x1=transpose(x1)
x2=ncdf_lec(file3,iodir=dir_mask,var='latitude', /nostruct) & x2=transpose(x2)
boite=ncdf_lec(file,iodir=dirin,var='box', /nostruct) & boite=transpose(boite)
variable_name=ncdf_lec(file,iodir=dirin,var='param_stats', /nostruct) & variable_name=STRING(variable_name)
tab_prof_model=ncdf_lec(file,iodir=dirin,var='deptht', /nostruct) & tab_prof_model=transpose(tab_prof_model)
tab_e3t=ncdf_lec(file,iodir=dirin,var='e3t_0', /nostruct) & tab_e3t=transpose(tab_e3t)
;tab_e3t=ncdf_lec(file,iodir=dirin,var='e3t', /nostruct) & tab_e3t=transpose(tab_e3t)

nb_prof_model=N_ELEMENTS(tab_prof_model)
nb_variables=N_ELEMENTS(variable_name)
;print, 'Prof model :: ',tab_prof_model
print, 'Prof  :: ',tab_prof
print,'Taille :: ',nb_prof_model
;print,'E3t :: ',tab_e3t
print, tab_choix
print, liste_zone
FOR ind=0,N_ELEMENTS(tab_choix)-1 DO BEGIN 
   FOR ind2=0,N_ELEMENTS(liste_zone)-1 DO BEGIN 
      PRINT,'choix, ZONE :: ',tab_choix(ind),'   ',liste_zone(ind2) 
      var=tab_choix(ind)
      zone=liste_zone(ind2)
      PRINT ,'Zone :: ',zone 
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
      print,'ok'
      FIND=find_indice(boite,zone)
      indice_i=FIND(0)
      taille=N_ELEMENTS(FIND(*))
      indice_f=FIND(taille-1)
      print,'PROFS , fichiers' ,nb_prof,nfichiers
      print,'nb_variables :: ',nb_variables
      print,'nb_prof_model :: ',nb_prof_model
      i=0L
      ;** Allocate tab
      rms_difftot=dblarr(nb_prof_model,nb_variables,412,nfichiers)
      indice_tot=dblarr(nb_prof_model,nb_variables,412,nfichiers) ;intarr
      print,'Dimensions  : ',nb_prof_model,nb_variables,nfichiers
      tab_indice_ini=intarr(nb_prof)
      tab_indice_fin=intarr(nb_prof)	  
      print,'nb_prof :: ',nb_prof
      print,'nb_var :: ',nb_variables
      print,'nb_files :: ',nfichiers
      ; initialisation
      rms_difftot(*,*,*,*)=0L
      indice_tot(*,*,*,*)=0L
      ;** Recherche des indice pour les boites
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
      ; Normalisation par le nombre d'obs par boite
      while i le nfichiers-1 do begin
     ; while i le 1 do begin
          file=filelist(i)
          dirin=dir_stats_MERC
          rms_diff=ncdf_lec(file,iodir=dirin,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
          indice=ncdf_lec(file,iodir=dirin,var='indice_box', /nostruct) & indice=transpose(indice)
          indice_tot(*,*,*,i)=indice
          rms_difftot(*,*,*,i)=rms_diff(*,*,*,*)
          il_nelem=N_ELEMENTS(rms_diff(1,*,1))
          print,'fichier :',i,nfichiers-1,il_nelem
          clear,indice,rms_diff
          i=i+1
      endwhile
      ii=WHERE(indice_tot(*,*,*,*) GT 0)
      IF (ii(0) NE -1) THEN BEGIN 
          rms_difftot(ii)=rms_difftot(ii)/indice_tot(ii)
      ENDIF ELSE BEGIN
          print, "indice box are missing"
          STOP
      ENDELSE

      vect_val=intarr(taille)
      ; On enleve PSAL et TEMP
      rms=dblarr(nb_prof,il_nelem-2,nfichiers)
      rms_cumul=dblarr(nb_prof,il_nelem-2,nfichiers)
      nbval_cumul=dblarr(nb_prof,il_nelem-2,nfichiers)
      nb_data=dblarr(nb_prof,il_nelem-2,nfichiers)
      val_rms=0L
      val_nbval=0L
      rms(*,*,*)=0L
      val_rms_new=0L
      rms_cumul(*,*,*)=0L
      nbval_cumul(*,*,*)=0L
      nb_data(*,*,*)=0L
      prof=0L 
      fichier=0L

      print,'Boucle'

      WHILE prof le N_ELEMENTS(profondeur)-1 DO BEGIN
         FOR fichier=0,nfichiers-1 DO BEGIN
            FOR il_ind2=2,il_nelem-1 DO BEGIN
	        val_rms_tmp=0L
		val_nbval_tmp=0L
		val_tot_e3t=0L
		il_var=0
		FOR il_ind=0,taille-1  do begin
                     il_indice=FIND(il_ind)
		     ;; Recherche des indices valides    
	             vect=WHERE(rms_difftot(tab_indice_ini(prof):tab_indice_fin(prof),il_ind2,il_indice,fichier) GT 0)
	   	     IF (vect(0) NE -1) THEN BEGIN
                       ;; Calcul de la rms cumulée
	   	       val_rms_tmp=val_rms_tmp+TOTAL(rms_difftot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier)*tab_e3t(vect+tab_indice_ini(prof)))
	   	       ;; Calcul du volume cumulé
                       val_tot_e3t=val_tot_e3t+TOTAL(tab_e3t(vect+tab_indice_ini(prof)))
		       ;; Calcul du nombre total d'obs cumulé
         	       val_nbval_tmp=val_nbval_tmp+TOTAL(indice_tot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier))
                     ENDIF
		  il_var=il_var+1
		ENDFOR
		val_rms_new=SQRT(val_rms_tmp/val_tot_e3t)
		val_nbval=val_nbval_tmp
                rms(prof,il_ind2-2,fichier)=val_rms_new
	        rms_cumul(prof,il_ind2-2,fichier)=val_rms_tmp
	        nbval_cumul(prof,il_ind2-2,fichier)=val_tot_e3t
		nb_data(prof,il_ind2-2,fichier)=val_nbval
            ENDFOR
         ENDFOR 
        prof=prof+1	
     ENDWHILE 
      ; Valeurs des jours en jours juliens
      ndays=N_ELEMENTS(days)
      jours=fltarr(ndays)

      FOR il_ind=0,ndays-1 DO BEGIN
	  IF ( STRLEN(STRING(days(il_ind))) eq 6 ) THEN BEGIN
	  ;  print,'passe ici', STRLEN(STRING(days(il_ind)))
            chdate2jul,STRING(days(il_ind))+'15', yyyy, mm, dd, run1
	  ENDIF ELSE BEGIN
	 ;   print,'passe la', SIZE((days(il_ind)))
            chdate2jul,STRING(days(il_ind)) , yyyy, mm, dd, run1
	  ENDELSE
         jours(il_ind)=run1
       ;  print,'Jour :: ',jours(il_ind)
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
      
      
      output='logo gif'
      output='gif'
      ;output='screen gif'
      prof=0L 
      ;IF ( OPER eq "NO" )  THEN BEGIN
      ;  tab_ASCII=fltarr(5,nfichiers)
      ;ENDIF ELSE BEGIN
      ;  tab_ASCII=fltarr(9,nfichiers)
      ;ENDELSE
      ;tab_ASCII_2=fltarr(8)
      ;tab_var=strarr(7)
    ;  tab_ASCII=fltarr(nb_variables-1,nfichiers)
      print,nb_variables-1
      print,il_nelem-2
      if nb_variables eq 4 then begin
        tab_ASCII=fltarr(3,nfichiers)
        tab_ASCII_2=fltarr(3)
        print,'cas1'
      endif else begin 
        tab_ASCII=fltarr(nb_variables/2+1,nfichiers)
        tab_ASCII_2=fltarr(nb_variables/2+1)
        print,'cas2'
      endelse
      print,nb_variables/2
      tab_ASCII_2(*)=0L
      tab_var=strarr(nb_variables)
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
	   ll_valide=0
           ;; Boucle sur les variables
           FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
              clear,numx1,numx2 
              numx1=jours
              numx2=rms(prof,il_ind,*)
	      nb_cumul=nbval_cumul(prof,il_ind,*)
	      nb_data_indice=nb_data(prof,il_ind,*)
              titre='Rms diff '+var+' '+type_data+' '+modele+' '+profondeur(prof)+ ' class4 '+zone
              xtitle='rms diff'
              clear,cmin,cmax
	      if (var eq 'SAL') THEN BEGIN
		; if ( lissage eq 'yes' ) then begin
		;    cmin=MIN(SMOOTH(MEDIAN(transpose(rms(prof,1:*:2,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN),/NaN )
		;    cmax=MAX(SMOOTH(MEDIAN(transpose(rms(prof,1:*:2,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN),/NaN )
                ;    if cmax GT 1.5 THEN cmax=1.5
                ; endif else begin
		    cmin=MIN( rms(prof,1:*:2,*),/NaN )
                    cmax=MAX( rms(prof,1:*:2,*),/NaN )
                    if cmax GT 1.5 THEN cmax=1.5
		; endelse
               endif else begin
              if (var eq 'TEMP') THEN BEGIN
		;if ( lissage eq 'yes' ) then begin
		;   cmin=MIN(SMOOTH(MEDIAN(transpose(rms(prof,0:*:2,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN),/NaN )
		;   cmax=MAX(SMOOTH(MEDIAN(transpose(rms(prof,0:*:2,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN),/NaN )
                ;   if cmax GT 3 THEN cmax=3
                ;endif else begin
                   cmin=MIN( rms(prof,0:*:2,*),/NaN )
                   cmax=MAX( rms(prof,0:*:2,*),/NaN )
                   if cmax GT 3 THEN cmax=3
		;endelse
               endif
              endelse
              i=WHERE(rms EQ 0) & IF i(0) NE -1 THEN  rms(i)=!VALUES.F_NAN
              xtitle2=boite(il_ind+2)
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
              ishold=1
              number=WHERE(FINITE(numx2(*)) eq 1)  
	      number2=WHERE((numx2(*)) NE  0)
              IF number(0)  NE -1 AND number2(0) NE -1  THEN BEGIN
                ll_valide=ll_valide+1
                PRINT,'Variable Valide',variable_name(il_ind+2) 
                IF ( OPER eq "NO" )  THEN BEGIN 
		 IF (strtrim(variable_name(il_ind+2)) eq 'HDCST_TEMP' or strtrim(variable_name(il_ind+2)) eq 'HDCST_PSAL' or $
	         	strtrim(variable_name(il_ind+2)) eq 'SMARV' or strtrim(variable_name(il_ind+2)) eq 'TMARV' or $
	         	strtrim(variable_name(il_ind+2)) eq 'SMARV11' or strtrim(variable_name(il_ind+2)) eq 'TMARV11' or $
			strtrim(variable_name(il_ind+2)) eq 'SMLEV13' or strtrim(variable_name(il_ind+2)) eq 'TMLEV13' or $
			strtrim(variable_name(il_ind+2)) eq 'SMLEV18' or strtrim(variable_name(il_ind+2)) eq 'TMLEV18' or $
			strtrim(variable_name(il_ind+2)) eq 'SMLEV05' or strtrim(variable_name(il_ind+2)) eq 'TMLEV05' or $
		      	strtrim(variable_name(il_ind+2)) eq 'SMLEV09' or strtrim(variable_name(il_ind+2)) eq 'TMLEV09' ) THEN BEGIN
		        print,'-------------------------------------------------'
		        print,'Variable :: ',variable_name(il_ind+2)
		        print,'-------------------------------------------------'
		      if ( lissage eq 'yes' ) then begin
                        rms_smooth=SMOOTH(MEDIAN(transpose(rms(prof,il_ind,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                        numx2=rms_smooth
		        nb_cumul_smooth=SMOOTH(MEDIAN(transpose(nb_cumul),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
		      endif else begin
                        numx2=rms(prof,il_ind,*)
		      endelse
                      IF  il_ind2 LT 1 THEN BEGIN
		        if ( lissage eq 'yes' ) then begin
                           plot_serietemp_oper2,1.0,val4,PLOT_KIND=kind,NOTE2=strtrim(variable_name(il_ind+2),1),RIGHT=nb_cumul_smooth;,OVERPLOT=8
		        endif else begin
                           plot_serietemp_oper2,1.0,val4,PLOT_KIND=kind,NOTE2=strtrim(variable_name(il_ind+2),1),RIGHT=nb_cumul,OVERPLOT=8
			endelse
                      ENDIF ELSE BEGIN
                         plot_serietemp_oper2,1.0,val4,PLOT_KIND=kind,NOTE2=strtrim(variable_name(il_ind+2),1)
                      ENDELSE
	              il_ind2=il_ind2+1
	   	      tab_ASCII(0,*)=TRANSPOSE(numx1)
	   	      tab_ASCII(il_ind2,*)=rms(prof,il_ind,*) ; numx2
		      tab_ASCII_2(il_ind2-1)=SQRT(TOTAL(rms_cumul(prof,il_ind,*),/nan)/TOTAL(nbval_cumul(prof,il_ind,*),/nan))
		      tab_var(il_ind2-1)=variable_name(il_ind+2)
		      nb_val_tot=TOTAL(nb_data(prof,il_ind,*))
                      if il_nelem le 4 then begin
		          tab_ASCII(il_nelem-2,*)=nb_data(prof,il_ind,*)
                      endif else begin
		          ;tab_ASCII(nb_variables/2-1,*)=nb_data(prof,il_ind,*)
		          tab_ASCII(il_nelem-3,*)=nb_data(prof,il_ind,*)
                      endelse
	   	      ;tab_ASCII(il_nelem-2,*)=nb_data(prof,il_ind,*)
                      ;IF (strtrim(variable_name(il_ind+2)) eq 'HDCST_TEMP' or strtrim(variable_name(il_ind+2)) eq 'HDCST_PSAL') THEN BEGIN
                      ;  tab_ASCII(il_nelem-2,*)= nb_cumul
		      ;ENDIF
                  ENDIF
                ENDIF ELSE BEGIN
                   IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
		    and variable_name(il_ind+2) ne 'TMLEV' and variable_name(il_ind+2) ne 'SMLEV' ) THEN BEGIN
		      if ( lissage eq 'yes' ) then begin
                        rms_smooth=SMOOTH(MEDIAN(transpose(rms(prof,il_ind,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                        numx2=rms_smooth
		        nb_cumul_smooth=SMOOTH(MEDIAN(transpose(nb_cumul),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
		      endif else begin
                        nmx2=rms(prof,il_ind,*)
	              endelse
		      print,'-------------------------------------------------'
		      print,'Variable :: ',variable_name(il_ind+2)
		      print,'-------------------------------------------------'
	              IF  il_ind2 LT 1 THEN BEGIN
		         if ( lissage eq 'yes' ) then begin
		            plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=strtrim(variable_name(il_ind+2),1),RIGHT=nb_cumul_smooth ;,OVERPLOT=8
		         endif else begin
		            plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=strtrim(variable_name(il_ind+2),1),RIGHT=nb_cumul,OVERPLOT=8
		         endelse 
		      ENDIF ELSE BEGIN
		         plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=strtrim(variable_name(il_ind+2),1)
		      ENDELSE
                      il_ind2=il_ind2+1
		       IF (strtrim(variable_name(il_ind+2)) eq 'HDCST_TEMP' or strtrim(variable_name(il_ind+2)) eq 'HDCST_PSAL' $
        	         or strtrim(variable_name(il_ind+2)) eq 'ANA_TEMP'  or    strtrim(variable_name(il_ind+2)) eq 'ANA_PSAL' $
                    	 or strtrim(variable_name(il_ind+2)) eq 'PERS_TEMP' or    strtrim(variable_name(il_ind+2)) eq 'PERS_PSAL' $ 
	                 or strtrim(variable_name(il_ind+2)) eq 'FRCST1D_TEMP' or strtrim(variable_name(il_ind+2)) eq 'FRCST1D_PSAL' $
        	         or strtrim(variable_name(il_ind+2)) eq 'FRCST3D_TEMP' or strtrim(variable_name(il_ind+2)) eq 'FRCST3D_PSAL' $
        	         or strtrim(variable_name(il_ind+2)) eq 'FRCST5D_TEMP' or strtrim(variable_name(il_ind+2)) eq 'FRCST5D_PSAL' $
        	         or strtrim(variable_name(il_ind+2)) eq 'FRCST6D_TEMP' or strtrim(variable_name(il_ind+2)) eq 'FRCST6D_PSAL' $
			 or strtrim(variable_name(il_ind+2)) eq 'SMARV' or strtrim(variable_name(il_ind+2)) eq 'TMARV' $
			 or strtrim(variable_name(il_ind+2)) eq 'SMARV11' or strtrim(variable_name(il_ind+2)) eq 'TMARV11' $
		         or strtrim(variable_name(il_ind+2)) eq 'SMLEV13' or strtrim(variable_name(il_ind+2)) eq 'TMLEV13' $ 
		         or strtrim(variable_name(il_ind+2)) eq 'SMLEV18' or strtrim(variable_name(il_ind+2)) eq 'TMLEV18' $ 
			 or strtrim(variable_name(il_ind+2)) eq 'SMLEV09' or strtrim(variable_name(il_ind+2)) eq 'TMLEV09' ) THEN BEGIN
			 il_ind3=il_ind3+1
			 print,'INDICE : ',il_ind3-1
			 tab_ASCII(0,*)=TRANSPOSE(numx1)
                         tab_ASCII(il_ind3,*)=rms(prof,il_ind,*) ; numx2
			 tab_ASCII_2(il_ind3-1)=SQRT(TOTAL(rms_cumul(prof,il_ind,*),/nan)/TOTAL(nbval_cumul(prof,il_ind,*),/nan))
			 tab_var(il_ind3-1)=variable_name(il_ind+2)
			 nb_val_tot=TOTAL(nb_data(prof,il_ind,*))
			; tab_ASCII(il_nelem-2,*)=nb_data(prof,il_ind,*)
			 tab_ASCII(nb_variables/2-1,*)=nb_data(prof,il_ind,*)
    		      ENDIF 
                   ENDIF
                 ENDELSE
             ENDIF ELSE BEGIN
              PRINT ,'Variable NON Valide',variable_name(il_ind+2)
              ll_valide=ll_valide
            ENDELSE
           ENDFOR
	   ;; write ASCII file
           iof=1
           err=0
	   file=dirname_out+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)+'.txt'  
	   OPENW, iof, file, ERROR=err
           print ,'Ecriture file ascii ',file,err
           IF err EQ 0 THEN BEGIN
            ;IF ( OPER eq "NO" )  THEN BEGIN
            ;   PRINTF, iof, tab_ASCII, FORMAT='(F10.1, 1X ,F10.8,1X ,F10.8,1X ,F10.8,1X,F10.1)'
            ;ENDIF ELSE BEGIN
	       CASE nb_variables/2 OF
                  2:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,1X,F10.1)'
		  ENDCASE
                  3:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.1)'
		  ENDCASE
                  4:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.1)'
		  ENDCASE
                  5:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
		  ENDCASE
                  6:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
		  ENDCASE
                  7:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
		  ENDCASE
                  8:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                     
                  9:BEGIN
                     PRINTF, iof, tab_ASCII, FORMAT='(F10.1,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                     
		  ELSE: PRINT, 'nombre de variables non pris en compte'
	       ENDCASE                                                                                                     
               ;PRINTF, iof, tab_ASCII, FORMAT='(F10.1, 1X ,F10.8,1X ,F10.8,1X ,F10.8,1X,F10.8,1X,F10.8,1x,F10.8,1x,F10.8,1x,F10.1)'
            ;ENDELSE
	   ENDIF
	   IF err EQ 0 THEN CLOSE, iof
	  ;;IF ( OPER eq "YES" )  THEN BEGIN
	     tab_ASCII_2(nb_variables/2-1)=nb_val_tot
             ;; write ASCII file
             iof=1
             err=0
             file=dirname_out+'/File_ASCII/Fic_ASCII_EAN_rmsval_'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)+'.txt'
             OPENW, iof, file, ERROR=err
             print ,'Ecriture file ascii EAN',file,err,nb_variables/2
	     ;print,tab_ASCII_2
             ;print,nb_variables/2
             IF err EQ 0 THEN BEGIN
	     CASE nb_variables/2 OF
		  2:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:1), FORMAT='(F10.8,1X,F10.1)'
                  ENDCASE
		  3:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:2), FORMAT='(F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE
		  4:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:3), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE  
                  5:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:4), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                   
                  6:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:5), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                   
                  7:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:6), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                     
                  8:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:7), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                     
                  9:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:8), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE                                                                                                     
                  10:BEGIN
                     PRINTF, iof, tab_ASCII_2(0:9), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,F10.8,1X,1x,F10.8,1X,F10.8,1X,F10.1)'
                  ENDCASE 
	      ELSE: PRINT, 'nombre de variables non pris en compte',nb_variables/2
	      ENDCASE                                                                                                     
             ENDIF
             IF err EQ 0 THEN CLOSE, iof
            ; PRINT ,'Valeur des variables du fichier :: ',tab_var
	   ;;ENDIF
	IF ll_valide GE 1 THEN BEGIN
           ishold=0
           do_output,dirname_out+'/Serie_temp_rms_'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)
        ENDIF
        prof=prof+1
      ENDWHILE
   ENDFOR
ENDFOR 
END
