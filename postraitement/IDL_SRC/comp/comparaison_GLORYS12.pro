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
PRO comparaison_GLORYS12,output_dir,modele1,modele2,modele3,lissage,NB_VALEURS,NB_VALEURS2,type

@param
@param_class4
@config_GLORYS12V1

dirname_out_RTR=fic_out
dirin=dir_stats_MERC
dirname_out=output_dir	

@config_GLORYS12V1-free
dirname_out_RTR2=fic_out

@config_GLO4
dirname_out_RTR3=fic_out

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
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,$
        listemodele,liste_zone_GLOMyo,profondeur3,profondeur4,$
        liste_zone_PSY2_SHOM,tab_prof,tab_prof_model,tab_e3t,tab_prof_2,variable_name_2,$
        variable_name_3,variable_name_4,tab_prof_3,profondeur5,file_mask,file_save,tab_prof_4,tab_prof_5

tab_prof=profondeur2 ; 0-50 50-100 100-150 ...
;tab_prof=profondeur5 ; 0-100 100-300 300-800
tab_prof=profondeur4 ; 0-5 -5-100 100-300 300-800
;tab_prof=profondeur
print,tab_prof
; Compilation & Execution 
;; choix du type de tracé 
kind='solid_line no_bg grid mean'
clear,titre,units
;;;liste_region=strarr(13) 
liste_region=strarr(14) 
liste_region(*)=liste_zone(*)
liste_region=strarr(1) 
liste_region(0)='GLO'
;;liste_region=strarr(9) 
;;liste_region(0)='GLO'
;;liste_region(1)='ARC'
;;liste_region(2)='IND'
;;liste_region(3)='MED'
;;liste_region(4)='NAT'
;;liste_region(5)='NPA'
;;liste_region(6)='TAT'
;;liste_region(7)='TPA'
;;liste_region(8)='ACC'

   ;; Definition des couleurs du tracé
   Def_colors
   common COLOR_BLOCK,black,grey,white,bleuey,cyan,green,gold,yellow,red,blue,salmon,aquam,brown,burly,dark_orange,gmt_land
   c1_bis=black  ;; noir
   c1=white      ;; noir
   c2=blue       ;; bleu
   c3=red
   c4=green
   c5=cyan
   c6=salmon
   c7=brown
   c8=grey
   c9=yellow
   c10=dark_orange
   nb_prof=N_ELEMENTS(tab_prof)
   range_values=fltarr(2,nb_prof)
   print,tab_choix
   print,liste_region
   ind=0L
   ind2=0L

    FOR ind=0,N_ELEMENTS(tab_choix)-1 DO BEGIN  
       FOR ind2=0,N_ELEMENTS(liste_region)-1 DO BEGIN 
       var=tab_choix(ind)                            
       zone=liste_region(ind2)
       output_dir_tmp=output_dir+'/'+zone+'/'
       FILE_MKDIR,output_dir_tmp
       print,'Variable zone :: ',var,zone
 ;; Lecture du fichier ASCII
           prof=0L
	   il_ind2=0L
           output='logo ps A3'
           output='logo gif'
           output='ps A3'
          ; output='screen'
          ;  output='logo jpeg'
	   ;output='ps logo hold'
	   prof=0L
          WHILE prof le nb_prof-1 DO BEGIN
	      print,'Profondeur :: ',prof,nb_prof
	      il_ind2=0L
              ctot=intarr(9,3)
              ctot(0,*)=c3
              if (prof ge 0) then ctot(0,*)=c3
              ctot(1,*)=c10
              ctot(2,*)=c4
              ctot(3,*)=c2
              ctot(4,*)=c1_bis
              ctot(5,*)=c2
              ctot(6,*)=c9
              ctot(7,*)=c8
              ctot(8,*)=c6
	      ;; Lecture du fichier 1
  	      if ( type eq 'mean' ) then begin
                file1=dirname_out_RTR+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele1+'_'+tab_prof(prof)+'.txt'    
	      endif else begin
                file1=dirname_out_RTR+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele1+'_'+tab_prof(prof)+'.txt'    
              endelse
	      print,file1
              data_struct=READ_ASCII(file1) & field = data_struct.field1 
	      time=field(0,*)
              var1=transpose(field(1,*))
              var2=transpose(field(2,*))
              var3=transpose(field(3,*))
	      if ( lissage eq 'yes' ) then begin 
		HDCT=SMOOTH(MEDIAN(var1,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
                LEV13=SMOOTH(MEDIAN(var2,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
		nb_cumul=SMOOTH(MEDIAN(var3,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
		 HDCT=var1
		 LEV13=var2
		 nb_cumul=var3
              endelse
	      ;;
	      ;; Lecture du fichier 2
              modele_type2=modele2
              if ( type eq 'mean' ) then begin
                file2=dirname_out_RTR2+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele2+'_'+tab_prof(prof)+'.txt'
              endif else begin
                file2=dirname_out_RTR2+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele2+'_'+tab_prof(prof)+'.txt'
              endelse
              data_struct=READ_ASCII(file2) & field2 = data_struct.field1
              time2=field2(0,*)
              var5=transpose(field2(1,*))
              var6=transpose(field2(2,*))
              if ( lissage eq 'yes' ) then begin
               HDCT2=SMOOTH(MEDIAN(var5,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
	       ;nb_cumul=SMOOTH(MEDIAN(var6,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
               HDCT2=var5
	       ;nb_cumul=var6
              endelse
	      ;;  Lecture du fichier 3
	      modele_type2=modele3
              if ( type eq 'mean' ) then begin
               file3=dirname_out_RTR3+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+zone+'_'+modele3+'_'+tab_prof(prof)+'.txt'
              endif else begin
              file3=dirname_out_RTR3+'/File_ASCII/Fic_ASCII_'+var+'_'+zone+'_'+modele3+'_'+tab_prof(prof)+'.txt'
              endelse
              data_struct=READ_ASCII(file3) & field3 = data_struct.field1
              time3=field3(0,*)
              var6=transpose(field3(1,*))
              if ( lissage eq 'yes' ) then begin
               HDCT3=SMOOTH(MEDIAN(var6,NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
              endif else begin
               HDCT3=var6
              endelse

              min1=MIN(HDCT,/NaN)
              min2=MIN(LEV13,/NaN)
              min3=MIN(HDCT2,/NaN)
              min4=MIN(HDCT3,/NaN)


              max1=MAX(HDCT,/NaN)
              max2=MAX(LEV13,/NaN)
              max3=MAX(HDCT2,/NaN)
              max4=MAX(HDCT3,/NaN)

	      tabmin=fltarr(4)
	      tabmin(0)=min1
	      tabmin(1)=min2
	      tabmin(2)=min3
	      tabmin(3)=min4


	      tabmax=fltarr(4)
	      tabmax(0)=max1
	      tabmax(1)=max2
	      tabmax(2)=max3
	      tabmax(3)=max4

	      if ( type eq 'mean' ) then begin
                 name_out=output_dir_tmp+'Comparaison_GLORYS12_meandiff_'+var+'_'+zone+'_allmodels_'+tab_prof(prof) 
	      endif else begin
                 name_out=output_dir_tmp+'/Comparaison_GLORYS12_rmsdiff_'+var+'_'+zone+'_allmodels_'+tab_prof(prof) 
	      endelse
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
	        ;titre='Mean diff (mod-obs) '+var+' '+tab_prof(prof)+ ' class4 '+zone+ ' '+tab_prof(prof) 
                xtitle='Mean diff'       
	        titre='(analysis-obs) mean '+tab_choix2(ind)+'   '+zone1+'  '+tab_prof(prof)  
	      endif else begin
	        ;titre='Rms diff (mod-obs) '+var+' '+tab_prof(prof)+ ' class4 '+zone  
                xtitle='Rms diff'       
	        titre='(analysis-obs) RMS '+tab_choix2(ind)+'   '+zone1+'  '+tab_prof(prof)  
	      endelse
	      print ,'TITRE :: ',titre   
            ;  plot_serietemp_test5,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out;;,OVERPLOT=8
              ;;  Plot GLORYS12
              il_ind2=il_ind2+1
              numx1=time
              numx2=HDCT
              legende='G12'
              val4=rgb2ind(ctot(0,0),ctot(0,1),ctot(0,2))
            ;  val4=FSC_COLOR('black')
              ;val4=FSC_COLOR('blue')
              ;cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              dirname_out=output_dir_tmp
              ishold=1
              xinterv=2
              plot_serietemp_oper3,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_cumul,XINTERV=xinterv
	      ;;tracé GLORYS12V1-free
              il_ind2=il_ind2+1 
              numx1=time2
              numx2=HDCT2
              legende='F12'
              ishold=1
              val4=rgb2ind(ctot(1,0),ctot(1,1),ctot(1,2))
              ;val4=FSC_COLOR('red')
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              ;plot_serietemp_test5,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out
              plot_serietemp_oper3,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_cumul,XINTERV=xinterv
              ;; Plot GLO4
              il_ind2=il_ind2+1
              numx1=time3
              numx2=HDCT3
              legende='G4'
              ishold=1
              val4=rgb2ind(ctot(3,0),ctot(3,1),ctot(3,2))
              ;val4=FSC_COLOR('green')
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              ;plot_serietemp_test5,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out
              plot_serietemp_oper3,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_cumul,XINTERV=xinterv
              ;; Tracé CLIM WOA13
              il_ind2=il_ind2+1 
              numx1=time
              numx2=LEV13
              ishold=1 
              ;legende='WOA05'
              legende='CLIM'
              ;val4=FSC_COLOR('blue')
              val4=rgb2ind(ctot(4,0),ctot(4,1),ctot(4,2))
              ;print,'ctot :: ',ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)
              ;print,'Couleur : ',val4
              cmin=MIN(tabmin)
              cmax=MAX(tabmax)
              ;if (cmax ge 2) then cmax=2.5
              dirname_out=output_dir_tmp
              ;plot_serietemp_test5,2,val4,PLOT_KIND=kind,NOTE2="WOA09",OUTPUT_FILE=name_out;;,OVERPLOT=8
              plot_serietemp_oper3,2,val4,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_cumul,XINTERV=xinterv
	      if ( type eq 'mean' ) then begin
		name_out='Comparaison_GLORYS12_meandiff_'+var+'_'+zone+'_allmodels_'+tab_prof(prof)
	      endif else begin
		name_out='Comparaison_GLORYS12_rmsdiff_'+var+'_'+zone+'_allmodels_'+tab_prof(prof)
              endelse
	      ishold=0
              close_all
              do_output,output_dir_tmp+'/'+name_out
	      SPAWN,'convert -density 600 -background white -flatten -resize 15% '+output_dir_tmp+name_out+'.ps '+dirname_out+name_out+'.gif'
              SPAWN,'rm '+dirname_out+name_out+'.ps'
             prof=prof+1 
	   ENDWHILE
       ENDFOR  
   ENDFOR  
END
