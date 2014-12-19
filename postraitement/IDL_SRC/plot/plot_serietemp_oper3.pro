PRO plot_serietemp_oper3, scale, tscolorin, PLOT_KIND=plot_kind, OUTPUT_FILE=output_file, NOTE2=note2,OVERPLOT=overplot ,XRANGE=xrange,YRANGE=yrange,RIGHT=nb_data

; idl command
;
;## plot_ts: [over]plot a 1D time serie
;
; author : Benkiran Mounir  & EG 01/08 (IDL translation)
; author : Greiner Eric (MathLab)
; edition: Greiner Eric 2002/10/12 no overplot when ishold and noplot=0
; edition: Greiner Eric 2004/11/28 'year' case
; edition: Greiner Eric 2005/05/23 icon showing position xlon-ylat in bottom right corner
; edition: Greiner Eric 2005/05/23 output_file parameter
; edition: Greiner Eric 2006/06/30 grid keyword
; edition: Greiner Eric 2005/10/03 no icon if configuration/domain are not set
; edition: Cousin Remi 2005/11/25 add argument note2 to chose legend
; edition: C.REGNIER 2007/18/12 add keyword OVERPLOT for solid line
; edition: C.REGNIER 2011/05/24 add keyword RIGHT for right axis
; remove datetick to simplify
; edition: C.REGNIER  2008/05/14 new routine to simply the drawing,
;remove code and clean 
; with points
; input: 	[tmin] : begining of dates	ex: chdate2jul, '1994/01/01', yyy, mm, dd, tmin
;		[tmax] : end of dates		ex: chdate2jul, '1995/01/01', yyy, mm, dd, tmax

;		plot_kind: keyword 	'no_bg' 	--> no background color
;					'solid_line' 	--> linestyle is solid
;					'dotted_line' 	--> linestyle is dotted
;					'dashed_line' 	--> linestyle is dashed
;					'no_legend' 	--> no legend
;					'colormap_ind' 	--> color index relative to colormap
;					'grid' 		--> grid for the values (not time)
;					'no_dateticks' 	--> no date ticks
;					'cycle'		--> time_label is 'cycle'
;					'year'		--> time_label is 'year'
;					'month'		--> time_label is 'month'
;					'first'		--> time_label is 'first'
;					'mean'		--> draw a thin line for the mean
;					'fitlin'	--> draw a thin line for the linear fit
;					'no_icon'	--> does not show icon position in corner
;
;		xlon-ylat		position of the time serie for the icon
;
;		units			units for the axis legend
;
;		output			'none'		--> no plot
;
; see also area to shade areas (ex: difference btw time serie and zero)

@param
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Header 
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PRINT, 'plot_serietemp: plot time series'
IF NOT isfinite(output) 	THEN output='screen'
IF NOT isfinite(scale) 		THEN scale=1.
IF     isfinite(tscolorin) 	THEN tscolor=tscolorin-1
IF NOT isfinite(plot_kind) 	THEN plot_kind=' '
IF NOT isfinite(configuration) 	THEN configuration='none'
IF configuration NE 'none' AND NOT isfinite(domain) THEN default
show_icon=1
IF STRPOS(plot_kind,'no_icon') NE -1 THEN show_icon=0
IF configuration EQ 'none' THEN show_icon=0
IF NOT isfinite(domain) THEN show_icon=0
print,'Fonction plot serie temp oper3'
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; load colors
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; some colors for THIS program

common COLOR_BLOCK,black,grey,white,bleuey,cyan,green,gold,yellow,red,blue,salmon,aquam,brown,burly,gmt_land
Def_colors

colors=[black,cyan, green, yellow, red, blue, salmon,  aquam, brown,burly] ; serie of fav colors (flashy and distinct)

; NOTE: rainbow order is 5 1 7 2 3 6 4
ncolors=n_elements(colors(*,0))
IF isfinite(tscolor) THEN tscolor=(tscolor MOD ncolors)

dots=0
IF STRPOS(plot_kind,'dots') 	   NE -1 THEN dots=1


;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Definition of parameters in the windows
;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; window of the plot in the figure: origine and sizes

x0=0.10 & y0=.17        &       dxw=1-2.*x0 & dyw=1-1.5*y0      ; 01/03/02

!P.POSITION=[ x0, y0, x0+dxw, y0+dyw ]

; plot
; dimension of the media
a4=[210., 297.]
a4R=[297., 210.]
shape=a4R
axisratio=0.5

IF NOT isfinite(ishold) THEN ishold=0
IF NOT isfinite(noplot) THEN noplot=0
IF NOT isfinite(units)	THEN units=' '
IF NOT isfinite(cmin) 	THEN cmin=MIN(numx2, /NAN)
IF NOT isfinite(cmax) 	THEN cmax=MAX(numx2, /NAN)
IF cmin GE cmax THEN BEGIN
   cmin=MIN(numx2, /NAN)
   cmax=MAX(numx2, /NAN)
ENDIF
;fmean=MEAN(numx2, /NAN)
fmean=0


; date ticks
IF NOT isfinite(tmin) THEN tmin=MIN( numx1 )
IF NOT isfinite(tmax) THEN tmax=MAX( numx1 )
IF tmin GE MAX( numx1 ) THEN tmin=MIN( numx1 )
IF tmax LE MIN( numx1 ) THEN tmax=MAX( numx1 )
IF tmin GE tmax THEN BEGIN
   PRINT, 'plot_ts: error: time axis is dull'
   RETURN
ENDIF


IF STRPOS(output,'none') EQ -1 THEN BEGIN
; titre du plot
   !P.title=' '
   new=1
   IF ishold THEN new=0
   IF ishold AND noplot EQ 0 THEN new=1 ; we dont overplot over the previous window
   IF STRPOS(output,'screen') EQ -1 AND noplot 	EQ 0  THEN new=1
   IF STRPOS(output,'screen') NE -1 AND !D.window	EQ -1 THEN new=1

;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Compute new plot
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   IF new THEN BEGIN
      PRINT, 'plot_ts: new plot'
      noplot=1

; 		preparation of the output (device)
		print,'Prep output',output_file
		prep_output, shape,axisratio, OUTPUT_FILE=output_file
		print,'Prep output OK'
                ;; Chargement palette
                LOADCT, 33, /silent 
                ;; rv=0
                IF STRPOS(output, 'screen') 	EQ -1 THEN  BEGIN
                   IF STRPOS(output, 'ps'  ) 	NE -1 THEN rv=1
                   IF STRPOS(output, 'gif' ) 	NE -1 THEN rv=1
                   IF STRPOS(output, 'png' ) 	NE -1 THEN rv=1
                   IF STRPOS(output, 'jpeg') 	NE -1 THEN rv=1
                   IF rv THEN BEGIN
                      PRINT,'my_colormap: device in reverse video'
                      z=black   ; reverse video
                      black=white ; reverse video
                      white=z     ; reverse video
                   ENDIF
                ENDIF
; CAUTION: 	1rst and last colors cant be modified on some PCs. The colormap seems 
;		to be altered, but default holds anyway. It's a bug  (thanks IDL).
                
;        we set the 1st color (NaN <-> background)
                TVLCT, black,   000 ; default on PCs
;;       we set the last color (text)
                TVLCT, white,   !D.TABLE_SIZE-1

;       	some color indexes in the current colormap
		black=  rgb2ind(000,000,000)
		grey=   rgb2ind(127,127,127)
		;grey=   rgb2ind(184,184,184)
		white=  rgb2ind(255,255,255)
	
		bgi=grey ; background color

		IF STRPOS(plot_kind,'no_bg') EQ -1 THEN $
		plot_rect, x0, y0, x0+dxw, y0+dyw, 0., bgi, 'norm' ; background color for the plot

 ; 		line styles: 0=solid, 1=dotted (not good) , 2=dashed
		linestyle=0
		IF STRPOS(plot_kind,'solid_line' ) NE -1 THEN linestyle=0
		IF STRPOS(plot_kind,'dotted_line') NE -1 THEN linestyle=1
		IF STRPOS(plot_kind,'dashed_line') NE -1 THEN linestyle=2

		ticklen=-0.02
		IF STRPOS(plot_kind, 'grid') NE -1 THEN yticklen=1
		;;; rajout C. REGNIER
                IF STRPOS(plot_kind, 'grid') NE -1 THEN BEGIN
                 xticksval=0
                 xticklen=1
                ENDIF ELSE BEGIN
                xticksval=1
                xticklen=0
                ENDELSE
                ;;;
                ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                ;; Date format for X axis 
                ;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                numx1=numx1(*)
              ;  tmax=MAX(numx1)
              ;  tmin=MIN(numx1)
		dummy = LABEL_DATE(DATE_FORMAT=['%N','%Y'])
                IF (KEYWORD_SET(xrange)) THEN BEGIN
                   absc_range=xrange 
                ENDIF ELSE BEGIN
                   absc_range=[tmin, tmax]
                ENDELSE	
                
                IF (KEYWORD_SET(yrange)) THEN BEGIN
                   ord_range=yrange
                ENDIF ELSE BEGIN
                   minval=MIN(numx2, /NAN)
                   maxval=MAX(numx2, /NAN)
                   ord_range=[minval,maxval]
                ENDELSE
                tscolorin=black
		color=grey
                ;; Plot data  
		IF (KEYWORD_SET(nb_data)) THEN BEGIN
		   PLOT, numx1, nb_data,  /NODATA,/noerase, $
                   LINESTYLE=3,THICK=3,BACKGROUND = 0, COLOR=white ,XCHARSIZE=1.5, YCHARSIZE=1.5, $
                   YSTYLE=4,YTICKLEN=yticklen,YGRIDSTYLE=1, $
                   XTICKUNITS = ['Time', 'Time'],$
                   XTICKINTERVAL=1,$
                   XTICKFORMAT='LABEL_DATE'
	           color=FSC_COLOR('grey')
                   area, numx1, nb_data, nb_data*0,1, color
                   AXIS, YAXIS=1,XCHARSIZE=1.5, YCHARSIZE=1.5,YRANGE=[MIN(nb_data,/NaN),MAX(nb_data,/NaN)], ytitle=' Data number ',COLOR =black
	           ishold=1		 
	        ENDIF 
                PLOT,[tmin, tmax], [cmin, cmax*1.05] , /NODATA, /NOERASE, $
                    LINESTYLE=linestyle,THICK=7.*ABS(scale), COLOR=black, BACKGROUND=white,XCHARSIZE=1.5, YCHARSIZE=1.5, $
                    YSTYLE=8,YTICKLEN=yticklen,YGRIDSTYLE=1, $
                    XTICKUNITS = ['Time', 'Time'],$
                    XTICKINTERVAL=1,$
                    XTICKFORMAT='LABEL_DATE' 
                ;; Overplot dots on the line
                ishold=1
                ;; ishold=1
                ;;;; Ajout C. REGNIER                 
                if (KEYWORD_SET(overplot)) then begin 
                   a=FINDGEN(17)*(!PI*2/16.)
                   ;; Definition d'un point !!
                   USERSYM, COS(a), SIN(a), /FILL                                                                             ; use PSYM=8
                    OPLOT, numx1, numx2, PSYM=overplot,LINESTYLE=linestyle, SYMSIZE=0.5,THICK=3.*ABS(scale),COLOR=tscolorin    ;; Modifs C.REGNIER
                ENDIF

;;                
; one of the set of colors : the closest in the current colortable

                IF STRPOS(plot_kind,'colormap_ind') EQ -1 THEN BEGIN ; local colors
                   IF NOT isfinite(tscolor) THEN BEGIN & ncolor=(noplot-1) MOD ncolors
                   ENDIF ELSE BEGIN & ncolor=tscolor & ENDELSE
                   ;; color=rgb2ind(colors(ncolor,0), colors(ncolor,1), colors(ncolor,2)) modifs cregnier
                      color=tscolorin
                   ENDIF ELSE BEGIN
                      color=tscolorin
                   ENDELSE
                   OPLOT, numx1, numx2, LINESTYLE=linestyle, THICK=3.*ABS(scale),COLOR=tscolorin  ;; modifs C. REGNIER
                   ;;;
                   IF dots THEN plot_dot, numx1, numx2, scale, tscolorin  ;; Modifs C.REGNIER

; plot the mean as a thin solid line
                   IF STRPOS(plot_kind,'mean') NE -1 AND isfinite(fmean) THEN $
                      OPLOT, [min(numx1),max(numx1)],[fmean,fmean], LINESTYLE=0, THICK=0.5*ABS(scale), COLOR=color

; titre du plot
                   IF NOT isfinite(titre) THEN BEGIN
                      titre_2Dfield
                   ENDIF ELSE BEGIN
                      IF NOT isfinite(cmdtitre) THEN cmdtitre='!17 '+titre+ '!13'
                      IF STRPOS(cmdtitre,titre) EQ -1 THEN cmdtitre='!17 '+titre+ '!13' ; title was changed
                   ENDELSE
                   
; 		titre in normal[ized] coordinates
                   charsize=2.2*45/STRLEN(titre)
                                ;charsize=MIN([ 2.125, charsize])
                   charsize=MIN([ 2, charsize])
                   print,'charsize',charsize
                   XYOUTS, x0+dxw/2, 1-y0/4, cmdtitre, /norm, alignment=0.5, $
                           CHARSIZE=charsize, CHARTHICK=1, COLOR=black
                   
;		legend
                   chx2=units
                   note=units
                   XYOUTS,  x0    -dxw/10., 0.5, note, /norm, alignment=0.5, CHARSIZE=2.0, ORIENTATION= 90., COLOR=black
                   XYOUTS,  x0+dxw+dxw/20., 0.5, note, /norm, alignment=0.5, CHARSIZE=2.0, ORIENTATION=-90., COLOR=black
                   
                ENDIF ELSE BEGIN
                  
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;
;	Overlay	Overlay	Overlay	Overlay	Overlay	Overlay	Overlay	Overlay	Overlay	Overlay	Overlay
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

                   noplot=noplot+1
                   PRINT, 'plot_ts: overlay plot #',noplot 

; one of the set of colors : the closest in the current colortable
                   IF STRPOS(plot_kind,'colormap_ind') EQ -1 THEN BEGIN ; local colors
                      IF NOT isfinite(tscolor) THEN BEGIN & ncolor=(noplot-1) MOD ncolors
                      ENDIF ELSE BEGIN & ncolor=tscolor & ENDELSE
                         color=rgb2ind(colors(ncolor,0), colors(ncolor,1), colors(ncolor,2))
                      ENDIF ELSE BEGIN
                         color=tscolorin  
                      ENDELSE
      
; 	line styles: 0=solid, 1=dotted (not good), 2=dashed
                      linestyle=(noplot-1) MOD 2
                      linestyle=2
                      IF noplot GT 2 AND noplot LE 4 THEN linestyle=-1
                      IF noplot GT 4 THEN linestyle=3
                      IF STRPOS(plot_kind,'solid_line' ) NE -1 THEN linestyle=0
                      IF STRPOS(plot_kind,'dotted_line') NE -1 THEN linestyle=1
                      IF STRPOS(plot_kind,'dashed_line') NE -1 THEN linestyle=2
                      IF STRPOS(plot_kind,'dots') 	   NE -1 THEN dots=1
                      PRINT, 'plot_ts: linestyle is ',linestyle
                      
;       	some color indexes in the current colormap
                      black=  rgb2ind(000,000,000)
                      grey=   rgb2ind(127,127,127)
                      grey=   rgb2ind(184,184,184)
                      white=  rgb2ind(255,255,255)

		IF linestyle LT 0 THEN BEGIN
                   PLOT_DOT, numx1, numx2, scale, color ; plot dots
                ENDIF
                IF 0 LE linestyle AND linestyle LE 2 THEN BEGIN 
                   date_time=TIMEGEN(N_ELEMENTS(numx1)-1,UNITS='Days',START= JULDAY(01, 01, 1950))
                   numx1=numx1(*)+date_time(0)
                   OPLOT, numx1, numx2, LINESTYLE=linestyle, THICK=3.*ABS(scale), COLOR=tscolorin 
                   ishold=1
                        ;;;; Ajout C. REGNIER                 
                   if (KEYWORD_SET(overplot)) then begin 
                      a=FINDGEN(17)*(!PI*2/16.)
                      ;; Definition d'un point !!
                      USERSYM, COS(a), SIN(a), /FILL                                                                                ; use PSYM=8
                      OPLOT, numx1, numx2, PSYM=overplot,LINESTYLE=linestyle, SYMSIZE=0.5,THICK=3.*ABS(scale),COLOR=tscolorin       ;;  Modifs C.REGNIER
                   ENDIF
;;; 
                ENDIF
                IF linestyle GE 3  THEN BEGIN ; black in the middle
                   OPLOT, numx1, numx2, LINESTYLE=linestyle, THICK=7.*ABS(scale), COLOR=tscolorin ;;  Modifs C.REGNIER
                   IF scale GT 0 THEN $
                      OPLOT, numx1, numx2, LINESTYLE=linestyle, THICK=3.*scale, COLOR=black
                   
                ENDIF
                
                IF dots THEN plot_dot, numx1, numx2, scale, tscolorin ;;  Modifs C.REGNIER
; stairs : PSYM=10
             ENDELSE
                
; linear fit

                zx1= (1.+(x0+dxw))/2. &  zy1=0 & zdy=y0/5
                zx1= 0.8 &  zy1=0 & zdy=y0/5
                
                IF STRPOS(plot_kind,'fitlin') NE -1 THEN BEGIN
                   
                   i=WHERE( FINITE(numx1) EQ 1 AND FINITE(numx2) EQ 1)
                   correlation=CORRELATE( numx1(i), numx2(i) )
                   std=STDDEV( numx1(i)-numx2(i) )
                   result=POLY_FIT( numx1(i), numx2(i),  1) ; fit : linear regression
                   PRINT, 'plot_ts: fit is   y= ',result(1),' * x + ', result(0)
                   PRINT, 'plot_ts: ', correlation, std
; 	draw fit axis
                   colorseg=color & scale=-0.7
                   axe1min=tmin & axe1max=tmax
                   plot_seg, 	axe1min, result(1)*axe1min+result(0), $
                                axe1max, result(1)*axe1max+result(0), scale, colorseg
                   IF isfinite(correlation) THEN BEGIN 
                      note='!3correlation '+string(format='(F7.2)', correlation)
                      zy1=zy1+zdy/2
                      XYOUTS, zx1, zy1, note, /norm, alignment=1.0, CHARSIZE=charsize*0.6, COLOR=black
                      note='!3stddev '+string(format='(F7.2)', std)
                      zy1=zy1+zdy/2
                      XYOUTS, zx1, zy1, note, /norm, alignment=1.0, CHARSIZE=charsize*0.6, COLOR=black
                      note='!3fit bias '+string(format='(F7.2)', result(0))
                      zy1=zy1+zdy/2
                      XYOUTS, zx1, zy1, note, /norm, alignment=1.0, CHARSIZE=charsize*0.6, COLOR=black
                      note='!3fit slope '+string(format='(F7.2)', result(1))
                  zy1=zy1+zdy/2
                  XYOUTS, zx1, zy1, note, /norm, alignment=1.0, CHARSIZE=charsize*0.6, COLOR=black
               ENDIF    
                ENDIF    
                
;               legend: note describing the filename
                IF STRPOS(plot_kind,'no_legend') EQ -1 THEN BEGIN
                   
                   IF NOT isfinite(note2) THEN BEGIN
                                ;name_output
                      print,'Font1', !P.FONT
                     ; note2='!17'+base_output+'!13'
                      note2='!5'+base_output+'!5'
                      WHILE ((( I = STRPOS(note2,'_') )) NE -1) DO STRPUT, note2, ' ', I ; string : character substitution 
                   ENDIF
                   
                   i=((noplot-1) MOD 2) & j=(noplot-1)/2 ; 2 columns, 3 raws
       		   ;; TEST
          	   IF STRPOS(note2,'HDCST_TEMP' ) NE -1 THEN note2='HINDCAST'
          	   IF STRPOS(note2,'HDCST_PSAL' ) NE -1 THEN note2='HINDCAST'
          	   IF STRPOS(note2,'ANA_TEMP' ) NE -1 THEN note2='NOWCAST'
          	   IF STRPOS(note2,'ANA_PSAL' ) NE -1 THEN note2='NOWCAST'
          	   IF STRPOS(note2,'FRCST1D_TEMP' ) NE -1 THEN note2='FRCST-1DAY'
          	   IF STRPOS(note2,'FRCST1D_PSAL' ) NE -1 THEN note2='FRCST-1DAY'
          	   IF STRPOS(note2,'FRCST3D_TEMP' ) NE -1 THEN note2='FRCST-3DAY'
          	   IF STRPOS(note2,'FRCST3D_PSAL' ) NE -1 THEN note2='FRCST-3DAY'
          	   IF STRPOS(note2,'FRCST5D_PSAL' ) NE -1 THEN note2='FRCST-5DAY'
          	   IF STRPOS(note2,'FRCST5D_TEMP' ) NE -1 THEN note2='FRCST-5DAY'
          	   IF STRPOS(note2,'FRCST6D_PSAL' ) NE -1 THEN note2='FRCST-6DAY'
          	   IF STRPOS(note2,'FRCST6D_TEMP' ) NE -1 THEN note2='FRCST-6DAY'
          	   IF STRPOS(note2,'PERS_PSAL' ) NE -1 THEN note2='PERS'
          	   IF STRPOS(note2,'PERS_TEMP' ) NE -1 THEN note2='PERS'
		   IF (note2 eq 'TMLEV' ) THEN note2='CLIM-LEV05'
		   IF (note2 eq 'SMLEV' ) THEN note2='CLIM-LEV05'
		   IF (strtrim(note2) eq 'TMLEV05' ) THEN note2='CLIM-LEV05'
		   IF (strtrim(note2) eq 'SMLEV05' ) THEN note2='CLIM-LEV05'
		   IF (note2 eq 'TMLEV09' ) THEN note2='CLIM-LEV09'
		   IF (note2 eq 'SMLEV09' ) THEN note2='CLIM-LEV09'
		   IF (strtrim(note2) eq 'TMLEV13' ) THEN note2='CLIM-LEV13'
		   IF (strtrim(note2) eq 'SMLEV13' ) THEN note2='CLIM-LEV13'
		   IF STRPOS(note2,'TMARV' ) NE -1 THEN note2='CLIM-ARIVO'
                   IF STRPOS(note2,'SMARV' ) NE -1 THEN note2='CLIM-ARIVO'
		   IF STRPOS(note2,'TMARV11' ) NE -1 THEN note2='CLIM-ARIVO11'
                   IF STRPOS(note2,'SMARV11' ) NE -1 THEN note2='CLIM-ARIVO11'
		   ;; 
		   print ,'Note oper3  :: ',note2
                   note2='!5'+note2+'!5'
	           zx1=x0+dxw/10+noplot*dxw/7 & zy1=y0+dyw+0.01 ; legend left corner
                   print,'Font2',!P.FONT                          ; !P.FONT
                   XYOUTS, zx1, zy1, note2, /norm, alignment=0.5, CHARSIZE=1.5, COLOR=tscolorin ;; modifs C.REGNIER
                ENDIF                
; output
                do_output, output_file
             ENDIF
PRINT,'plot_serietemp: fin OK'


END
