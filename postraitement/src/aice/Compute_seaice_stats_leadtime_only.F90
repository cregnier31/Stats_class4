! vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
PROGRAM Stats_seaice_OLA
    !
    !**** Stats_seaice_OLA
    !
    !     Purpose :
    !     Read OLA netcdf file and compute Stats for seaice variables
    !
    !***  Method  :    Step 1
    !                  Read OLA netcdf file
    !                  Select the area 
    !                  Read Mask File 
    !                  Find cell of each observation in the analysis grid
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
    !       1.0       C.REGNIER    12/05/2016   created
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
    !USE omp_lib
    !** ++  Local Declarations
    !
    IMPLICIT NONE
    CHARACTER(LEN=256)                           :: cl_filein,cl_input,cl_stats,cl_stats2,cl_namelist,cl_path,cl_maskfile,cl_stats_dir
    CHARACTER(LEN=40)                            :: cl_lon,cl_lat,cl_time,cl_var,cl_var1,cl_qc,cl_varobs,cl_zone,cl_echeance,cl_dataset,cl_date1,cl_date2
    CHARACTER(LEN=30)                            :: cl_ref,cl_conf,cl_leadtime,cl_var2
    CHARACTER(LEN=3)                             :: cl_seuil
    CHARACTER(LEN=256),DIMENSION(:),ALLOCATABLE  :: cla_dimname,cla_dataFile
    CHARACTER(LEN=30), DIMENSION(:,:), POINTER   :: clpa_dataset
    REAL(KIND=4)                                 :: rl_latmin,rl_latmax,rl_seuil,rl_diff,rl_diffsqr,rl_lon,&
                                                    rl_lat,rl_IDboite,rl_varconc,rl_ana,rl_sum,&
                                                    rl_time_tmp,rl_nbsec,rl_tmp_leadtime
    REAL(KIND=4),DIMENSION(:,:),POINTER          :: rlpa_lonm,rlpa_latm
    REAL(KIND=4),DIMENSION(:),ALLOCATABLE        :: rla_sum_timeserie,rla_diff_timeserie,rla_rms_timeserie,rla_time,rla_PCT_timeserie,&
                                                    rla_PCI_timeserie,rla_BIAS_timeserie,rla_PCW_timeserie,rla_hitice_timeserie,rla_falsealarm_timeserie,&
                                                    rla_miss_timeserie,rla_hitwater_timeserie

    REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE      :: rla_sum_timeserie_leadtime,rla_diff_timeserie_leadtime,rla_rms_timeserie_leadtime,rla_time_leadtime,rla_PCT_timeserie_leadtime,&
                                                    rla_PCI_timeserie_leadtime,rla_BIAS_timeserie_leadtime,rla_PCW_timeserie_leadtime,rla_hitice_timeserie_leadtime,rla_falsealarm_timeserie_leadtime,&
                                                    rla_miss_timeserie_leadtime,rla_hitwater_timeserie_leadtime
    REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    :: rla_hitice_tmp_leadtime,rla_hitice_leadtime
    REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    :: rla_falsealarm_tmp_leadtime,rla_falsealarm_leadtime
    REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    :: rla_miss_tmp_leadtime,rla_miss_leadtime,rla_sumsqrt_tmp_leadtime
    REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    :: rla_hitwater_tmp_leadtime,rla_hitwater_leadtime,rla_diff_tmp_leadtime
    REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE    :: rla_PCI_leadtime,rla_PCW_leadtime,rla_PCT_leadtime,rla_BIAS_leadtime,rla_sumsqrt_leadtime,rla_diff_leadtime,rla_nbpoints_leadtime,rla_nbpoints_tmp_leadtime

    REAL(KIND=4),DIMENSION(:),POINTER            :: rlpa_lon,rlpa_lat,rlpa_time
    REAL(KIND=4),DIMENSION(:,:),POINTER          :: rlpa_x,rlpa_y
    REAL(KIND=4)      , DIMENSION(:,:,:), POINTER   :: rlpa_var,rlpa_varobs,rlpa_QC02,rlpa_QC07
    REAL(KIND=4)      , DIMENSION(:,:,:,:), POINTER :: rlpa_var4D_leadtime
    !REAL(KIND=4),DIMENSION(:),POINTER            :: rlpa_x,rlpa_y
    REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE      :: rla_sumsqrt,rla_diff,rla_nbpoints,rla_boite,rla_indice
    REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE      :: rla_sumsqrt_tmp,rla_diff_tmp,rla_nbpoints_tmp,rla_hitice,rla_falsealarm,rla_miss,rla_hitwater
    REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE      :: rla_hitice_tmp,rla_falsealarm_tmp,rla_miss_tmp,rla_hitwater_tmp,&
                                                    rla_PCI,rla_PCW,rla_PCT,rla_BIAS


    REAL(KIND=4), DIMENSION(4)                   :: rla_poids_vertex,rla_dist_vertex
    INTEGER(KIND=4),DIMENSION(3)                 :: ila_mask
    INTEGER, DIMENSION(:),POINTER                :: ilpa_igrd,ilpa_jgrd
    INTEGER, DIMENSION(:),POINTER                :: ila_dimlen
    INTEGER, DIMENSION(:,:),POINTER              :: ilpa_kanvas
    INTEGER(KIND=4),DIMENSION(:,:,:),POINTER     :: ilpa_mask
    INTEGER(KIND=4),DIMENSION(1)                 :: ila_lon,ila_lat,il_loc
    INTEGER(KIND=4),DIMENSION(2)                 :: ila_lon2D,ila_lat2D
    INTEGER(KIND=4)                              :: il_file_id,il_nbx,il_nby,il_filemask,il_nbfile,il_narg,iargc,&
                                                    il_i,il_j,il_ji,il_k,il_fic,il_status,il_prof,il_nbprof,il_indice,il_filein,&
                                                    il_fileid,il_boite,il_ir,SWnode,il_count,il_xindex,il_yindex,il_t1,il_t2,il_nbdim,&
                                                    il_echeance,il_cpt
    INTEGER, DIMENSION(4)                        :: ila_vertxindex,ila_vertyindex,vertex,ila_dim4D
    LOGICAL,DIMENSION(4)                         :: lla_nbr_vertex
    LOGICAL                                      :: ll_ice_data,ll_ice_model,ll_ice_model_2
    LOGICAL,DIMENSION(:),ALLOCATABLE             :: ll_ice_model_leadtime

!
    NAMELIST / Liste_aice / il_nbfile,cl_conf,cl_path,cl_stats_dir,rl_seuil,il_echeance
    il_narg=iargc()
    IF (il_narg.NE.6) THEN
        PRINT *,' '
        PRINT *,' Compute seaice usage : '
        PRINT *,' -n namelist   : namelist file -z zone: ARC or ANT'
        PRINT *,' -f leadime   : fcst or pers'
        STOP
    ELSE
        DO il_ji=1,il_narg
            CALL getarg(il_ji,cl_input)
            IF (cl_input .EQ. '-n') THEN
                CALL getarg(il_ji+1, cl_namelist)
            ELSE IF(cl_input .EQ. '-z') THEN 
               CALL getarg(il_ji+1, cl_zone)
            ELSE IF(cl_input .EQ. '-f') THEN 
               CALL getarg(il_ji+1, cl_leadtime)
            ENDIF
        ENDDO
    ENDIF
    WRITE (0,*) 'Read namelist ',cl_namelist
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
    WRITE (0,*) 'Read namelist OK'
    WRITE (cl_seuil,'(F3.2)') rl_seuil
    print *,cl_seuil
    IF (TRIM(cl_zone) .EQ. 'ARC') THEN
        WRITE (0,*) 'ARC zone'
        rl_latmin=45.0
        rl_latmax=90.0
        cl_maskfile=TRIM(cl_path)//'/'//'Stereopolar_ARC_msk.nc'
    ELSE IF (TRIM(cl_zone) .EQ. 'ANT') THEN
        WRITE (0,*) 'ANT zone'
        rl_latmin=-77.0
        rl_latmax=-55.0
        cl_maskfile=TRIM(cl_path)//'/'//'Stereopolar_ANT_msk.nc'
    ELSE
        WRITE (0,*) 'Zone not known'
        STOP
    ENDIF
    WRITE(0,*) "Mask :: ",cl_maskfile
    !** Open Grid File
    cl_lon='longitude'
    cl_lat='latitude'
    cl_var='mask'
    WRITE(0,*) ''
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
    !** Allocate output stats matrix
    !** 2D matrix
    ALLOCATE(rla_nbpoints(il_nbx,il_nby),rla_diff(il_nbx,il_nby),rla_sumsqrt(il_nbx,il_nby),rla_boite(il_nbx,il_nby),rla_indice(il_nbx,il_nby))
    ALLOCATE(rla_nbpoints_tmp(il_nbx,il_nby),rla_diff_tmp(il_nbx,il_nby),rla_sumsqrt_tmp(il_nbx,il_nby))
    ALLOCATE(rla_hitice(il_nbx,il_nby),rla_falsealarm(il_nbx,il_nby),rla_miss(il_nbx,il_nby),rla_hitwater(il_nbx,il_nby))
    ALLOCATE(rla_hitice_tmp(il_nbx,il_nby),rla_falsealarm_tmp(il_nbx,il_nby),rla_miss_tmp(il_nbx,il_nby),rla_hitwater_tmp(il_nbx,il_nby))
    ALLOCATE(rla_PCI(il_nbx,il_nby),rla_PCW(il_nbx,il_nby),rla_PCT(il_nbx,il_nby),rla_BIAS(il_nbx,il_nby))
    !** 
    ! leadtime
    ALLOCATE(rla_nbpoints_leadtime(il_nbx,il_nby,il_echeance),rla_diff_leadtime(il_nbx,il_nby,il_echeance),rla_sumsqrt_leadtime(il_nbx,il_nby,il_echeance))
    ALLOCATE(rla_nbpoints_tmp_leadtime(il_nbx,il_nby,il_echeance),rla_diff_tmp_leadtime(il_nbx,il_nby,il_echeance),rla_sumsqrt_tmp_leadtime(il_nbx,il_nby,il_echeance))
    ALLOCATE(rla_hitice_leadtime(il_nbx,il_nby,il_echeance),rla_falsealarm_leadtime(il_nbx,il_nby,il_echeance),rla_miss_leadtime(il_nbx,il_nby,il_echeance),rla_hitwater_leadtime(il_nbx,il_nby,il_echeance))
    ALLOCATE(rla_hitice_tmp_leadtime(il_nbx,il_nby,il_echeance),rla_falsealarm_tmp_leadtime(il_nbx,il_nby,il_echeance),rla_miss_tmp_leadtime(il_nbx,il_nby,il_echeance),rla_hitwater_tmp_leadtime(il_nbx,il_nby,il_echeance))
    ALLOCATE(rla_PCI_leadtime(il_nbx,il_nby,il_echeance),rla_PCW_leadtime(il_nbx,il_nby,il_echeance),rla_PCT_leadtime(il_nbx,il_nby,il_echeance),rla_BIAS_leadtime(il_nbx,il_nby,il_echeance))
    !** Timeseries 
    ALLOCATE(rla_rms_timeserie(il_nbfile),rla_sum_timeserie(il_nbfile),rla_diff_timeserie(il_nbfile),rla_time(il_nbfile))
    ALLOCATE(rla_PCT_timeserie(il_nbfile),rla_PCI_timeserie(il_nbfile),rla_BIAS_timeserie(il_nbfile),rla_PCW_timeserie(il_nbfile))
    ALLOCATE(rla_hitice_timeserie(il_nbfile),rla_falsealarm_timeserie(il_nbfile),rla_miss_timeserie(il_nbfile),rla_hitwater_timeserie(il_nbfile))
    ! leadtime 
    ALLOCATE(rla_rms_timeserie_leadtime(il_nbfile,il_echeance),rla_sum_timeserie_leadtime(il_nbfile,il_echeance),rla_diff_timeserie_leadtime(il_nbfile,il_echeance))
    ALLOCATE(rla_PCT_timeserie_leadtime(il_nbfile,il_echeance),rla_PCI_timeserie_leadtime(il_nbfile,il_echeance),rla_BIAS_timeserie_leadtime(il_nbfile,il_echeance),rla_PCW_timeserie_leadtime(il_nbfile,il_echeance))
    ALLOCATE(rla_hitice_timeserie_leadtime(il_nbfile,il_echeance),rla_falsealarm_timeserie_leadtime(il_nbfile,il_echeance),rla_miss_timeserie_leadtime(il_nbfile,il_echeance),rla_hitwater_timeserie_leadtime(il_nbfile,il_echeance))
    ALLOCATE(ll_ice_model_leadtime(il_echeance))
    !** Initialization
    rla_diff(:,:)=0.0
    rla_sumsqrt(:,:)=0.0
    rla_nbpoints(:,:)=0.0
    rla_boite(:,:)=0.0
    rla_hitice(:,:)=0.
    rla_falsealarm(:,:)=0.
    rla_miss(:,:)=0.
    rla_hitwater(:,:)=0.
    rla_PCI(:,:)=0.
    rla_PCW(:,:)=0.
    rla_PCT(:,:)=0.
    rla_BIAS(:,:)=0.
    ! forecast
    rla_diff_leadtime(:,:,:)=0.0
    rla_sumsqrt_leadtime(:,:,:)=0.0
    rla_nbpoints_leadtime(:,:,:)=0.0
    rla_hitice_leadtime(:,:,:)=0.
    rla_falsealarm_leadtime(:,:,:)=0.
    rla_miss_leadtime(:,:,:)=0.
    rla_hitwater_leadtime(:,:,:)=0.
    rla_PCI_leadtime(:,:,:)=0.
    rla_PCW_leadtime(:,:,:)=0.
    rla_PCT_leadtime(:,:,:)=0.
    rla_BIAS_leadtime(:,:,:)=0.

    DO il_ji=1, il_nbfile
        !** Initialization for temporary matrix
        rla_diff_tmp(:,:)=0.0
        rla_sumsqrt_tmp(:,:)=0.0
        rla_nbpoints_tmp(:,:)=0.0
        rla_hitice_tmp(:,:)=0.0
        rla_falsealarm_tmp(:,:)=0.0
        rla_miss_tmp(:,:)=0.0
        rla_hitwater_tmp(:,:)=0.0
        ! leadtime
        rla_diff_tmp_leadtime(:,:,:)=0.0
        rla_sumsqrt_tmp_leadtime(:,:,:)=0.0
        rla_nbpoints_tmp_leadtime(:,:,:)=0.0
        rla_hitice_tmp_leadtime(:,:,:)=0.
        rla_falsealarm_tmp_leadtime(:,:,:)=0.
        rla_miss_tmp_leadtime(:,:,:)=0.
        rla_hitwater_tmp_leadtime(:,:,:)=0.
        !
        il_t1=0
        il_t2=0
        CALL SYSTEM_CLOCK(count=il_t1)
        print *,'OK1'
        READ(il_fic,FMT='(A)') cla_dataFile(il_ji)
        cl_filein=cla_dataFile(il_ji)
        print *,'File in : ',cl_filein
        !** Open Netcdf CLASS4  file
        cl_lon='longitude'
        cl_lat='latitude'
        cl_var1='best_estimate'
        cl_var2=TRIM(cl_leadtime)
        WRITE(0,*) 'leadtime : ',cl_var2
        cl_varobs='observation'
        cl_time='obs_time'
        CALL MIOL_openr_file_NC(cl_filein,il_filein)
        CALL MIOL_read_field_NC(il_filein,cl_lon,rlpa_lon,ila_lon)   
        CALL MIOL_read_field_NC(il_filein,cl_lat,rlpa_lat,ila_lat)   
        CALL MIOL_read_field_NC(il_filein,cl_time,rlpa_time)
        cl_qc='QC02'
        CALL MIOL_read_field_NC(il_filein,TRIM(cl_qc),rlpa_QC02)
        cl_qc='QC07'
        CALL MIOL_read_field_NC(il_filein,TRIM(cl_qc),rlpa_QC07)
        CALL MIOL_read_field_NC(il_filein,TRIM(cl_var1),rlpa_var)
        WRITE(0,*) 'OK1'
        CALL MIOL_read_field_NC(il_filein,TRIM(cl_var2),rlpa_var4D_leadtime,ila_dim4D)
        CALL MIOL_read_field_NC(il_filein,TRIM(cl_varobs),rlpa_varobs)
        WRITE(0,*) 'Read OK :',cl_filein
        CALL MIOL_close_file_NC(il_filein)
        il_nbprof=ila_lon(1)
        il_echeance=ila_dim4D(2)
        WRITE(0,*) 'il_echeance :',ila_dim4D(2)
        rla_time(il_ji)=rlpa_time(1)
        !!$omp parallel do private (il_prof,rl_diff,rl_lon,rl_lat,rl_varconc,rl_ana,vertex,SWnode,il_count,il_loc,il_xindex,il_yindex,rl_sum,rl_diffsqr,lla_nbr_vertex,rla_poids_vertex,rla_dist_vertex,ila_vertxindex,ila_vertyindex) shared (rla_diff,rla_sumsqrt,rla_nbpoints_tmp)

        !!$omp parallel do private (il_prof,rl_diff,rl_lon,rl_lat,rl_varconc,rl_tmp_leadtime,rl_ana,ll_ice_model,ll_ice_model_2,ll_ice_data,vertex,SWnode,il_count,il_loc,il_xindex,il_yindex,rl_sum,rl_diffsqr,lla_nbr_vertex,rla_poids_vertex,rla_dist_vertex,ila_vertxindex,ila_vertyindex) shared (rla_diff,rla_sumsqrt,rla_nbpoints_tmp,rla_diff_leadtime,rla_sumsqrt_leadtime,rla_nbpoints_tmp_leadtime)

        !$omp parallel do private (il_prof,rl_lon,rl_lat,rl_tmp_leadtime,rl_varconc,rl_ana,vertex,SWnode,ll_ice_model,ll_ice_model_2,ll_ice_data,il_count,il_loc,il_xindex,il_yindex,rl_diff,rl_sum,rl_diffsqr,lla_nbr_vertex,rla_poids_vertex,rla_dist_vertex,ila_vertxindex,ila_vertyindex) shared (ll_ice_model_leadtime,rla_diff,rla_diff_leadtime,rla_sumsqrt,rla_sumsqrt_leadtime,rla_hitice,rla_hitice_leadtime,rla_falsealarm,rla_falsealarm_tmp,rla_falsealarm_leadtime,rla_miss,rla_miss_leadtime,rla_hitwater,rla_hitwater_leadtime,rla_diff_tmp_leadtime,rla_sumsqrt_tmp_leadtime,rla_nbpoints,rla_nbpoints_tmp,rla_nbpoints_tmp_leadtime,rla_nbpoints_leadtime,rla_hitice_tmp_leadtime,rla_falsealarm_tmp_leadtime,rla_miss_tmp_leadtime,rla_hitwater_tmp_leadtime)



        DO il_prof=1,il_nbprof
            ll_ice_data=.FALSE.
            ll_ice_model=.FALSE.
            ll_ice_model_2=.FALSE.
            ll_ice_model_leadtime(:)=.FALSE.
            rl_lon=rlpa_lon(il_prof)
            rl_lat=rlpa_lat(il_prof)
            rl_varconc=rlpa_varobs(1,1,il_prof) 
            rl_ana=rlpa_var(1,1,il_prof)
            ! Test observation depending on the are and threshold
            IF ( (rl_lat .GE. rl_latmin) .AND. &
               & (rl_lat .LE. rl_latmax) .AND. (rlpa_QC02(1,1,il_prof) .EQ. 0) .AND. &
               & (rlpa_QC07(1,1,il_prof) .EQ. 0) .AND. (rl_varconc .GT. rl_seuil) ) THEN 
                !** Find position in the stereopolar grid
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
                    rl_sum= SUM(rla_poids_vertex(:))
                    IF ( rl_sum  > 1.01 ) THEN
                        WRITE(0,*) 'Somme des poids > 1 :: ',rl_sum
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
                    rla_boite(il_xindex,il_yindex)=il_boite
                    rl_diffsqr=rl_diff*rl_diff
                    rla_diff(il_xindex,il_yindex)=rla_diff(il_xindex,il_yindex)+rl_diff
                    rla_sumsqrt(il_xindex,il_yindex)=rla_sumsqrt(il_xindex,il_yindex)+rl_diffsqr 
                    rla_nbpoints(il_xindex,il_yindex)=rla_nbpoints(il_xindex,il_yindex)+1
                    rla_diff_tmp(il_xindex,il_yindex)=rla_diff_tmp(il_xindex,il_yindex)+rl_diff
                    rla_sumsqrt_tmp(il_xindex,il_yindex)=rla_sumsqrt_tmp(il_xindex,il_yindex)+rl_diffsqr 
                    rla_nbpoints_tmp(il_xindex,il_yindex)=rla_nbpoints_tmp(il_xindex,il_yindex)+1
                    !** Compute contingency table
                    IF ( rl_varconc > rl_seuil) ll_ice_data=.TRUE.
                    !** Forecast case
                    DO il_cpt=1,il_echeance
                        !** Forecast 
                        rl_tmp_leadtime=rlpa_var4D_leadtime(1,il_cpt,1,il_prof) 
                        rla_diff_leadtime(il_xindex,il_yindex,il_cpt)=rl_tmp_leadtime-rl_varconc
                        rla_sumsqrt_leadtime(il_xindex,il_yindex,il_cpt)=rla_sumsqrt_leadtime(il_xindex,il_yindex,il_cpt)+rla_diff_leadtime(il_xindex,il_yindex,il_cpt)**2
                        rla_nbpoints_leadtime(il_xindex,il_yindex,il_cpt)=rla_nbpoints_leadtime(il_xindex,il_yindex,il_cpt)+1
                        rla_nbpoints_tmp_leadtime(il_xindex,il_yindex,il_cpt)=rla_nbpoints_tmp_leadtime(il_xindex,il_yindex,il_cpt)+1
                       ! IF ( rl_tmp_leadtime > rl_seuil) ll_ice_model_leadtime(il_cpt)=.TRUE.
                        IF ( rl_tmp_leadtime > rl_seuil) ll_ice_model_2=.TRUE.
                        !IF ( ll_ice_model_leadtime(il_cpt) .AND. ll_ice_data) THEN
                        IF ( ll_ice_model_2 .AND. ll_ice_data) THEN
                            rla_hitice_leadtime(il_xindex,il_yindex,il_cpt)=rla_hitice_leadtime(il_xindex,il_yindex,il_cpt)+1
                            rla_hitice_tmp_leadtime(il_xindex,il_yindex,il_cpt)=rla_hitice_tmp_leadtime(il_xindex,il_yindex,il_cpt)+1
                        ENDIF
                        !IF ( ll_ice_model_leadtime(il_cpt) .AND. .NOT. ll_ice_data) THEN
                        IF ( ll_ice_model_2 .AND. .NOT. ll_ice_data) THEN
                            rla_falsealarm_leadtime(il_xindex,il_yindex,il_cpt)=rla_falsealarm_leadtime(il_xindex,il_yindex,il_cpt)+1
                            rla_falsealarm_tmp_leadtime(il_xindex,il_yindex,il_cpt)=rla_falsealarm_tmp_leadtime(il_xindex,il_yindex,il_cpt)+1
                        ENDIF
                        !IF ( .NOT. ll_ice_model_leadtime(il_cpt) .AND. ll_ice_data) THEN
                        IF ( .NOT. ll_ice_model_2 .AND. ll_ice_data) THEN
                            rla_miss_leadtime(il_xindex,il_yindex,il_cpt)=rla_miss_leadtime(il_xindex,il_yindex,il_cpt)+1
                            rla_miss_tmp_leadtime(il_xindex,il_yindex,il_cpt)=rla_miss_tmp_leadtime(il_xindex,il_yindex,il_cpt)+1
                        ENDIF
                        !IF ( .NOT. ll_ice_model_leadtime(il_cpt) .AND. .NOT. ll_ice_data) THEN
                        IF ( .NOT. ll_ice_model_2 .AND. .NOT. ll_ice_data) THEN
                            rla_hitwater_leadtime(il_xindex,il_yindex,il_cpt)=rla_hitwater_leadtime(il_xindex,il_yindex,il_cpt)+1
                            rla_hitwater_tmp_leadtime(il_xindex,il_yindex,il_cpt)=rla_hitwater_tmp_leadtime(il_xindex,il_yindex,il_cpt)+1
                        ENDIF
                    ENDDO
                    !** Analysis case
                    IF ( rl_ana > rl_seuil) ll_ice_model=.TRUE.
                    IF ( ll_ice_model .AND. ll_ice_data) THEN
                        rla_hitice(il_xindex,il_yindex)=rla_hitice(il_xindex,il_yindex)+1
                        rla_hitice_tmp(il_xindex,il_yindex)=rla_hitice_tmp(il_xindex,il_yindex)+1
                    ENDIF
                    IF ( ll_ice_model .AND. .NOT. ll_ice_data) THEN
                        rla_falsealarm(il_xindex,il_yindex)=rla_falsealarm(il_xindex,il_yindex)+1
                        rla_falsealarm_tmp(il_xindex,il_yindex)=rla_falsealarm_tmp(il_xindex,il_yindex)+1
                    ENDIF
                    IF ( .NOT. ll_ice_model .AND. ll_ice_data) THEN
                        rla_miss(il_xindex,il_yindex)=rla_miss(il_xindex,il_yindex)+1
                        rla_miss_tmp(il_xindex,il_yindex)=rla_miss_tmp(il_xindex,il_yindex)+1
                    ENDIF
                    IF ( .NOT. ll_ice_model .AND. .NOT. ll_ice_data) THEN
                        rla_hitwater(il_xindex,il_yindex)=rla_hitwater(il_xindex,il_yindex)+1
                        rla_hitwater_tmp(il_xindex,il_yindex)=rla_hitwater_tmp(il_xindex,il_yindex)+1
                    ENDIF
                ENDIF
            ENDIF
            !WRITE(0,*) "indice : ",il_prof,il_nbprof
        ENDDO
        !$omp end parallel do
        rla_diff_timeserie(il_ji)=SUM(rla_diff_tmp(:,:))/SUM(rla_nbpoints_tmp(:,:))
        rla_rms_timeserie(il_ji)=SQRT(SUM(rla_sumsqrt_tmp(:,:))/SUM(rla_nbpoints_tmp(:,:)))
        rla_sum_timeserie(il_ji)=SUM(rla_nbpoints_tmp(:,:))
        rla_PCT_timeserie(il_ji)=SUM(rla_hitice_tmp(:,:))/(SUM(rla_hitice_tmp(:,:))+SUM(rla_miss_tmp(:,:)))
        rla_PCI_timeserie(il_ji)=SUM(rla_hitwater_tmp(:,:))/(SUM(rla_falsealarm_tmp(:,:))+SUM(rla_hitwater_tmp(:,:)))
        rla_BIAS_timeserie(il_ji)=(SUM(rla_hitice_tmp(:,:))+SUM(rla_hitwater_tmp(:,:)))/(SUM(rla_nbpoints_tmp(:,:)))
        rla_PCW_timeserie(il_ji)=(SUM(rla_hitice_tmp(:,:))+SUM(rla_falsealarm_tmp(:,:)))/(SUM(rla_hitice_tmp(:,:))+SUM(rla_miss_tmp(:,:)))
        rla_hitice_timeserie(il_ji)=SUM(rla_hitice_tmp(:,:))
        rla_falsealarm_timeserie(il_ji)=SUM(rla_falsealarm_tmp(:,:))
        rla_miss_timeserie(il_ji)=SUM(rla_miss_tmp(:,:))
        rla_hitwater_timeserie(il_ji)=SUM(rla_hitwater_tmp(:,:))
        WRITE(0,*) 'time : ',rla_time(il_ji)
        DO il_cpt=1,il_echeance
            ! leadtime
            rla_diff_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_diff_tmp_leadtime(:,:,il_cpt))/SUM(rla_nbpoints_tmp_leadtime(:,:,il_cpt))
            rla_rms_timeserie_leadtime(il_ji,il_cpt)=SQRT(SUM(rla_sumsqrt_tmp_leadtime(:,:,il_cpt))/SUM(rla_nbpoints_tmp_leadtime(:,:,il_cpt)))
            rla_sum_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_nbpoints_tmp_leadtime(:,:,il_cpt))
            rla_PCT_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_hitice_tmp_leadtime(:,:,il_cpt))/(SUM(rla_hitice_tmp_leadtime(:,:,il_cpt))+SUM(rla_miss_tmp_leadtime(:,:,il_cpt)))
            rla_PCI_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_hitwater_tmp_leadtime(:,:,il_cpt))/(SUM(rla_falsealarm_tmp_leadtime(:,:,il_cpt))+SUM(rla_hitwater_tmp_leadtime(:,:,il_cpt)))
            rla_BIAS_timeserie_leadtime(il_ji,il_cpt)=(SUM(rla_hitice_tmp_leadtime(:,:,il_cpt))+SUM(rla_hitwater_tmp_leadtime(:,:,il_cpt)))/(SUM(rla_nbpoints_tmp_leadtime(:,:,il_cpt)))
            rla_PCW_timeserie_leadtime(il_ji,il_cpt)=(SUM(rla_hitice_tmp_leadtime(:,:,il_cpt))+SUM(rla_falsealarm_tmp_leadtime(:,:,il_cpt)))/(SUM(rla_hitice_tmp_leadtime(:,:,il_cpt))+SUM(rla_miss_tmp_leadtime(:,:,il_cpt)))
            rla_hitice_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_hitice_tmp_leadtime(:,:,il_cpt))
            rla_falsealarm_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_falsealarm_tmp_leadtime(:,:,il_cpt))
            rla_miss_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_miss_tmp_leadtime(:,:,il_cpt))
            rla_hitwater_timeserie_leadtime(il_ji,il_cpt)=SUM(rla_hitwater_tmp_leadtime(:,:,il_cpt))
        ENDDO

        WRITE(0,*) "File OK"
       ! WRITE(0,*) "rla_nbpoints(il_xindex,il_yindex) : ",rla_nbpoints(100,100)
        DEALLOCATE(rlpa_QC02) 
        DEALLOCATE(rlpa_QC07)
        DEALLOCATE(rlpa_var)
        DEALLOCATE(rlpa_var4D_leadtime)  
        DEALLOCATE(rlpa_varobs) 
        CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
        WRITE(0,*) "Temps de recherche :",REAL(il_t2 - il_t1) / il_ir
    ENDDO
    il_indice=1
    DO il_j=1,il_nby
        DO il_i=1,il_nbx
            IF ( rla_nbpoints(il_i,il_j) .GT. 0 ) THEN
                rla_diff(il_i,il_j)=rla_diff(il_i,il_j)/rla_nbpoints(il_i,il_j)
                rla_sumsqrt(il_i,il_j)=SQRT(rla_sumsqrt(il_i,il_j)/rla_nbpoints(il_i,il_j))
            ELSE
                rla_diff(il_i,il_j)=rg_fillvalue
                rla_sumsqrt(il_i,il_j)=rg_fillvalue
                rla_nbpoints(il_i,il_j)=rg_fillvalue
            ENDIF
            DO il_k=1,il_echeance
                IF ( rla_nbpoints_leadtime(il_i,il_j,il_k) .GT. 0 ) THEN
                    rla_diff_leadtime(il_i,il_j,il_k)=rla_diff_leadtime(il_i,il_j,il_k)/rla_nbpoints_leadtime(il_i,il_j,il_k)
                    rla_sumsqrt_leadtime(il_i,il_j,il_k)=SQRT(rla_sumsqrt_leadtime(il_i,il_j,il_k)/rla_nbpoints_leadtime(il_i,il_j,il_k))
                ELSE
                    rla_diff_leadtime(il_i,il_j,il_k)=rg_fillvalue
                    rla_sumsqrt_leadtime(il_i,il_j,il_k)=rg_fillvalue
                ENDIF
            ENDDO
            rla_indice(il_i,il_j)=il_indice
            il_indice=il_indice+1
        ENDDO
    ENDDO
    !! Compute Quantities
    rla_PCI(:,:)=rla_hitice(:,:)/(rla_hitice(:,:)+rla_miss(:,:))
    rla_PCW(:,:)=rla_hitwater(:,:)/(rla_falsealarm(:,:)+rla_hitwater(:,:))
    rla_PCT(:,:)=(rla_hitice(:,:)+rla_hitwater(:,:))/(rla_nbpoints(:,:))
    rla_BIAS(:,:)=(rla_hitice(:,:)+rla_falsealarm(:,:))/(rla_hitice(:,:)+rla_miss(:,:))

    rla_PCI_leadtime(:,:,:)=rla_hitice_leadtime(:,:,:)/(rla_hitice_leadtime(:,:,:)+rla_miss_leadtime(:,:,:))
    rla_PCW_leadtime(:,:,:)=rla_hitwater_leadtime(:,:,:)/(rla_falsealarm_leadtime(:,:,:)+rla_hitwater_leadtime(:,:,:))
    rla_PCT_leadtime(:,:,:)=(rla_hitice_leadtime(:,:,:)+rla_hitwater_leadtime(:,:,:))/(rla_nbpoints_leadtime(:,:,:))
    rla_BIAS_leadtime(:,:,:)=(rla_hitice_leadtime(:,:,:)+rla_falsealarm_leadtime(:,:,:))/(rla_hitice_leadtime(:,:,:)+rla_miss_leadtime(:,:,:))

    !!** Print output values
    il_nbdim=3
    ALLOCATE(cla_dimname(il_nbdim))
    ALLOCATE(ila_dimlen(il_nbdim))
    cla_dimname(1) = 'x'
    cla_dimname(2) = 'y'
    cla_dimname(3) = 'time'
    ila_dimlen(1) = il_nbx
    ila_dimlen(2) = il_nby
    !ila_dimlen(3) = il_nbfile
    ila_dimlen(3) = NF90_UNLIMITED
    !**  Date conversion for Min Max time interval
    rl_time_tmp=rla_time(1)+43200
    rl_nbsec=REAL(rl_time_tmp)
    CALL MCAL_conversion_STU50_CAL(rl_nbsec,cl_date1)
    rl_time_tmp=rla_time(size(rla_time(:)))
    rl_nbsec=REAL(rl_time_tmp)+43200
    CALL MCAL_conversion_STU50_CAL(rl_nbsec,cl_date2)
    cl_stats=TRIM(cl_stats_dir)//'Stats_contable_timeseries'//'_'//TRIM(cl_zone)//'_'//TRIM(cl_date1(1:10))//'_'//TRIM(cl_date2(1:10))//'_seuil'//TRIM(cl_seuil)//'_best.nc'
    cl_stats2=TRIM(cl_stats_dir)//'Stats_contable_timeseries'//'_'//TRIM(cl_zone)//'_'//TRIM(cl_date1(1:10))//'_'//TRIM(cl_date2(1:10))//'_seuil'//TRIM(cl_seuil)//'_'//TRIM(cl_leadtime)//'.nc'
    WRITE(0,*) 'Fichier stats ',cl_stats
    call MIOL_create_file_NC(TRIM(cl_stats),&
                             il_nbdim,&
                             cla_dimname,&
                             ila_dimlen)
    WRITE(0,*) 'Create file'
    call MIOL_openw_file_NC(TRIM(cl_stats), il_file_id)
    call MIOL_write_field_NC (il_file_id,&
                              'longitude',&
                              'XY',&
                              rlpa_lonm)
    call MIOL_write_field_NC (il_file_id,&
                              'latitude',&
                              'XY',&
                               rlpa_latm)
    call MIOL_write_field_NC (il_file_id,&
                              'time',&
                              'T',&
                               rla_time)
    WRITE(0,*) 'Write lon lat ok'
    call MIOL_write_field_NC (il_file_id,&
                              'mean_diff',&
                              'XY',&
                               rla_diff)
    call MIOL_write_field_NC (il_file_id,&
                              'rms_diff',&
                              'XY',&
                              rla_sumsqrt)
    WRITE(0,*) 'OK1'
    call MIOL_write_field_NC (il_file_id,&
                              'sum',&
                              'XY',&
                              rla_nbpoints)
    call MIOL_write_field_NC (il_file_id,&
                              'box',&
                              'XY',&
                              rla_boite)
    WHERE( isnan(rla_PCI(:,:)) ) rla_PCI(:,:)=rg_fillvalue
    call MIOL_write_field_NC (il_file_id,&
                              'PCI',&
                              'XY',&
                               rla_PCI(:,:))
    WHERE( isnan(rla_PCW(:,:)) ) rla_PCW(:,:)=rg_fillvalue
    call MIOL_write_field_NC (il_file_id,&
                              'PCW',&
                              'XY',&
                               rla_PCW(:,:))
    WHERE( isnan(rla_PCT(:,:)) ) rla_PCT(:,:)=rg_fillvalue
    call MIOL_write_field_NC (il_file_id,&
                              'PCT',&
                              'XY',&
                               rla_PCT(:,:))
    WHERE( isnan(rla_BIAS(:,:)) ) rla_BIAS(:,:)=rg_fillvalue
    call MIOL_write_field_NC (il_file_id,&
                              'BIAS',&
                              'XY',&
                               rla_BIAS(:,:))
    call MIOL_write_field_NC (il_file_id,&
                              'Hitice',&
                              'XY',&
                               rla_hitice(:,:))
    call MIOL_write_field_NC (il_file_id,&
                              'Miss',&
                              'XY',&
                               rla_miss(:,:))
    call MIOL_write_field_NC (il_file_id,&
                              'FalseAlarm',&
                              'XY',&
                              rla_falsealarm(:,:))
    call MIOL_write_field_NC (il_file_id,&
                              'Hitwater',&
                              'XY',&
                              rla_hitwater(:,:))
    !** Write timeseries
    call MIOL_write_field_NC (il_file_id,&
                              'rms_diff_timeserie',&
                              'T',&
                              rla_rms_timeserie)
    call MIOL_write_field_NC (il_file_id,&
                              'mean_diff_timeserie',&
                              'T',&
                              rla_diff_timeserie)
    call MIOL_write_field_NC (il_file_id,&
                              'PCI_timeserie',&
                              'T',&
                              rla_PCI_timeserie)
    call MIOL_write_field_NC (il_file_id,&
                              'PCW_timeserie',&
                              'T',&
                              rla_PCW_timeserie)
    call MIOL_write_field_NC (il_file_id,&
                              'PCT_timeserie',&
                              'T',&
                              rla_PCT_timeserie)
    call MIOL_write_field_NC (il_file_id,&
                              'BIAS_timeserie',&
                              'T',&
                              rla_BIAS_timeserie)
    call MIOL_write_field_NC (il_file_id,&
                              'Hitice_timeserie',&
                              'T',&
                               rla_hitice_timeserie(:))
    call MIOL_write_field_NC (il_file_id,&
                              'Miss_timeserie',&
                              'T',&
                               rla_miss_timeserie(:))
    call MIOL_write_field_NC (il_file_id,&
                              'FalseAlarm_timeserie',&
                              'T',&
                              rla_falsealarm_timeserie(:))
    call MIOL_write_field_NC (il_file_id,&
                              'Hitwater_timeserie',&
                              'T',&
                              rla_hitwater_timeserie(:))
    call MIOL_write_field_NC (il_file_id,&
                              'sum_timeserie',&
                              'T',&
                              rla_sum_timeserie)
    WRITE(0,*) 'OK2'
    call MIOL_write_field_NC (il_file_id,&
                              'indice',&
                              'XY',&
                              rla_indice)
    WRITE(0,*) 'OK3'
    CALL MIOL_close_file_NC(il_file_id)

    !! Write leatime file
    DEALLOCATE(cla_dimname)
    DEALLOCATE(ila_dimlen)
    il_nbdim=4
    ALLOCATE(cla_dimname(il_nbdim))
    ALLOCATE(ila_dimlen(il_nbdim))
    cla_dimname(1) = 'x'
    cla_dimname(2) = 'y'
    cla_dimname(3) = 'z'
    cla_dimname(4) = 'time'
    ila_dimlen(1) = il_nbx
    ila_dimlen(2) = il_nby
    ila_dimlen(3) = il_echeance
    ila_dimlen(4) = il_nbfile 
    !**  Date conversion for Min Max time interval
    WRITE(0,*) 'Fichier stats ',cl_stats2
    call MIOL_create_file_NC(TRIM(cl_stats2),&
                             il_nbdim,&
                             cla_dimname,&
                             ila_dimlen)
    WRITE(0,*) 'Create file'
    call MIOL_openw_file_NC(TRIM(cl_stats2), il_file_id)
    call MIOL_write_field_NC (il_file_id,&
                              'longitude',&
                              'XY',&
                              rlpa_lonm)
    call MIOL_write_field_NC (il_file_id,&
                              'latitude',&
                              'XY',&
                               rlpa_latm)
    WRITE(0,*) 'SIZE timeseries :',shape(rla_rms_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'mean_diff',&
                              'XYZ',&
                               rla_diff_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'rms_diff',&
                              'XYZ',&
                              rla_sumsqrt_leadtime)
    !** Write timeseries
    call MIOL_write_field_NC (il_file_id,&
                              'rms_diff_timeserie',&
                              'TZ',&
                              rla_rms_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'mean_diff_timeserie',&
                              'TZ',&
                              rla_diff_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'PCI_timeserie',&
                              'TZ',&
                              rla_PCI_timeserie_leadtime)
    WRITE(0,*) 'OK write ulimited'
    call MIOL_write_field_NC (il_file_id,&
                              'PCW_timeserie',&
                              'TZ',&
                              rla_PCW_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'PCT_timeserie',&
                              'TZ',&
                              rla_PCT_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'BIAS_timeserie',&
                              'TZ',&
                              rla_BIAS_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'Hitice_timeserie',&
                              'TZ',&
                               rla_hitice_timeserie_leadtime)
    WRITE(0,*) 'OK2'
    call MIOL_write_field_NC (il_file_id,&
                              'Miss_timeserie',&
                              'TZ',&
                               rla_miss_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'FalseAlarm_timeserie',&
                              'TZ',&
                              rla_falsealarm_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'Hitwater_timeserie',&
                              'TZ',&
                              rla_hitwater_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'sum_timeserie',&
                              'TZ',&
                              rla_sum_timeserie_leadtime)
    call MIOL_write_field_NC (il_file_id,&
                              'time',&
                              'T',&
                               rla_time)
    !!call MIOL_write_field_NC (il_file_id,&
    !!                          'indice',&
    !!                          'XY',&
    !!                          rla_indice)
    WRITE(0,*) 'OK3'
    CALL MIOL_close_file_NC(il_file_id)

    !! Write leatime file
    cl_stats=TRIM(cl_stats_dir)//'Stats_contable_timeseries'//'_'//TRIM(cl_zone)//'_'//TRIM(cl_date1(1:10))//'_'//TRIM(cl_date2(1:10))//'_seuil'//TRIM(cl_seuil)//'_'//TRIM(cl_leadtime)//'.nc'
    WRITE(0,*) 'OK1'
    WRITE(0,*) 'Fin prog'

CONTAINS
!
!*===================================================================================
!
!
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
    LOGICAL,DIMENSION(il_num_neighbors),INTENT(IN)                    :: lda_nbr_mask
    REAL(KIND=4), DIMENSION(il_num_neighbors), INTENT(OUT) :: rda_poids
    REAL(KIND=4), DIMENSION(il_num_neighbors), INTENT(OUT),OPTIONAL :: rda_dist
    REAL(KIND=4), PARAMETER :: rl_ra = 6371.0
    REAL(KIND=8), DIMENSION(il_num_neighbors)              :: rla_dist
    REAL(KIND=8) ::rl_dist_tot,rl_zlon,rl_zlat
    INTEGER      :: il_xind, il_yind
    INTEGER      :: il_n,il_i,il_miss,il_miss2,il_ind
    LOGICAL,DIMENSION(4)      :: ll_ref
!  
!
!***********************************************************************************
!
    !* Initialization

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
    DO il_ind=1,4
        IF  (rda_dist(il_ind) > 0 ) THEN 
            rda_dist(il_ind)=REAL(1/rla_dist(il_ind),KIND=4)*rl_ra
        ELSE
            rda_dist(il_ind)=0.0
        ENDIF
    ENDDO
    ENDSUBROUTINE  IDW
!
!*===================================================================================
!
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



END PROGRAM Stats_seaice_OLA
