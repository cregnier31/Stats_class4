load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
;  iodir="/homelocal/cregnier/DATA/CLASS4_ICE/"
  iodir="/naviti/data2/cregnier/CLASS4_MERCATOR/PSY4V2R2/dezip/"
 ; iodir="/naviti/data2/cregnier/CLASS4_GODAE/"
  MODEL="PSY4"
  ;MODEL="GIOPS"
  date="201502"
  stats_file="class4_"+date+"_Stats_aice.nc"
  fice    = addfile (iodir+stats_file, "r")
  step  = 1
  name="Rms_diff"
  ice=fice->rms_diff(::step,::step) 
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
  wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/FIG/CLASS4_aice/Stats_"+MODEL+"_class_aice_"+date+"_"+name)       ; open a workspace plot
  ;wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/FIG/CLASS4_aice/Stats_class_aice")       ; open a workspace plot
  ;wks = gsn_open_wks("png","/home/cregnier/DEV/NCL/ice/test")       ; open a workspace plot
  print(wks) 
  gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")  ; choose color map
  ;--- ressources construction 
  res                      = True               ; plot mods desired
  res@gsnFrame                    = False   ; Don't advance the frame
  res@gsnMaximize                 = True    ; Maximize plot in frame
  res@tiMainString  = "Class4 Ice fraction "+MODEL+" "+name+" "+date
  res@tiMainFontHeightF = 0.0225
  res@cnFillOn             = True               ; turn on color for contours
  res@cnLinesOn            =  False             ; turn off contour lines                                                                             
  res@cnLineLabelsOn       = False              ; turn off contour line labels
 ; res@gsnDraw                   = True             ; Dont' draw plot
  res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  res@cnMinLevelValF       = 0            ; set min contour level
  res@cnMaxLevelValF       = 0.2             ; set max contour level
  res@cnLevelSpacingF      = 0.01               ; set contour spacing
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
  res@cnFillPalette    = "WhiteBlueGreenYellowRed"   

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
