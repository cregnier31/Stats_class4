;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
PRO comparaison_rmsdiff_PSY3Q_PSY4,output_dir,modele2,lissage ,NB_VALEURS,NB_VALEURS2

@param
;@param_class4

@config_PSY3QV3R1

dirname_out=fic_out
dirin=dir_stats_MERC

; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'

Def_param_bulletin_new


COMMON param_CLASS4_new,variable_name,valeurs_cmax,$
	valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
	profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,$
	listemodele,liste_zone_GLOMyo,profondeur3,profondeur4,$
	liste_zone_PSY2_SHOM,tab_prof,tab_prof_model,tab_e3t

; Compilation & Execution 
;; choix du type de tracé 
kind='solid_line no_bg grid '
clear,titre,units
;;
liste_region=strarr(14) 
liste_region(*)=liste_zone(*) & $
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

nb_prof=N_ELEMENTS(profondeur4)
range_values=fltarr(2,nb_prof)
print,tab_choix
print,liste_region
ind=0L
ind2=0L


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
              file1=dirname_out+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele+'_'+profondeur4(prof)+'.txt'    
	      print,'file :',file1
              data_struct=READ_ASCII(file1) & field = data_struct.field1 
	      time=field(0,*)  
              var1=transpose(field(1,*))
              var2=transpose(field(2,*))
              var3=transpose(field(3,*))
              var4=transpose(field(4,*))
              var5=transpose(field(5,*))
              var6=transpose(field(6,*))
              var7=transpose(field(7,*))
	      if ( lissage eq 'yes' ) then begin 
                 HDCT=SMOOTH(MEDIAN(var1,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
		 NOW=SMOOTH(MEDIAN(var2,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
		 FCST1=SMOOTH(MEDIAN(var3,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
		 FCST3=SMOOTH(MEDIAN(var4,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
		 FCST5=SMOOTH(MEDIAN(var5,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                 ARIVO=SMOOTH(MEDIAN(var6,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
		 LEV=SMOOTH(MEDIAN(var7,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
		 HDCT=var1
		 NOW=var2
		 FCST1=var3
		 FCST3=var4
		 FCST5=var5
		 LEV=var6
		 ARIVO=var7
              endelse         
	      ;; Lecture du fichier 2
	      modele_type2=modele2 	
	      dirname_out2='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/'+modele2+'/' 
              file2=dirname_out2+'/suivi_rms/20110101_20110830/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele2+'_'+profondeur4(prof)+'.txt'   
              data_struct=READ_ASCII(file2) & field2 = data_struct.field1 
	      var7=transpose(field2(1,*))
	      var8=transpose(field2(2,*))
	      var9=transpose(field2(3,*))
	      var10=transpose(field2(4,*))
	      time2=field2(0,*)  
	     if ( lissage eq 'yes' ) then begin
               HDCT2=SMOOTH(MEDIAN(var7,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
	       NOW2=SMOOTH(MEDIAN(var8,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
	       FCST3_2=SMOOTH(MEDIAN(var9,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
	       FCST6_2=SMOOTH(MEDIAN(var10,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
             endif else begin
               HDCT2=var7
	       NOW2=var8
	       FCST3_2=var9
	       FCST6_2=var10
	     endelse
	    
              min1=MIN(HDCT,/NaN)
              min2=MIN(HDCT2,/NaN)
              min3=MIN(NOW,/NaN)
              min4=MIN(NOW2,/NaN)
	      min5=MIN(FCST3,/NaN)
	      min6=MIN(FCST3_2,/NaN)
	      min7=MIN(FCST1,/NaN)
	      min8=MIN(LEV,/NaN)
              min9=MIN(ARIVO,/NaN)

              max1=MAX(HDCT,/NaN)
              max2=MAX(HDCT2,/NaN)
              max3=MAX(NOW,/NaN)
              max4=MAX(NOW2,/NaN)
	      max5=MAX(FCST3,/NaN)
	      max6=MAX(FCST3_2,/NaN)
	      max7=MAX(FCST1,/NaN)
	      max8=MAX(LEV,/NaN)
              max9=MAX(ARIVO,/NaN)

 
	      tabmin=fltarr(9)	
	      tabmin(0)=min1 
	      tabmin(1)=min2  
	      tabmin(2)=min3 
              tabmin(3)=min4 
	      tabmin(4)=min5 
              tabmin(5)=min6 
              tabmin(6)=min7 
              tabmin(7)=min8 
              tabmin(8)=min9 

	      tabmax=fltarr(9)	
	      tabmax(0)=max1	
	      tabmax(1)=max2	
	      tabmax(2)=max3	
              tabmax(3)=max4
	      tabmax(4)=max5	
              tabmax(5)=max6
              tabmax(6)=max7
              tabmax(7)=max8
              tabmax(8)=max9
	      indice=where(time2 eq time(0))
	      IF (indice (0) NE -1) THEN BEGIN
	         indice_min=indice(0)
	         indice_max=N_ELEMENTS(time2)-1
	         indice_max2=N_ELEMENTS(time)-1
	         print,'indice :: ',indice,indice_max
	         print,'taille vecteur 1 :: ',N_ELEMENTS(time)
	         print,'taille vecteur 2 :: ',N_ELEMENTS(indice)
	      ENDIF ELSE BEGIN
		indice_min=120
		indice_max=240
	      ENDELSE   
              ;; 1ere tracé	
              numx1=time 
	      numx2=HDCT
              titre='Rms diff (mod-obs) '+var+' '+profondeur4(prof)+ ' class4 '+zone  
	      print ,'TITRE :: ',titre   
              xtitle='rms diff'       
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              ishold=1  
	      modele_type=modele 
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
              legende=modele_type+'_HDCT'
	      ;plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=legende
	      plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
              ;; 2eme tracé
              il_ind2=il_ind2+1 
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	      numx1=time2(indice_min:indice_max)
              numx2=HDCT2(indice_min:indice_max)
	      ;numx1=time2
              ;numx2=NOW2
              ishold=1  
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
	      legende=modele2+"_HDCT"
              plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
              ;plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
              ;; 3eme tracé
              il_ind2=il_ind2+1 
	      numx1=time
              numx2=FCST3
              ishold=1   
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
	      legende=modele+"_FCST3D"
              plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende ;;,OVERPLOT=8 
              ;plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
              ;; 4eme tracé
              il_ind2=il_ind2+1 
              numx1=time2(indice_min:indice_max) 
	      numx2=FCST3_2(indice_min:indice_max)
              ;numx1=time2 
	      ;numx2=FCST3_2
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              ishold=1  
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
	      legende=modele2+"_FCST3D"
	      plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende;,OVERPLOT=8 
              ;plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
               ;; 5eme tracé
              il_ind2=il_ind2+1
              numx1=time 
              numx2=FCST1 
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
	      legende=modele+"_FCST1D"
              plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende;,OVERPLOT=8 
              ;plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
               ;; 6eme tracé
              il_ind2=il_ind2+1
              numx1=time 
              numx2=LEV 
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
	      legende="LEV09"
              plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende 
              ;plot_serietemp_oper,1.0,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
 	      ;;;7eme tracé
              ;il_ind2=il_ind2+1
              ;numx1=time
              ;numx2=ARIVO
              ;val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              ;ishold=1
              ;cmin=MIN(tabmin)
              ;cmax=MAX(tabmax)
	      ;legende="ARIVO"
              ;plot_serietemp_test2,1.0,val4,PLOT_KIND=kind,NOTE2=legende 
              ishold=0  
              do_output,output_dir+'/Comparaison_annual_allmodels_'+var+'_'+zone+'_'+modele+'_'+profondeur4(prof) 
              prof=prof+1
	   ENDWHILE
       ENDFOR  
   ENDFOR  
END
