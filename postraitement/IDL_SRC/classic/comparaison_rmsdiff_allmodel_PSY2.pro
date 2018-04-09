;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
PRO comparaison_rmsdiff_allmodel_PSY2,output_dir,modele2,modele3,modele4,lissage

@param
@param_class4

@config_PSY2V4R1_RTR

dirname_out_RTR=fic_out
dirname_out_RTR2=fic_out2
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

Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
   valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
   profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,listemodele,liste_zone_GLOMyo

; Compilation & Execution 
;; choix du type de tracé 
kind='solid_line no_bg grid '
clear,titre,units
;;
liste_region=strarr(3) 
liste_region=liste_zone_PSY2 
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
   NB_VALEURS=3
   NB_VALEURS2=3


    FOR ind=0,N_ELEMENTS(tab_choix)-1 DO BEGIN  
       FOR ind2=0,N_ELEMENTS(liste_region)-1 DO BEGIN 
       var=tab_choix(ind)                            
       zone=liste_region(ind2)                        
       print,'Variable zone :: ',var,zone            
 ;; Lecture du fichier ASCII
           prof=0L                                  
	   il_ind2=0L                         
           output='gif'   
	   prof=0L             
          WHILE prof le nb_prof-1 DO BEGIN               
	      print,'Profondeur :: ',prof,nb_prof            
	      il_ind2=0L                          
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
	      ;; Lecture du fichier 1
              file1=dirname_out_RTR+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele+'_'+profondeur2(prof)+'.txt'    
              data_struct=READ_ASCII(file1) & field = data_struct.field1 
	      time=field(0,*)  
              var1=transpose(field(1,*))
              ;var2=transpose(field(2,*))
              ;var3=transpose(field(3,*))
	      if ( lissage eq 'yes' ) then begin 
                 HDCT=SMOOTH(MEDIAN(var1,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
               ;  LEV=SMOOTH(MEDIAN(var2,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
               ;  ARIVO=SMOOTH(MEDIAN(var3,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
              endif else begin
		 HDCT=var1
	;	 LEV=var2
	;	 ARIVO=var3
              endelse         
	      ;; Lecture du fichier 2
	      modele_type2='PSY2V4R1_RTR2' 	
              file2=dirname_out_RTR2+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele2+'_'+profondeur2(prof)+'.txt'
              data_struct=READ_ASCII(file2) & field2 = data_struct.field1 
	      var4=transpose(field2(1,*))
	      if ( lissage eq 'yes' ) then begin
                HDCT2=SMOOTH(MEDIAN(var4,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
              endif else begin
                HDCT2=var4
	      endelse
	      ;; Lecture du fichier 3
              modele_type3=modele3
	      dirname_out3='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele3+'/' 
              file3=dirname_out3+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele3+'_'+profondeur2(prof)+'.txt'   
              data_struct=READ_ASCII(file3) & field3 = data_struct.field1
              var5=transpose(field3(1,*))
              if ( lissage eq 'yes' ) then begin
                HDCT3=SMOOTH(MEDIAN(var5,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
                HDCT3=var5
              endelse
	      ;; Lecture du fichier 4
              modele_type4=modele4
              dirname_out4='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele4+'/'
              file4=dirname_out4+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele4+'_'+profondeur2(prof)+'.txt'
              data_struct=READ_ASCII(file4) & field4 = data_struct.field1
              var6=transpose(field4(1,*))
              if ( lissage eq 'yes' ) then begin
                HDCT4=SMOOTH(MEDIAN(var6,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
                HDCT4=var6
              endelse
	      ;; Lecture du fichier 5
              modele_type5='PSY3V3R1_RTR2'
              dirname_out5='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/PSY3V3R1/'
              file5=dirname_out5+'/rejeu_RTR/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_PSY3V3R1_'+profondeur2(prof)+'.txt'
              data_struct=READ_ASCII(file5) & field5 = data_struct.field1
              time2=field5(0,*)
	      var7=transpose(field5(1,*))
 	      var2=transpose(field5(2,*))
              var3=transpose(field5(3,*))
              if ( lissage eq 'yes' ) then begin
                HDCT5=SMOOTH(MEDIAN(var7,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                LEV=SMOOTH(MEDIAN(var2,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
                ARIVO=SMOOTH(MEDIAN(var3,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
                HDCT5=var7
                LEV=var2
                ARIVO=var3
              endelse
	      ;; Lecture du fichier 6
	      modele_type6='PSY3V3R1'
              dirname_out6='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/PSY3V3R1/'
              file6=dirname_out6+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_PSY3V3R1_'+profondeur2(prof)+'.txt'
              data_struct=READ_ASCII(file6) & field6 = data_struct.field1
              ;time2=field6(0,*)
              var8=transpose(field6(1,*))
              if ( lissage eq 'yes' ) then begin
                HDCT6=SMOOTH(MEDIAN(var8,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
                HDCT6=var8
              endelse
	   
              min1=MIN(HDCT,/NaN)
              min2=MIN(LEV,/NaN)
              min3=MIN(ARIVO,/NaN)
              min4=MIN(HDCT2,/NaN)
              min5=MIN(HDCT3,/NaN)
              min6=MIN(HDCT4,/NaN)
              min7=MIN(HDCT5,/NaN)

              max1=MAX(HDCT,/NaN)
              max2=MAX(LEV,/NaN)
              max3=MAX(ARIVO,/NaN)
              max4=MAX(HDCT2,/NaN)
              max5=MAX(HDCT3,/NaN)
              max6=MAX(HDCT4,/NaN)
              max7=MAX(HDCT5,/NaN)


	      tabmin=fltarr(7)	
	      tabmin(0)=min1 
	      tabmin(1)=min2  
	      tabmin(2)=min3 
              tabmin(3)=min4 
	      tabmin(4)=min5 
              tabmin(5)=min6 
              tabmin(6)=min7 
		

	      tabmax=fltarr(7)	
	      tabmax(0)=max1	
	      tabmax(1)=max2	
	      tabmax(2)=max3	
              tabmax(3)=max4
	      tabmax(4)=max5	
              tabmax(5)=max6
              tabmax(6)=max7

              ;; 1ere tracé	
              numx1=time[160:N_ELEMENTS(time)-1]
	      numx2=HDCT[160:N_ELEMENTS(time)-1]
              titre='Rms diff (mod-obs) '+var+' '+profondeur2(prof)+ ' class4 '+zone  
	      print ,'TITRE :: ',titre   
              xtitle='rms diff'       
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              ishold=1  
	      modele_type=modele 
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
              legende=modele_type 
	      plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
              ;; 2eme tracé
              il_ind2=il_ind2+1 
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	      numx1=time2[160:N_ELEMENTS(time2)-1]
              numx2=LEV[160:N_ELEMENTS(time2)-1] 
              ishold=1  
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
              plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2="WOA05";;,OVERPLOT=8 
              ;; 3eme tracé
              il_ind2=il_ind2+1 
	      numx1=time2[160:N_ELEMENTS(time2)-1]
              numx2=ARIVO[160:N_ELEMENTS(time2)-1]
              ishold=1   
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
              plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2="ARIVO";;,OVERPLOT=8 
              ;; 4eme tracé
              il_ind2=il_ind2+1 
              numx1=time2[160:N_ELEMENTS(time2)-1]
	      numx2=HDCT2[160:N_ELEMENTS(time2)-1]
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              ishold=1  
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2=modele_type2;,OVERPLOT=8 
              ;; 5eme tracé
              il_ind2=il_ind2+1
              numx1=time[160:N_ELEMENTS(HDCT3)-1]
              numx2=HDCT3[160:N_ELEMENTS(HDCT3)-1]
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2=modele_type3;,OVERPLOT=8 
               ;; 6eme tracé
              il_ind2=il_ind2+1
              numx1=time[160:N_ELEMENTS(time)-1]
              numx2=HDCT4[160:N_ELEMENTS(time)-1]
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2=modele_type4;,OVERPLOT=8 
 	      ;;7eme tracé
              il_ind2=il_ind2+1
              numx1=time[160:N_ELEMENTS(time)-1]
              numx2=HDCT6[160:N_ELEMENTS(time)-1]
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2='PSY3V3R1';,OVERPLOT=8
              ;; 8eme tracé
              il_ind2=il_ind2+1
              numx1=time2[160:N_ELEMENTS(time2)-1]
              numx2=HDCT5[160:N_ELEMENTS(time2)-1]
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2='PSY3V3R1_new';,OVERPLOT=8
              ishold=0  
              do_output,output_dir+'/Comparaison_trim_allmodels_'+var+'_'+zone+'_'+modele+'_'+profondeur2(prof) 
              prof=prof+1
	   ENDWHILE
       ENDFOR  
   ENDFOR  
END
