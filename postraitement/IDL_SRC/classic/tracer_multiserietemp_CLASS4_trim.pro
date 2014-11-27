PRO tracer_multiserietemp_CLASS4_trim,modele,fichier,fic_mask,profondeur,vec_prof,variable_name, $
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
  file=fichier
  nb_prof=N_ELEMENTS(profondeur)
  range_values=fltarr(2,nb_prof)
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
           'GS1_3250':BEGIN
;; Boite Gulf stream Box near the coast under florida
              FIND=WHERE(boite EQ 3250)
           ENDCASE
           'GS2_3260':BEGIN
;; Gulf stream Box off florida
              FIND=WHERE(boite EQ 3260)
           ENDCASE
           'GS3_3270':BEGIN
;; Gulf stream off florida
              FIND=WHERE(boite EQ 3270)  
           ENDCASE
           'GS4_3280':BEGIN
;; Gulf stream off florida
              FIND=WHERE(boite EQ 3280)  
           ENDCASE
           'GS5_3290':BEGIN
;; Gulf stream off florida
              FIND=WHERE(boite EQ 3290)  
           ENDCASE
           'GS6_3300':BEGIN
;; Gulf stream off florida
              FIND=WHERE(boite EQ 3300)  
           ENDCASE
           'GS7_2260':BEGIN
;; Atl tropical zone
              FIND=WHERE(boite EQ 2260)
           ENDCASE
           'GS8_1180':BEGIN
;; Atl tropical zone
              FIND=WHERE(boite EQ 1180)
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
              ;;    FIND=WHERE(boite GE 6000 AND boite LE 6770, COUNT)   
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
              FIND=WHERE(boite GE 7000 AND boite LE 7200, COUNT)
           ENDCASE
           'TAT': BEGIN
;; TAT 2120-2360 ; 3440-3790 ; 30N-30S
;;      FIND1=WHERE(boite GE 2120 AND boite LE 2360, COUNT)
;;      FIND2=WHERE(boite GE 3440 AND boite LE 3790, COUNT)
;;      FIND=[FIND1,FIND2]
; TAT  20N-20S
              FIND1=WHERE(boite GE 2120 AND boite LE 2310, COUNT)
              FIND2=WHERE(boite GE 3590 AND boite LE 3790, COUNT)
              FIND=[FIND1,FIND2]
           ENDCASE
           'TPA': BEGIN
;; TPA 4000-4530 ; 5260-5880 ; 30N-30S
;;      FIND1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
;;      FIND2=WHERE(boite GE 5260 AND boite LE 5880, COUNT)
;;      FIND=[FIND1,FIND2]
;; TPA 20N-20S
              FIND1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
              FIND2=WHERE(boite GE 5430 AND boite LE 5880, COUNT)
              FIND=[FIND1,FIND2]
           ENDCASE
           'Golf_stream':BEGIN
;; golf stream
;FIND=WHERE(boite EQ 3310, COUNT)
;;FIND=WHERE(boite GE 3260 AND boite LE 3280, COUNT)   ENDCASE
              FIND=WHERE(boite GE 3280 AND boite LE 3300, COUNT)
           ENDCASE
           'GLO':BEGIN
;; GLOBAL
              FIND=WHERE(boite GE 0, COUNT)
           ENDCASE
           
           ELSE:
                                ;  PRINT,'Zone non reconnue'
                                ;  exit,/NO_CONFIRM
        ENDCASE

        indice_i=FIND(0)
        taille=N_ELEMENTS(FIND(*))
        indice_f=FIND(taille-1)
        nfichiers=N_ELEMENTS(filelist)
        i=0L
        rms_difftot=dblarr(nb_prof,22,412,nfichiers)
        indice_tot=dblarr(nb_prof,22,412,nfichiers) ;intarr
;diff=fltarr(nfichiers-1)
        while i le nfichiers-1 do begin
           file=filelist(i)
           dirin=dir_stats_MERC
           rms_diff=ncdf_lec(file,iodir=dirin,var='rms_diff', /nostruct) & rms_diff=transpose(rms_diff)
           rms_difftot(*,*,*,i)=rms_diff
           indice=ncdf_lec(file,iodir=dirin,var='indice_box', /nostruct) & indice=transpose(indice)
           indice_tot(*,*,*,i)=indice
;  diff(i)=indice_tot(*,*,*,i)-indice
           il_nbreg=N_ELEMENTS(rms_diff(1,1,*))
           il_nelem=N_ELEMENTS(rms_diff(1,*,1))
           il_nprof=N_ELEMENTS(rms_diff(*,1,1))
                                ;print,il_nbreg,il_nelem,il_nprof
           i=i+1
        endwhile
        vect_val=intarr(taille)
; On enleve PSAL et TEMP
        rms=dblarr(nb_prof,il_nelem-2)
        nb_val_tot=dblarr(nb_prof,il_nelem-2)
        val_rms=0L
        rms(*,*,*)=0L
        nb_val_tot(*,*,*)=0L
        prof=0L 
        fichier=0L
        WHILE prof le  N_ELEMENTS(profondeur)-1 DO BEGIN
           FOR il_ind2=2,il_nelem-1 DO BEGIN
              ;; Recherche des indices valides
              vect_val=WHERE(rms_difftot(prof,il_ind2,indice_i:indice_f,fichier) GT 0)
;; Calcul de la rms
              IF (vect_val(0) NE -1) THEN BEGIN
                                ; PRINT,'Valeur :: ',prof,il_ind2,vect_val,indice_i,fichier
                 val_rms=SQRT(TOTAL(rms_difftot(prof,il_ind2,vect_val+indice_i,*)) / TOTAL(indice_tot(prof,il_ind2,vect_val+indice_i,*)))
                 nb_val= TOTAL(indice_tot(prof,il_ind2,vect_val+indice_i,*))
                 rms(prof,il_ind2-2)=val_rms
                 nb_val_tot(prof,il_ind2-2)=nb_val
              ENDIF
           ENDFOR
                                ;print,'fichier number :: ',fichier
           prof=prof+1

        ENDWHILE 

        PRINT ,'taille ',size(rms(*,1))
        PRINT ,'taille2',size(rms(1,*))
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
        cmin=50
        cmax=500
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
        PLOT,[xmin, xmax], [cmin, cmax] ,/NODATA ,YRANGE=[cmax ,cmin ],LINESTYLE=0,$
             TITLE='Rms diff vs depth' ,XTITLE='RMS misfit',YTITLE='Depth',$
             XCHARSIZE=1.5, YCHARSIZE=1.5,XSTYLE=8,YSTYLE=8,XGridStyle=1, YGridStyle=1,XTICKLEN=1,YTICKLEN=1,COLOR=black,BACKGROUND=white ;FSC_COLOR('white')
        TITLE=''
                                ;  Axis,Xaxis=0,YAxis=0,XTitle='RMS diff ';,COLOR=FSC_COLOR('black')

        FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
           print ,'Variable :: ', variable_name(il_ind+2)
           IF ( OPER eq "NO" )  THEN BEGIN 
              IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
                  and variable_name(il_ind+2) ne 'PERS3D_TEMP'  and variable_name(il_ind+2) ne 'PERS3D_PSAL' $
                  and variable_name(il_ind+2) ne 'PERS6D_TEMP'  and variable_name(il_ind+2) ne 'PERS6D_PSAL' $ 
                  and variable_name(il_ind+2) ne 'TMARV' and variable_name(il_ind+2) ne 'SMARV' ) THEN BEGIN
                 numx2=vec_prof(0:9)
                 numx1=rms(0:9,il_ind)
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
                 print, 'Variable ok',il_ind2
                 numx2=vec_prof(0:9)
                 numx1=rms(0:9,il_ind)
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
        cmin=50
        cmax=500
        xmax=MAX(alog10(nb_val_tot(0:9,*)),/NaN)
        xmin=MIN(alog10(nb_val_tot(0:9,*)),/NaN)
;       !P.POSITION=[ x0, y0, x0+dxw, y0+dyw ]
        PLOT,[xmin, xmax], [cmin, cmax] ,/NODATA ,/NOERASE,YRANGE=[cmax ,cmin ],$
             TITLE='Number values vs depth' ,XTITLE='Log10 Number values',YTITLE='Depth',$
             XCHARSIZE=1.5, YCHARSIZE=1.5,XRANGE=[xmin,xmax],LINESTYLE=1,XSTYLE=8,YSTYLE=8,XGridStyle=1,$
             YGridStyle=1,XTICKLEN=2,YTICKLEN=2,COLOR=FSC_COLOR('black'), BACKGROUND=white ; FSC_COLOR('white')
        FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
           numx2=vec_prof
           numx3=alog10(nb_val_tot(0:9,il_ind))
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
                    ishold=1
                    il_ind2=il_ind2+1
                 ENDIF
              ENDELSE     
           ENDIF
        ENDFOR
        ishold=0
        do_output,dirname_out+'/MultiSerie_trim'+var+'_'+zone+'_'+modele
        


     ENDFOR 
  ENDFOR
END
