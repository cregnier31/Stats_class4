load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  MODEL="PSY4V2R2"
  ;MODEL="PSY4V3R1"
  iodir="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"+MODEL+"/timeseries/"
  date="2016-03-01_2016-03-31"
  date="2016-09-01_2016-09-30"
  zone="ANT"
  ;zone="ARC"
  if ( zone .eq. "ARC" ) then 
    zone2="ARC_STR"
  else
    zone2="ANT_STR"
  end if
  variable="mean_diff"
  variable="rms_diff"
  leadtime="hindcast"
  seuil=".20"
  stats_file="Stats_contable_omp_timeseries_"+zone+"_"+date+"_seuil"+seuil+"_best_new.nc"
  print(iodir+stats_file)
  fice    = addfile (iodir+stats_file, "r")
  step  = 1
  name=variable
  ice=fice->$variable$(::step,::step) 
  nb_point=fice->sum_values(::step,::step) 
  ice=where(abs(ice).gt.1e20, ice@_FillValue, ice)
  if (any(isnan_ieee(ice))) then
      value = 0.0
      replace_ieeenan (ice, value, 0)
  end if
  ice = where(nb_point.lt.50,ice@_FillValue,ice)
  ;fillval=default_fillvalue("float")
  ;ice=where(isnan_ieee(ice),fillval,ice)

  ice@lat2d = fice->latitude(::step,::step)
  ice@lon2d = fice->longitude(::step,::step)
  print("ok1")
  ;---create plots
  dir_plot="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"+MODEL+"/Plot_oper/"
  wks = gsn_open_wks("png",dir_plot+"Stats_"+zone+"_"+MODEL+"_class4_aice_"+date+"_"+name+"_"+seuil)       ; open a workspace plot
  ;--- ressources construction 
  res                      = True               ; plot mods desired
  res@gsnFrame                    = False   ; Don't advance the frame
  res@gsnMaximize                 = True    ; Maximize plot in frame
  if ( variable .eq. "mean_diff" ) then
     res@tiMainString  = "Mean Diff ("+MODEL+"-Obs) Ice fraction "+date
     res@cnMinLevelValF       = -0.4            ; set min contour level
     res@cnMaxLevelValF       = 0.4             ; set max contour level
     res@cnLevelSpacingF      = 0.025               ; set contour spacing
     gsn_define_colormap(wks,"NCV_blu_red")  ; choose color map
     res@cnFillPalette    = "NCV_blu_red"   
  else
     res@tiMainString  = "RMS Diff "+MODEL+" Ice fraction "+date
     res@cnMinLevelValF       = 0            ; set min contour level
     res@cnMaxLevelValF       = 0.8             ; set max contour level
     res@cnLevelSpacingF      = 0.05               ; set contour spacing
     ;res@cnLevelSpacingF      = 0.1               ; set contour spacing
     gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")  ; choose color map
     res@cnFillPalette    = "WhiteBlueGreenYellowRed"   
  end if
  print("ok2")
  res@tiMainFontHeightF = 0.0225
  ;res@tiMainOffsetYF =1.0
  res@cnFillOn             = True               ; turn on color for contours
  res@cnLinesOn            =  False             ; turn off contour lines                                                                             
  res@cnLineLabelsOn       = False              ; turn off contour line labels
 ; res@gsnDraw                   = True             ; Dont' draw plot
  res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
  ;res@cnFillMode       = "RasterFill"       ; Raster Mode
  res@mpLandFillColor       = "gray"            ; set land to be gray
  if ( zone .eq. "ARC" ) then 
    res@gsnPolar   = "NH"                         ; specify the hemisphere
    res@mpMinLatF  = 45                           ; minimum lat to plot
    if ( variable .eq. "mean_diff" ) then
     res@cnMinLevelValF       = -0.5            ; set min contour level
     res@cnMaxLevelValF       = 0.5            ; set max contour level
     res@cnLevelSpacingF      = 0.05               ; set contour spacing
    else
     res@cnMinLevelValF       = 0           ; set min contour level
     res@cnMaxLevelValF       = 0.8             ; set max contour level
     res@cnLevelSpacingF      = 0.05              ; set contour spacing
    end if
  else 
    if ( variable .eq. "mean_diff" ) then
     res@cnMinLevelValF       = -1.            ; set min contour level
     res@cnMaxLevelValF       = 1.            ; set max contour level
     res@cnLevelSpacingF      = 0.05               ; set contour spacing
    end if
    res@gsnPolar   = "SH"
    res@mpMinLatF  = -90                            ; minimum lat to plot
    res@mpMaxLatF  = -55                            ; minimum lat to plot
  end if  
  res@mpDataBaseVersion = "MediumRes"


 ;---Panel resources
  res@lbTitleString    =  "Ice Fraction"                                                                                       
  res@lbOrientation            = "Horizontal"     ; vertical label bar
  ;res@lbLabelFontHeightF =.022                 ; make labels larger
  res@lbTitleFontHeightF       = .015
  ;res@pmLabelBarOrthogonalPosF = .10           ; move whole thing down
  res@lbLabelStride            = 4
  print ("OK 1")
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
