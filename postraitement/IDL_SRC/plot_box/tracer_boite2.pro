PRO tracer_boite2

;==========================================================================
;##  Trace les boites definies par C-E  en fonction des coordonnées d'entree
;
;    author: C REGNIER Juin 2007 avec des sources issues de A. BelMadani
;
;==========================================================================
@param
@param_gauges

box=ncdf_lec(file,iodir=dirin,var='mask', /nostruct)& box=transpose(box)
field2=ncdf_lec(file,iodir=dirin,var='longitude', /nostruct) & field2=transpose(field2)
field3=ncdf_lec(file,iodir=dirin,var='latitude', /nostruct) & field3=transpose(field3)
il_nblon=N_ELEMENTS(box(1,*))
il_nblat=N_ELEMENTS(box(*,1))
print,il_nblon,il_nblat
;print,box

;kindchoice='unknown'
 kindchoice='unknown'
   palette='default'
;kindchoice='UserLevels';kindchoice='MaxiLevels';'no_iso'
;palette='miami'
;palette
;='ferret'
titre='Geographical boxes'
units='box number'
domain='global'
;domain='zoom NAT'
;cmin=1000
;cmax=7200
cmin=1000
cmax=7200
dc=10
ishold=0

;x1=fltarr(1442,1021)
;x2=fltarr(1442,1021)
;field=fltarr(1442,1021)
field=box*1.
ii=where(field lt 1000.) & field(ii)=!VALUES.F_NAN
ii=where(abs(field2)  gt 200.)  & field(ii)=!VALUES.F_NAN
;ii=where(field lt 1000.) & field(ii)=!VALUES.F_NAN
x1=field2
x2=field3

;set_plot,'z'
plot_2Dfield

;map=tvrd()
;set_plot,'x'
;tv,map

;il_ind=1
;scale=1
;color=100
;print,'LAT LON ::',il_nblon,il_nblat
;val=fltarr(il_nblon*il_nblat)

;FOR il_reg=0,il_nblon-1 DO BEGIN
;    FOR il_sreg=0,il_nblat-1 DO BEGIN
;       val(il_ind)=field(il_sreg,il_reg)  
;       print,'VAL ::',il_ind,val(il_ind)
;       IF (il_ind) GT 2 AND val(il_ind) NE val(il_ind-1) THEN BEGIN
;           color=color+1
;           print,'region suivante'
;      ENDIF
;       ;plot_dot,field2(il_sreg,il_reg),field2(il_sreg,il_reg),scale,color
 ;     print,'field2(il_sreg,il_reg)',field2(il_sreg,il_reg),field3(il_sreg,il_reg)
 ;     plot,field2(il_sreg,il_reg),field3(il_sreg,il_reg),color=color
 ;     print,'Tracé du point n° ',il_ind
 ;      il_ind=il_ind+1
 ;  ENDFOR
;ENDFOR


; Sauvegarde de l'image obtenue
output='screen logo gif'
do_output,dirname_out+'Tracer_boite'
END
