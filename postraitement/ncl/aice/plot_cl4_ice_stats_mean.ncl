load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  model="PSY4V2R2"
  iodir="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"+model+"/timeseries/"
  stats_file=""
  fice    = addfile (iodir+stats_file, "r")
  step  = 1
  name="Mean_diff"
  date="20150201"
  ice=fice->Seaice_diff(::step,::step) 
  if (any(isnan_ieee(ice))) then
      value = 0.0
      replace_ieeenan (ice, value, 0)
  end if
  ice = where(ice.eq.0,ice@_FillValue,ice)
  fillval=default_fillvalue("float")
  ice=where(isnan_ieee(ice),fillval,ice)

  ;print(ice)

  ice@lat2d = fice->latitude(::step,::step)
  ice@lon2d = fice->longitude(::step,::step)

  ;---create plots
;  wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/FIG/CLASS4_aice/Stats_class_aice_"+date+"_"+name)       ; open a workspace plot
  ;wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/FIG/CLASS4_aice/Stats_class_aice")       ; open a workspace plot
  wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/ice/Stats_class_aice_mean")       ; open a workspace plot
  print(wks) 
  gsn_define_colormap(wks,"NCV_blu_red")  ; choose color map
  ;--- ressources construction 
  res                      = True               ; plot mods desired
  res@gsnFrame                    = False   ; Don't advance the frame
  res@gsnMaximize                 = True    ; Maximize plot in frame
  res@tiMainString  = "Class4 Ice fraction "+name+" "+date
  res@tiMainFontHeightF = 0.0225
  res@cnFillOn             = True               ; turn on color for contours
  res@cnLinesOn            =  False             ; turn off contour lines                                                                             
  res@cnLineLabelsOn       = False              ; turn off contour line labels
 ; res@gsnDraw                   = True             ; Dont' draw plot
  res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res@cnMinLevelValF       = -0.2            ; set min contour level
  res@cnMaxLevelValF       = 0.2             ; set max contour level
  res@cnLevelSpacingF      = 0.025               ; set contour spacing
  ;res@cnFillMode       = "RasterFill"       ; Raster Mode
  res@mpLandFillColor       = "gray"            ; set land to be gray
  res@gsnPolar   = "NH"                         ; specify the hemisphere
  res@mpMinLatF  = 45                           ; minimum lat to plot
  res@mpDataBaseVersion = "MediumRes"

;     res@gsnPolar   = "SH"
;     res@mpMinLatF  = -90                            ; minimum lat to plot
;     res@mpMaxLatF  = -60                            ; minimum lat to plot

  res@lbOrientation            = "Horizontal"     ; vertical label bar
  res@lbLabelStride            = 4
  res@cnFillPalette    = "NCV_blu_red"   

  ; Create the map
  plot = gsn_csm_contour_map_polar(wks,ice,res)
  print("ok")
  ;; Overlay the two plots and draw them.
  frame(wks)  
; Maximize plot in the frame
;  print ("OK2")
;  draw(map)   ; This will draw map and the attached markers
;
;  print ("Draw ok")
end
