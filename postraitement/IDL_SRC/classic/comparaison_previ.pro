;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
PRO comparaison_previ,output_dir1,output_dir2,output_dir3,modele1,modele2

@param
@param_class4


; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
time=[ 0 , 3 , 6 ]
;; Definition des variables
var1=modele1
var2=modele2
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
;liste_region=strarr(11) 
;liste_region=liste_zone
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
   NB_VALEURS=6
   NB_VALEURS2=6


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
              file1=output_dir1+'/Fic_ASCII_PREVI'+var+'_'+zone+'_'+var1+'_'+profondeur2(prof)+'.txt'    
              data_struct=READ_ASCII(file1) & field = data_struct.field1 
              HDCT=transpose(field(1,*))
              FRCST3D=transpose(field(2,*))
              FRCST6D=transpose(field(3,*))
	      FIELD1=[HDCT,FRCST3D,FRCST6D]
	      ;; Lecture du fichier 2
              file2=output_dir2+'/Fic_ASCII_PREVI'+var+'_'+zone+'_'+var2+'_'+profondeur2(prof)+'.txt'   
              data_struct=READ_ASCII(file2) & field2 = data_struct.field1 
	      HDCT_PSY2=transpose(field2(1,*))
              FRCST3D_PSY2=transpose(field2(2,*))
              FRCST6D_PSY2=transpose(field2(3,*))
	      FIELD2=[HDCT_PSY2,FRCST3D_PSY2,FRCST6D_PSY2]
              	    
              min1=MIN(HDCT,/NaN)
              min2=MIN(FRCST3D,/NaN)
              min3=MIN(FRCST6D,/NaN)
              min4=MIN(HDCT_PSY2,/NaN)
              min5=MIN(FRCST3D_PSY2,/NaN)
              min6=MIN(FRCST6D_PSY2,/NaN)

              max1=MAX(HDCT,/NaN)
              max2=MAX(FRCST3D,/NaN)
              max3=MAX(FRCST6D,/NaN)
              max4=MAX(HDCT_PSY2,/NaN)
              max5=MAX(FRCST3D_PSY2,/NaN)
              max6=MAX(FRCST3D_PSY2,/NaN)


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

              ;; 1ere tracé	
              numx1=time 
	      numx2=FIELD1
              titre='Rms diff (mod-obs) '+var+' '+profondeur2(prof)+ ' class4 '+zone  
	      print ,'TITRE :: ',titre   
              xtitle='rms diff'       
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
              ishold=1  
	      modele_type=var1 
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
	      ;if (cmax ge 2) then cmax=2.5 
              legende=modele_type 
	      plot_serietemp_test3,2,val4,PLOT_KIND=kind,NOTE2=legende;;,OVERPLOT=8 
              ;; 2eme tracé
              il_ind2=il_ind2+1 
	      val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) 
	      numx1=time 
              numx2=FIELD2
              ishold=1  
              cmin=MIN(tabmin)           
              cmax=MAX(tabmax) 	  
              plot_serietemp_test3,2,val4,PLOT_KIND=kind,NOTE2=modele2;;,OVERPLOT=8 
              ishold=0  
              do_output,output_dir3+'/Comparaison_previ_'+var+'_'+zone+'_PSY2vsPSY3_'+profondeur2(prof) 
              prof=prof+1
	   ENDWHILE
       ENDFOR  
   ENDFOR  
END
