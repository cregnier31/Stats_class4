  PROGRAM Stats_aice_final
  !
  !
  !     History
  !     -------
  !      Version    Programmer    Date       Description
  !      ---------------------------------------------
  !       1.0       C.REGNIER    23/03/2016   created
  !
  !** ++  MODULES used
  !  
  USE MIOL
  USE MCAL
  USE netcdf
  !
  !** ++  Local Declarations
  !
  IMPLICIT NONE
  CHARACTER(LEN=256)                          :: cl_leadtime,format_string,cl_input,cl_stats_dir,cl_stats,cl_zone,cl_model,cl_year,cl_month
  CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE :: cla_dimname,cla_dataFile
  REAL(KIND=4),DIMENSION(:,:),POINTER         :: rlpa_lon,rlpa_lat
  REAL(KIND=4),DIMENSION(:,:,:),POINTER       :: rlpa_Hitice,rlpa_Miss,rlpa_FalseAlarm,rlpa_Hitwater,rlpa_sum
  REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE   :: rla_nb_cumul
  REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE   :: rla_Hitice_cumul,rla_miss_cumul,rla_Hitwater_cumul,&
                                                 rla_FalseAlarm_cumul,rla_PCI,rla_PCW,rla_PCT,rla_BIAS
  INTEGER(KIND=4)                             :: il_file,il_file_id,il_i,il_j,il_ji,&
                                                 il_narg,iargc,il_nbdim,il_nb_echeance,il_nlon,il_nlat
  LOGICAL                                     :: ll_exist
  INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE    :: ila_dimlen
  INTEGER(KIND=4),DIMENSION(2)                :: ila2D
  INTEGER(KIND=4),DIMENSION(4)                :: ila4D
  INTEGER(KIND=4),DIMENSION(3)                :: ila3D
  INTEGER(KIND=4),DIMENSION(1)                :: ila_time


  il_narg=iargc()
  IF (il_narg.NE.10) THEN
     PRINT *,' '
     PRINT *,' Compute seaice usage : '
     PRINT *,' -p path : stats_dir'
     PRINT *,' -m model : modele '
     PRINT *,' -z choose ARC or ANT '
     PRINT *,' -l leadtime'
     PRINT *,' -y year'
     STOP
  ELSE
     DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-p') THEN
           CALL getarg(il_ji+1, cl_stats_dir)
        ELSE IF(cl_input .EQ. '-m') THEN
           CALL getarg(il_ji+1, cl_model)
        ELSE IF(cl_input .EQ. '-z') THEN
           CALL getarg(il_ji+1, cl_zone)
        ELSE IF(cl_input .EQ. '-l') THEN
           CALL getarg(il_ji+1, cl_leadtime)
        ELSE IF(cl_input .EQ. '-y') THEN
           CALL getarg(il_ji+1, cl_year)
        ENDIF
     ENDDO
  ENDIF
  !** Second loop to threat all the statistics
  DO il_i=1,12
     if (il_i < 10) then
        format_string = "(A1,I1)"
        write (cl_month,format_string) "0",il_i
      else
        format_string = "(I2)"
        write (cl_month,format_string) il_i
     endif
     print *, trim(cl_month)
     cl_input=TRIM(cl_stats_dir)//"Stats_contable_"//TRIM(cl_zone)//"_"//TRIM(cl_model)//"_"// &
              & TRIM(cl_year)//"_"//TRIM(cl_month)//"_"//TRIM(cl_leadtime)//"_aice.nc"
     INQUIRE(FILE=cl_input,EXIST=ll_exist)
     WRITE(0,*) "File :",cl_input
     IF ( ll_exist)  THEN
         WRITE (0,*) 'File exist'
         WRITE(0,*) 'Open file'
         CALL MIOL_openr_file_NC(cl_input,il_file)
         IF ( il_i ==1 ) THEN
            CALL MIOL_read_field_NC(il_file,'longitude',rlpa_lon,ila2D)
            CALL MIOL_read_field_NC(il_file,'latitude',rlpa_lat,ila2D)
            il_nlon=ila2D(1)
            il_nlat=ila2D(2)
         ENDIF
         CALL MIOL_read_field_NC(il_file,'Hitice',rlpa_Hitice,ila3D)
         CALL MIOL_read_field_NC(il_file,'Miss',rlpa_Miss,ila3D)
         CALL MIOL_read_field_NC(il_file,'FalseAlarm',rlpa_FalseAlarm,ila3D)
         CALL MIOL_read_field_NC(il_file,'Hitwater',rlpa_Hitwater,ila3D)
         CALL MIOL_read_field_NC(il_file,'sum_values',rlpa_sum,ila3D)
         CALL MIOL_close_file_NC(il_file)
         il_nb_echeance=ila3D(3)
         IF ( il_i ==1 ) THEN
            ALLOCATE(rla_Hitice_cumul(il_nlon,il_nlat,il_nb_echeance),rla_miss_cumul(il_nlon,il_nlat,il_nb_echeance))
            ALLOCATE(rla_Hitwater_cumul(il_nlon,il_nlat,il_nb_echeance),rla_FalseAlarm_cumul(il_nlon,il_nlat,il_nb_echeance))
            ALLOCATE(rla_nb_cumul(il_nlon,il_nlat,il_nb_echeance))
            rla_Hitice_cumul(:,:,:)=0.0
            rla_Hitwater_cumul(:,:,:)=0.0
            rla_miss_cumul(:,:,:)=0.0
            rla_FalseAlarm_cumul(:,:,:)=0.0
            rla_nb_cumul(:,:,:)=0.0
         ENDIF
         WHERE( rlpa_Hitwater .eq. rg_fillvalue ) rlpa_Hitwater=0.0
         WHERE( rlpa_FalseAlarm .eq. rg_fillvalue ) rlpa_FalseAlarm=0.0
         WHERE( rlpa_Hitice .eq. rg_fillvalue ) rlpa_Hitice=0.0
         WHERE( rlpa_Miss .eq. rg_fillvalue ) rlpa_Miss=0.0
         WHERE(rlpa_sum .eq. rg_fillvalue ) rlpa_sum=0.0
         rla_nb_cumul(:,:,:)=rla_nb_cumul(:,:,:)+rlpa_sum(:,:,:)
         rla_Hitwater_cumul(:,:,:)=rla_Hitwater_cumul(:,:,:)+rlpa_Hitwater(:,:,:)
         rla_FalseAlarm_cumul(:,:,:)=rla_FalseAlarm_cumul(:,:,:)+rlpa_FalseAlarm(:,:,:)
         rla_Hitice_cumul(:,:,:)=rla_Hitice_cumul(:,:,:)+rlpa_Hitice(:,:,:)
         rla_miss_cumul(:,:,:)=rla_miss_cumul(:,:,:)+rlpa_Miss(:,:,:)
         DEALLOCATE(rlpa_Hitice)
         DEALLOCATE(rlpa_Miss)
         DEALLOCATE(rlpa_FalseAlarm)
         DEALLOCATE(rlpa_Hitwater)
         DEALLOCATE(rlpa_sum)
     ELSE
        WRITE (0,*) 'File don t exist'
     ENDIF
  ENDDO
  ALLOCATE(rla_PCI(il_nlon,il_nlat,il_nb_echeance),rla_PCW(il_nlon,il_nlat,il_nb_echeance))
  ALLOCATE(rla_PCT(il_nlon,il_nlat,il_nb_echeance),rla_BIAS(il_nlon,il_nlat,il_nb_echeance))
  !! Compute Quantities
  WHERE(rla_nb_cumul .lt. 200 ) rla_nb_cumul=-rg_fillvalue
  !WHERE( rla_Hitwater_cumul .eq. 0 ) rla_Hitwater_cumul=rg_fillvalue
  !WHERE( rla_FalseAlarm_cumul .eq. 0 ) rla_FalseAlarm_cumul=rg_fillvalue
  !WHERE( rla_miss_cumul .eq. 0 ) rla_miss_cumul=rg_fillvalue
  !WHERE( rla_Hitice_cumul .eq. 0 ) rla_Hitice_cumul=rg_fillvalue
  rla_PCI(:,:,:)=rla_Hitice_cumul(:,:,:)/(rla_Hitice_cumul(:,:,:)+rla_miss_cumul(:,:,:))
  rla_PCW(:,:,:)=rla_Hitwater_cumul(:,:,:)/(rla_FalseAlarm_cumul(:,:,:)+rla_Hitwater_cumul(:,:,:))
  rla_PCT(:,:,:)=(rla_Hitice_cumul(:,:,:)+rla_Hitwater_cumul(:,:,:))/(rla_nb_cumul(:,:,:))
  rla_BIAS(:,:,:)=(rla_Hitice_cumul(:,:,:)+rla_FalseAlarm_cumul(:,:,:))/(rla_Hitice_cumul(:,:,:)+rla_miss_cumul(:,:,:))
  WHERE( isnan(rla_PCI) ) rla_PCI=rg_fillvalue 
  WHERE( isnan(rla_PCW) ) rla_PCW=rg_fillvalue 
  WHERE(rla_nb_cumul .lt. 200 ) rla_PCW=rg_fillvalue
  WHERE( isnan(rla_PCT) ) rla_PCT=rg_fillvalue 
  WHERE(rla_PCT .LE. 0 ) rla_PCT=rg_fillvalue
  WHERE(rla_BIAS .LE. 0 ) rla_BIAS=rg_fillvalue
  WHERE(rla_PCW .LE. 0 ) rla_PCW=rg_fillvalue
  WHERE(rla_PCI .LE. 0 ) rla_PCI=rg_fillvalue
  WHERE( isnan(rla_BIAS) ) rla_BIAS=rg_fillvalue 
  !!** Print output values
  il_nbdim=3
  ALLOCATE(cla_dimname(il_nbdim))
  ALLOCATE(ila_dimlen(il_nbdim))
  cla_dimname(1) = 'x' 
  cla_dimname(2)=  'y'
  cla_dimname(3)=  'z'
  ila_dimlen(1) = il_nlon
  ila_dimlen(2) = il_nlat
  ila_dimlen(3) = il_nb_echeance

  cl_stats=TRIM(cl_stats_dir)//'Stats_contable_skill_'//TRIM(cl_zone)//'_'//TRIM(cl_model)//'_'//TRIM(cl_year)//'_'//TRIM(cl_leadtime)//'.nc'
  WRITE(0,*) 'Fichier stats ',cl_stats
  call MIOL_create_file_NC(TRIM(cl_stats),&
                           il_nbdim,&
                           cla_dimname,&
                           ila_dimlen)
  call MIOL_openw_file_NC(TRIM(cl_stats), il_file_id)
  call MIOL_write_field_NC (il_file_id,&
                            'longitude',&
                            'XY',&
                            rlpa_lon) 
  call MIOL_write_field_NC (il_file_id,&
                            'latitude',&
                            'XY',&
                             rlpa_lat)
  call MIOL_write_field_NC (il_file_id,&
                            'PCI',&
                            'XYZ',&
                            rla_PCI)  
  call MIOL_write_field_NC (il_file_id,&
                            'PCW',&
                            'XYZ',&
                            rla_PCW)  
  call MIOL_write_field_NC (il_file_id,&
                            'PCT',&
                            'XYZ',&
                            rla_PCT)  
  call MIOL_write_field_NC (il_file_id,&
                            'BIAS',&
                            'XYZ',&
                            rla_BIAS)  
  call MIOL_write_field_NC (il_file_id,&
                            'sum',&
                            'XYZ',&
                             rla_nb_cumul)  
  CALL MIOL_close_file_NC(il_file_id)
  
END PROGRAM Stats_aice_final
