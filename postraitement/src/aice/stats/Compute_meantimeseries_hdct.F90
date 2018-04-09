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
  REAL(KIND=4),DIMENSION(:,:,:),POINTER     :: rlpa_mean_diff_cumul_hdct,rlpa_rms_diff_cumul_hdct
  REAL(KIND=4),DIMENSION(:,:,:),POINTER     :: rlpa_nb_cumul
  REAL(KIND=4),DIMENSION(:),POINTER           :: rlpa_time
  REAL(KIND=4),DIMENSION(:,:),POINTER         :: rlpa_lon
  REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE :: rla_mean_diff_cumul_hdct_time,rla_rms_diff_cumul_hdct_time,rla_nb_cumul_time
  REAL(KIND=4),DIMENSION(:),ALLOCATABLE      :: rla_meandiff_hdct,rla_rmsdiff_hdct,rla_sum
  REAL(KIND=4),DIMENSION(:),ALLOCATABLE       :: rla_time
  INTEGER(KIND=4)                             :: il_file,il_file_id,il_i,il_j,il_ji,il_ind_time,il_ind_time2,il_nb_time,&
                                                 il_narg,iargc,il_nbdim,il_nb_echeance,il_nbtime,il_nlon,il_nlat
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
  il_nbtime=0
  !* First loop to find the dimension of time
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
                & TRIM(cl_year)//"_"//TRIM(cl_month)//"_timeseries_aice_best.nc"
     INQUIRE(FILE=cl_input,EXIST=ll_exist)
     IF ( ll_exist)  THEN
         WRITE (0,*) 'File exist'
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
  il_nb_echeance=6
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
              & TRIM(cl_year)//"_"//TRIM(cl_month)//"_timeseries_aice_best.nc"
     INQUIRE(FILE=cl_input,EXIST=ll_exist)
     IF ( ll_exist)  THEN
         WRITE (0,*) 'File exist'
         WRITE(0,*) 'Open file'
         CALL MIOL_openr_file_NC(cl_input,il_file)
         IF ( il_i ==1 ) THEN
            CALL MIOL_read_field_NC(il_file,'longitude',rlpa_lon,ila2D)
            il_nlon=ila2D(1)
            il_nlat=ila2D(2)
         ENDIF
         WRITE(0,*) 'Read OK1'
         CALL MIOL_read_field_NC(il_file,'time',rlpa_time,ila_time)
         WRITE(0,*) 'Read OK2'
         CALL MIOL_read_field_NC(il_file,'mean_diff_cumul_best',rlpa_mean_diff_cumul_hdct,ila3D)   
         WHERE(rlpa_mean_diff_cumul_hdct > 1.e20) rlpa_mean_diff_cumul_hdct=0
         WHERE(rlpa_mean_diff_cumul_hdct < -1.e10) rlpa_mean_diff_cumul_hdct=0
         WRITE(0,*) 'Read OK3'
         CALL MIOL_read_field_NC(il_file,'rms_diff_cumul_best',rlpa_rms_diff_cumul_hdct,ila3D)   
         WHERE(rlpa_rms_diff_cumul_hdct > 1.e20) rlpa_rms_diff_cumul_hdct=0
         WHERE(rlpa_rms_diff_cumul_hdct < -1.e10) rlpa_rms_diff_cumul_hdct=0
         WRITE(0,*) 'Read OK4'
         CALL MIOL_read_field_NC(il_file,'nb_cumul',rlpa_nb_cumul,ila3D)
         WRITE(0,*) 'Read OK5'
         WRITE(0,*) ila2D(:)
         IF ( il_i ==1 ) THEN
            ALLOCATE(rla_mean_diff_cumul_hdct_time(il_nlon,il_nlat,il_nbtime))
            ALLOCATE(rla_rms_diff_cumul_hdct_time(il_nlon,il_nlat,il_nbtime))
            ALLOCATE(rla_nb_cumul_time(il_nlon,il_nlat,il_nbtime))
            ALLOCATE(rla_time(il_nbtime))
         ENDIF
         il_nb_time=ila_time(1)
         WRITE(0,*) "Dimension time",il_nb_time
         il_ind_time2=il_ind_time2+il_nb_time
         WRITE(0,*) "Fead mean_diff_cumul",il_ind_time,il_ind_time2
         rla_mean_diff_cumul_hdct_time(:,:,il_ind_time:il_ind_time2)=rlpa_mean_diff_cumul_hdct(:,:,:)
         WRITE(0,*) "Fead rms_diff_cumul"
         rla_rms_diff_cumul_hdct_time(:,:,il_ind_time:il_ind_time2)=rlpa_rms_diff_cumul_hdct(:,:,:)
         WRITE(0,*) "Fead nb cumul"
         rla_nb_cumul_time(:,:,il_ind_time:il_ind_time2)=rlpa_nb_cumul(:,:,:)
         WRITE(0,*) "Fead nb time"
         rla_time(il_ind_time:il_ind_time2)=rlpa_time(:)
         WRITE(0,*) "Month ok",TRIM(cl_month),il_ind_time,il_ind_time2
         il_ind_time=il_ind_time+il_nb_time
         CALL MIOL_close_file_NC(il_file)
         DEALLOCATE(rlpa_mean_diff_cumul_hdct)
         DEALLOCATE(rlpa_rms_diff_cumul_hdct)
         DEALLOCATE(rlpa_nb_cumul)
         DEALLOCATE(rlpa_time)    
     ELSE
        WRITE (0,*) 'File don t exist'
     ENDIF
  ENDDO
  !** Compute Final statistics
  ALLOCATE(rla_sum(il_nbtime),rla_meandiff_hdct(il_nbtime),rla_rmsdiff_hdct(il_nbtime))
  rla_meandiff_hdct(:)  = 0
  rla_rmsdiff_hdct(:)  =  0
  rla_sum(:)=0
  
  DO il_j=1,il_nbtime
       rla_meandiff_hdct(il_j)=SUM(rla_mean_diff_cumul_hdct_time(:,:,il_j))/SUM(rla_nb_cumul_time(:,:,il_j))
       IF ( rla_meandiff_hdct(il_j) < -0.8 ) THEN 
          WRITE(0,*) 'Problem with time ',il_j
          WRITE(0,*) rla_time(il_j)/86400
       ENDIF
       rla_rmsdiff_hdct(il_j)=SQRT(SUM(rla_rms_diff_cumul_hdct_time(:,:,il_j))/SUM(rla_nb_cumul_time(:,:,il_j)))
       rla_sum(il_j)=SUM(rla_nb_cumul_time(:,:,il_j))
  ENDDO
  !!** Print output values
  il_nbdim=1
  ALLOCATE(cla_dimname(il_nbdim))
  ALLOCATE(ila_dimlen(il_nbdim))
  cla_dimname(1)=  'time'
  ila_dimlen(1) = il_nbtime

  cl_stats=TRIM(cl_stats_dir)//'Stats_timeseries_'//TRIM(cl_zone)//'_'//TRIM(cl_model)//'_'//TRIM(cl_year)//'_'//TRIM(cl_leadtime)//'.nc'
  WRITE(0,*) 'Fichier stats ',cl_stats
  call MIOL_create_file_NC(TRIM(cl_stats),&
                           il_nbdim,&
                           cla_dimname,&
                           ila_dimlen)
  call MIOL_openw_file_NC(TRIM(cl_stats), il_file_id)
  call MIOL_write_field_NC (il_file_id,&
                            'time',&
                            'T',&
                            rla_time)
  call MIOL_write_field_NC (il_file_id,&
                            'mean_diff',&
                            'T',&
                             rla_meandiff_hdct)
  call MIOL_write_field_NC (il_file_id,&
                            'rms_diff',&
                            'T',&
                            rla_rmsdiff_hdct)  
  call MIOL_write_field_NC (il_file_id,&
                            'sum',&
                            'T',&
                            rla_sum)  
  CALL MIOL_close_file_NC(il_file_id)
  
END PROGRAM Stats_aice_final
