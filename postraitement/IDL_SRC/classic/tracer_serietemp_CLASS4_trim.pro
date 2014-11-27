PRO tracer_serietemp_CLASS4_trim,modele,fichier,fic_mask,profondeur,variable_name, $
                                 kind,filelist,dir_stats_MERC,days,valeurs_cmax,valeurs_cmax_sal,liste_zone,tab_choix,OPER
;==========================================================================
;##  Trace des statistiques pour les fichers class4
;
;    author: C REGNIER Septembre 2007
;    author: C REGNIER Mai 2009 :: Compute rms diff for differentes
;    echeances et differents runs
;    author: C REGNIER Janvier 2010 :: corrections to adapt the number of prof
;
;==========================================================================

@param
@param_gauges
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
      FIND=WHERE(boite GE 6000 AND boite LE 6770, COUNT)   
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
    FIND1=WHERE(boite GE 2120 AND boite LE 2360, COUNT)
    FIND2=WHERE(boite GE 3440 AND boite LE 3790, COUNT)
    FIND=[FIND1,FIND2]
 ENDCASE
  'TPA': BEGIN
;; TPA 4000-4530 ; 5260-5880 ; 30N-30S
    FIND1=WHERE(boite GE 4000 AND boite LE 4530, COUNT)
    FIND2=WHERE(boite GE 5260 AND boite LE 5880, COUNT)
    FIND=[FIND1,FIND2]
 ENDCASE
  'Golf_stream':BEGIN
;; golf stream
;FIND=WHERE(boite EQ 3310, COUNT)
;;FIND=WHERE(boite GE 3260 AND boite LE 3280, COUNT)   ENDCASE
   FIND=WHERE(boite GE 3250 AND boite LE 3280, COUNT)
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
rms_difftot=dblarr(nb_prof,20,412,nfichiers)
indice_tot=dblarr(nb_prof,20,412,nfichiers) ;intarr
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
  print,il_nbreg,il_nelem,il_nprof
  i=i+1
endwhile
vect_val=intarr(taille)
; On enleve PSAL et TEMP
rms=dblarr(nb_prof,il_nelem-2,nfichiers)
val_rms=0L
rms(*,*,*)=0L
prof=0L 
fichier=0L

WHILE prof le N_ELEMENTS(profondeur)-1 DO BEGIN
   FOR fichier=0,nfichiers-1 DO BEGIN
      FOR il_ind2=2,il_nelem-1 DO BEGIN
      ;; Recherche des indices valides
         vect_val=WHERE(rms_difftot(prof,il_ind2,indice_i:indice_f,fichier) GT 0)
        ; PRINT,vect_val
      ;; Calcul de la rms
         IF (vect_val(0) NE -1) THEN BEGIN
        ; PRINT,'Valeur :: ',prof,il_ind2,vect_val,indice_i,fichier
         val_rms=SQRT(TOTAL(rms_difftot(prof,il_ind2,vect_val+indice_i,fichier)) / TOTAL(indice_tot(prof,il_ind2,vect_val+indice_i,fichier)))
         rms(prof,il_ind2-2,fichier)=val_rms
         ENDIF
      ENDFOR
      print,'fichier number :: ',fichier
   ENDFOR 
   prof=prof+1
ENDWHILE 


; Valeurs des jours en jours juliens
ndays=N_ELEMENTS(days)
jours=fltarr(ndays)

FOR il_ind=0,ndays-1 DO BEGIN
chdate2jul,STRING(days(il_ind)) , yyyy, mm, dd, run1
jours(il_ind)=run1
ENDFOR

;; Definition des couleurs du tracé
Def_colors
common COLOR_BLOCK,black,grey,white,bleuey,cyan,green,gold,yellow,red,blue,salmon,aquam,brown,burly,gmt_land
c1_bis=black  ;; noir
c1=white  ;; noir
c2=blue  ;; bleu
c3=green ;; vert
c4=red ;; vert
c5=cyan
c6=salmon
c7=brown
c8=grey
c9=gold


output='gif'
prof=0L 

WHILE prof le nb_prof-1 DO BEGIN
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

;; Boucle sur les variables 

FOR il_ind=il_begin,il_nelem-3,2 DO BEGIN 
   clear,numx1,numx2   
   numx1=jours
   numx2=rms(prof,il_ind,*)
   titre='Rms diff '+modele+' '+profondeur(prof)+ ' class4 '+zone
   xtitle='rms diff'
   clear,cmin,cmax
;   cmin=range_values(0,prof)
;   cmax=range_values(1,prof)
   i=WHERE(rms EQ 0) & IF i(0) NE -1 THEN  rms(i)=!VALUES.F_NAN
   if (var eq 'SAL') THEN BEGIN
        cmin=MIN( rms(prof,1:*:2,*),/NaN )
	cmax=MAX( rms(prof,1:*:2,*),/NaN )
	PRINT ,'SAL ',cmin,cmax
    endif else begin
   if (var eq 'TEMP') THEN BEGIN
      cmin=MIN( rms(prof,0:*:2,*),/NaN )
      cmax=MAX( rms(prof,0:*:2,*),/NaN )
      PRINT ,'TEMP ',cmin,cmax
     endif
    endelse
	   
xtitle2=boite(il_ind+2)
   val4=rgb2ind(ctot(il_ind2,0),ctot(il_ind2,1),ctot(il_ind2,2)) & $
      ishold=1

   IF ( OPER eq "NO" )  THEN BEGIN 
      IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
       and variable_name(il_ind+2) ne 'PERS3D_TEMP'  and variable_name(il_ind+2) ne 'PERS3D_PSAL' $
       and variable_name(il_ind+2) ne 'PERS6D_TEMP'  and variable_name(il_ind+2) ne 'PERS6D_PSAL') THEN BEGIN
         plot_serietemp,0,val4,PLOT_KIND=kind,NOTE2=variable_name(il_ind+2),OVERPLOT=8
     il_ind2=il_ind2+1
     print ,il_ind,il_ind2
     ENDIF
   ENDIF ELSE BEGIN
       IF (variable_name(il_ind+2) ne 'FSTGS_TEMP' and variable_name(il_ind+2) ne 'FSTGS_PSAL' $
           and variable_name(il_ind+2) ne 'PERS_TEMP'  and variable_name(il_ind+2) ne 'PERS_PSAL') THEN BEGIN
         plot_serietemp,0,val4,PLOT_KIND=kind,NOTE2=variable_name(il_ind+2),OVERPLOT=8
	il_ind2=il_ind2+1
        print ,il_ind,il_ind2
      ENDIF
    ENDELSE     

ENDFOR
ishold=0
do_outputbis,dirname_out+'Serie_temp/Serie_trim'+var+'_'+zone+'_'+modele+'_'+profondeur(prof)
prof=prof+1

ENDWHILE

 ENDFOR
ENDFOR 


END
