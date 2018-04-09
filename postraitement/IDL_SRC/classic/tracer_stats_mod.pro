PRO tracer_stats_mod,month_ini,month_fin,zone,var1,var2,critere
;==========================================================================
;##  Trace des statistiques pour les fichers class4
;
;    author: C REGNIER Mars 2008
;
;==========================================================================
@param
@param_gauges
@param_class4

;;---------------------------------
;; Definition des variables
;;--------------------------------
profondeur=strarr(6)

profondeur(0)='0-5m'
profondeur(1)='5-100m'
profondeur(2)='100-500m'
profondeur(3)='500-2000m'
profondeur(4)='2000-5000m'
profondeur(5)='0-6000m'

variable=strarr(22)

variable(0)='TEMP'
variable(1)='PSAL'
variable(2)='HDCST_TEMP'
variable(3)='HDCST_PSAL'
variable(4)='ANA_TEMP'
variable(5)='ANA_PSAL'
variable(6)='FRCST3D_TEMP'
variable(7)='FRCST3D_PSAL'
variable(8)='FRCST6D_TEMP'
variable(9)='FRCST6D_PSAL'
variable(10)='PERS3D_TEMP'
variable(11)='PERS3D_PSAL'
variable(12)='PERS6D_TEMP'
variable(13)='PERS6D_PSAL'
variable(14)='FSTGS_TEMP'
variable(15)='FSTGS_PSAL'
variable(16)='TMLEV'
variable(17)='SMLEV'
variable(18)='TMMED'
variable(19)='SMMED'
variable(20)='TMBAL'
variable(21)='SMBAL'

; Valeur des indices
chdate2jul, '2007/04/01', yyy, mm, dd, avril
chdate2jul, '2007/05/01', yyy, mm, dd, mai
chdate2jul, '2007/06/01', yyy, mm, dd, juin
chdate2jul, '2007/07/01', yyy, mm, dd, juillet
chdate2jul, '2007/08/01', yyy, mm, dd, aout
chdate2jul, '2007/09/01', yyy, mm, dd, septembre

mois=strarr(12)
mois(0)='January'
mois(1)='February'
mois(2)='Mars'
mois(3)='April'
mois(4)='May'
mois(5)='Juny'
mois(6)='July'
mois(7)='August'
mois(8)='September'
mois(9)='October'
mois(10)='November'
mois(11)='December'

;---------------------------------------------
;; Lecture masque et boites
;----------------------------------------------

file_mask='maskbox.nc'
file_box='box.nc'

x1=ncdf_lec(file_mask,iodir=dir_mask,var='longitude', /nostruct) & x1=transpose(x1)
x2=ncdf_lec(file_mask,iodir=dir_mask,var='latitude', /nostruct) & x2=transpose(x2)
boite=ncdf_lec(file_box,iodir=dir_mask,var='box', /nostruct) & boite=transpose(boite)


;; Choix de la zone à étudier

CASE zone OF
         'A':BEGIN
             ;; Atl Nord de 3000 à 4000
             FIND=WHERE(boite GE 3000 AND boite LT 4000, COUNT)
             print,'Zone Atlantique'
             domaine='North Atlantic'
             listemodele=strarr(5)
             listemodele(0)='PSY3V1'
             listemodele(1)='PSY3V2R2'
             listemodele(2)='PSY2V3'
             listemodele(3)='WOA05'
             listemodele(4)='FOAM'
             nmodel=5
             
         ENDCASE
         'P':BEGIN
             ;; pacifique nord 5000 à 6000
             FIND=WHERE(boite GE 5000 AND boite LT 6000, COUNT)
             domaine='North Pacific'
             print,'Zone North Pacific '
             listemodele=strarr(3)
             listemodele(0)='PSY3V1'
             listemodele(1)='PSY3V2R2'
             listemodele(2)='WOA05'
             nmodel=3
         ENDCASE
         'I':BEGIN
             ;; Indien de 6000 à 7000
             FIND=WHERE(boite GE 6000 AND boite LT 7000, COUNT)
             print,'Zone Indian '
             domaine='Indian'
             listemodele=strarr(3)
             listemodele(0)='PSY3V1'
             listemodele(1)='PSY3V2R2'
             listemodele(2)='WOA05'
             nmodel=3
         ENDCASE
         'MED':BEGIN
             ;zone='A'
             domaine='Mediterranee'
             print,'Zone Med '
            ; FIND=WHERE(boite GE 1000 AND boite LT 1300 AND boite NE 1190, COUNT)
             FIND=WHERE(boite GE 1000 AND boite LT 2000, COUNT)
                         

             listemodele=strarr(5)
             listemodele(0)='PSY3V1'
             listemodele(1)='PSY3V2R2'
             listemodele(2)='PSY2V3'
             listemodele(3)='WOA05'
             listemodele(4)='MFS'
             nmodel=5
         ENDCASE
         'T':BEGIN
             FIND=WHERE(boite GE 0)
             print,'Zone Gobal '
             domaine='Global'
             listemodele=strarr(3)
             listemodele(0)='PSY3V2R2'
             listemodele(1)='PSY3V1'
             listemodele(2)='WOA05'
             nmodel=3
         ENDCASE
         ELSE:
     ENDCASE

     indice_i=FIND(0)
     taille=N_ELEMENTS(FIND(*))
     indice_f=FIND(taille-1)
     print,'INDICE :',indice_i,indice_f
     val=fltarr(taille)


;;--------------------------------------
;; Boucle sur les profondeurs : Choix de la profondeur
;;----------------------------------------

 prof=0L
 
 WHILE prof le 5 DO BEGIN
;; Choix du parametre


     FOR il_ind2=var1,var2  DO BEGIN
       ; RMS diff
         nb_elem=(month_fin-month_ini)+1
         rms_PSY3V2=fltarr(nb_elem,1)
         rms_PSY3V1=fltarr(nb_elem,1)
         rms_PSY2V3=fltarr(nb_elem,1)
         rms_FOAM=fltarr(nb_elem,1)
         rms_LEV=fltarr(nb_elem,1)
         rms_MFS=fltarr(nb_elem,1)
         
         test_pair=il_ind2 mod 2
         IF test_pair EQ 0 THEN BEGIN
             indice_var=0
            ;IF modele EQ 'WOA05' THEN BEGIN
        ;    parametre='TEMPLEV'
            ;ENDIF ELSE BEGIN 
             parametre='TEMPERATURE'
           ; ENDELSE
             print,'Variable temperature'
         ENDIF ELSE BEGIN
             indice_var=1
             print,'Variable salinité'
            ; IF modele EQ 'WOA05' THEN BEGIN
        ;     parametre='SALLEV'
            ; ENDIF ELSE BEGIN 
             parametre='SALINITY'
           ; ENDELSE
         ENDELSE

;;------------------------------------------------------------------
;; Boucle sur la liste des modeles en fonction de la zone choisie
;;------------------------------------------------------------------

         FOR modele_i=0,nmodel-1  DO BEGIN
             modele=listemodele(modele_i)
             print,'MODELE::',modele
             print,'VARIABLE',var1,var2
             
             IF critere EQ 0 THEN BEGIN
                 file=modele+'_'+zone+'_2007_stats.nc'
                 IF zone EQ 'MED' THEN BEGIN
                     file=modele+'_A_2007_stats.nc'
                 ENDIF 
                 
                 choix='Avec_critere'
                 CASE  modele OF
                     'FOAM':BEGIN
                         dirfile=dir_stats_FOAM+choix+'/'
                         PRINT,'DIRFILE',dirfile,dir_stats_FOAM
                     ENDCASE
                     'MFS':BEGIN
                         dirfile=dir_stats_MFS+choix+'/'
                     ENDCASE
                     'PSY3V1':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                     'PSY3V2R2':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                     'PSY2V3':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                     'WOA05':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                 ENDCASE
             ENDIF ELSE BEGIN
                 choix='Sans_critere'
                 file=modele+'_T_2007_stats.nc'

                 CASE  modele OF
                     'FOAM':BEGIN
                         dirfile=dir_stats_FOAM+choix+'/'
                     ENDCASE
                     'MFS':BEGIN
                         dirfile=dir_stats_MFS+choix+'/'
                     ENDCASE
                     'PSY3V2R2':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                     'PSY3V1':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                     'PSY2V3':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                     'WOA05':BEGIN
                         dirfile=dir_stats_MERC+modele+'/'+choix+'/'
                     ENDCASE
                 ENDCASE
             ENDELSE

;;-----------------------------------------------------------------------------------------
;; Boucle sur les mois de stats
;;------------------------------------------------------------------------------------------
         count=0
         FOR i=month_ini,month_fin  DO BEGIN
             print,'MONTH READ ::',mois(i-1),i,dirfile,file
             
             CASE  modele OF
                 'PSY3V2R2':BEGIN
                     rms_diff_PSY3V2=ncdf_lec(file,iodir=dirfile,var='rms_diff_0'+STRING(FORMAT='(I1)', i), /nostruct) & rms_diff_PSY3V2=transpose(rms_diff_PSY3V2)
                     indice_PSY3V2=ncdf_lec(file,iodir=dirfile,var='indice_0'+STRING(FORMAT='(I1)', i), /nostruct) & indice_PSY3V2=transpose(indice_PSY3V2)
                     val=WHERE(rms_diff_PSY3V2(prof,il_ind2,indice_i:indice_f) GT 0)
                     IF val(0) NE -1 THEN BEGIN
                         rms_PSY3V2(count,*)=SQRT( TOTAL(rms_diff_PSY3V2(prof,il_ind2,val+indice_i))/ TOTAL(indice_PSY3V2(prof,il_ind2,val+indice_i)))
                     ENDIF
                     clear,val
                 ENDCASE
                 'PSY3V1':BEGIN
                     rms_diff_PSY3V1=ncdf_lec(file,iodir=dirfile,var='rms_diff_0'+STRING(FORMAT='(I1)', i), /nostruct) & rms_diff_PSY3V1=transpose(rms_diff_PSY3V1)
                     indice_PSY3V1=ncdf_lec(file,iodir=dirfile,var='indice_0'+STRING(FORMAT='(I1)', i), /nostruct) & indice_PSY3V1=transpose(indice_PSY3V1)
                     val=WHERE(rms_diff_PSY3V1(prof,il_ind2,indice_i:indice_f) GT 0)
                     IF val(0) NE -1 THEN BEGIN
                         rms_PSY3V1(count,*)=SQRT( TOTAL(rms_diff_PSY3V1(prof,il_ind2,val+indice_i))/ TOTAL(indice_PSY3V1(prof,il_ind2,val+indice_i)))
                     ENDIF
                     clear,val
                 ENDCASE
                 'FOAM':BEGIN
                     rms_diff_FOAM=ncdf_lec(file,iodir=dirfile,var='rms_diff_0'+STRING(FORMAT='(I1)', i), /nostruct) & rms_diff_FOAM=transpose(rms_diff_FOAM)
                     indice_FOAM=ncdf_lec(file,iodir=dirfile,var='indice_0'+STRING(FORMAT='(I1)', i), /nostruct) & indice_FOAM=transpose(indice_FOAM)
                     val=WHERE(rms_diff_FOAM(prof,il_ind2,indice_i:indice_f) GT 0)
                     IF val(0) NE -1 THEN BEGIN
                         rms_FOAM(count,*)=SQRT( TOTAL(rms_diff_FOAM(prof,il_ind2,val+indice_i))/ TOTAL(indice_FOAM(prof,il_ind2,val+indice_i)))
                     ENDIF
                     clear,val
                 ENDCASE
                 'PSY2V3':BEGIN
                     rms_diff_PSY2V3=ncdf_lec(file,iodir=dirfile,var='rms_diff_0'+STRING(FORMAT='(I1)', i), /nostruct) & rms_diff_PSY2V3=transpose(rms_diff_PSY2V3)
                     indice_PSY2V3=ncdf_lec(file,iodir=dirfile,var='indice_0'+STRING(FORMAT='(I1)', i), /nostruct) & indice_PSY2V3=transpose(indice_PSY2V3)
                     val=WHERE(rms_diff_PSY2V3(prof,il_ind2,indice_i:indice_f) GT 0)
                     IF val(0) NE -1 THEN BEGIN
                         rms_PSY2V3(count,*)=SQRT( TOTAL(rms_diff_PSY2V3(prof,il_ind2,val+indice_i))/ TOTAL(indice_PSY2V3(prof,il_ind2,val+indice_i)))
                     ENDIF
                     clear,val
                 ENDCASE
                 'WOA05':BEGIN
                     il_ind3=il_ind2+14
                     rms_diff_WOA05=ncdf_lec(file,iodir=dirfile,var='rms_diff_0'+STRING(FORMAT='(I1)', i), /nostruct) & rms_diff_WOA05=transpose(rms_diff_WOA05)
                     indice_WOA05=ncdf_lec(file,iodir=dirfile,var='indice_0'+STRING(FORMAT='(I1)', i), /nostruct) & indice_WOA05=transpose(indice_WOA05)
                     val=WHERE(rms_diff_WOA05(prof,il_ind3,indice_i:indice_f) GT 0)
                     IF val(0) NE -1 THEN BEGIN
                     rms_LEV(count,*)=   SQRT( TOTAL(rms_diff_WOA05 (prof,il_ind3,val+indice_i))/ TOTAL(indice_WOA05(prof,il_ind3,val+indice_i)))
                     ENDIF
                     nom_var_LEV=variable(il_ind3)
                     clear,val
                 ENDCASE
                 'MFS':BEGIN
                     rms_diff_MFS=ncdf_lec(file,iodir=dirfile,var='rms_diff_0'+STRING(FORMAT='(I1)', i), /nostruct) & rms_diff_MFS=transpose(rms_diff_MFS)
                     indice_MFS=ncdf_lec(file,iodir=dirfile,var='indice_0'+STRING(FORMAT='(I1)', i), /nostruct) & indice_MFS=transpose(indice_MFS)
                     val=WHERE(rms_diff_MFS(prof,il_ind2,indice_i:indice_f) GT 0)
                     IF val(0) NE -1 THEN BEGIN
                         rms_MFS(count,*)= SQRT( TOTAL(rms_diff_MFS(prof,il_ind2,val+indice_i))/ TOTAL(indice_MFS(prof,il_ind2,val+indice_i)))
                     ENDIF
                     clear,val
                 ENDCASE
             ENDCASE 
             count=count+1
         ENDFOR  ;; FOR i=month_ini,month_fin
         
       ENDFOR     ;; FOR modele_i=0,nmodel-1
     
       nom_var=variable(il_ind2)

         tmin=avril
         tmax=septembre

         ;clear,output,cmin,cmax
         output='logo gif'
         ;; Titre
         titre='Class4 '+domaine+' '+parametre+' '+profondeur(prof)

;;-------------------------------------------------------------------
;; Tracé des series temporelles en fonction de la zone choisie         
;;-------------------------------------------------------------------
        
         CASE zone OF
         'A':BEGIN
             VAL_RMS=cat(1, [rms_PSY3V1(*,0)], [rms_PSY3V2(*,0)]) 
             VAL_RMS2=cat(1,VAL_RMS,[rms_FOAM(*,0)])
             VAL_RMS3=cat(1,VAL_RMS2,[rms_LEV(*,0)])
             VAL_RMS4=cat(1,VAL_RMS3,[rms_PSY2V3(*,0)])
             cmax=1.2*MAX(VAL_RMS4)
             cmin=0.8*MIN(VAL_RMS4)
             ishold=1
             val=rgb2ind(0,0,255)
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_PSY3V2(*,0)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V2R2 '+nom_var,OVERPLOT=8
             clear,numx2
             numx2=rms_PSY3V1(*,0)
             ishold=1
             numx1=[avril,mai,juin,juillet,aout,septembre]
             val=rgb2ind(127,127,127)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V1 '+nom_var,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_LEV(*,0)
             ishold=1
             var=rgb2ind(255,0,0)
             plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='WOA05 '+nom_var_LEV,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_FOAM(*,0)
             ishold=1
             val=rgb2ind(0,0,0)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='FOAM '+nom_var,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_PSY2V3(*,0)
             ishold=1
             var=rgb2ind(144,0,0)
             plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY2V3 '+nom_var,OVERPLOT=8

        ENDCASE
        'P':BEGIN
            VAL_RMS=cat(1, [rms_PSY3V1(*,0)], [rms_PSY3V2(*,0)]) 
             VAL_RMS4=cat(1,VAL_RMS,[rms_LEV(*,0)])
             cmax=1.2*MAX(VAL_RMS4)
             cmin=0.8*MIN(VAL_RMS4)
             ishold=1
             val=rgb2ind(0,0,255)
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_PSY3V2(*,0)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V2R2 '+nom_var,OVERPLOT=8
             clear,numx2
             numx2=rms_PSY3V1(*,0)
             ishold=1
             numx1=[avril,mai,juin,juillet,aout,septembre]
             val=rgb2ind(127,127,127)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V1 '+nom_var,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_LEV(*,0)
             ishold=1
             var=rgb2ind(255,0,0)
             plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='WOA05 '+nom_var_LEV,OVERPLOT=8
         ENDCASE
          'I':BEGIN
              VAL_RMS=cat(1, [rms_PSY3V1(*,0)], [rms_PSY3V2(*,0)]) 
              VAL_RMS4=cat(1,VAL_RMS,[rms_LEV(*,0)])
              cmax=1.2*MAX(VAL_RMS4)
              cmin=0.8*MIN(VAL_RMS4)
              ishold=1
              val=rgb2ind(0,0,255)
              numx1=[avril,mai,juin,juillet,aout,septembre]
              numx2=rms_PSY3V2(*,0)
              plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V2R2 '+nom_var,OVERPLOT=8
              clear,numx2
              numx2=rms_PSY3V1(*,0)
              ishold=1
              numx1=[avril,mai,juin,juillet,aout,septembre]
              val=rgb2ind(127,127,127)
              plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V1 '+nom_var,OVERPLOT=8
              clear,numx2
              numx1=[avril,mai,juin,juillet,aout,septembre]
              numx2=rms_LEV(*,0)
              ishold=1
              var=rgb2ind(255,0,0)
              plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='WOA05 '+nom_var_LEV,OVERPLOT=8
        ENDCASE
          'MED':BEGIN
             VAL_RMS=cat(1, [rms_PSY3V1(*,0)], [rms_PSY3V2(*,0)]) 
             VAL_RMS3=cat(1,VAL_RMS,[rms_LEV(*,0)])
             VAL_RMS4=cat(1,VAL_RMS3,[rms_PSY2V3(*,0)])
             VAL_RMS5=cat(1,VAL_RMS4,[rms_MFS(*,0)])
                          
             cmax=1.2*MAX(VAL_RMS5)
             cmin=0.8*MIN(VAL_RMS5)
             ishold=1
             val=rgb2ind(0,0,255)
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_PSY3V2(*,0)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V2R2 '+nom_var,OVERPLOT=8
             clear,numx2
             numx2=rms_PSY3V1(*,0)
             ishold=1
             numx1=[avril,mai,juin,juillet,aout,septembre]
             val=rgb2ind(127,127,127)
             plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V1 '+nom_var,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_LEV(*,0)
             ishold=1
             var=rgb2ind(255,0,0)
             plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='WOA05 '+nom_var_LEV,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_PSY2V3(*,0)
             ishold=1
             var=rgb2ind(144,0,0)
             plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY2V3 '+nom_var,OVERPLOT=8
             clear,numx2
             numx1=[avril,mai,juin,juillet,aout,septembre]
             numx2=rms_MFS(*,0)
             ishold=1
             var=rgb2ind(102,0,153)
             plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='MFS '+nom_var,OVERPLOT=8

        ENDCASE
        'T':BEGIN
            VAL_RMS=cat(1, [rms_PSY3V1(*,0)], [rms_PSY3V2(*,0)])
            VAL_RMS4=cat(1,VAL_RMS,[rms_LEV(*,0)])
            cmax=1.2*MAX(VAL_RMS4)
            cmin=0.8*MIN(VAL_RMS4)
            ishold=1
            val=rgb2ind(0,0,255)
            numx1=[avril,mai,juin,juillet,aout,septembre]
            numx2=rms_PSY3V2(*,0)
            plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V2R2 '+nom_var,OVERPLOT=8
            clear,numx2
            numx2=rms_PSY3V1(*,0)
            ishold=1
            numx1=[avril,mai,juin,juillet,aout,septembre]
            val=rgb2ind(127,127,127)
            plot_ts2,0,val,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='PSY3V1 '+nom_var,OVERPLOT=8
            clear,numx2
            numx1=[avril,mai,juin,juillet,aout,septembre]
            numx2=rms_LEV(*,0)
            ishold=1
            var=rgb2ind(255,0,0)
            plot_ts2,0,var,PLOT_KIND='solid_line no_bg colormap_ind grid',NOTE2='WOA05 '+nom_var_LEV,OVERPLOT=8
        ENDCASE
        ELSE:
    ENDCASE
;--------------------------------
; Sauvegarde de l'image obtenue
;--------------------------------
         ishold=0
         do_outputbis,dirname_out+'Rmsdiff_'+domaine+'_'+profondeur(prof)+'_'+nom_var+'_'+choix
        
         
     ENDFOR      ;;FOR il_ind2=var1,var2
     prof=prof+1
     ENDWHILE    ;;WHILE prof le 5
END
