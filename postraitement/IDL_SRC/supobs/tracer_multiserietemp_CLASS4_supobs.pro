PRO tracer_multiserietemp_CLASS4_supobs,modele,fic_mask,tab_prof, $
                                      kind,filelist,dir_stats_MERC,days,valeurs_cmax,valeurs_cmax_sal,liste_zone,tab_choix,OPER

;==========================================================================
;##  Trace des statistiques pour les fichers class4
;
;    author: C REGNIER Septembre 2007
;    author: C REGNIER Mai 2009 :: Compute rms diff for differentes
;    echeances et differents runs
;    author: C REGNIER fevrier 2010 : création du multiplot,add gulf stream boxes
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
  print,dirname_out
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
  nb_prof=N_ELEMENTS(tab_prof-1)
 
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
        rms_difftot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers)
        indice_tot=dblarr(nb_prof_model,nb_variables,il_nbox,nfichiers) ;intarr
	tab_indice_ini=intarr(nb_prof)
        tab_indice_fin=intarr(nb_prof)	  

        ; Rercherche des indice pour les boites
        indice2=0
        FOR indice=1,nb_prof-1 DO BEGIN
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
           rms_diff=ncdf_lec(file,iodir=dirin,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
	   print,"Read ok :",dirin+file
           rms_difftot(*,*,*,i)=rms_diff
           indice=ncdf_lec(file,iodir=dirin,var='indice_box', /nostruct) & indice=transpose(indice)
           indice_tot(*,*,*,i)=indice
           il_nbreg=N_ELEMENTS(rms_diff(1,1,*))
           il_nelem=N_ELEMENTS(rms_diff(1,*,1))
           il_nprof=N_ELEMENTS(rms_diff(*,1,1))
                                ;print,il_nbreg,il_nelem,il_nprof
           i=i+1
        endwhile

        ;; Normalisation par le nombre d'obs par boite
        ii=WHERE(indice_tot(*,*,*,*) GT 0)
        IF (ii(0) NE -1) THEN BEGIN
           rms_difftot(ii)=rms_difftot(ii)/indice_tot(ii)
        ENDIF
        print, "Normalisation ok"

        vect_val=intarr(taille)
; On enleve PSAL et TEMP
        rms=dblarr(nb_prof,il_nelem-2,nfichiers)
        nb_data=dblarr(nb_prof,il_nelem-2,nfichiers)
        val_rms=0L
        val_nbval=0L
        rms(*,*,*)=0L
        val_rms_new=0L
        nb_data(*,*,*)=0L
        prof=0L 
        fichier=0L
	tab_prof_model=dblarr(nb_prof-1)
        WHILE prof le N_ELEMENTS(profondeur)-1 DO BEGIN
            FOR il_ind2=2,il_nelem-1 DO BEGIN
                val_rms_tmp=0L
                val_nbval_tmp=0L
                val_tot_e3t=0L
                il_var=0
                FOR fichier=0,nfichiers-1 DO BEGIN
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
                 ENDFOR
                 val_rms_new=SQRT(val_rms_tmp/val_tot_e3t)
                 val_nbval=val_nbval_tmp
                 rms(prof,il_ind2-2)=val_rms_new
                 nb_data(prof,il_ind2-2)=val_nbval
           ENDFOR
           prof=prof+1	
        ENDWHILE 
        
        prof=0L 
	print,tab_prof
         WHILE prof le nb_prof-2 DO BEGIN
           tab_prof_model(prof)=(tab_prof(prof)+tab_prof(prof+1))/2
           prof=prof+1
	ENDWHILE
	print,tab_prof_model
	
        ;PRINT ,'taille ',size(rms(*,1))
        ;PRINT ,'taille2',size(rms(1,*))
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
        colors(1)='blue'
        colors(2)='red'
        colors(3)='cyan'
        colors(4)='green'
        colors(5)='gold'
        colors(6)='Chocolate'
        colors(7)='grey'
        colors(8)='salmon'
        colors(9)='Hot Pink'
        colors(10)='Aquamarine'



        output='grid screen gif'
	;output='grid A3 ps'
        prof=0L 

        clear,ctot
        il_ind2=0L
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


;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Definition of parameters in the windows
;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; window of the plot in the figure: origine and sizes

        x0=0.10
        y0=0.12



        x0=0.10 & y0=.17        &       dxw=1-2.*x0 & dyw=1-1.5*y0 ; 01/03/02
; plot
        a4=[210., 297.]
        a4R=[297., 210.]
        shape=a4R
        axisratio=0.5
	name_out='MultiSerie_trim'+var+'_'+zone+'_'+modele
        prep_output, shape, axisratio 

        common COLOR_BLOCK,black,grey,white,bleuey,cyan,green,gold,yellow,red,blue,salmon,aquam,brown,burly,gmt_land
        Def_colors
;colors=[black,cyan, green, yellow, red, blue, salmon,  aquam, brown,burly] ; serie of fav colors (flashy and distinct)

        z=black                 ; reverse video
        black=white             ; reverse video
        white=z                 ; reverse video
;        we set the 1st color (NaN <-> background)
        TVLCT, black,   000     ; default on PCs
;;       we set the last color (text)
        TVLCT, white,   !D.TABLE_SIZE-1
;       	some color indexes in the current colormap
        black=  rgb2ind(000,000,000)
        grey=   rgb2ind(127,127,127)
        white=  rgb2ind(255,255,255)
        ticklen=-0.02
        IF STRPOS(kind,'grid') NE -1 THEN yticklen=1
                ;;; rajout C. REGNIER
        IF STRPOS(kind,'grid') NE -1 THEN BEGIN
           xticksval=0
           xticklen=1
        ENDIF ELSE BEGIN
           xticksval=1
           xticklen=0
        ENDELSE

;print ,'pre output'
;DEVICE, RETAIN=2, DECOMPOSED=0  
;; Boucle sur les variables 
        !Y.MARGIN=[y0+15*dyw,y0]
;; Multiplot avec 2 images côte à côte
        !P.multi = [ 0, 2 ,1 ]
                                ;   plot_xy,0,val4,PLOT_KIND=kind,NOTE2=variable_name(il_ind+2),OVERPLOT=8
;       !P.POSITION=[ x0, y0, x0+dxw, y0+dyw ]
        ;cmin=50
        ;cmax=500
;        cmin=MIN(tab_prof_model,/NaN)
;	cmax=MAX(tab_prof_model,/NaN)
        cmin=MIN(tab_prof,/NaN)
	cmax=MAX(tab_prof,/NaN)
	if (cmax GT 3000) then cmax=1500
        xmin=0.05
        i=WHERE(rms EQ 0) & IF i(0) NE -1 THEN  rms(i)=!VALUES.F_NAN
        if (var eq 'SAL') THEN BEGIN
           xmin=MIN( rms(*,1:*:2),/NaN )
           xmax=MAX( rms(*,1:*:2), /NaN )
        endif else begin
           if (var eq 'TEMP') THEN BEGIN
              xmin=MIN( rms(*,0:*:2),/NaN )
              xmax=MAX(rms(*,0:*:2),/NaN )
           endif                                                                                                        
        endelse
        print, xmax,xmin
	numx2=tab_prof_model(*)
	numx1=nb_data(*,il_ind)
	;cgHistoplot,data, BINSIZE=1.0, /FILL
	;STOP
;	PLOT,numx1, numx2,/noerase, $
;            YRANGE=[cmax ,cmin ],LINESTYLE=0,Psym=10,$
;	    TITLE='Rms diff vs depth' ,XTITLE='RMS misfit',YTITLE='Depth',$
;            XCHARSIZE=1.5, YCHARSIZE=1.5,XSTYLE=3,YSTYLE=8,XGridStyle=1,$
;	     YGridStyle=1,XTICKLEN=1,YTICKLEN=1,COLOR=black,BACKGROUND=white         
;	 PLOT,numx1, numx2, /NODATA,/noerase, $
;                   LINESTYLE=3,THICK=3,BACKGROUND = 0,COLOR=255 ,XCHARSIZE=0.9, YCHARSIZE=1.1, $
;                   XSTYLE=8,YSTYLE=4,YTICKLEN=yticklen,YGRIDSTYLE=1
;
;	     color=1 
           ;  area, nb_data, numx1,nb_data*0,1, color
;           ;  AXIS, YAXIS=1, YRANGE=[MIN(nb_data,/NaN),MAX(nb_data,/NaN)], ytitle=' Number of data ',COLOR =1
	    ; ishold=1		 	
        PLOT,[xmin, xmax], [cmin, cmax] ,/NODATA ,YRANGE=[cmax ,cmin ],LINESTYLE=0,$
             TITLE='Rms diff vs depth' ,XTITLE='RMS misfit',YTITLE='Depth',$
             XCHARSIZE=1.5, YCHARSIZE=1.5,XSTYLE=8,YSTYLE=8,XGridStyle=1, YGridStyle=1,XTICKLEN=1,YTICKLEN=1,COLOR=black,BACKGROUND=white ;FSC_COLOR('white')
        TITLE=''
        FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
           print ,'Variable :: ', variable_name(il_ind+2)
           IF ( OPER eq "NO" )  THEN BEGIN 
              IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                  and variable_name(il_ind+2) ne 'PERS3D_TEMP'  and variable_name(il_ind+2) ne 'PERS3D_PSAL' $
                  and variable_name(il_ind+2) ne 'PERS6D_TEMP'  and variable_name(il_ind+2) ne 'PERS6D_PSAL' $ 
                  and variable_name(il_ind+2) ne 'TMARV' and variable_name(il_ind+2) ne 'SMARV' ) THEN BEGIN
               ;  numx2=vec_prof(0:9)
               ;  numx1=rms(0:9,il_ind)
                 numx2=tab_prof_model(*)
                 numx1=rms(*,il_ind)
                 Number=WHERE(numx1(*) GT 0)
                 IF number(0)  NE -1 THEN BEGIN
                    ; Axis,YAxis=0,XTitle='RMS diff ',COLOR=FSC_COLOR('black')
                    a=FINDGEN(17)*(!PI*2/16.)
                    USERSYM, COS(a), SIN(a), /FILL  
                    OPLOT, numx1, numx2, LINESTYLE=0, THICK=2., COLOR=FSC_COLOR(colors(il_ind2)) ; COLOR=FSC_COLOR('red') ;,PSYM=1 ;;  Modifs C.REGNIER
                    ;OPLOT, numx1, numx2, LINESTYLE=0, COLOR=FSC_COLOR(colors(il_ind2))
                    print, colors(il_ind2),il_ind2
                    ishold=1
                    ;; boucle OPLOT ici
                    OPLOT, numx1, numx2, PSYM=8,LINESTYLE=1,COLOR=FSC_COLOR(colors(il_ind2)), SYMSIZE=0.8,THICK=2 ;COLOR=FSC_COLOR('red')
                    IF (variable_name(il_ind+2) eq 'HDCST_TEMP' or variable_name(il_ind+2) eq 'HDCST_PSAL' ) THEN BEGIN
                       note2='!3'+modele+' '+variable_name(il_ind+2)+'!3'
                    ENDIF ELSE BEGIN
                       note2='!3'+variable_name(il_ind+2)+'!3' 
                    ENDELSE
                    noplot=il_ind2+1
                    i=((noplot-1) MOD 2) & j=(noplot-1)/2          ; 2 columns, 3 raws
                    zx1=x0+dxw/4+i*dxw/2 & zy1=y0 -dyw/9 -j*dyw/28 ; legend below plot
                    XYOUTS, zx1, zy1, note2, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=FSC_COLOR(colors(il_ind2)) 
                    il_ind2=il_ind2+1
                      ;; write ASCII file
                    iof=1
                    err=0
                    tab_ASCII=rms(10,il_ind)
                    file=dirname_out+'/File_ASCII/Fic_ASCII_'+modele+'_'+profondeur(10)+'.txt'  
                    OPENW, iof, file, ERROR=err, /APPEND 
                    print ,'Ecriture file ascii ',file,err 
                    IF err EQ 0 THEN BEGIN
                       PRINTF, iof, variable_name(il_ind+2),zone,tab_ASCII, FORMAT='(A10, 1X ,A10,1x,F10.8)'
                    ENDIF
                    IF err EQ 0 THEN CLOSE, iof
                 ENDIF     
              ENDIF
           ENDIF ELSE BEGIN
              IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                  and variable_name(il_ind+2) ne 'PERS_TEMP'  and variable_name(il_ind+2) ne 'PERS_PSAL') THEN BEGIN
                 print, 'Variable ok',il_ind
                 ;numx2=vec_prof(0:9)
                 ;numx1=rms(0:9,il_ind)
                 numx2=tab_prof_model(*)
                 numx1=rms(*,il_ind)
		 print,numx2,numx1
                 Number=WHERE(numx1(*) GT 0)
                 IF number(0)  NE -1 AND  max(numx1) NE 0 THEN BEGIN
                    a=FINDGEN(17)*(!PI*2/16.)
                    USERSYM, COS(a), SIN(a), /FILL  
                    OPLOT, numx1, numx2, LINESTYLE=0, THICK=2., COLOR=FSC_COLOR(colors(il_ind2)) ; COLOR=FSC_COLOR('red') ;,PSYM=1 ;;  Modifs C.REGNIER
                    print, colors(il_ind2),il_ind2
                    ishold=1
                    ;; boucle OPLOT ici
                    OPLOT, numx1, numx2, PSYM=8,LINESTYLE=1,COLOR=FSC_COLOR(colors(il_ind2)), SYMSIZE=0.8,THICK=2 ;COLOR=FSC_COLOR('red')
                    IF (variable_name(il_ind+2) eq 'HDCST_TEMP' or  variable_name(il_ind+2) eq 'HDCST_PSAL' ) THEN BEGIN
                       note2='!3'+modele+' '+variable_name(il_ind+2)+'!3'
                    ENDIF ELSE BEGIN
                       note2='!3'+variable_name(il_ind+2)+'!3'	
                    ENDELSE
                    noplot=il_ind2+1
                    i=((noplot-1) MOD 2) & j=(noplot-1)/2           ; 2 columns, 3 raws
                    zx1=x0+dxw/4+i*dxw/2 & zy1=y0 -dyw/9 -j*dyw/28  ; legend below plot
                    XYOUTS, zx1, zy1, note2, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=FSC_COLOR(colors(il_ind2)) 
                    il_ind2=il_ind2+1
                 ENDIF
              ENDIF
           ENDELSE
           
            
        ENDFOR
        ishold=1
        il_ind2=0L
        ;cmin=50
        ;cmax=500
        cmin=MIN(tab_prof_model,/NaN)
	cmax=MAX(tab_prof_model,/NaN)
	if (cmax GT 3000) then cmax=1500
        xmax=MAX(alog10(nb_data),/NaN)
        xmin=MIN(alog10(nb_data),/NaN)
       ;!P.POSITION=[ x0, y0, x0+dxw, y0+dyw ]
       PLOT,[xmin, xmax], [cmin, cmax] ,/NODATA ,/NOERASE,YRANGE=[cmax ,cmin ],$
             TITLE='Number values vs depth' ,XTITLE='Log10 Number values',YTITLE='Depth',$
             XCHARSIZE=1.5, YCHARSIZE=1.5,XRANGE=[xmin,xmax],LINESTYLE=1,XSTYLE=8,YSTYLE=8,XGridStyle=1,$
             YGridStyle=1,XTICKLEN=2,YTICKLEN=2,COLOR=FSC_COLOR('black'), BACKGROUND=white ; FSC_COLOR('white')
        FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
           numx2=tab_prof_model(*)
           numx3=alog10(nb_data(*,il_ind))
           Number=WHERE(numx3(*) GT 0)
           IF number(0)  NE -1 AND  max(numx1) NE 0 THEN BEGIN
              IF ( OPER eq "NO" )  THEN BEGIN 
                 IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                     and variable_name(il_ind+2) ne 'PERS3D_TEMP'  and variable_name(il_ind+2) ne 'PERS3D_PSAL' $
                     and variable_name(il_ind+2) ne 'PERS6D_TEMP'  and variable_name(il_ind+2) ne 'PERS6D_PSAL' $
                     and variable_name(il_ind+2) ne 'TMARV' and variable_name(il_ind+2) ne 'SMARV' ) THEN BEGIN
                                ;  Axis,YAxis=1,XTitle='Number values',COLOR=FSC_COLOR('black')
                    OPLOT, numx3, numx2, LINESTYLE=0, THICK=2.,COLOR=FSC_COLOR(colors(il_ind2))
                    OPLOT, numx3, numx2, PSYM=8,LINESTYLE=1,SYMSIZE=0.8,THICK=2,COLOR=FSC_COLOR(colors(il_ind2))
                    ishold=1
                    il_ind2=il_ind2+1
                 ENDIF
              ENDIF ELSE BEGIN
                 IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                     and variable_name(il_ind+2) ne 'PERS_TEMP'  and variable_name(il_ind+2) ne 'PERS_PSAL'$
                     and variable_name(il_ind+2) ne 'TMARV' and variable_name(il_ind+2) ne 'SMARV'  ) THEN BEGIN
                                ;  Axis,YAxis=1,XTitle='Number values',COLOR=FSC_COLOR('black')
                    OPLOT, numx3, numx2, LINESTYLE=0, THICK=2.,COLOR=FSC_COLOR(colors(il_ind2))
                    OPLOT, numx3, numx2, PSYM=8,LINESTYLE=1,SYMSIZE=0.8,THICK=2,COLOR=FSC_COLOR(colors(il_ind2))
		    color=1
                    ishold=1
                    il_ind2=il_ind2+1
                 ENDIF
              ENDELSE     
           ENDIF
        ENDFOR
	STOP
        ishold=0
        do_output,dirname_out+'/MultiSerie_trim'+var+'_'+zone+'_'+modele
        
STOP

     ENDFOR 
  ENDFOR
END
