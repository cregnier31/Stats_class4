PRO tracer_serietemp_CLASS4,modele,fichier,fic_mask,profondeur,variable,dom,kind,zone
;==========================================================================
;##  Trace des statistiques pour les fichers class4
;
;    author: C REGNIER Septembre 2007
;
;==========================================================================
@param
@param_gauges

;file1='PSY3V1_A_2007_stats.nc'

file3=fic_mask
file=fichier

x1=ncdf_lec(file3,iodir=dir_mask,var='longitude', /nostruct) & x1=transpose(x1)
x2=ncdf_lec(file3,iodir=dir_mask,var='latitude', /nostruct) & x2=transpose(x2)



boite=ncdf_lec(file,iodir=dirin,var='box', /nostruct) & boite=transpose(boite)

rms_diff2=ncdf_lec(file,iodir=dirin,var='rms_diff_05', /nostruct) & rms_diff2=transpose(rms_diff2)
indice2=ncdf_lec(file,iodir=dirin,var='indice_05', /nostruct) & indice2=transpose(indice2)

rms_diff3=ncdf_lec(file,iodir=dirin,var='rms_diff_06', /nostruct) & rms_diff3=transpose(rms_diff3)
indice3=ncdf_lec(file,iodir=dirin,var='indice_06', /nostruct) & indice3=transpose(indice3)

rms_diff4=ncdf_lec(file,iodir=dirin,var='rms_diff_07', /nostruct) & rms_diff4=transpose(rms_diff4)
indice4=ncdf_lec(file,iodir=dirin,var='indice_07', /nostruct) & indice4=transpose(indice4)

il_nbreg=N_ELEMENTS(rms_diff2(1,1,*))
il_nelem=N_ELEMENTS(rms_diff2(1,*,1))
il_nprof=N_ELEMENTS(rms_diff2(*,1,1))
print,il_nbreg,il_nelem,il_nprof
;; golf stream
;FIND=WHERE(boite GE 3250 AND boite LE 3280, COUNT)
;FIND=WHERE(boite EQ 3310, COUNT)
;FIND=WHERE(boite GE 3260 AND boite LE 3280, COUNT)
;FIND=WHERE(boite GE 3250 AND boite LE 3280, COUNT)
;; Atlantique 2000 à 4000
FIND=WHERE(boite GE 2000 AND boite LT 4000, COUNT)
;; Atl Nord de 3000 à 4000
;FIND=WHERE(boite GE 3000 AND boite LT 4000, COUNT)
;; Indien de 6000 à 7000
;;FIND=WHERE(boite GE 6000 AND boite LT 7000, COUNT)
;; pacifique nord 5000 à 6000
;;FIND=WHERE(boite GE 5000 AND boite LT 6000, COUNT)
;; pacifique sud et trop de 4000  à 5000
;; pacifique
;:FIND=WHERE(boite GE 4000 AND boite LT 6000, COUNT)
;;FIND=WHERE(boite GE 4000 AND boite LT 5000, COUNT)
;FIND=WHERE(boite EQ 3250, COUNT)
print,'FIND',FIND
indice_i=FIND(0)
taille=N_ELEMENTS(FIND(*))
indice_f=FIND(taille-1)
print,'INDICE :',indice_i,indice_f

;val1=fltarr(taille)
val2=fltarr(taille)
val3=fltarr(taille)
val4=fltarr(taille)
;val5=fltarr(taille)

; On enleve PSAL et TEMP
;mean_val1=fltarr(il_nelem-2)
mean_val2=fltarr(il_nelem-2)
mean_val3=fltarr(il_nelem-2)
mean_val4=fltarr(il_nelem-2)
;mean_val5=fltarr(il_nelem-2)

;rms=fltarr(5,20)
rms=fltarr(3,22)
print,il_nelem-1
prof=0
;choix de la profondeur
;prof(0)=
;prof(1)=
;prof(2)=
;prof(3)=
;prof(4)=
;prof(5)=
rms(*,0)=0
rms(*,1)=0

prof=0L 
WHILE prof le 5 DO BEGIN
FOR il_ind2=2,il_nelem-1 DO BEGIN
   
        ;val1=WHERE(rms_diff1(prof,il_ind2,indice_i:indice_f) GT 0)
        ;print,'val1',val1
       ; IF val1 NE -1 THEN BEGIN
       ;     mean_val1(il_ind2-2)=SQRT( TOTAL(rms_diff1(prof,il_ind2,val1+indice_i))/ TOTAL(indice1(prof,il_ind2,val1+indice_i)))
       ; ENDIF ELSE BEGIN
       ;     mean_val1(il_ind2-2)=!values.f_nan
       ; ENDELSE

        val2=WHERE(rms_diff2(prof,il_ind2,indice_i:indice_f) GT 0) ;indice_f) GT 0);; stats sur les valeurs valides!!
     ; IF val2(0) NE -1 THEN BEGIN
            mean_val2(il_ind2-2)= SQRT(TOTAL(rms_diff2(prof,il_ind2,val2+indice_i)) / TOTAL(indice2(prof,il_ind2,val2+indice_i)))
            print,'mean_val ::',mean_val2(il_ind2-2)
    ; ENDIF ELSE BEGIN
        ;    mean_val2(il_ind2-2)=!values.f_nan
       ; ENDELSE

        val3=WHERE(rms_diff3(prof,il_ind2,indice_i:indice_f) GT 0) ;indice_f) GT 0)
        ;IF val3 NE -1 THEN BEGIN
         mean_val3(il_ind2-2)= SQRT(TOTAL(rms_diff3(prof,il_ind2,val3+indice_i)) / TOTAL(indice3(prof,il_ind2,val3+indice_i)))
          print,'mean_val ::',mean_val3(il_ind2-2)
        ;ENDIF ELSE BEGIN
         ;   mean_val3(il_ind2-2)=!values.f_nan
        ;ENDELSE

        val4=WHERE(rms_diff4(prof,il_ind2,indice_i:indice_f) GT 0) ;indice_f) GT 0)
        ;IF val4 NE -1 THEN BEGIN
            mean_val4(il_ind2-2)=SQRT(TOTAL(rms_diff4(prof,il_ind2,val4+indice_i)) / TOTAL(indice4(prof,il_ind2,val4+indice_i)))
            print,'mean_val ::',mean_val4(il_ind2-2)
                                ;ENDIF ELSE BEGIN
         ;   mean_val4(il_ind2-2)=!values.f_nan
        ;ENDELSE

        ;val5=WHERE(rms_diff5(prof,il_ind2,indice_i:indice_f) GT 0) ;indice_f) GT 0)
        ;IF val5 NE -1 THEN BEGIN
        ;    mean_val5(il_ind2-2)=SQRT(TOTAL(rms_diff5(prof,il_ind2,val5+indice_i))/ TOTAL(indice5(prof,il_ind2,val5+indice_i)))
         ;ENDIF ELSE BEGIN
         ;   mean_val5(il_ind2-2)=!values.f_nan
        ;ENDELSE
            rms(0,il_ind2)=mean_val2(il_ind2-2)
            rms(1,il_ind2)=mean_val3(il_ind2-2)
            rms(2,il_ind2)=mean_val4(il_ind2-2)

ENDFOR

; rms(0,*)=mean_val1
; rms(1,*)=mean_val2
; rms(2,*)=mean_val3
; rms(3,*)=mean_val4
; rms(4,*)=mean_val5



; Valeur des indices
chdate2jul, '2007/04/15', yyy, mm, dd, avril
chdate2jul, '2007/05/15', yyy, mm, dd, mai
chdate2jul, '2007/06/15', yyy, mm, dd, juin
chdate2jul, '2007/07/15', yyy, mm, dd, juillet
chdate2jul, '2007/08/15', yyy, mm, dd, aout
chdate2jul, '2007/09/01', yyy, mm, dd, septembre

;numx1=[avril,mai,juin,juillet,aout]
numx1=[mai,juin,juillet]
;tmin=avril
;tmax=septembre
tmin=mai
tmax=juillet
output='logo gif'

 FOR il_ind=4,12,2 DO BEGIN
 ishold=1
 numx2=rms(*,il_ind)
 print,'numx2',numx2
 titre=zone+' Modele '+modele+' '+profondeur(prof)+ ' class4'
 cmax=MAX(rms)
 cmin=MIN(rms);MIN(numx2)*0.5


; cmax=MAX(numx2)+MAX(numx2)*0.3
; cmin=MIN(numx2)-0.1;MIN(numx2)*0.5
 ishold=1
 xtitle='rms diff'
;color=0.5*il_ind+1
;line=-0.5+il_ind*0.2
; print,'COLOR',color
 
 xtitle2=boite(il_ind+2)
print,'il_ind',il_ind

plot_ts,PLOT_KIND='month',NOTE2=variable(il_ind)
;plot,numx2,numx1
ENDFOR
numx2=rms(*,16)
; cmax=MAX(numx2)+MAX(numx2)*0.3
; cmin=MIN(numx2)-0.1;MIN(numx2)*0.5
 ishold=1
plot_ts,PLOT_KIND='month',NOTE2=variable(16)

ishold=0
 do_outputbis,dirname_out+'serie_'+zone+'_'+modele+'_'+profondeur(prof)
    prof=prof+1
ENDWHILE 
END
