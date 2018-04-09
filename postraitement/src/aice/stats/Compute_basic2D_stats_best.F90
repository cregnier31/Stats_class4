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
  REAL(KIND=4),DIMENSION(:,:,:),POINTER       :: rlpa_mean_diff_cumul,rlpa_rms_diff_cumul
  REAL(KIND=4),DIMENSION(:,:,:,:),POINTER     :: rlpa_nb_cumul
  REAL(KIND=4),DIMENSION(:),POINTER           :: rlpa_time
  REAL(KIND=4),DIMENSION(:,:),POINTER         :: rlpa_lon,rlpa_lat
  REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE   :: rla_rms_diff_cumul_time,rla_nb_cumul_time,rla_mean_diff_cumul_time
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE     :: rla_meandiff,rla_rmsdiff,rla_sum
  REAL(KIND=4),DIMENSION(:),ALLOCATABLE       :: rla_time
  INTEGER(KIND=4)                             :: il_file,il_file_id,il_i,il_j,il_ji,il_ind_time,il_ind_time2,il_nb_time,&
                                                 il_narg,iargc,il_nbdim,il_nbtime,il_nlon,il_nlat
  LOGICAL                                     :: ll_exist
  INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE    :: ila_dimlen
  INTEGER(KIND=4),DIMENSION(2)                :: ila2D
  INTEGER(KIND=4),DIMENSION(3)                :: ila3D
  INTEGER(KIND=4),DIMENSION(4)                :: ila4D
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
  il_nbtime=0
  !* First loop to find the dimension of time
  DO il_i=1,1
     if (il_i < 10) then
        format_string = "(A1,I1)"
        write (cl_month,format_string) "0",il_i
      else
        format_string = "(I2)"
        write (cl_month,format_string) il_i
     endif
     print *, trim(cl_month)
     !   cl_input=TRIM(cl_stats_dir)//"Stats_contable_"//TRIM(cl_zone)//"_"//TRIM(cl_model)//"_"// &
     !           & TRIM(cl_year)//"_"//TRIM(cl_month)//"_timeseries_aice_"//TRIM(cl_leadtime)//".nc"
     cl_input=TRIM(cl_stats_dir)//"Stats_contable_"//TRIM(cl_zone)//"_"//TRIM(cl_model)//"_"// &
                & TRIM(cl_year)//"_trim1_timeseries_aice_fcst.nc"

     INQUIRE(FILE=cl_input,EXIST=ll_exist)
     IF ( ll_exist)  THEN
         WRITE (0,*) 'File exist : ',cl_input
         WRITE(0,*) 'Open file'
         CALL MIOL_openr_file_NC(cl_input,il_file)
         CALL MIOL_read_field_NC(il_file,'time',rlpa_time,ila_time)
         WRITE(0,*) "Dimension time",ila_time(1)
         il_nbtime=il_nbtime+ila_time(1)
     ENDIF
  ENDDO

  WRITE(0,*) "Dimension Time final",il_nbtime
  il_ind_time=1
  il_ind_time2=0
  !** Second loop to threat all the statistics
  DO il_i=1,1
     if (il_i < 10) then
        format_string = "(A1,I1)"
        write (cl_month,format_string) "0",il_i
      else
        format_string = "(I2)"
        write (cl_month,format_string) il_i
     endif
     print *, trim(cl_month)
     !cl_input=TRIM(cl_stats_dir)//"Stats_contable_"//TRIM(cl_zone)//"_"//TRIM(cl_model)//"_"// &
     !         & TRIM(cl_year)//"_"//TRIM(cl_month)//"_timeseries_aice_"//TRIM(cl_leadtime)//".nc"
     cl_input=TRIM(cl_stats_dir)//"Stats_contable_"//TRIM(cl_zone)//"_"//TRIM(cl_model)//"_"// &
                & TRIM(cl_year)//"_trim1_timeseries_aice_fcst.nc"
     print *,'cl_input : ',cl_input
     INQUIRE(FILE=cl_input,EXIST=ll_exist)
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
         WRITE(0,*) 'Read OK1'
         CALL MIOL_read_field_NC(il_file,'time',rlpa_time,ila_time)
         WRITE(0,*) 'Read OK2'
         CALL MIOL_read_field_NC(il_file,'mean_diff_cumul_best',rlpa_mean_diff_cumul,ila3D)   
         WHERE(rlpa_mean_diff_cumul > 1.e20) rlpa_mean_diff_cumul=0
         WHERE(rlpa_mean_diff_cumul < -1.e10) rlpa_mean_diff_cumul=0
         WRITE(0,*) 'Read OK3'
         CALL MIOL_read_field_NC(il_file,'rms_diff_cumul_best',rlpa_rms_diff_cumul,ila3D)   
         WHERE(rlpa_rms_diff_cumul > 1.e20) rlpa_rms_diff_cumul=0
         WHERE(rlpa_rms_diff_cumul < -1.e10) rlpa_rms_diff_cumul=0
         WRITE(0,*) 'Read OK4'
         CALL MIOL_read_field_NC(il_file,'nb_cumul',rlpa_nb_cumul,ila4D)
         WRITE(0,*) 'Read OK5 : ',shape(rlpa_nb_cumul)
         IF ( il_i ==1 ) THEN
            ALLOCATE(rla_rms_diff_cumul_time(il_nlon,il_nlat,il_nbtime))
            ALLOCATE(rla_mean_diff_cumul_time(il_nlon,il_nlat,il_nbtime))
            ALLOCATE(rla_nb_cumul_time(il_nlon,il_nlat,il_nbtime))
            ALLOCATE(rla_time(il_nbtime))
         ENDIF
         il_nb_time=ila_time(1)
         WRITE(0,*) "Dimension time",il_nb_time
         il_ind_time2=il_ind_time2+il_nb_time
         WRITE(0,*) "Fead mean_diff_cumul",il_ind_time,il_ind_time2
         rla_mean_diff_cumul_time(:,:,il_ind_time:il_ind_time2)=rlpa_mean_diff_cumul(:,:,:)
         WRITE(0,*) "Fead rms_diff_cumul"
         rla_rms_diff_cumul_time(:,:,il_ind_time:il_ind_time2)=rlpa_rms_diff_cumul(:,:,:)
         WRITE(0,*) "Fead nb cumul"
         WRITE(0,*) shape(rla_nb_cumul_time)
         rla_nb_cumul_time(:,:,il_ind_time:il_ind_time2)=rlpa_nb_cumul(:,:,:,1)
         WRITE(0,*) "Fead nb time"
         rla_time(il_ind_time:il_ind_time2)=rlpa_time(:)
         WRITE(0,*) "Month ok",TRIM(cl_month),il_ind_time,il_ind_time2
         il_ind_time=il_ind_time+il_nb_time
         CALL MIOL_close_file_NC(il_file)
         DEALLOCATE(rlpa_mean_diff_cumul)
         DEALLOCATE(rlpa_rms_diff_cumul)
         DEALLOCATE(rlpa_nb_cumul)
         DEALLOCATE(rlpa_time)    
     ELSE
        WRITE (0,*) 'File don t exist'
     ENDIF
  ENDDO
  !** Compute Final statistics
  ALLOCATE(rla_sum(il_nlon,il_nlat),rla_meandiff(il_nlon,il_nlat),rla_rmsdiff(il_nlon,il_nlat))
  rla_meandiff(:,:)  = 0
  rla_rmsdiff(:,:)  =  0
  rla_sum(:,:)=0
  
  DO il_i=1,il_nlon
    DO il_j=1,il_nlat
        IF (SUM(rla_nb_cumul_time(il_i,il_j,:) ) > 0 ) THEN 
            rla_meandiff(il_i,il_j)=SUM(rla_mean_diff_cumul_time(il_i,il_j,:))/SUM(rla_nb_cumul_time(il_i,il_j,:))
            rla_rmsdiff(il_i,il_j)=SQRT(SUM(rla_rms_diff_cumul_time(il_i,il_j,:))/SUM(rla_nb_cumul_time(il_i,il_j,:)))
            rla_sum(il_i,il_j)=SUM(rla_nb_cumul_time(il_i,il_j,:))
        ELSE
            rla_meandiff(il_i,il_j)=rg_FillValue
            rla_rmsdiff(il_i,il_j)=rg_FillValue
        ENDIF
    ENDDO
  ENDDO
  WHERE(rla_sum .lt. 100 ) rla_rmsdiff=rg_fillvalue
  WHERE(rla_sum .lt. 100 ) rla_meandiff=rg_fillvalue
  !!** Print output values
  il_nbdim=2
  ALLOCATE(cla_dimname(il_nbdim))
  ALLOCATE(ila_dimlen(il_nbdim))
  cla_dimname(1) = 'x'
  cla_dimname(2) = 'y'
  ila_dimlen(1) = il_nlon
  ila_dimlen(2) = il_nlat

  cl_stats=TRIM(cl_stats_dir)//'Stats_basics2D_'//TRIM(cl_zone)//'_'//TRIM(cl_model)//'_'//TRIM(cl_year)//'_'//TRIM(cl_leadtime)//'.nc'
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
                            'mean_diff',&
                            'XY',&
                             rla_meandiff)
  call MIOL_write_field_NC (il_file_id,&
                            'rms_diff',&
                            'XY',&
                            rla_rmsdiff)  
  call MIOL_write_field_NC (il_file_id,&
                            'sum',&
                            'XY',&
                            rla_sum)  
  CALL MIOL_close_file_NC(il_file_id)
  
END PROGRAM Stats_aice_final
