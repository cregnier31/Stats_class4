PRO calculer_stats_MYO2,modele,fichier1,fic_mask,profondeur,variable_name, $
                               kind,filelist,dir_stats_MERC,days,valeurs_cmax,$
			       valeurs_cmax_sal,liste_zone,tab_choix,OPER,tab_prof,$
			       tab_prof_model,tab_e3t

;==========================================================================
;##  Trace de l'evolution de la rms difference pour les fichiers class4
;
;    author: C REGNIER Septembre 2007
;    author: C REGNIER Mai 2009 :: Compute rms diff for differentes
;    echeances et differents runs
;    author: C REGNIER Janvier 2010 :: corrections to adapt the number of prof
;    author: C REGNIER Aout 2010 :: 
;    author: C.REGNIER Juin 2011 :: ajout des zones baltic, NordSea et Facade
;    author: C.REGNIER Janvier 2013 :: calcul des stats MyOcean2

;;   Dans ce code un poids plus grand est donné aux boîtes qui ont le plus de données et qui ont donc une représentativité plus grande
;
;==========================================================================

@param
@param_class4

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Definition des variables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
file3=fic_mask
file=fichier1
nb_prof=N_ELEMENTS(profondeur)
nb_prof_model=N_ELEMENTS(tab_prof_model)
range_values=fltarr(2,nb_prof)
nb_variables=N_ELEMENTS(variable_name)
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
      PRINT ,'Zone :: ',zone 
      if (var eq 'SAL') THEN BEGIN
         il_begin=1
      endif else begin
         if (var eq 'TEMP') THEN BEGIN
            il_begin=0
         ENDIF
      ENDELSE

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Choix de la zone
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      FIND=find_indice(boite,zone)
      indice_i=FIND(0)
      taille=N_ELEMENTS(FIND(*))
      indice_f=FIND(taille-1)
      nfichiers=N_ELEMENTS(filelist)
      i=0L
      print,'nb_prof :: ',nb_prof
      ;** Recherche des indice pour les boites
      tab_indice_ini=intarr(nb_prof)
      tab_indice_fin=intarr(nb_prof)	  
      indice2=0
      FOR indice=1,nb_prof-1 DO BEGIN
	FIND2=WHERE(tab_prof_model GE tab_prof(indice-1) AND tab_prof_model LT tab_prof(indice), COUNT)
	indice_ini=FIND2(0)
	indice_fin=FIND2(N_ELEMENTS(FIND2)-1)
	tab_indice_ini(indice2)=indice_ini
	tab_indice_fin(indice2)=indice_fin
	indice2=indice2+1
      ENDFOR
      ;; Dernière case du tableau => toute la colonne d'eau
      tab_indice_ini(indice2)=0
      tab_indice_fin(indice2)=tab_indice_fin(indice2-1)
      print,'indice :',tab_indice_ini(indice2),tab_indice_fin(indice2)
      ;** Allocate tab
      rms_difftot=dblarr(nb_prof_model,nb_variables,412,nfichiers)
      mean_difftot=dblarr(nb_prof_model,nb_variables,412,nfichiers)
      rms_tot=dblarr(nb_prof_model,nb_variables,412,nfichiers)
      mean_tot=dblarr(nb_prof_model,nb_variables,412,nfichiers)
      indice_tot=dblarr(nb_prof_model,nb_variables,412,nfichiers) ;intarr
      ; initialisation
      rms_difftot(*,*,*,*)=0L
      indice_tot(*,*,*,*)=0L
      while i le nfichiers-1 do begin
        file=filelist(i)
        dirin=dir_stats_MERC
        rms_diff=ncdf_lec(file,iodir=dirin,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
        rms_difftot(*,*,*,i)=rms_diff(*,*,*,*)
        mean_diff=ncdf_lec(file,iodir=dirin,var='mean_diff', /nostruct) & mean_diff=transpose(mean_diff)
        mean_difftot(*,*,*,i)=mean_diff(*,*,*,*)
        rms_var=ncdf_lec(file,iodir=dirin,var='rms', /nostruct) & rms_var=transpose(rms_var)
	rms_tot(*,*,*,i)=rms_var(*,*,*,*)
        mean_var=ncdf_lec(file,iodir=dirin,var='mean', /nostruct) & mean_var=transpose(mean_var)
	mean_tot(*,*,*,i)=mean_var(*,*,*,*)
	indice=ncdf_lec(file,iodir=dirin,var='indice_box', /nostruct) & indice=transpose(indice)
        indice_tot(*,*,*,i)=indice
        il_nelem=N_ELEMENTS(rms_diff(1,*,1))
	print,'fichier :',file,i
	clear,indice,rms_diff,mean_diff,rms_var,mean_var
        i=i+1
      endwhile
      ; Normalisation par le nombre d'obs par boite
      ii=WHERE(indice_tot(*,*,*,*) GT 0)
      IF (ii(0) NE -1) THEN BEGIN 
        rms_difftot(ii)=rms_difftot(ii)/indice_tot(ii)
        mean_difftot(ii)=mean_difftot(ii)/indice_tot(ii)
	rms_tot(ii)=rms_tot(ii)/indice_tot(ii)
	mean_tot(ii)=mean_tot(ii)/indice_tot(ii)
      ENDIF

; Valeurs des jours en jours juliens
      ndays=N_ELEMENTS(days)
      jours=fltarr(ndays)
      jour1=days(0) 
      jour2=days(ndays-1) 
      FOR il_ind=0,ndays-1 DO BEGIN
         chdate2jul,STRING(days(il_ind)) , yyyy, mm, dd, run1
         jours(il_ind)=run1
         print,'Jour :: ',jours(il_ind)
      ENDFOR


;; Calcul de la moyenne et de la MSE
    prof=0L
    fichier=0L

    WHILE prof le N_ELEMENTS(profondeur)-1 DO BEGIN
       FOR fichier=0,nfichiers-1 DO BEGIN
          tab_ASCII=fltarr(11)
          il_var=0
          FOR il_ind2=il_begin,il_nelem-1,2 DO BEGIN
             IF (variable_name(il_ind2) eq 'TEMP' or variable_name(il_ind2) eq 'PSAL' $
                 or variable_name(il_ind2) eq 'HDCST_TEMP' or variable_name(il_ind2) eq 'HDCST_PSAL' $
                 or variable_name(il_ind2) eq 'ANA_TEMP' or variable_name(il_ind2) eq 'ANA_PSAL' $
                 or variable_name(il_ind2) eq 'FRCST3D_TEMP' or variable_name(il_ind2) eq 'FRCST3D_PSAL' $
                 or variable_name(il_ind2) eq 'FRCST6D_TEMP' or variable_name(il_ind2) eq 'FRCST6D_PSAL' $
                ) THEN BEGIN
                print,"Variable name OK : ",variable_name(il_ind2)
                val_rms_tmp=0L
                val_mean_tmp=0L
                val_nbval_tmp=0L
                val_tot_e3t=0L
                val_tot2_e3t=0L
                var1=0L
                var2=0L
                FOR  il_ind=0,taille-1 do begin
                   il_indice=FIND(il_ind)
                   vect=WHERE(mean_tot(tab_indice_ini(prof):tab_indice_fin(prof),il_ind2,il_indice,fichier) GT 0)
                   IF (vect(0) NE -1) THEN BEGIN $
                   ;; Mean 
                      val_mean_tmp=val_mean_tmp+TOTAL(mean_tot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier)*tab_e3t(vect+tab_indice_ini(prof)))
                      val_nbval_tmp=val_nbval_tmp+TOTAL(indice_tot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier))
                      val_tot_e3t=val_tot_e3t+TOTAL(tab_e3t(vect+tab_indice_ini(prof)))
                   ENDIF
                ;; Mean square error
                   vect2=WHERE(rms_difftot(tab_indice_ini(prof):tab_indice_fin(prof),il_ind2,il_indice,fichier) GT 0)
                   IF (vect2(0) NE -1) THEN BEGIN
                      val_rms_tmp=val_rms_tmp+TOTAL(rms_difftot(vect2+tab_indice_ini(prof),il_ind2,il_indice,fichier)*tab_e3t(vect2+tab_indice_ini(prof)))
                      val_tot2_e3t=val_tot2_e3t+TOTAL(tab_e3t(vect2+tab_indice_ini(prof)))
                   ENDIF
                ENDFOR
                val_rms_new=val_rms_tmp/val_tot2_e3t
                val_mean_new=val_mean_tmp/val_tot_e3t 
                IF ( il_ind2 EQ il_begin ) THEN BEGIN
                   tab_ASCII(0)=jours(fichier)
                   tab_ASCII(1)=val_nbval_tmp
                   tab_ASCII(2)=val_mean_new
                   print,'tab_ASCII(0),tab_ASCII(1),tab_ASCII(2): ',tab_ASCII(0:2)
                   il_var=3     
                ENDIF ELSE BEGIN
                    print,'indice : ',il_ind2
                    tab_ASCII(il_var)=val_mean_new
                    print,'indice : ',il_var
                    print,'Valeur : ',tab_ASCII(il_var)
                    il_var=il_var+1
                    tab_ASCII(il_var)=val_rms_new
                     print,'indice2 : ',il_var
                     print,'Valeur2: ',tab_ASCII(il_var)
                    il_var=il_var+1
                ENDELSE
             ENDIF
          ENDFOR
          ;print,'Profondeur : ',profondeur(prof)
          ;print,'Valeurs  :',tab_ASCII(*)
          ;; write ASCII file
          iof=1
          err=0
          file=dirname_out+'/MYO2_product_quality_'+modele+'_'+zone+'_'+jour1+'_'+jour2+'_'+var+'_'+profondeur(prof)+'.txt'
           OPENW, iof, file, ERROR=err,/append
           print ,'Ecriture file ascii ',file,err
           IF err EQ 0 THEN BEGIN
             PRINTF, iof, tab_ASCII, FORMAT='(F10.2,2x,F10.1,2X,9(F10.7,2x))'
             ;PRINTF, iof, tab_ASCII, FORMAT='(F10.2,2x,F10.1,2X,F10.8,2X,F10.8,2X,F10.8,2X,F10.8,2X,F10.8,2X,F10.8,2X,F10.8,2X,F10.8,2X,F10.8,2X)'
           ENDIF
           IF err EQ 0 THEN CLOSE, iof
           PRINT ,'Ecriture des valeurs OK'
         ENDFOR
       prof=prof+1
    ENDWHILE
  ENDFOR
ENDFOR



END
