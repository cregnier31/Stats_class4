load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  iodir="/homelocal/cregnier/DATA/CLASS4_ICE/"
  ;iodir="/naviti/data2/cregnier/CLASS4_GODAE/"
  modele="PSY4V3R1"
  ;modele="PSY4V2R2"
  ;iodir="/naviti/data2/cregnier/CLASS4_MERCATOR/"+modele+"/dezip/"
  iodir="/naviti/data5/cregnier/CLASS4_MERCATOR/"+modele+"/"
  indice=26
  indice=1
  do while(indice.le.7) 
    if ( indice .lt. 10 )  then
      day="0"+indice
    else 
      day=indice
    end if
    date="201611"+day
    print(date)
    ice_file="class4_"+date+"_"+modele+"_orca12_aice.nc"
 ;   ice_file="class4_20150727_GIOPS_CONCEPTS_1.1_aice.nc"
    fice    = addfile (iodir+ice_file, "r")
    nd    = 0                            ; depth index
    step  = 5
    lead_name="best_estimate"
    type_var="Model "+modele+" "+lead_name
    type_var=lead_name
    print(fice)
    ice=  fice->$lead_name$(::step,0,0) 
    lat1d= fice->latitude(::step)
    lon1d= fice->longitude(::step)
    nlon=dimsizes(lon1d)
    nlat=dimsizes(lat1d) 

    ;---create plots
    ;wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/FIG/"+modele+"interp1_"+lead_name+"_class4_"+date+"_"+type_var)       ; open a workspace plot
    wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/FIG/"+modele+"_"+lead_name+"_class4_"+date+"_"+type_var)       ; open a workspace plot
    print(wks)
    ;gsn_define_colormap(wks,"default")
    ;gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")  ; choose color map
    ;gsn_define_colormap(wks,"WhiteBlue")  ; choose color map
    gsn_define_colormap(wks,"seaice_2")  ; choose color map
    ;gsn_define_colormap(wks,"seaice_1")  ; choose color map
    ;gsn_define_colormap(wks,"MPL_PuBuGn")  ; choose color map
    cmap = gsn_retrieve_colormap(wks)
    nc1 = NhlNewColor(wks,.8,.8,.8)        ; Add light gray to colormap,
                                           ; for continents.
    ;---Levels to use for grouping ice  values
    levels = fspan(0.0,1.0,100)
    nlevels  = dimsizes(levels)
    ;
    ; Get a nice span of colors through the current color map, but
    ; skip the first three colors (0-2).
    ;
    colors = span_color_indexes(cmap(3:,:),dimsizes(levels)+1) + 3
  
    ;--- ressources construction 
    res                      = True               ; plot mods desired
    res@gsnFrame                    = False   ; Don't advance the frame
    res@gsnMaximize                 = True    ; Maximize plot in frame
    res@mpFillColors = (/-1,-1,nc1,-1/)    ;assign light gray to land masses
    ;res@tiMainString  = "Class4 Ice fraction Observations AMSR2 20150107"
    res@tiMainString  = "Class4 Ice fraction "+type_var+" "+date
    res@tiMainFontHeightF = 0.0225
;    res@mpDataBaseVersion  = "MediumRes"     ; Better map resolution
;    res@pmTickMarkDisplayMode = "Always"    ; Nicer map tickmark
    res@gsnPolar   = "NH"                         ; specify the hemisphere
    ;res@mpMinLatF  = 40                           ; minimum lat to plot
    res@mpMinLatF  = 60                            ; minimum lat to plot

    ; Create the map
    map=gsn_csm_map_polar(wks,res)
   
;
;  Create logical variables to hold the marker and text resources.
;  These markers are different than the XY markers, because they are not
;  associated with an XY plot. You can put these markers on any plot.
;
   gsres               = True
   gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
   gsres@gsMarkerSizeF = 0.002
   markerid = new(nlevels+1,graphic)
   do i=0,nlevels
      if(i.eq.0) then                         ; first level
         ii := ind(ice.lt.levels(0))
      else if(i.eq.nlevels) then              ; middle levels
         ii := ind(ice.ge.levels(nlevels-1))
      else                                    ; last level
         ii := ind(ice.ge.levels(i-1).and.ice.lt.levels(i))
      end if
      end if    
      if(.not.any(ismissing(ii))) then
        gsres@gsMarkerColor = colors(i)
        markerid(i) = gsn_add_polymarker(wks,map,lon1d(ii),lat1d(ii),gsres)
        print ("OK "+i)
      end if
      print ("OK "+i+nlevels)
   end do

  print ("OK2")
  draw(map)   ; This will draw map and the attached markers
  print ("Draw ok")
;----------------------------------------------------------------------
; Draw a labelbar
;----------------------------------------------------------------------
  lbres                    = True
;  lbres@vpWidthF           = 0.60             ; width
  lbres@vpWidthF           = 0.10             ; width
;  lbres@vpHeightF          = 0.10             ; height
  lbres@vpHeightF          = 0.40             ; height
  lbres@lbPerimOn          = False            ; Turn off perimeter.
  lbres@lbOrientation      = "vertical"     ; Default is vertical.
  lbres@lbLabelAlignment   = "InteriorEdges"  ; Default is "BoxCenters".
  lbres@lbFillColors       = colors           ; Colors for boxes.
  lbres@lbMonoFillPattern  = True             ; Fill them all solid.
  lbres@lbLabelFontHeightF = 0.012            ; label font height
  labels = sprintf("%4.2f",levels)
  print ("OK4")
  gsn_labelbar_ndc (wks,nlevels+1,labels,0.91,0.4,lbres) 
  ;gsn_labelbar_ndc (wks,nlevels+1,labels,0.25,0.08,lbres) 
  frame(wks)
  ;psres = True
  ;maximize_output(wks,psres)  ; calls draw and frame for you 
  print("Plot ok")
  indice=indice+1
  print(indice)
  delete(ice)
  delete(fice)
  delete(wks)
  delete(lat1d)
  delete(lon1d)
  delete(nlon)
  delete(nlat)
 end do
end
