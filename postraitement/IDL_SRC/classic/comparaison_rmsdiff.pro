;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@param
@compile
@param_class4
@config_PSY3V3R1
modele2="PSY3V2R2"   
;@config_PSY2V4R1
;modele2="PSY2V3R1"   


dirname_out_RTR1=fic_out_RTR1
dirname_out_RTR2=fic_out_RTR2

output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/Comparaison/'
dirin=dir_stats_MERC

; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'

;; Definition des variable_names
;;variable_name2=strarr(5)
;;variable_name2(0)='HDCST_TEMP'
;;variable_name2(1)='HDCST_PSAL'
;;variable_name2(2)='TMLEV'
;;variable_name2(3)='SMLEV'
;;variable_name2(4)='TMARV'
;;variable_name2(5)='SMARV'
;; Definition des variables

.compile Def_param_bulletin
.compile Def_colors
.compile plot_serietemp_test
.compile plot_serietemp_test2
.compile median_filter
Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
   valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
   profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,listemodele

; Compilation & Execution 
.compile tracer_suivi_rmsdiff
;; choix du type de tracé 
kind='solid_line no_bg grid '
clear,titre,units
;;
CASE modele OF  & $
   'PSY3V2R2': BEGIN & $
   liste_region=strarr(11) & $
   liste_region(*)=liste_zone(*) & $
   ENDCASE & $
   'PSY3V3R1': BEGIN & $
   liste_region=strarr(11) & $
   liste_region(*)=liste_zone(*) & $
;         liste_region=strarr(1) & $ 
;         liste_region(*)=liste_TEST(*) & $ 
   ENDCASE & $

   'PSY2V3R1': BEGIN & $
   liste_region=strarr(3) & $
   liste_region=liste_zone_PSY2 & $
   ENDCASE & $

   'PSY2V4R1': BEGIN & $
   liste_region=strarr(3) & $
   liste_region=liste_zone_PSY2 & $
   ENDCASE & $

   ENDCASE & $
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

   nb_prof=N_ELEMENTS(profondeur2)
   range_values=fltarr(2,nb_prof)
   print,tab_choix
   print,liste_region
   ind=0L
   ind2=0L

;; test
;; file1='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/PSY3V3R1/RTR1//File_ASCII/Fic_ASCII_TEMP_GLO_PSY3V3R1_0-50m.txt'
;; data_struct=READ_ASCII(file1) & field = data_struct.field1
;; time=field(0,*) 
;; HDCT=field(1,*) 
;; LEV=field(2,*)  
;; ARIVO=field(3,*)  
;; var1=transpose(HDCT)
;; plot,time,MEDIAN(var1,5),BACKGROUND=black

;; STOP

    FOR ind=0,N_ELEMENTS(tab_choix)-1 DO BEGIN  & $
       FOR ind2=0,N_ELEMENTS(liste_region)-1 DO BEGIN & $
       var=tab_choix(ind)                            & $
       zone=liste_region(ind2)                         & $
       print,'Variable zone :: ',var,zone            & $
 ;; Lecture du fichier ASCII
           prof=0L                                 & $ 
	   il_ind2=0L                         & $
           output='gif'  & $
	   prof=0L            & $ 
          WHILE prof le nb_prof-1 DO BEGIN               & $
	      print,'Profondeur :: ',prof,nb_prof            & $
	      il_ind2=0L                         & $
              ctot=intarr(9,3)                                 & $
              ctot(0,*)=c1                               & $
              if (prof ge 0) then ctot(0,*)=c1_bis     & $
              ctot(1,*)=c2                             & $
              ctot(2,*)=c3                             & $
              ctot(3,*)=c4 & $  
              ctot(4,*)=c5  & $
              ctot(5,*)=c6 & $
              ctot(6,*)=c7 & $
              ctot(7,*)=c8 & $
              ctot(8,*)=c9  & $
	      ;; Lecture du fichier 1
              file1=dirname_out_RTR1+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele+'_'+profondeur2(prof)+'.txt'   & $ 
              data_struct=READ_ASCII(file1) & field = data_struct.field1 & $
	      time=field(0,*)  & $
	      HDCT=field(1,*)  & $
              LEV=field(2,*)   & $
              ARIVO=field(3,*) & $ 
              
	      ;; Lecture du fichier 2
	      modele_type2=modele2 & $	
	      dirname_out2='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele2+'/' & $
              file2=dirname_out2+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele2+'_'+profondeur2(prof)+'.txt'   & $
              data_struct=READ_ASCII(file2) & field2 = data_struct.field1 & $
	      HDCT2=field2(1,*)  & $
	      ;; Lecture du fichier 3
              file3=dirname_out_RTR2+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele+'_'+profondeur2(prof)+'.txt'   & $
              data_struct=READ_ASCII(file3) & field3 = data_struct.field1 & $
              HDCT_RTR2=field3(1,*)  & $

              min1=MIN(field(1:3,*),/NaN )   & $
	      min2=MIN(field2(1,*),/NaN )	& $
	      min3=MIN(field3(1,*),/NaN )	& $
	      max1=MAX(field(1:3,*),/NaN )        & $
	      max2=MAX(field2(1,*),/NaN )        & $
	      max3=MAX(field3(1,*),/NaN )        & $

	       

	      tabmin=fltarr(3)	& $
	      tabmin(0)=min1 & $
	      tabmin(1)=min2	& $
	      tabmin(2)=min3	& $
	      tabmax=fltarr(3)	& $
	      tabmax(0)=max1	& $
	      tabmax(1)=max2	& $
	      tabmax(2)=max3	& $
	      
              ;; 1ere tracé	
              numx1=time & $
	      var1=transpose(HDCT)  & $ 
	      numx2=MEDIAN(var1,3) & $
	      ;numx2=HDCT & $
              titre='Comparaison Rms diff '+profondeur2(prof)+ ' class4 '+zone & $ 
	      print ,'TITRE :: ',titre   & $
              xtitle='rms diff'       & $
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
              ishold=1  & $
	      modele_type=modele & $
              cmin=MIN(tabmin)           & $
              cmax=MAX(tabmax) 	  & $
	      if (cmax ge 2) then cmax=3 & $
              legende=modele_type & $
	      plot_serietemp_test2,0,val4,PLOT_KIND=kind,NOTE2=legende,OVERPLOT=8 & $
              ;; 2eme tracé
              il_ind2=il_ind2+1 & $
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
	      numx1=time & $
	      ;;numx2=MEDIAN(tranpose(LEV),3) & $
	      numx2=LEV & $
              ishold=1  & $
              cmin=MIN(tabmin)           & $
              cmax=MAX(tabmax) 	  & $
	      if (cmax ge 2) then cmax=3 & $
              plot_serietemp_test2,0,val4,PLOT_KIND=kind,NOTE2="LEVITUS",OVERPLOT=8 & $
              ;; 3eme tracé
              il_ind2=il_ind2+1 & $
	      numx1=time & $ 
	      ;;numx2=MEDIAN(tranpose(ARIVO),3) & $
	      numx2=ARIVO & $
              ishold=1  & $
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
              cmin=MIN(tabmin)           & $
              cmax=MAX(tabmax) 	  & $
	      if (cmax ge 2) then cmax=3 & $
              plot_serietemp_test2,0,val4,PLOT_KIND=kind,NOTE2="ARIVO",OVERPLOT=8 & $
              ;; 4eme tracé
              il_ind2=il_ind2+1 & $
              numx1=time & $
	      ;;numx2=MEDIAN(tranpose(HDCT2),3) & $
	      numx2=HDCT2 & $
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
              ishold=1  & $
              cmin=MIN(tabmin)           & $
              cmax=MAX(tabmax) 	  & $
	      if (cmax ge 2) then cmax=3 & $
	      plot_serietemp_test2,0,val4,PLOT_KIND=kind,NOTE2=modele_type2,OVERPLOT=8 & $
              ;; 5eme tracé
              il_ind2=il_ind2+1 & $
	      numx1=time & $
	      ;; numx2=MEDIAN(tranpose(HDCT_RTR2),3)  & $
	      numx2=HDCT_RTR2 & $
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
              ishold=1  & $
              cmin=MIN(tabmin)           & $
              cmax=MAX(tabmax)    & $
              if (cmax ge 2) then cmax=3 & $
              plot_serietemp_test2,0,val4,PLOT_KIND=kind,NOTE2="PSY3V3R1-RTR2",OVERPLOT=8 & $
              ishold=0  & $
              do_output,output_dir+'/Comparaison_trim'+var+'_'+zone+'_'+modele+'_'+profondeur2(prof) & $
              prof=prof+1 & $
	   ENDWHILE & $
       ENDFOR & $ 
   ENDFOR  & $
exit, /NO_CONFIRM
