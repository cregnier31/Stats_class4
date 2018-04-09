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
  REAL(KIND=4),DIMENSION(:,:),POINTER         :: rlpa_lon
  REAL(KIND=4),DIMENSION(:,:),POINTER         :: rlpa_Hitice,rlpa_Miss,rlpa_FalseAlarm,rlpa_Hitwater,rlpa_sum
!  REAL(KIND=4),DIMENSION(:,:,:,:),ALLOCATABLE :: rla_Hitice_cumul,rla_miss_cumul,rla_Hitwater_cumul,&
!                                                 rla_FalseAlarm_cumul
  REAL(KIND=4),DIMENSION(:),ALLOCATABLE       :: rla_PCI,rla_PCW,rla_PCT,rla_BIAS,rla_nb_cumul
  INTEGER(KIND=4)                             :: il_file,il_file_id,il_i,il_j,il_ji,&
                                                 il_nbtime,il_narg,iargc,il_nbdim,il_nb_echeance,il_nlon,il_nlat
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
  il_nbtime=12
  DO il_i=1,il_nbtime
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
            il_nlon=ila2D(1)
            il_nlat=ila2D(2)
         ENDIF
         CALL MIOL_read_field_NC(il_file,'Hitice',rlpa_Hitice,ila2D)
         CALL MIOL_read_field_NC(il_file,'Miss',rlpa_Miss,ila2D)
         CALL MIOL_read_field_NC(il_file,'FalseAlarm',rlpa_FalseAlarm,ila2D)
         CALL MIOL_read_field_NC(il_file,'Hitwater',rlpa_Hitwater,ila2D)
         CALL MIOL_read_field_NC(il_file,'sum_values',rlpa_sum,ila2D)
         CALL MIOL_close_file_NC(il_file)
         IF ( il_i ==1 ) THEN
            ALLOCATE(rla_PCI(il_nbtime),rla_PCW(il_nbtime))
            ALLOCATE(rla_PCT(il_nbtime),rla_BIAS(il_nbtime))
            ALLOCATE(rla_nb_cumul(il_nbtime))
            rla_nb_cumul(:)=0.0
            rla_PCI(:)=0.0
            rla_PCT(:)=0.0
            rla_PCW(:)=0.0
            rla_BIAS(:)=0.0
         ENDIF
         WHERE( rlpa_Hitwater .eq. rg_fillvalue ) rlpa_Hitwater=0.0
         WHERE( rlpa_FalseAlarm .eq. rg_fillvalue ) rlpa_FalseAlarm=0.0
         WHERE( rlpa_Hitice .eq. rg_fillvalue ) rlpa_Hitice=0.0
         WHERE( rlpa_Miss .eq. rg_fillvalue ) rlpa_Miss=0.0
         WHERE(rlpa_sum .eq. rg_fillvalue ) rlpa_sum=0.0
         rla_PCI(il_i)=SUM(rlpa_Hitice(:,:))/(SUM(rlpa_Hitice(:,:))+SUM(rlpa_Miss(:,:)))
         rla_PCT(il_i)=(SUM(rlpa_Hitice(:,:))+SUM(rlpa_Hitwater(:,:)))/SUM(rlpa_sum(:,:))
         rla_PCW(il_i)=SUM(rlpa_Hitwater(:,:))/(SUM(rlpa_FalseAlarm(:,:))+SUM(rlpa_Hitwater(:,:)))
         rla_BIAS(il_i)=(SUM(rlpa_Hitice(:,:))+SUM(rlpa_FalseAlarm(:,:)))/(SUM(rlpa_Hitice(:,:))+SUM(rlpa_Miss(:,:)))
         rla_nb_cumul(il_i)=SUM(rlpa_sum(:,:))
         DEALLOCATE(rlpa_Hitice)
         DEALLOCATE(rlpa_Miss)
         DEALLOCATE(rlpa_FalseAlarm)
         DEALLOCATE(rlpa_Hitwater)
         DEALLOCATE(rlpa_sum)
     ELSE
        WRITE (0,*) 'File don t exist'
     ENDIF
  ENDDO
  !! Compute Quantities
  !WHERE(rla_nb_cumul .lt. 100 ) rla_nb_cumul=rg_fillvalue
  WHERE( isnan(rla_PCI) ) rla_PCI=rg_fillvalue 
  WHERE( isnan(rla_PCW) ) rla_PCW=rg_fillvalue 
  WHERE( isnan(rla_PCT) ) rla_PCT=rg_fillvalue 
  WHERE( isnan(rla_BIAS) ) rla_BIAS=rg_fillvalue 
  WHERE( isnan(rla_nb_cumul) ) rla_nb_cumul=rg_fillvalue 
  !!** Print output values
  il_nbdim=1
  ALLOCATE(cla_dimname(il_nbdim))
  ALLOCATE(ila_dimlen(il_nbdim))
  cla_dimname(1)=  'time'
  ila_dimlen(1) = il_nbtime

  cl_stats=TRIM(cl_stats_dir)//'Stats_timeseries_skill_'//TRIM(cl_zone)//'_'//TRIM(cl_model)//'_'//TRIM(cl_year)//'_'//TRIM(cl_leadtime)//'.nc'
  WRITE(0,*) 'Fichier stats ',cl_stats
  call MIOL_create_file_NC(TRIM(cl_stats),&
                           il_nbdim,&
                           cla_dimname,&
                           ila_dimlen)
  call MIOL_openw_file_NC(TRIM(cl_stats), il_file_id)
  call MIOL_write_field_NC (il_file_id,&
                            'PCI',&
                            'T',&
                            rla_PCI)  
  call MIOL_write_field_NC (il_file_id,&
                            'PCW',&
                            'T',&
                            rla_PCW)  
  call MIOL_write_field_NC (il_file_id,&
                            'PCT',&
                            'T',&
                            rla_PCT)  
  call MIOL_write_field_NC (il_file_id,&
                            'BIAS',&
                            'T',&
                            rla_BIAS)  
  call MIOL_write_field_NC (il_file_id,&
                            'sum',&
                            'T',&
                             rla_nb_cumul)  
  CALL MIOL_close_file_NC(il_file_id)
  
END PROGRAM Stats_aice_final
