load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
  MODEL="PSY4V2R2"
  ;MODEL="PSY4V3R1"
  iodir="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"+MODEL+"/timeseries/"
  dir_plot="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"+MODEL+"/Plot_oper/"
  date="2016-09-01_2016-09-30"
  ;date="2016-03-01_2016-03-31"
  zone="ANT"
  ;zone="ARC"
  seuil=".20"
  ;variable="FalseAlarm"
 ; variable="Hitice"
 ; variable="PCT"
 ; variable="Miss"
 ; lead_time="best"
  lead_time_tab=(/"best"/)
 variable_tab=(/"Hitwater","FalseAlarm","Hitice","Miss"/)
 max_val=(/200.0,200.0,1000.0,50.0/)
 min_val=(/0.0,0.0,0.0,0.0/)
 inter_val=(/20.0,20.0,100.0,2.0/)
 il_ind_var=0
 il_ind=0
 do while (il_ind_var.le.3)
   variable=variable_tab(il_ind_var)
   lead_time=lead_time_tab(il_ind)
   lead_time_var=3
   i=1
   stats_file="Stats_contable_omp_timeseries_"+zone+"_"+date+"_seuil"+seuil+"_best_new.nc"
   varice    = addfile (iodir+"/"+stats_file, "r")
   step  = 1
   name=variable
   ice=varice->$variable$(::step,::step) 
   ice=where(abs(ice).gt.1e20, ice@_FillValue, ice)
   if (any(isnan_ieee(ice))) then
      value = 0.0
      replace_ieeenan (ice, value, 0)
   end if
   print(min_val)
   print(max_val)
   nb_point=varice->sum_values(::step,::step) 
   ice=where(abs(ice).gt.1e20, ice@_FillValue, ice)
   if (any(isnan_ieee(ice))) then
      value = 0.0
      replace_ieeenan (ice, value, 0)
   end if
   ice = where(nb_point.lt.5,ice@_FillValue,ice)
   ice@lat2d = varice->latitude(::step,::step)
   ice@lon2d = varice->longitude(::step,::step)
   ;---create plots
   wks = gsn_open_wks("png",dir_plot+"Stats_"+zone+"_"+MODEL+"_class4_aice_"+date+"_"+name+"_"+seuil)       ; open a workspace plot
   print(dir_plot+"Stats_"+zone+"_"+MODEL+"_class4_aice_"+date+"_"+name+"_"+seuil)
   ;--- ressources construction 
   res                      = True               ; plot mods desired
   res@gsnFrame                    = False   ; Don't advance the frame
   res@gsnMaximize                 = True    ; Maximize plot in frame
   ;  res@tiMainString  = "RMS error "+MODEL+" Ice fraction "+date
   res@cnMinLevelValF       = min_val(il_ind_var)    ; set min contour level
   res@cnMaxLevelValF       = max_val(il_ind_var)    ; set max contour level
   res@cnLevelSpacingF      = inter_val(il_ind_var)  ; set contour spacing
   gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")  ; choose color map
   res@cnFillPalette    = "WhiteBlueGreenYellowRed"   
   res@tiMainFontHeightF = 0.0225
   ;res@tiMainOffsetYF =1.0
   res@cnFillOn             = True               ; turn on color for contours
   res@cnLinesOn            =  False             ; turn off contour lines
   res@cnLineLabelsOn       = False              ; turn off contour line labels
   res@gsnDraw                   = True             ; Dont' draw plot
   res@cnLevelSelectionMode = "ManualLevels"     ; set manual contour levels
   res@mpLandFillColor       = "gray"            ; set land to be gray
   if ( zone .eq. "ARC" ) then 
      res@gsnPolar   = "NH"                         ; specify the hemisphere
      res@mpMinLatF  = 45                           ; minimum lat to plot
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
   res@lbTitleString    =  variable+" for "+MODEL+" "+date
   res@lbTitleFontHeightF       = .015
   res@lbLabelStride            = 4
   print ("OK 1")
   ; Create the map
   plot = gsn_csm_contour_map_polar(wks,ice,res)
   print("ok")
   ;; Overlay the two plots and draw them.
   frame(wks)  
   il_ind_var=il_ind_var+1
 end do
end
