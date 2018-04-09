PROGRAM Stats_aice
  !
  !**** Stats_aice_class4
  !
  !     Purpose :
  !     Read Class4 aice coming from GIOPS, find position in a stereopolar analysis grid, compute statistics in the grid
  !     la validation des fichiers enrichis
  !
  !***  Method  :    Step 1
  !                  Read Class4 file
  !                  Read Mask File 
  !                  Step 2
  !                  Find cell of each observation in the analysis grid
  !                  Step 3
  !                  Compute classical statistics Mean/RMS/Meancumul/RMScumul 
  !     Externals :  MIOL_getFreeLu
  !                 MIOL_read_field_NC,MIOL_create_file_NC,MIOL_openw_file_NC
  !                 MIOL_write_field_NC,MIOL_close_file_NC
  !                 read_profile,valid_profile,stat_boite_class4,fermer_table_argo
  !                 LireDefBoite,ChargerBathy,FermerBathy
  !     Files :
  !     References:
  !
  !     History
  !     -------
  !      Version    Programmer    Date       Description
  !      ---------------------------------------------
  !       1.0       C.REGNIER    25/03/2015   created
  !
  !** ++  MODULES used
  !  
  USE miol
  USE mcal
  USE netcdf
  USE boite_bins
  USE table_boite
  USE Canvas
  USE geomlibcha
  USE omp_lib
!  USE MPI
  !
  !** ++  Local Declarations
  !
  IMPLICIT NONE
  CHARACTER(LEN=256)                         :: cl_input,cl_stats_1,cl_stats_2,cl_maskfile,cl_filein,cl_colocFile,cl_namelist,cl_nproc,cl_path
  CHARACTER(LEN=40)                          :: cl_lon,cl_lat,cl_var,cl_var1,cl_var2,cl_var3,cl_qc,cl_varobs,cl_zone,cl_conf,cl_date
  CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE  :: cla_dimname,cla_dataFile

  REAL(KIND=4),DIMENSION(:),POINTER          :: rlpa_lon,rlpa_lat
  REAL(KIND=4),DIMENSION(:,:),POINTER        :: rlpa_x,rlpa_y
  REAL(KIND=4),DIMENSION(:),ALLOCATABLE      :: rla_fcst,rla_pers
  REAL(KIND=4),DIMENSION(:,:),POINTER        :: rlpa_lonm,rlpa_latm
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE    :: rla_sumsqrt,rla_diff,rla_hitice,rla_falsealarm,rla_miss,rla_hitwater,&
                                                rla_PCI,rla_PCW,rla_PCT,rla_BIAS
  REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    ::  rla_tmp,rla_sum,rla_diff_fcst,rla_sumsqrt_fcst,rla_diff_pers,rla_sumsqrt_pers,&
                                                   rla_PCI_fcst,rla_PCW_fcst,rla_PCT_fcst,rla_BIAS_fcst,&
                                                   rla_PCI_pers,rla_PCW_pers,rla_PCT_pers,rla_BIAS_pers,&
                                                   rla_hitice_fcst,rla_falsealarm_fcst,rla_miss_fcst,rla_hitwater_fcst,&
                                                   rla_hitice_pers,rla_falsealarm_pers,rla_miss_pers,rla_hitwater_pers
  INTEGER(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    :: ila_n
  REAL(KIND=4), DIMENSION(4)                 :: rla_poids_vertex,rla_dist_vertex
  REAL(KIND=4)      , DIMENSION(:,:,:), POINTER   :: rlpa_var,rlpa_varobs,rlpa_QC02,rlpa_QC07        
  REAL(KIND=4)      , DIMENSION(:,:,:,:), POINTER  :: rlpa_var4D_fcst,rlpa_var4D_pers
  REAL(KIND=4)                               :: rl_varconc,rl_seuil,rl_seuil2,rl_ana,rl_tmp_fcst,rl_tmp_pers,rl_diff_fcst,rl_diff_pers
  REAL(KIND=4)                               :: rl_sum2,rl_diff,rl_diffsqr,rl_lon,rl_lat,rl_IDboite,rl_latmin,rl_latmax
  INTEGER(KIND=4),DIMENSION(:,:,:),POINTER   :: ilpa_mask
  INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE   :: ila_dimlen
  INTEGER(KIND=4)                            :: il_echeance,il_count,il_ierror,il_len,il_narg,iargc,il_nbdim,il_fic,&
                                                il_cpt,il_ficloc,il_ji,il_jj,il_status,il_filein,&
                                                il_threadid,il_nthreads,il_iproc,il_nproc,il_ind,SWnode,il_filemask,il_nbx,il_nby,&
                                                il_n,il_file_id,il_boite,il_comp,il_nbprof,il_prof,il_xindex,il_yindex,il_nbfile,il_t1,il_t2,il_ir
  INTEGER(KIND=4),DIMENSION(1)               :: ila_lon,ila_lat,il_loc
  INTEGER(KIND=4),DIMENSION(2)               :: ila_lon2D,ila_lat2D
  INTEGER(KIND=4),DIMENSION(3)               :: ila_mask
  INTEGER, DIMENSION(:),POINTER              :: ilpa_igrd,ilpa_jgrd
  INTEGER, DIMENSION(:,:),POINTER            :: ilpa_kanvas
  INTEGER, DIMENSION(4)                      :: ila_vertxindex,ila_vertyindex,vertex 
  LOGICAL,DIMENSION(4)                       :: lla_nbr_vertex
  LOGICAL                                    :: ll_ice_cl4,ll_model_fcst,ll_model_pers,ll_model_ana
  !**
  call system('hostname')
  NAMELIST / Liste_aice / il_nbfile,cl_conf,cl_date,cl_path,rl_seuil,rl_seuil2
  il_narg=iargc()
  IF (il_narg.NE.6) THEN
     PRINT *,' '
     PRINT *,' Compute seaice usage : '
     PRINT *,' -n namelist   : namelist file'
     PRINT *,' -p proc : number of proc'
     PRINT *,' -z choose the Hemisphere SH or NH'
     STOP
  ELSE
     DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-n') THEN
           CALL getarg(il_ji+1, cl_namelist)
        ELSE IF(cl_input .EQ. '-p') THEN 
           CALL getarg(il_ji+1, cl_nproc)
           read (cl_nproc,'(I3)') il_nproc
        ELSE IF(cl_input .EQ. '-z') THEN 
           CALL getarg(il_ji+1, cl_zone)
        ENDIF
     ENDDO
  ENDIF 
  IF (TRIM(cl_zone) .EQ. 'ARC') THEN
     WRITE (0,*) 'ARC zone'
     rl_latmin=45.0
     rl_latmax=90.0
     cl_maskfile='/naviti/data2/cregnier/static/Stereopolar_ARC_msk_new.nc'
  ELSE IF (TRIM(cl_zone) .EQ. 'ANT') THEN
     WRITE (0,*) 'ANT zone'
     rl_latmin=-77.0
     rl_latmax=-55.0
     cl_maskfile='/naviti/data2/cregnier/static/Stereopolar_ANT_msk.nc'
     cl_maskfile='/naviti/data2/cregnier/static/Stereopolar_ANT_msk_new.nc'
  ELSE 
    WRITE (0,*) 'Zone not known'
    STOP 
  ENDIF
  !** Open Grid File
  cl_lon='longitude'
  cl_lat='latitude'
  cl_var='mask'
  WRITE(0,*) 'Open Mask file'
  CALL MIOL_openr_file_NC(cl_maskfile,il_filemask)
  CALL MIOL_read_field_NC(il_filemask,cl_lon,rlpa_lonm,ila_lon2D)   
  CALL MIOL_read_field_NC(il_filemask,cl_lat,rlpa_latm,ila_lat2D)   
  CALL MIOL_read_field_NC(il_filemask,cl_var,ilpa_mask,ila_mask)   
  CALL MIOL_read_field_NC(il_filemask,'x',rlpa_x)   
  CALL MIOL_read_field_NC(il_filemask,'y',rlpa_y)   
  il_nbx=ila_lon2D(1)
  il_nby=ila_lon2D(2)
  CALL MIOL_close_file_NC(il_filemask)
  !** Compute Canvas
  !print *,'taille :',shape(ilpa_mask)
  WRITE(0,*) 'Genere canvas'
  CALL GenereCanvas(ilpa_mask(:,:,1),ilpa_kanvas,ilpa_igrd,ilpa_jgrd)
  WRITE(0,*) 'Generation Canvas OK'
!
  ! Open Namelist file
  CALL MIOL_getFreeLU(il_fic)
  OPEN(il_fic, file=TRIM(cl_namelist), &
       status='old', &
       form='formatted', &
       iostat=il_status)
  READ(il_fic, Liste_aice)
  ALLOCATE(cla_dataFile(il_nbfile), stat=il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) ' interpolate_prof3D : memory allocation error.'
     CALL flush(0)
     STOP
  ENDIF
  il_echeance=6
  ALLOCATE(rla_sum(il_nbx,il_nby,il_echeance),rla_diff(il_nbx,il_nby),rla_sumsqrt(il_nbx,il_nby))
  ALLOCATE(rla_diff_fcst(il_nbx,il_nby,il_echeance),rla_sumsqrt_fcst(il_nbx,il_nby,il_echeance))
  ALLOCATE(rla_diff_pers(il_nbx,il_nby,il_echeance),rla_sumsqrt_pers(il_nbx,il_nby,il_echeance))
  ALLOCATE(rla_hitice(il_nbx,il_nby),rla_falsealarm(il_nbx,il_nby),rla_miss(il_nbx,il_nby),rla_hitwater(il_nbx,il_nby))
  ALLOCATE(rla_hitice_fcst(il_nbx,il_nby,il_echeance),rla_falsealarm_fcst(il_nbx,il_nby,il_echeance),rla_miss_fcst(il_nbx,il_nby,il_echeance),rla_hitwater_fcst(il_nbx,il_nby,il_echeance))
  ALLOCATE(rla_hitice_pers(il_nbx,il_nby,il_echeance),rla_falsealarm_pers(il_nbx,il_nby,il_echeance),rla_miss_pers(il_nbx,il_nby,il_echeance),rla_hitwater_pers(il_nbx,il_nby,il_echeance))
  ALLOCATE(rla_PCI(il_nbx,il_nby),rla_PCW(il_nbx,il_nby),rla_PCT(il_nbx,il_nby),rla_BIAS(il_nbx,il_nby))
  ALLOCATE(rla_PCI_fcst(il_nbx,il_nby,il_echeance),rla_PCW_fcst(il_nbx,il_nby,il_echeance),rla_PCT_fcst(il_nbx,il_nby,il_echeance),rla_BIAS_fcst(il_nbx,il_nby,il_echeance))
  ALLOCATE(rla_PCI_pers(il_nbx,il_nby,il_echeance),rla_PCW_pers(il_nbx,il_nby,il_echeance),rla_PCT_pers(il_nbx,il_nby,il_echeance),rla_BIAS_pers(il_nbx,il_nby,il_echeance))
  ALLOCATE(ila_n(il_nbx,il_nby,il_echeance))
  ila_n(:,:,:)=0.
  rla_hitice(:,:)=0.
  rla_falsealarm(:,:)=0.
  rla_miss(:,:)=0.
  rla_hitwater(:,:)=0.
  rla_hitice_fcst(:,:,:)=0.
  rla_falsealarm_fcst(:,:,:)=0.
  rla_miss_fcst(:,:,:)=0.
  rla_hitwater_fcst(:,:,:)=0.
  rla_hitice_pers(:,:,:)=0.
  rla_falsealarm_pers(:,:,:)=0.
  rla_miss_pers(:,:,:)=0.
  rla_hitwater_pers(:,:,:)=0.
  rla_PCI(:,:)=0.
  rla_PCW(:,:)=0.
  rla_PCT(:,:)=0.
  rla_BIAS(:,:)=0.
  rla_PCI_fcst(:,:,:)=0.
  rla_PCW_fcst(:,:,:)=0.
  rla_PCT_fcst(:,:,:)=0.
  rla_BIAS_fcst(:,:,:)=0.
  rla_PCI_pers(:,:,:)=0.
  rla_PCW_pers(:,:,:)=0.
  rla_PCT_pers(:,:,:)=0.
  rla_BIAS_pers(:,:,:)=0.
  rla_sum(:,:,:)=0.
  rla_diff(:,:)=0.
  rla_diff_fcst(:,:,:)=0.
  rla_diff_pers(:,:,:)=0.
  rla_sumsqrt(:,:)=0.
  rla_sumsqrt_fcst(:,:,:)=0.
  rla_sumsqrt_pers(:,:,:)=0.

  ! Initialize MPI
  !CALL mpi_init(il_ierror)
  !CALL mpi_comm_rank(mpi_comm_world,il_iproc,il_ierror)
  !CALL mpi_comm_size(mpi_comm_world,il_nproc,il_ierror)
 ! il_n=0
  DO il_ji=1, il_nbfile
     READ(il_fic,FMT='(A)') cla_dataFile(il_ji)
     cl_filein=cla_dataFile(il_ji)
     il_t1=0
     il_t2=0
     CALL SYSTEM_CLOCK(count=il_t1)
     WRITE(0,*) "Open File : ",cl_filein
     !** Open Data file
     WRITE(0,*) 'Work on :',cl_filein
    ! cl_filein='/homelocal/cregnier/DATA/CLASS4_ICE/class4_20150201_PSY4QV2R2_ORCA12_aice.nc'
     cl_lon='longitude'
     cl_lat='latitude'
     cl_qc='QC02'
     cl_var1='best_estimate'
     cl_var2='forecast'
     cl_var3='persistence'
     cl_varobs='observation'
     CALL MIOL_openr_file_NC(cl_filein,il_filein)
     CALL MIOL_read_field_NC(il_filein,cl_lon,rlpa_lon,ila_lon)   
     CALL MIOL_read_field_NC(il_filein,cl_lat,rlpa_lat,ila_lat)   
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_qc),rlpa_QC02)
     cl_qc='QC07'
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_qc),rlpa_QC07)
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_var1),rlpa_var)
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_var2),rlpa_var4D_fcst)
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_var3),rlpa_var4D_pers)
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_varobs),rlpa_varobs)
     WRITE(0,*) 'Read OK :',cl_filein
    ! print *,COUNT(rlpa_var(:,:,:) .NE. 0.)
    ! print *,SHAPE(rlpa_var)
     CALL MIOL_close_file_NC(il_filein)
     il_nbprof=ila_lon(1)
     il_ind=0
     CALL MIOL_getFreeLU(il_ficloc)
     il_len=len_trim(cl_filein)
    ! cl_colocfile=TRIM(cl_filein(1:il_len-3))//'.dat'
    ! WRITE(0,*) 'Name of coloc file ',cl_colocfile
  !   cl_colocFile='/homelocal/cregnier/DATA/CLASS4_ICE/position_coloc_20150102.txt'
!     OPEN(il_ficloc, file=TRIM(cl_colocFile), &
!                  status='new', &
!                  form='formatted')
     WRITE(0,*) 'Begin parallel do'
     !!$omp parallel do private (il_prof,rl_lon,rl_lat,il_loc,il_xindex,il_yindex,rl_diff,rl_diffsqr)
     !$omp parallel do private (il_prof,rl_lon,rl_lat,rl_varconc,rl_ana,ll_model_ana,ll_ice_cl4,vertex,SWnode,il_count,il_loc,il_xindex,il_yindex,rl_diff,rl_sum2,rl_diffsqr,lla_nbr_vertex,rla_poids_vertex,rla_dist_vertex,ila_vertxindex,ila_vertyindex) shared (rla_diff,rla_sumsqrt,rla_sum,rla_hitice,rla_falsealarm,rla_miss,rla_hitwater,ila_n)
     DO il_prof = 1,il_nbprof
        il_threadid = omp_get_thread_num()
        il_nthreads = omp_get_num_threads()
        !print "(A, I2, A, I2)", '-- PARALLEL REGION: threadid = ',il_threadid,' nthreads = ',il_nthreads
        ! IF ( ila_qcprofilel(il_prof) == 1 ) THEN
        !** recherche du numero de boite
        rl_lon=rlpa_lon(il_prof)
        rl_lat=rlpa_lat(il_prof)
        il_boite=9999.
        rl_varconc=rlpa_varobs(1,1,il_prof)
        rl_ana=rlpa_var(1,1,il_prof)
        rla_fcst(:)=rlpa_var4D_fcst(1,1:il_echeance,1,il_prof)
        rla_pers(:)=rlpa_var4D_pers(1,1:il_echeance,1,il_prof)
        !rl_seuil=0.15
        !rl_seuil2=0.2
        ll_model_ana=.FALSE.
        ll_ice_cl4=.FALSE.
        !IF ( (rl_lat .GE. rl_latmin) .AND. &
        !            (rl_lat .LE. rl_latmax) .AND. (rlpa_QC02(1,1,il_prof) .EQ. 0) .AND. rl_varconc .GT. rl_seuil ) THEN
        IF ( (rl_lat .GE. rl_latmin) .AND. &
                    (rl_lat .LE. rl_latmax) .AND. (rlpa_QC02(1,1,il_prof) .EQ. 0) .AND.  (rlpa_QC07(1,1,il_prof) .EQ. 0) ) THEN
                    !(rl_lat .LE. rl_latmax) .AND. (rlpa_var(1,1,il_prof) .NE. 0) ) THEN
          !WRITE(0,*) "Recherche position : ",il_prof,il_nbprof
          CALL getSWnode_orca_grid(rl_lon,&
                                   rl_lat,&
                                   rlpa_lonm(:,:), &
                                   rlpa_latm(:,:), &
                                   ilpa_kanvas(:,:),&
                                   ilpa_igrd(:),&
                                   ilpa_jgrd(:),&
                                   il_nbx, &
                                   il_nby, &
                                   SWnode,& 
                                   vertex)
          !** Initialisation
          lla_nbr_vertex(:)=.FALSE. 
          rla_poids_vertex(:)=0.0
          rla_dist_vertex(:)=0.0
          ila_vertxindex(:)=9999
          ila_vertyindex(:)=9999
          !*  check to see if points are land point
          il_count=COUNT(vertex(1:4) /= 0)
          !IF (ANY (vertex(1:4) /= 0) ) THEN
          IF ( il_count /= 0)  THEN
             ! au moins un des 4 vertex trouvé est un point ocean 
             WHERE(vertex(:) /=0)  
                lla_nbr_vertex= .TRUE.
                ila_vertxindex(:)=ilpa_igrd(vertex(:))
                ila_vertyindex(:)=ilpa_jgrd(vertex(:))
             ELSEWHERE
                ila_vertxindex(:)=9999
                ila_vertyindex(:)=9999
                lla_nbr_vertex(:)=.FALSE.  
             ENDWHERE
             !** Compute Nearest Box
             CALL IDW(rl_lon,&
                           rl_lat, &
                           rlpa_lonm(:,:), &
                           rlpa_latm(:,:), &
                           rla_poids_vertex(:),&
                           il_nbx, &
                           il_nby, &
                           ila_vertxindex(:),&
                           ila_vertyindex(:),&
                           lla_nbr_vertex(:),&
                           rla_dist_vertex(:))

              rl_sum2= SUM(rla_poids_vertex(:))
              IF ( rl_sum2  > 1.01 ) THEN
                 WRITE(0,*) 'Somme des poids > 1 :: ',rl_sum2
                 WRITE(0,*) 'Valeur des vertex en x :: ',ila_vertxindex(:)
                 WRITE(0,*) 'Valeur des vertex en y :: ',ila_vertyindex(:)
                 WRITE(0,*) 'nombre de vextex :: ',lla_nbr_vertex(:)
                 WRITE(0,*) 'poids :: ',rla_poids_vertex(:)
                 WRITE(0,*) 'position du point :: ',rl_lon,rl_lat
                 STOP
             ENDIF
             il_loc=MAXLOC(rla_poids_vertex(:))
             il_xindex=ila_vertxindex(il_loc(1))
             il_yindex=ila_vertyindex(il_loc(1))
             il_boite=ilpa_kanvas(il_xindex,il_yindex)
             rl_diff=rl_ana-rl_varconc
             rl_diffsqr=rl_diff*rl_diff
             !$OMP ATOMIC
             rla_diff(il_xindex,il_yindex)=rla_diff(il_xindex,il_yindex)+rl_diff
             !$OMP ATOMIC
             rla_sumsqrt(il_xindex,il_yindex)=rla_sumsqrt(il_xindex,il_yindex)+rl_diffsqr
             IF ( rl_varconc > rl_seuil2) ll_ice_cl4=.TRUE.
             IF ( rl_ana > rl_seuil2) ll_model_ana=.TRUE.
             IF ( ll_model_ana .AND. ll_ice_cl4) rla_hitice(il_xindex,il_yindex)=rla_hitice(il_xindex,il_yindex)+1
             IF ( ll_model_ana .AND. .NOT. ll_ice_cl4) rla_falsealarm(il_xindex,il_yindex)=rla_falsealarm(il_xindex,il_yindex)+1
             IF ( .NOT. ll_model_ana .AND. ll_ice_cl4)  rla_miss(il_xindex,il_yindex)=rla_miss(il_xindex,il_yindex)+1
             IF ( .NOT. ll_model_ana .AND. .NOT. ll_ice_cl4) rla_hitwater(il_xindex,il_yindex)=rla_hitwater(il_xindex,il_yindex)+1
             DO il_cpt=1,il_echeance
                 !$OMP ATOMIC
                 ila_n(il_xindex,il_yindex,il_cpt)=ila_n(il_xindex,il_yindex,il_cpt)+1
                 rla_sum(il_xindex,il_yindex,il_cpt)=rla_sum(il_xindex,il_yindex,il_cpt)+1
                 !** Forecast
                 ll_model_fcst=.FALSE.
                 rl_tmp_fcst=rlpa_var4D_fcst(1,il_cpt,1,il_prof) 
                 rl_diff_fcst=rl_tmp_fcst-rlpa_varobs(1,1,il_prof)
                 !$OMP ATOMIC
                 rla_diff_fcst(il_xindex,il_yindex,il_cpt)=rla_diff_fcst(il_xindex,il_yindex,il_cpt)+rl_diff_fcst
                 !$OMP ATOMIC
                 rla_sumsqrt_fcst(il_xindex,il_yindex,il_cpt)=rla_sumsqrt_fcst(il_xindex,il_yindex,il_cpt)+(rl_diff_fcst*rl_diff_fcst)
                 IF ( rl_tmp_fcst > rl_seuil2) ll_model_fcst=.TRUE.
                 IF ( ll_model_fcst .AND. ll_ice_cl4) rla_hitice_fcst(il_xindex,il_yindex,il_cpt)=rla_hitice_fcst(il_xindex,il_yindex,il_cpt)+1
                 IF ( ll_model_fcst .AND. .NOT. ll_ice_cl4) rla_falsealarm_fcst(il_xindex,il_yindex,il_cpt)=rla_falsealarm_fcst(il_xindex,il_yindex,il_cpt)+1
                 IF ( .NOT. ll_model_fcst .AND. ll_ice_cl4)  rla_miss_fcst(il_xindex,il_yindex,il_cpt)=rla_miss_fcst(il_xindex,il_yindex,il_cpt)+1
                 IF ( .NOT. ll_model_fcst .AND. .NOT. ll_ice_cl4) rla_hitwater_fcst(il_xindex,il_yindex,il_cpt)=rla_hitwater_fcst(il_xindex,il_yindex,il_cpt)+1
                 !** Persistency
                 ll_model_pers=.FALSE.
                 rl_tmp_pers=rlpa_var4D_pers(1,il_cpt,1,il_prof) 
                 rl_diff_pers=rl_tmp_pers-rlpa_varobs(1,1,il_prof)
                 !$OMP ATOMIC
                 rla_diff_pers(il_xindex,il_yindex,il_cpt)=rla_diff_pers(il_xindex,il_yindex,il_cpt)+rl_diff_pers
                 !$OMP ATOMIC
                 rla_sumsqrt_pers(il_xindex,il_yindex,il_cpt)=rla_sumsqrt_pers(il_xindex,il_yindex,il_cpt)+(rl_diff_pers*rl_diff_pers)
                 IF ( rl_tmp_pers > rl_seuil2) ll_model_pers=.TRUE.
                 IF ( ll_model_pers .AND. ll_ice_cl4) rla_hitice_pers(il_xindex,il_yindex,il_cpt)=rla_hitice_pers(il_xindex,il_yindex,il_cpt)+1
                 IF ( ll_model_pers .AND. .NOT. ll_ice_cl4) rla_falsealarm_pers(il_xindex,il_yindex,il_cpt)=rla_falsealarm_pers(il_xindex,il_yindex,il_cpt)+1
                 IF ( .NOT. ll_model_pers .AND. ll_ice_cl4)  rla_miss_pers(il_xindex,il_yindex,il_cpt)=rla_miss_pers(il_xindex,il_yindex,il_cpt)+1
                 IF ( .NOT. ll_model_pers .AND. .NOT. ll_ice_cl4) rla_hitwater_pers(il_xindex,il_yindex,il_cpt)=rla_hitwater_pers(il_xindex,il_yindex,il_cpt)+1
             ENDDO
            !WRITE(0,*) 'Vertex OK : ',il_xindex,il_yindex
             !WRITE(0,*) 'Boite OK : ',il_boite
             !WRITE(0,*) 'Vertex OK : ',vertex
             !WRITE(0,*) '******************************'
             !il_ind=il_ind+1
           !  WRITE(il_ficloc,'(i8,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,i6,2x,i6)',ADVANCE='yes') &
           !                 il_prof, rl_lon, rl_lat, &
           !                 il_ind,il_xindex,il_yindex,il_boite
             !WRITE(il_ficloc,'(i8,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,i6,2x,&
             !               i6,2x,i6,2x,i6)',ADVANCE='yes') &
             !               il_prof, rl_lon, rl_lat, &
             !               il_ind,vertex(1),vertex(2),vertex(3),vertex(4),il_boite
             CALL FLUSH(0)
          ENDIF
        ENDIF
     ENDDO
     !$omp end parallel do
     !CLOSE(il_ficloc)
     WRITE(0,*) "File OK"
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps de recherche :",REAL(il_t2 - il_t1) / il_ir
  ENDDO


  !! Compute Quantities
   rla_PCI(:,:)=rla_hitice(:,:)/(rla_hitice(:,:)+rla_miss(:,:))
   rla_PCW(:,:)=rla_hitwater(:,:)/(rla_falsealarm(:,:)+rla_hitwater(:,:))
   rla_PCT(:,:)=(rla_hitice(:,:)+rla_hitwater(:,:))/(ila_n(:,:,1))
   rla_BIAS(:,:)=(rla_hitice(:,:)+rla_falsealarm(:,:))/(rla_hitice(:,:)+rla_miss(:,:))
   rla_PCI_fcst(:,:,:)=rla_hitice_fcst(:,:,:)/(rla_hitice_fcst(:,:,:)+rla_miss_fcst(:,:,:))
   rla_PCW_fcst(:,:,:)=rla_hitwater_fcst(:,:,:)/(rla_falsealarm_fcst(:,:,:)+rla_hitwater_fcst(:,:,:))
   rla_PCT_fcst(:,:,:)=(rla_hitice_fcst(:,:,:)+rla_hitwater_fcst(:,:,:))/(ila_n(:,:,:))
   rla_BIAS_fcst(:,:,:)=(rla_hitice_fcst(:,:,:)+rla_falsealarm_fcst(:,:,:))/(rla_hitice_fcst(:,:,:)+rla_miss_fcst(:,:,:))
   rla_PCI_pers(:,:,:)=rla_hitice_pers(:,:,:)/(rla_hitice_pers(:,:,:)+rla_miss_pers(:,:,:))
   rla_PCW_pers(:,:,:)=rla_hitwater_pers(:,:,:)/(rla_falsealarm_pers(:,:,:)+rla_hitwater_pers(:,:,:))
   rla_PCT_pers(:,:,:)=(rla_hitice_pers(:,:,:)+rla_hitwater_pers(:,:,:))/(ila_n(:,:,:))
   rla_BIAS_pers(:,:,:)=(rla_hitice_pers(:,:,:)+rla_falsealarm_pers(:,:,:))/(rla_hitice_pers(:,:,:)+rla_miss_pers(:,:,:))
!  call MPI_Finalize(ierr)
  CLOSE(il_fic)
  il_nbdim=3
  ALLOCATE(rla_tmp(il_nbx,il_nby,il_echeance))
  ALLOCATE(cla_dimname(il_nbdim))
  ALLOCATE(ila_dimlen(il_nbdim))
  cla_dimname(1) = 'x' 
  cla_dimname(2)=  'y'
  cla_dimname(3)=  'z'
  ila_dimlen(1) = il_nbx 
  ila_dimlen(2) = il_nby
  ila_dimlen(3) = il_echeance

  rla_tmp(:,:,:)=rg_fillvalue
  il_len=len_trim(cl_filein)
  !cl_stats=TRIM(cl_filein(1:il_len-27))//'_'//TRIM(cl_zone)//'_Stats_aice.nc' 
  cl_stats_1=TRIM(cl_path)//'Stats_contable_'//TRIM(cl_zone)//'_'//TRIM(cl_conf)//'_'//TRIM(cl_date)//'_forecast_aice.nc' 
  WRITE(0,*) 'Fichier stats forecast :',cl_stats_1 
  call MIOL_create_file_NC(TRIM(cl_stats_1),&
                           il_nbdim,&
                           cla_dimname,&
                           ila_dimlen)
  call MIOL_openw_file_NC(TRIM(cl_stats_1), il_file_id)  
  call MIOL_write_field_NC (il_file_id,&
                            'longitude',&
                            'XY',&
                            rlpa_lonm) 
  call MIOL_write_field_NC (il_file_id,&
                            'latitude',&
                            'XY',&
                             rlpa_latm)
  call MIOL_write_field_NC (il_file_id,&
                            'x',&
                            'XY',&
                             rlpa_x)
  call MIOL_write_field_NC (il_file_id,&
                            'y',&
                            'XY',&
                             rlpa_y)
  call MIOL_write_field_NC (il_file_id,&
                            'Canvas',&
                            'XY',&
                             ilpa_kanvas)
  WHERE(rla_diff_fcst(:,:,:) .NE. 0) rla_tmp(:,:,:)= rla_diff_fcst(:,:,:)/rla_sum(:,:,:)
  WHERE( isnan(rla_tmp(:,:,:)) ) rla_tmp(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'mean_diff',&
                            'XYZ',&
                             rla_tmp(:,:,:))
  rla_tmp(:,:,:)=rg_fillvalue
  WHERE(rla_sumsqrt_fcst(:,:,:) .NE. 0) rla_tmp(:,:,:)=  SQRT(rla_sumsqrt_fcst(:,:,:)/rla_sum(:,:,:))
  WHERE( isnan(rla_tmp(:,:,:)) ) rla_tmp(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'rms_diff',&
                            'XYZ',&
                             rla_tmp(:,:,:))
  WHERE( isnan(rla_PCI_fcst(:,:,:)) ) rla_PCI_fcst(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'PCI',&
                            'XYZ',&
                             rla_PCI_fcst(:,:,:))
  WHERE( isnan(rla_PCW_fcst(:,:,:)) ) rla_PCW_fcst(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'PCW',&
                            'XYZ',&
                             rla_PCW_fcst(:,:,:))
  WHERE( isnan(rla_PCT_fcst(:,:,:)) ) rla_PCT_fcst(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'PCT',&
                            'XYZ',&
                             rla_PCT_fcst(:,:,:))
  WHERE( isnan(rla_BIAS_fcst(:,:,:)) ) rla_BIAS_fcst(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'BIAS',&
                            'XYZ',&
                             rla_BIAS_fcst(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'Hitice',&
                            'XYZ',&
                             rla_hitice_fcst(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'Miss',&
                            'XYZ',&
                             rla_miss_fcst(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'FalseAlarm',&
                            'XYZ',&
                            rla_falsealarm_fcst(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'Hitwater',&
                            'XYZ',&
                            rla_hitwater_fcst(:,:,:))
  CALL MIOL_close_file_NC(il_file_id)
  cl_stats_2=TRIM(cl_path)//'Stats_contable_'//TRIM(cl_zone)//'_'//TRIM(cl_conf)//'_'//TRIM(cl_date)//'_pers_aice.nc' 
  WRITE(0,*) 'Fichier stats persistence ',cl_stats_2
  call MIOL_create_file_NC(TRIM(cl_stats_2),&
                           il_nbdim,&
                           cla_dimname,&
                           ila_dimlen)
  call MIOL_openw_file_NC(TRIM(cl_stats_2), il_file_id)  
  call MIOL_write_field_NC (il_file_id,&
                            'longitude',&
                            'XY',&
                            rlpa_lonm) 
  call MIOL_write_field_NC (il_file_id,&
                            'latitude',&
                            'XY',&
                             rlpa_latm)
  call MIOL_write_field_NC (il_file_id,&
                            'x',&
                            'XY',&
                             rlpa_x)
  call MIOL_write_field_NC (il_file_id,&
                            'y',&
                            'XY',&
                             rlpa_y)
  WHERE(rla_diff_pers(:,:,:) .NE. 0) rla_tmp(:,:,:)= rla_diff_pers(:,:,:)/rla_sum(:,:,:)
  WHERE( isnan(rla_tmp(:,:,:)) ) rla_tmp(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'mean_diff',&
                            'XYZ',&
                             rla_tmp(:,:,:))
  rla_tmp(:,:,:)=rg_fillvalue
  WHERE(rla_sumsqrt_pers(:,:,:) .NE. 0) rla_tmp(:,:,:)=  SQRT(rla_sumsqrt_pers(:,:,:)/rla_sum(:,:,:))
  WHERE( isnan(rla_tmp(:,:,:)) ) rla_tmp(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'rms_diff',&
                            'XYZ',&
                             rla_tmp(:,:,:))
  WHERE( isnan(rla_PCI_pers(:,:,:)) ) rla_PCI_pers(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'PCI',&
                            'XYZ',&
                             rla_PCI_pers(:,:,:))
  WHERE( isnan(rla_PCW_pers(:,:,:)) ) rla_PCW_pers(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'PCW',&
                            'XYZ',&
                             rla_PCW_pers(:,:,:))
  WHERE( isnan(rla_PCT_pers(:,:,:)) ) rla_PCT_pers(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'PCT',&
                            'XYZ',&
                             rla_PCT_pers(:,:,:))
  WHERE( isnan(rla_BIAS_pers(:,:,:)) ) rla_BIAS_pers(:,:,:)=rg_fillvalue
  call MIOL_write_field_NC (il_file_id,&
                            'BIAS',&
                            'XYZ',&
                             rla_BIAS_pers(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'Hitice',&
                            'XYZ',&
                             rla_hitice_pers(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'Miss',&
                            'XYZ',&
                             rla_miss_pers(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'FalseAlarm',&
                            'XYZ',&
                            rla_falsealarm_pers(:,:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'Hitwater',&
                            'XYZ',&
                            rla_hitwater_pers(:,:,:))
  CALL MIOL_close_file_NC(il_file_id)

CONTAINS

      SUBROUTINE IDW(rd_lonprof, &
                         rd_latprof, &
                         rda_longrid, &
                         rda_latgrid, &
                         rda_poids,&
                         id_nx, &
                         id_ny, &
                         ida_xindex, &
                         ida_yindex,&
                         lda_nbr_mask,&
                         rda_dist)

!      
!** + DECLARATIONS
!
      IMPLICIT NONE

      INTEGER, INTENT(IN) :: id_nx, &
                             id_ny
      REAL(KIND=4), INTENT(IN) :: rd_lonprof, &
                                  rd_latprof
      REAL(KIND=4), DIMENSION(id_nx, id_ny), INTENT(IN) :: rda_longrid, &
                                                           rda_latgrid
      INTEGER, parameter :: il_num_neighbors=4  ! num nearest neighbors to interpolate from
  
      INTEGER, DIMENSION(il_num_neighbors),INTENT(IN)   :: ida_xindex, &
                                            ida_yindex
!
      LOGICAL,DIMENSION(il_num_neighbors),INTENT(IN)                    :: lda_nbr_mask
      REAL(KIND=4), DIMENSION(il_num_neighbors), INTENT(OUT) :: rda_poids
      REAL(KIND=4), DIMENSION(il_num_neighbors), INTENT(OUT),OPTIONAL :: rda_dist

      REAL(KIND=4), PARAMETER :: rl_ra = 6371.0
      REAL(KIND=8), DIMENSION(il_num_neighbors)              :: rla_dist
      REAL(KIND=8) ::rl_dist_tot,rl_zlon,rl_zlat
      INTEGER      :: il_xind, il_yind
      INTEGER :: il_n,il_i,il_miss,il_miss2
      LOGICAL,DIMENSION(4)      :: ll_ref
!   
!
!***********************************************************************************
!
      !* Initialisation

      rl_dist_tot=0.0
      rla_dist(:)=0.0
      il_miss=9999.
      il_miss2=0.
        
      !*check if on of the 4 points is the same as reference point
      ll_ref(1:4)=.FALSE.
      DO  il_i=1,il_num_neighbors
         IF ( ((ida_xindex(il_i) == il_miss) .AND. (ida_yindex(il_i) == il_miss)) .OR. &
            ((ida_xindex(il_i) == il_miss2) .AND. (ida_yindex(il_i) == il_miss2)) ) THEN
             ll_ref(il_i)=.FALSE.
          ELSE
             il_xind = ida_xindex(il_i)
             il_yind = ida_yindex(il_i)
             rl_zlon = rda_longrid(il_xind,il_yind)
             rl_zlat = rda_latgrid(il_xind,il_yind)
             IF( rl_zlon==rd_lonprof .AND. rl_zlat==rd_latprof ) ll_ref(il_i)=.TRUE.
          ENDIF
      ENDDO

      !* Compute the different distances
      IF( COUNT(ll_ref) .NE. 0 )THEN
         DO  il_i=1,il_num_neighbors
            rda_poids(il_i) = COUNT((/ll_ref(il_i)/))
         ENDDO
      ELSE
         DO  il_i=1,il_num_neighbors
            IF ( ((ida_xindex(il_i) == il_miss) .AND. (ida_yindex(il_i) == il_miss)) .OR. &
               ((ida_xindex(il_i) == il_miss2) .AND. (ida_yindex(il_i) == il_miss2)) ) THEN
                  rla_dist(il_i)=0.0
                  ll_ref(il_i)=.FALSE.
            ELSE
                 ll_ref(il_i)=.TRUE.
                 CALL compute_distance(rd_lonprof, & ! point A coordinates (lon)
                                            rd_latprof, &            ! point A coordinates (lat)
                                            rda_longrid(ida_xindex(il_i),ida_yindex(il_i)), &            ! point B coordinates (lon)
                                            rda_latgrid(ida_xindex(il_i),ida_yindex(il_i)), &            ! point B coordinates (lat)
                                            rla_dist(il_i))
            ENDIF       
            IF (lda_nbr_mask(il_i)) THEN
              rla_dist(il_i) = 1/rla_dist(il_i)
              rl_dist_tot = rl_dist_tot + rla_dist(il_i)
            ENDIF
         ENDDO
         !** Calcul des poids pour chaque points
         DO il_n=1,il_num_neighbors
            IF (lda_nbr_mask(il_n)) THEN
               rda_poids(il_n) = rla_dist(il_n)/rl_dist_tot
            ELSE
               rda_poids(il_n)=0.0
            ENDIF
         ENDDO
      ENDIF
      rda_poids(:)=REAL(rda_poids(:),KIND=4)
      rda_dist(:)=REAL(1/rla_dist(:),KIND=4)*rl_ra  
   ! PRINT *,'rda_poids',rda_poids(:)

!
!*===================================================================================
!
ENDSUBROUTINE  IDW
!
SUBROUTINE compute_distance (rd_lon_a, &
                                          rd_lat_a, &
                                          rd_lon_b, &
                                          rd_lat_b, &
                                          rd_distance)
 
         
          !----------------------------------------------------------------------
 
          IMPLICIT NONE
 
          REAL(KIND=4), INTENT(IN) :: rd_lon_a, rd_lat_a, rd_lon_b, rd_lat_b
          REAL(KIND=8), INTENT(OUT) :: rd_distance ! rd_distance between a et b on the globe
 
          REAL(KIND=8), PARAMETER :: pi = 3.14159265359
          REAL(KIND=8) :: coslat_a, &    ! cos(lat) of source grid point
                          coslon_a, &    ! cos(lon) of source grid point
                          sinlat_a, &    ! sin(lat) of source grid point
                          sinlon_a, &    ! sin(lon) of source grid point
                          coslat_b, &    ! cos(lat) of destination grid point
                          coslon_b, &    ! cos(lon) of destination grid point
                          sinlat_b, &    ! sin(lat) of destination grid point
                          sinlon_b       ! sin(lon) of destination grid point
          REAL(KIND=8), PARAMETER :: rd_deg2rad = pi/180.   ! conversion for deg to rads
 
          !----------------------------------------------------------------------
 
          coslat_a = COS(rd_lat_a*rd_deg2rad)
          coslon_a = COS(rd_lon_a*rd_deg2rad)
          sinlat_a = SIN(rd_lat_a*rd_deg2rad)
          sinlon_a = SIN(rd_lon_a*rd_deg2rad)
 
          coslat_b = COS(rd_lat_b*rd_deg2rad)
          coslon_b = COS(rd_lon_b*rd_deg2rad)
          sinlat_b = SIN(rd_lat_b*rd_deg2rad)
          sinlon_b = SIN(rd_lon_b*rd_deg2rad)
 
          rd_distance = ACOS( sinlat_a*sinlat_b + &
                              coslat_a*coslat_b*  &
                            ( coslon_a*coslon_b + &
                              sinlon_a*sinlon_b) )
 
 
        ENDSUBROUTINE compute_distance
 
  !******************************************************************************

     
END PROGRAM  Stats_aice
