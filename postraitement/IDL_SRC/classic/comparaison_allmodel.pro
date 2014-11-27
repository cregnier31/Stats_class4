;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
; C.REGNIER  Janvier   2012 Modifs pour nouveaux rtr
;-----------------------------------------------------------------------
; extension du path
PRO comparaison_allmodel,output_dir,modele2,modele3,modele4,lissage,NB_VALEURS,NB_VALEURS2,type

@param
@param_class4
@config_PSY3V3R1_RTR


dirname_out_RTR=fic_out
dirin=dir_stats_MERC
dirname_out=dirname_out_RTR

dirname_out_RTR2=fic_dir+modele2+'/2007-2011/'
dirname_out_RTR3=fic_dir+modele3+'/2007-2011/'
dirname_out_RTR4=fic_dir+modele4+'/2007-2011/'

; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'

tab_choix2=strarr(2)
tab_choix2(0)='salinity'
tab_choix2(1)='temperature'



Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
    valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
    profondeur,profondeur2,profondeur3,profondeur4,liste_zone,$
    liste_zone_PSY2,liste_TEST,listemodele,$
    liste_zone_GLOMyo,liste_zone_PSY2_SHOM,liste_zone_2


; Compilation & Execution 
;; choix du type de tracé 
kind='solid_line no_bg grid mean'
clear,titre,units
;;
liste_region=strarr(5) 
liste_region=liste_zone_PSY2 

liste_region=strarr(3) 
liste_region=liste_zone_2 
;liste_region=strarr(3) 
;liste_region(0)='NAT'
;liste_region(1)='TAT'
;liste_region(2)='MED'
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
   c9=yellow
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
           ;output='logo ps A3'   
           output='ps A3'   
          ; output='screen'   
           ; output='logo jpeg'   
	   ;output='ps logo hold'
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
              ctot(5,*)=c9 
              ctot(6,*)=c7 
              ctot(7,*)=c8 
              ctot(8,*)=c9 
	      print,'ctot(5,*) : ',ctot(5,*)
	      ;; Lecture du fichier 1
  	      if ( type eq 'mean' ) then begin
                file1=dirname_out_RTR+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele+'_'+profondeur4(prof)+'.txt'    
	      endif else begin
                file1=dirname_out_RTR+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele+'_'+profondeur4(prof)+'.txt'    
              endelse
              data_struct=READ_ASCII(file1) & field = data_struct.field1 
	      time=field(0,*) 
              var1=transpose(field(1,*))
              var2=transpose(field(2,*))
              var3=transpose(field(3,*))
	      if ( lissage eq 'yes' ) then begin 
                 HDCT=SMOOTH(MEDIAN(var1,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
                 LEV=SMOOTH(MEDIAN(var2,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
                 ARIVO=SMOOTH(MEDIAN(var3,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
              endif else begin
		 HDCT=var1
		 LEV=var2
		 ARIVO=var3
              endelse         
	      ;; Lecture du fichier 2
	      modele_type2=modele2 	
  	      if ( type eq 'mean' ) then begin
                file2=dirname_out_RTR2+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele2+'_'+profondeur4(prof)+'.txt'   
	      endif else begin
                file2=dirname_out_RTR2+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele2+'_'+profondeur4(prof)+'.txt'   
	      endelse
              data_struct=READ_ASCII(file2) & field2 = data_struct.field1 
	      var4=transpose(field2(1,*))
	     if ( lissage eq 'yes' ) then begin
               HDCT2=SMOOTH(MEDIAN(var4,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
             endif else begin
               HDCT2=var4
	     endelse
	       ;; Lecture du fichier 3
              modele_type3=modele3
  	      if ( type eq 'mean' ) then begin
                file3=dirname_out_RTR3+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele3+'_'+profondeur4(prof)+'.txt'
	      endif else begin
                file3=dirname_out_RTR3+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele3+'_'+profondeur4(prof)+'.txt'
	      endelse
              data_struct=READ_ASCII(file3) & field3 = data_struct.field1
              var5=transpose(field3(1,*))
             if ( lissage eq 'yes' ) then begin
               HDCT3=SMOOTH(MEDIAN(var5,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
             endif else begin
               HDCT3=var5
             endelse
	      ;; Lecture du fichier 4
              modele_type4=modele4
  	      if ( type eq 'mean' ) then begin
                 file4=dirname_out_RTR4+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele4+'_'+profondeur4(prof)+'.txt'
	      endif else begin
                 file4=dirname_out_RTR4+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele4+'_'+profondeur4(prof)+'.txt'
	      endelse
              data_struct=READ_ASCII(file4) & field4 = data_struct.field1
              var6=transpose(field4(1,*))
             if ( lissage eq 'yes' ) then begin
               HDCT4=SMOOTH(MEDIAN(var6,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
             endif else begin
               HDCT4=var6
             endelse
	    
              min1=MIN(HDCT,/NaN)
              min2=MIN(LEV,/NaN)
              min3=MIN(ARIVO,/NaN)
              min4=MIN(HDCT2,/NaN)
              min5=MIN(HDCT3,/NaN)
              min6=MIN(HDCT4,/NaN)

              max1=MAX(HDCT,/NaN)
              max2=MAX(LEV,/NaN)
              max3=MAX(ARIVO,/NaN)
              max4=MAX(HDCT2,/NaN)
              max5=MAX(HDCT3,/NaN)
              max6=MAX(HDCT4,/NaN)


	      tabmin=fltarr(6)	
	      tabmin(0)=min1 
	      tabmin(1)=min2  
	      tabmin(2)=min3 
              tabmin(3)=min4 
	      tabmin(4)=min5 
              tabmin(5)=min6 
		

	      tabmax=fltarr(6)	
	      tabmax(0)=max1	
	      tabmax(1)=max2	
	      tabmax(2)=max3	
              tabmax(3)=max4
	      tabmax(4)=max5	
              tabmax(5)=max6

  	      if ( type eq 'mean' ) then begin
                 name_out=output_dir+'/Comparaison_allmodels_meandiff_'+var+'_'+zone+'_allmodels_'+profondeur4(prof) 
	      endif else begin
                 name_out=output_dir+'/Comparaison_allmodels_rmsdiff_'+var+'_'+zone+'_allmodels_'+profondeur4(prof) 
	      endelse
              ;; 1ere tracé	
              numx1=time 
	      numx2=HDCT
	      zone1=zone
	      CASE zone OF
 	         'NAT': BEGIN
		   zone1='North Atlantic'
                 ENDCASE
		 'MED': BEGIN
		   zone1='Mediterranean'
		 ENDCASE
		 'IND' : BEGIN
		   zone1='Indian'
		 ENDCASE  
		 'TAT' : BEGIN
		   zone1='Tropical Atlantic'
		 ENDCASE
	         ELSE:
	      ENDCASE 
  	      if ( type eq 'mean' ) then begin
	        ;titre='Mean diff (mod-obs) '+var+' '+profondeur4(prof)+ ' class4 '+zone  
                xtitle='Mean diff'       
	        titre='(analysis-obs) mean '+tab_choix2(ind)+'   '+zone1  
	      endif else begin
	        ;titre='Rms diff (mod-obs) '+var+' '+profondeur4(prof)+ ' class4 '+zone  
                xtitle='Rms diff'       
	        titre='(analysis-obs) RMS '+tab_choix2(ind)+'   '+zone1  
	      endelse
	      print ,'TITRE :: ',titre   
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	      print,'ctot :: ',ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)
	      print,'Couleur : ',val4
              ishold=1  
	      modele_type=modele 
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
	      CASE modele_type OF
                  'PSY3V3R1': BEGIN
                   legende='IRG_V1V2'
                  ENDCASE
                  'PSY3V3R2': BEGIN
                   legende='IRG_DEV'
                  ENDCASE
                  'PSY2V4R2': BEGIN
                   legende='HRZ_V1/V1V2'
                  ENDCASE
                  'PSY2V4R3': BEGIN
                   legende='HRZ_DEV'
                  ENDCASE
              ENDCASE
	      plot_serietemp_test4,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out;;,OVERPLOT=8 
              ;; 2eme tracé
              il_ind2=il_ind2+1 
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	      print,'ctot :: ',ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)
	      print,'Couleur : ',val4
	      numx1=time 
              numx2=LEV
              ishold=1  
	      legende='WOA05'
	      ;legende=''
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
              plot_serietemp_test4,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out ;;,OVERPLOT=8 
        ;      ;; 3eme tracé
               il_ind2=il_ind2+1 
	;      numx1=time  
        ;      numx2=ARIVO
        ;      ishold=1   
	;      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	;      print,'ctot :: ',ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)
	;      print,'Couleur : ',val4
        ;      cmin=MIN(tabmin)           
        ;      cmax=MAX(tabmax) 	  
	;      ;if (cmax ge 2) then cmax=2.5 
        ;      plot_serietemp_test2,2,val4,PLOT_KIND=kind,NOTE2="ARIVO",OUTPUT_FILE=name_out ;;,OVERPLOT=8 
              ;; 4eme tracé
              il_ind2=il_ind2+1 
              numx1=time 
	      numx2=HDCT2 
	      CASE modele_type2 OF
                  'PSY3V3R1': BEGIN
                   legende='IRG_V1V2'
                  ENDCASE
                  'PSY3V3R2': BEGIN
                   legende='IRG_DEV'
                  ENDCASE
                  'PSY2V4R2': BEGIN
                   legende='HRZ_V1/V1V2'
                  ENDCASE
                  'PSY2V4R3': BEGIN
                   legende='HRZ_DEV'
                  ENDCASE
              ENDCASE
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	      print,'ctot :: ',ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)
	      print,'Couleur : ',val4
              ishold=1  
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
	      plot_serietemp_test4,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out ;,OVERPLOT=8 
	      ;; 5eme tracé
              ;il_ind2=il_ind2+1
              numx1=time
              numx2=HDCT4
	      CASE modele_type4 OF
                  'PSY3V3R1': BEGIN
                   legende='IRG_V1V2'
                  ENDCASE
                  'PSY3V3R2': BEGIN
                   legende='IRG_DEV'
                  ENDCASE
                  'PSY2V4R2': BEGIN
                   legende='HRZ_V1/V1V2'
                  ENDCASE
                  'PSY2V4R3': BEGIN
                   legende='HRZ_DEV'
                  ENDCASE
              ENDCASE
	      print,modele_type3 
              ;val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
	     ; val4 = FSC_Color("Hot Pink", !D.Table_Size-4)
	      val4 = FSC_Color("Deep Pink", !D.Table_Size-4)
	      val4 = FSC_Color("Green Yellow", !D.Table_Size-4)
	      print,'Couleur : ',val4
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              plot_serietemp_test4,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out ;,OVERPLOT=8 
               ;; 6eme tracé
              il_ind2=il_ind2+1
              julian = JULDAY(12,30,2009,12,0,0)              
	      ii=WHERE(time LT julian ) 
	      time2=fltarr(N_ELEMENTS(ii)-1)
              time2=time[ii(0):ii(N_ELEMENTS(ii)-1)]
              numx1=time2
              numx2=HDCT3[ii(0):ii(N_ELEMENTS(ii)-1)]
	      CASE modele_type3 OF
                  'PSY3V3R1': BEGIN
                   legende='IRG_V1V2'
                  ENDCASE
                  'PSY3V3R2': BEGIN
                   legende='IRG_DEV'
                  ENDCASE
                  'PSY2V4R2': BEGIN
                   legende='HRZ_V1/V1V2'
                  ENDCASE
                  'PSY2V4R3': BEGIN
                   legende='HRZ_DEV'
                  ENDCASE
              ENDCASE
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
	      print,'ctot :: ',ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)
	      print,'Couleur : ',val4
              ishold=1
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              plot_serietemp_test4,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out;,OVERPLOT=8 
              ;; Tracé bis   
              julian = JULDAY(12,30,2009,12,0,0)              
	      ii=WHERE(time GE julian ) 
	      time2=fltarr(N_ELEMENTS(ii)-1)
              time2=time[ii(0):N_ELEMENTS(time)-1]
	      numx1=time2	
	      numx2=HDCT3[ii(0):N_ELEMENTS(time)-1]
	      legende=''
	      ishold=1
              val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2))
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              ; plot_serietemp_test2,2,val4,PLOT_KIND='dotted_line no_bg grid mean',NOTE2=legende,OUTPUT_FILE=name_out;,OVERPLOT=8
              plot_serietemp_test4,2,val4,PLOT_KIND='dashed_line no_bg grid mean',NOTE2=legende,OUTPUT_FILE=name_out;,OVERPLOT=8
              ishold=0 
              dirname_out=output_dir	
  	      if ( type eq 'mean' ) then begin
                 do_output,output_dir+'/Comparaison_allmodels_meandiff_'+var+'_'+zone+'_allmodels_'+profondeur4(prof) 
	      endif else begin
                 do_output,output_dir+'/Comparaison_allmodels_rmsdiff_'+var+'_'+zone+'_allmodels_'+profondeur4(prof) 
             endelse
              prof=prof+1
	   ENDWHILE
       ENDFOR  
   ENDFOR  
END
