PRO tracer_multiserietemp_CLASS4_supobs_statsval,display,date_title,modele,fic_mask,tab_prof, $
                                      kind,filelist,dir_stats_MERC,days,valeurs_cmax,valeurs_cmax_sal,liste_zone,tab_choix,OPER,trans

;==========================================================================
;##  Trace des statistiques pour les fichers class4
;
;    author: C REGNIER Janvier 2014 : Creation des profils moyens en rms error et mean error avec nouvelles focntionnalités 
;                                     de l'IDL 8
;
;==========================================================================

@param
@param_class4

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Definition des variables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  file3=fic_mask
  file=filelist(0)
  nb_prof=N_ELEMENTS(tab_prof)
;; Reconstitution profondeur
  profondeur=strarr(nb_prof-1)
  profondeur(*)=0
  FOR ind=0,nb_prof-2 DO BEGIN
    profondeur(ind)=strtrim(STRING(UINT(tab_prof(ind))),1)+'-'+strtrim(STRING(UINT(tab_prof(ind+1))),1)+'m'
    print,'Valeur :: ',profondeur(ind)
  ENDFOR
  depthlayers=strtrim(STRING(UINT(tab_prof(0))),1)+'-'+strtrim(STRING(UINT(tab_prof(nb_prof-1))),1)+'m'
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; Lecture des boites
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  x1=ncdf_lec(file3,iodir=dir_mask,var='longitude', /nostruct) & x1=transpose(x1)
  x2=ncdf_lec(file3,iodir=dir_mask,var='latitude', /nostruct) & x2=transpose(x2)
  variable_name=ncdf_lec(file,iodir=dirin,var='param_stats', /nostruct) & variable_name=STRING(variable_name)
  boite=ncdf_lec(file,iodir=dirin,var='box', /nostruct) & boite=transpose(boite)
  tab_prof_model=ncdf_lec(file,iodir=dirin,var='deptht', /nostruct) & tab_prof_model=transpose(tab_prof_model)
  tab_e3t=ncdf_lec(file,iodir=dirin,var='e3t', /nostruct) & tab_e3t=transpose(tab_e3t)
  nb_prof_model=N_ELEMENTS(tab_prof_model)
  nb_variables=N_ELEMENTS(variable_name)
  range_values=fltarr(2,nb_prof-1)
  nb_prof=N_ELEMENTS(tab_prof)-1
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
        FIND=find_indice(boite,zone)
        indice_i=FIND(0)
        taille=N_ELEMENTS(FIND(*))
        indice_f=FIND(taille-1)
        nfichiers=N_ELEMENTS(filelist)
        il_nbox=N_ELEMENTS(boite)
        i=0L
	print,nb_prof,nb_variables,il_nbox,nfichiers
        ;** Allocate tab
        rms_tot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers)
        mean_tot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers)
        indice_tot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers) ;intarr
	tab_indice_ini=intarr(nb_prof)
        tab_indice_fin=intarr(nb_prof)	  

        ; Rercherche des indices pour les boites
        indice2=0
        FOR indice=1,nb_prof DO BEGIN
	    print ,'indice nb_prof :: ',indice,nb_prof
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
        print,'indice :',tab_indice_ini(indice2-1),tab_indice_fin(indice2-1),indice2
        print,'Pronfondeur : ',profondeur(indice2-1)
;; Lecture de mean et rms 
        while i le nfichiers-1 do begin
           file=filelist(i)
           dirin=dir_stats_MERC
           rms=ncdf_lec(file,iodir=dirin,var='rms', /nostruct) & rms=transpose(rms)
           mean_tab=ncdf_lec(file,iodir=dirin,var='mean', /nostruct) & mean_tab=transpose(mean_tab)
	   print,"Read ok :",dirin+file
           rms_tot(*,*,*,i)=rms
           mean_tot(*,*,*,i)=mean_tab
           indice=ncdf_lec(file,iodir=dirin,var='indice_box', /nostruct) & indice=transpose(indice)
           indice_tot(*,*,*,i)=indice
           il_nbreg=N_ELEMENTS(rms(1,1,*))
           il_nelem=N_ELEMENTS(rms(1,*,1))
           il_nprof=N_ELEMENTS(rms(*,1,1))
                                ;print,il_nbreg,il_nelem,il_nprof
           i=i+1
        endwhile
        clear,rms,mean_tab
        ;; Normalisation par le nombre d'obs par boite
        ii=WHERE(indice_tot(*,*,*,*) GT 0)
        IF (ii(0) NE -1) THEN BEGIN
           rms_tot(ii)=rms_tot(ii)/indice_tot(ii)
	   mean_tot(ii)=mean_tot(ii)/indice_tot(ii)
        ENDIF
        print, "Normalisation ok"

        vect_val=intarr(taille)
; On enleve PSAL et TEMP
	print,nb_prof
        rms=dblarr(nb_prof,il_nelem)
	mean_tab=dblarr(nb_prof,il_nelem)
        nb_data=dblarr(nb_prof,il_nelem)
        val_rms=0L
	val_mean=0L
        val_nbval=0L
        rms(*,*)=0L
	mean_tab(*,*)=0L
        val_rms_new=0L
        val_mean_new=0L
        nb_data(*,*)=0L
        prof=0L 
        fichier=0L
	il_ind2=0L
        WHILE prof le N_ELEMENTS(profondeur)-1 DO BEGIN
            FOR il_ind2=0,il_nelem-1 DO BEGIN
                val_rms_tmp=0L
                val_mean_tmp=0L
                val_nbval_tmp=0L
                val_tot_e3t=0L
                il_var=0
                FOR fichier=0,nfichiers-1 DO BEGIN
                       FOR il_ind=0,taille-1  do begin
                             il_indice=FIND(il_ind)
                           ;; Recherche des indices valides    
                             vect=WHERE(rms_tot(tab_indice_ini(prof):tab_indice_fin(prof),il_ind2,il_indice,fichier) GT 0)
              	         IF (vect(0) NE -1) THEN BEGIN
                               ;; Calcul de la mean et rms cumulée
              	            val_rms_tmp=val_rms_tmp+TOTAL(rms_tot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier)*tab_e3t(vect+tab_indice_ini(prof)))
                            val_mean_tmp=val_mean_tmp+TOTAL(mean_tot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier)*tab_e3t(vect+tab_indice_ini(prof)))

              	            ;; Calcul du volume cumulé
                               val_tot_e3t=val_tot_e3t+TOTAL(tab_e3t(vect+tab_indice_ini(prof)))
                             ;; Calcul du nombre total d'obs cumulé
                             val_nbval_tmp=val_nbval_tmp+TOTAL(indice_tot(vect+tab_indice_ini(prof),il_ind2,il_indice,fichier))
                         ENDIF
                         il_var=il_var+1
                       ENDFOR
                 ENDFOR
                 val_rms_new=SQRT((val_rms_tmp)/val_tot_e3t)
		 val_mean_new=val_mean_tmp/val_tot_e3t
                 val_nbval=val_nbval_tmp
                 rms(prof,il_ind2)=val_rms_new
		 mean_tab(prof,il_ind2)=val_mean_new
                 nb_data(prof,il_ind2)=val_nbval
           ENDFOR
           prof=prof+1	
        ENDWHILE 
                 
        prof=0L 
	print,tab_prof
	tab_prof_end=dblarr(nb_prof)
         WHILE prof le nb_prof-1 DO BEGIN
           tab_prof_end(prof)=(tab_prof(prof)+tab_prof(prof+1))/2
           prof=prof+1
	ENDWHILE
;; Definition des couleurs du tracé
        Def_colors
        common COLOR_BLOCK,black,grey,white,bleuey,cyan,green,gold,yellow,red,blue,salmon,aquam,brown,burly,gmt_land
        c1_bis=black  ;; noir
        c1=white      ;; noir
        c2=blue       ;; bleu
        c3=green      ;; vert
        c4=red        ;; vert
        c5=cyan
        c6=salmon
        c7=brown
        c8=grey
        c9=gold


        colors=strarr(11)
        colors(0)='black'
        colors(1)='red'
        colors(2)='Gray'
        colors(3)='blue'
        colors(4)='Forest Green'
        colors(5)='Burlywood'
        colors(6)='Deep Pink'
        colors(7)='grey'
        colors(8)='salmon'
        colors(9)='Hot Pink'
        colors(10)='Aquamarine'

        prof=0L 

        il_ind2=0L
        il_ind=0L

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;~~~~~~~~~~~~~~~~~~~~~~~PLOT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
       cmin=MIN(tab_prof,/NaN)
       cmax=MAX(tab_prof,/NaN)
       if (cmax GT 3000) then cmax=1500
       xmin=0.05
       i=WHERE(rms EQ 0) & IF i(0) NE -1 THEN  rms(i)=!VALUES.F_NAN
       i=WHERE(mean_tab EQ 0) & IF i(0) NE -1 THEN  mean_tab(i)=!VALUES.F_NAN
       mydevice = !D.NAME 
       IF (display eq 0 ) THEN BEGIN 
         winsize = 500
         w = WINDOW(DIMENSIONS=[2*winsize, winsize],BUFFER=1)
       ENDIF ELSE BEGIN
	  winsize = 500
          w = WINDOW(DIMENSIONS=[2*winsize, winsize],BUFFER=0)
       ENDELSE
       FOR il_ind=il_begin,il_nelem-1,2 DO BEGIN 
           print ,'Variable :: ', variable_name(il_ind)
              IF (variable_name(il_ind) ne 'PERS_TEMP'  and variable_name(il_ind) ne 'PERS_PSAL') THEN BEGIN
                 print, 'Variable ok',il_ind
                 numx2=tab_prof_end(*)
                 ;numx1=rms(*,il_ind)
                 numx1=mean_tab(*,il_ind)
        	 print,numx2,numx1
                 Number=WHERE(numx1(*) GT 0)
                 IF number(0)  NE -1 AND  max(numx1) NE 0 THEN BEGIN
		    IF ( il_ind eq il_begin ) THEN BEGIN
	             	  cmin=MIN(numx2)-10
                          cmax=MAX(numx2)+50
	             	  cmin2=MIN(mean_tab(*,il_ind))-1
                          cmax2=MAX(mean_tab(*,il_ind))+1
			  print,'Valeurs RMS :',numx1
                ; 	  series= PLOT(numx1,numx2, /CURRENT,POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                ;                        YRANGE=[cmax ,cmin ],XRANGE=[cmin2,cmax2],TITLE=date_title+' '+modele+' zone '+zone ,XTITLE='RMS and Mean',YTITLE='Depth',$
                ;                       COLOR=FSC_COLOR(colors(il_ind2)),NAME=variable_name(il_ind))   

                           numx2=tab_prof_end(*)
                           numx1=mean_tab(*,il_ind)
		;	   print,'Valeurs Mean :',numx1
		         ;  series= PLOT(numx1,numx2,/CURRENT,OVERPLOT=1,LINESTYLE='-:',POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                         ;              TITLE='' ,XTITLE='Mean and RMS',YTITLE='Depth',$
                         ;              COLOR=FSC_COLOR(colors(il_ind2)),NAME=variable_name(il_ind))
                 	  series= PLOT(numx1,numx2, /CURRENT,POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                                        YRANGE=[cmax ,cmin ],XRANGE=[cmin2,cmax2],TITLE=date_title+' '+modele+' zone '+zone ,XTITLE='Mean',YTITLE='Depth',$
                                       COLOR=FSC_COLOR(colors(il_ind2)),NAME=variable_name(il_ind))   
			
			   numx1(*)=0L
                	   series_3= PLOT(numx1,numx2,/CURRENT,OVERPLOT=1,LINESTYLE=1,POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                                       TITLE='' ,XTITLE='Mean',YTITLE='Depth',$
                                       COLOR='black')

		    ENDIF ELSE BEGIN
                       ;    series= PLOT(numx1,numx2,/CURRENT,OVERPLOT=1,POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                       ; 	       TITLE='' ,XTITLE='Mean and RMS',YTITLE='Depth',$
		       ; 	       COLOR=FSC_COLOR(colors(il_ind2)),NAME=variable_name(il_ind))
	               ;    numx2=tab_prof_end(*)
                       ;    numx1=mean_tab(*,il_ind)
		       ;    series_2= PLOT(numx1,numx2,/CURRENT,OVERPLOT=1,LINESTYLE='-:',POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                       ;                TITLE='' ,XTITLE='Mean and RMS',YTITLE='Depth',$
                       ;                COLOR=FSC_COLOR(colors(il_ind2)),NAME=variable_name(il_ind))
                           series= PLOT(numx1,numx2,/CURRENT,OVERPLOT=1,POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                        	       TITLE='' ,XTITLE='Mean',YTITLE='Depth',$
		        	       COLOR=FSC_COLOR(colors(il_ind2)),NAME=variable_name(il_ind))
			   numx1(*)=0L
                	   series_2= PLOT(numx1,numx2,/CURRENT,OVERPLOT=1,LINESTYLE=1,POSITION=[0.12, 0.10, 0.68, 0.90],XSTYLE=3, $
                                       TITLE='' ,XTITLE='Mean',YTITLE='Depth',$
                                       COLOR='black')
			   print,'color :: ',colors(il_ind2)
		    ENDELSE
		    series.SYM_COLOR = FSC_COLOR(colors(il_ind2))
		    series.SYM_FILLED = 1
		    series.SYM_FILL_COLOR = FSC_COLOR(colors(il_ind2))
		    series.thick = 2  
		    series.SYMBOL = 'o'
                    ;series_2.thick = 0.5
                    ;series_2.SYM_FILLED = 1
                    ;series_2.thick = 1.5
                    ;series_2.SYMBOL = 'D'
		    ;;;; Save object in a temporary object
                    CASE il_ind2 OF
                       0:BEGIN
                        series1=series
                       ENDCASE
                       1:BEGIN
                        series2=series
                        ENDCASE
                       2:BEGIN
                        series3=series
                       ENDCASE
                       3:BEGIN
                        series4=series
                       ENDCASE
                       4:BEGIN
                        series5=series
                       ENDCASE
                       5:BEGIN
                        series6=series
                       ENDCASE
                       6:BEGIN
                        series7=series
                       ENDCASE
                       7:BEGIN
                        series8=series
                       ENDCASE
                      ELSE: STOP
                    ENDCASE
	            CASE strtrim(variable_name(il_ind)) OF
		       'HDCST_TEMP':BEGIN
       		           tab_ASCII_rms_HDTEMP=dblarr(nb_prof)
       		           tab_ASCII_mean_HDTEMP=dblarr(nb_prof)
        	           tab_ASCII_rms_HDTEMP=rms(*,il_ind)
		           tab_ASCII_mean_HDTEMP=mean_tab(*,il_ind)
		       ENDCASE
		       'HDCST_PSAL':BEGIN
       		           tab_ASCII_rms_HDPSAL=dblarr(nb_prof)
       		           tab_ASCII_mean_HDPSAL=dblarr(nb_prof)
                           tab_ASCII_rms_HDPSAL=rms(*,il_ind)
		           tab_ASCII_mean_HDPSAL=mean_tab(*,il_ind)
		       ENDCASE
		       'TEMP':BEGIN
       		           tab_ASCII_rms_TEMP=dblarr(nb_prof)
       		           tab_ASCII_mean_TEMP=dblarr(nb_prof)
        	           tab_ASCII_rms_TEMP=rms(*,il_ind)
		           tab_ASCII_mean_TEMP=mean_tab(*,il_ind)
		       ENDCASE
		       'PSAL':BEGIN
       		           tab_ASCII_rms_PSAL=dblarr(nb_prof)
       		           tab_ASCII_mean_PSAL=dblarr(nb_prof)
                           tab_ASCII_rms_PSAL=rms(*,il_ind)
		           tab_ASCII_mean_PSAL=mean_tab(*,il_ind)
		       ENDCASE
		       'TMLEV09':BEGIN
       		           tab_ASCII_rms_TMLEV=dblarr(nb_prof)
       		           tab_ASCII_mean_TMLEV=dblarr(nb_prof)
                           tab_ASCII_rms_TMLEV=rms(*,il_ind)
		           tab_ASCII_mean_TMLEV=mean_tab(*,il_ind)
		       ENDCASE
		       'SMLEV09':BEGIN
       		           tab_ASCII_rms_SMLEV=dblarr(nb_prof)
       		           tab_ASCII_mean_SMLEV=dblarr(nb_prof)
                           tab_ASCII_rms_SMLEV=rms(*,il_ind)
		           tab_ASCII_mean_SMLEV=mean_tab(*,il_ind)
		       ENDCASE
		       'TMARV11':BEGIN
       		           tab_ASCII_rms_TMARV=dblarr(nb_prof)
       		           tab_ASCII_mean_TMARV=dblarr(nb_prof)
                           tab_ASCII_rms_TMARV=rms(*,il_ind)
		           tab_ASCII_mean_TMARV=mean_tab(*,il_ind)
		       ENDCASE
		       'SMARV11':BEGIN
       		           tab_ASCII_rms_SMARV=dblarr(nb_prof)
       		           tab_ASCII_mean_SMARV=dblarr(nb_prof)
                           tab_ASCII_rms_SMARV=rms(*,il_ind)
		           tab_ASCII_mean_SMARV=mean_tab(*,il_ind)
		       ENDCASE
		       ELSE : PRINT,'Variable : ',variable_name(il_ind+2)
		    ENDCASE
                    il_ind2=il_ind2+1
                 ENDIF
	      ENDIF
           ENDFOR
           ;; Write ASCII File
           file=dirname_out+'/File_ASCII/MultiSerie_'+depthlayers+'_'+var+'_'+zone+'_'+modele+'.txt'
           iof=1
           err=0
           OPENW, iof, file, ERROR=err
           print ,'Ecriture file ascii ',file,err
           IF  err EQ 0 THEN BEGIN
	      CASE nb_prof OF
                   4:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F8.4,2X,F8.4,2X,F8.4,2X,F8.4)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
                   ENDCASE
                   5:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F8.4,2X,F8.4,2X,F8.4,2X,F8.4,2x,F8.4)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
	           ENDCASE
                   6:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F8.4,2X,F8.4,2X,F8.4,2X,F8.4,2x,F8.4,2X,F8.4)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
	           ENDCASE
                   7:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F8.4,2X,F8.4,2X,F8.4,2X,F8.4,2x,F8.4,2X,F8.4,2X,F8.4)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_TEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                 ;        PRINTF, iof, tab_ASCII_mean_TMLEV09(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		 ;        PRINTF, iof, tab_ASCII_rms_TMLEV09(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_PSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_PSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                        ; PRINTF, iof, tab_ASCII_mean_SMLEV09(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                        ; PRINTF, iof, tab_ASCII_rms_SMLEV09(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
	           ENDCASE
                   8:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
	           ENDCASE
                   9:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
	           ENDCASE
                   12:BEGIN
                      PRINTF, iof, tab_prof_end(*), FORMAT='(F10.8,1X,F10.8,1X,F10.8,1X,F10.1)'
		      IF ( il_begin eq 0) THEN BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_HDTEMP(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		         PRINTF, iof, tab_ASCII_rms_TMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDIF ELSE BEGIN
                         PRINTF, iof, tab_ASCII_mean_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_HDPSAL(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_mean_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
                         PRINTF, iof, tab_ASCII_rms_SMLEV(*), FORMAT='(F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8,1X,F12.8)'
		      ENDELSE
	           ENDCASE
	           ;ELSE: PRINT, 'nombre de variables non pris en compte'
              ENDCASE
              CLOSE, iof
           ENDIF ELSE BEGIN	
	      PRINT ,'Pb with file creation'
	   ENDELSE
	   ;; Create legend object depending on the number of profiles
	   print,'Indice',il_ind2
	   CASE il_ind2 OF
		0: BEGIN
	           GOTO, Passe   
	        ENDCASE
                2:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2], /DATA, $
                          /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100, POSITION=[0.2,1])
                ENDCASE
                3:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2,series3], /DATA, $
                          /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100)
		  ;, POSITION=[0.1,0.08])
                  ;        /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100, POSITION=[0.1,0.08])
                ENDCASE
                4:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2,series3,series4], /DATA, $
                          /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100, POSITION=[0.005,0.05])
                ENDCASE
                5:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2,series3,series4,series5], $
                          /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100, POSITION=[0.2,1])
                ENDCASE
                6:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2,series3,series4,series5,series6], $
                          /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100, POSITION=[0.2,1])
                ENDCASE
                7:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2,series3,series4,series5,series6,series7], $
                          /AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100,POSITION=[0.2,1])
                          ;/AUTO_TEXT_COLOR, FONT_SIZE=10,TRANSPARENCY=100,POSITION=[0.35,0.9])
                          ;/AUTO_TEXT_COLOR, FONT_SIZE=10,POSITION=[0.65,0.5])
                          ;/AUTO_TEXT_COLOR, FONT_SIZE=10, POSITION=[MAX(rms),tab_prof_end(nb_prof-2)])
                ENDCASE 
                8:BEGIN
                  myLegend = LEGEND(TARGET=[series1,series2,series3,series4,series5,series6,series7 $
		 	    ,series8],/DATA,/AUTO_TEXT_COLOR, FONT_SIZE=10,POSITION=[MAX(rms),tab_prof_end(nb_prof-2)])
                ENDCASE 
	       ;ELSE:
               ;   ;print,'nombre de valeurs trop grande'
               ;   ;STOP
           ENDCASE
;;        Plot Barplot for nb data value
          numx2=tab_prof_end(*)
          numx3=nb_data(*,il_begin);
          il_ind2=0
	  print,numx2
	  print,numx3
          barplot= BARPLOT(numx2,alog10(numx3),/CURRENT,POSITION=[0.70, 0.10, 0.95, 0.90],YSHOWTEXT=0,XSTYLE=1, $
                           YRANGE=[cmax ,cmin],TITLE='Number values vs depth',FONT_COLOR='blue',XTITLE='Number values in log 10',YTITLE='',$
                           YCOLOR='blue',XCOLOR='blue',BOTTOM_COLOR='cyan',FILL_COLOR='blue',/HORIZONTAL)
          IF (trans eq 1) THEN BEGIN 
             name_out=dirname_out+'/MultiSerie_'+depthlayers+'_'+var+'_'+zone+'_'+modele+'.png'
             barplot.save,name_out,/TRANSPARENT
	  ENDIF ELSE BEGIN
             name_out=dirname_out+'/MultiSerie_'+depthlayers+'_'+var+'_'+zone+'_'+modele+'.gif'
             barplot.save,name_out
	  ENDELSE
          print,'Plot OK ::',name_out
     ENDFOR 
  ENDFOR
END

