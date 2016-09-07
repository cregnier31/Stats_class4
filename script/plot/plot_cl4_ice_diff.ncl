load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin
    iodir="/homelocal/cregnier/DATA/CLASS4_ICE/"
    all_files = systemfunc ("ls /scratch/work/smer883/class4/PSY4V3R1/aice/class4_*20151*nc")
    rank=(dimsizes(all_files))
    indice=0
    do while(indice.le.rank-1)
        ice_file=all_files(indice)
        print(ice_file)
        str=str_split(ice_file,"_")
        date=str_split(str(1),".")
        str_date=date(0)
        print(ice_file)
        fice    = addfile (ice_file, "r")
        nd    = 0                            ; depth index
        step  = 10
        ice=  fice->best_estimate(::step,0,0) 
        ice_obs=  fice->observation(::step,0,0) 
        diff_ice=ice_obs-ice
        ;ice_obs=ice_obs/100
        ;ice=ice_model
        ;type="model"
        type="diff_obs_model_ARC"
        lat1d= fice->latitude(::step)
        lon1d= fice->longitude(::step)
        nlon=dimsizes(lon1d)
        nlat=dimsizes(lat1d)
        ;---create plots
        wks = gsn_open_wks("png","/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_V4/script/plot/class4_AMSR_"+str_date+"_"+type)       ; open a workspace plot
        ; gsn_define_colormap(wks,"default")
        ; gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")  ; choose color map
        gsn_define_colormap(wks,"seaice_2")
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
        res@tiMainString  = "Class4 Ice fraction AMSR2 diff Obs - Model PSY4V3R1 "+str_date
        res@tiMainFontHeightF = 0.0125
        res@gsnPolar   = "NH"                         ; specify the hemisphere
        res@mpMinLatF  = 60                           ; minimum lat to plot
        ;res@cnFillOn             = True               ; turn on color for contours
        res@cnLinesOn            = False              ; turn off contour lines
        res@cnLineLabelsOn       = False              ; turn off contour line labels
        ; Create the map
        map=gsn_csm_map_polar(wks,res)
        gsres               = True
        gsres@gsMarkerIndex = 16          ; Use filled dots for markers.
        gsres@gsMarkerSizeF = 0.002
        markerid = new(nlevels+1,graphic)
        do i=0,nlevels
            if(i.eq.0) then                         ; first level
               ii := ind(diff_ice.lt.levels(0))
            else if(i.eq.nlevels) then              ; middle levels
               ii := ind(diff_ice.ge.levels(nlevels-1))
            else                                    ; last level
               ii := ind(diff_ice.ge.levels(i-1).and.diff_ice.lt.levels(i))
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
        delete(diff_ice)
        delete(ice)
        delete(ice_obs)
        delete(fice)
        delete(lat1d)
        delete(lon1d)
        delete(nlon)
        delete(nlat)
        indice=indice+1
   end do
end
