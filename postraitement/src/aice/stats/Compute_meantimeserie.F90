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
  !
  !** ++  Local Declarations
  !
  IMPLICIT NONE
  CHARACTER(LEN=256)                         :: cl_input,cl_stats,cl_maskfile,cl_filein,cl_colocFile,cl_namelist,cl_nproc
  CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE  :: cla_dimname,cla_dataFile

  REAL(KIND=4),DIMENSION(:),POINTER          :: rlpa_lon,rlpa_lat
  REAL(KIND=4),DIMENSION(:,:),POINTER        :: rlpa_lonm,rlpa_latm
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE    :: rla_sum,rla_sumsqrt,rla_diff,rla_tmp
  INTEGER(KIND=4),DIMENSION(:,:,:),POINTER   :: ilpa_mask
  INTEGER, DIMENSION(4)                      :: ila_vertxindex,ila_vertyindex,vertex 
  INTEGER(KIND=4)                            :: il_nbmonth
  LOGICAL,DIMENSION(4)                      :: lla_nbr_vertex
  !**

  il_nbmonth=12
!  NAMELIST / Liste_aice / il_nbfile
!  il_narg=iargc()
!  IF (il_narg.NE.2) THEN
!     PRINT *,' '
!     PRINT *,' Compute seaice usage : '
!     PRINT *,' -n namelist   : namelist file'
!     STOP
!  ELSE
!     DO il_ji=1,il_narg
!        CALL getarg(il_ji,cl_input)
!        IF (cl_input .EQ. '-n') THEN
!           CALL getarg(il_ji+1, cl_namelist)
!        ENDIF
!     ENDDO
!  ENDIF 
  il_
  !** Open Grid File
  cl_lon='longitude'
  cl_lat='latitude'
  cl_var='mask'
  cl_maskfile='/homelocal/cregnier/DATA_SGPS/static/output_masks/PSY4V2R2_ARC_msk.nc'
   cl_maskfile='/naviti/data2/cregnier/static/PSY4V2R2_ARC_msk.nc'
  CALL MIOL_openr_file_NC(cl_maskfile,il_filemask)
  CALL MIOL_read_field_NC(il_filemask,cl_lon,rlpa_lonm,ila_lon2D)   
  CALL MIOL_read_field_NC(il_filemask,cl_lat,rlpa_latm,ila_lat2D)   
  CALL MIOL_read_field_NC(il_filemask,cl_var,ilpa_mask,ila_mask)   
  il_nbx=ila_lon2D(1)
  il_nby=ila_lon2D(2)
  CALL MIOL_close_file_NC(il_filemask)
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
  ALLOCATE(rla_sum(il_nbx,il_nby),rla_diff(il_nbx,il_nby),rla_sumsqrt(il_nbx,il_nby))
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
     cl_var='best_estimate'
     cl_varobs='observation'
     CALL MIOL_openr_file_NC(cl_filein,il_filein)
     CALL MIOL_read_field_NC(il_filein,cl_lon,rlpa_lon,ila_lon)   
     CALL MIOL_read_field_NC(il_filein,cl_lat,rlpa_lat,ila_lat)   
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_qc),rlpa_3Dtmp)
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_var),rlpa_var)
     CALL MIOL_read_field_NC(il_filein,TRIM(cl_varobs),rlpa_varobs)
    ! print *,COUNT(rlpa_var(:,:,:) .NE. 0.)
    ! print *,COUNT(rlpa_3Dtmp(:,:,:) .EQ. 1)
    ! print *,SHAPE(rlpa_3Dtmp)
    ! print *,SHAPE(rlpa_var)
     CALL MIOL_close_file_NC(il_filein)
     rl_latmin=MINVAL(rlpa_latm)
     rl_latmin=45.0
     rl_latmax=MAXVAL(rlpa_latm)
     il_nbprof=ila_lon(1)
     !** Compute Canvas
     !print *,'taille :',shape(ilpa_mask)
     CALL GenereCanvas(ilpa_mask(:,:,1),ilpa_kanvas,ilpa_igrd,ilpa_jgrd)
     WRITE(0,*) 'Generation Canvas OK'
     il_ind=0
     CALL MIOL_getFreeLU(il_ficloc)
     il_len=len_trim(cl_filein)
     cl_colocfile=TRIM(cl_filein(1:il_len-3))//'.dat'
     WRITE(0,*) 'Name of coloc file ',cl_colocfile
  !   cl_colocFile='/homelocal/cregnier/DATA/CLASS4_ICE/position_coloc_20150102.txt'
     OPEN(il_ficloc, file=TRIM(cl_colocFile), &
                  status='new', &
                  form='formatted')
     IF ( il_ji == 1 ) THEN
        rla_sum(:,:)=0
        rla_diff(:,:)=0
        rla_sumsqrt(:,:)=0
     ENDIF
     DO il_prof = 1,il_nbprof
        ! IF ( ila_qcprofilel(il_prof) == 1 ) THEN
        !** recherche du numero de boite
        rl_lon=rlpa_lon(il_prof)
        rl_lat=rlpa_lat(il_prof)
        il_boite=9999.
        IF ( (rl_lat .GE. rl_latmin) .AND. &
                    (rl_lat .LE. rl_latmax) .AND. (rlpa_3Dtmp(1,1,il_prof) .EQ. 0) .AND. (rlpa_var(1,1,il_prof) .NE. 0) ) THEN
                    !(rl_lat .LE. rl_latmax) .AND. (rlpa_var(1,1,il_prof) .NE. 0) ) THEN
          !print *,rl_lon,rl_lat,rlpa_3Dtmp(1,1,il_prof),rlpa_var(1,1,il_prof)
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
          IF (ANY (vertex(1:4) /= 0) ) THEN
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
             CALL MCAL_IDW(rl_lon,&
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

             IF ( SUM(rla_poids_vertex(:)) > 1.01 ) THEN
                 WRITE(0,*) 'Somme des poids > 1 :: ',SUM(rla_poids_vertex(:))
                 WRITE(0,*) 'Valeur des vertex en x :: ',ila_vertxindex(:)
                 WRITE(0,*) 'Valeur des vertex en y :: ',ila_vertyindex(:)
                 WRITE(0,*) 'nombre de vextex :: ',lla_nbr_vertex(:)
                 WRITE(0,*) 'position du point :: ',rl_lon,rl_lat
                 STOP
             ENDIF
             il_loc=MAXLOC(rla_poids_vertex(:))
             il_xindex=ila_vertxindex(il_loc(1))
             il_yindex=ila_vertyindex(il_loc(1))
             il_boite=ilpa_kanvas(il_xindex,il_yindex)
             rla_sum(il_xindex,il_yindex)=rla_sum(il_xindex,il_yindex)+1
             rl_diff=rlpa_var(1,1,il_prof)-rlpa_varobs(1,1,il_prof)
             rl_diffsqr=rl_diff*rl_diff
             rla_diff(il_xindex,il_yindex)=rla_diff(il_xindex,il_yindex)+rl_diff
             rla_sumsqrt(il_xindex,il_yindex)=rla_sumsqrt(il_xindex,il_yindex)+rl_diffsqr
             !WRITE(0,*) 'Vertex OK : ',il_xindex,il_yindex
             !WRITE(0,*) 'Boite OK : ',il_boite
             !WRITE(0,*) 'Vertex OK : ',vertex
             !WRITE(0,*) '******************************'
             il_ind=il_ind+1
             WRITE(il_ficloc,'(i8,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,i6,2x,i6)',ADVANCE='yes') &
                            il_prof, rl_lon, rl_lat, &
                            il_ind,il_xindex,il_yindex,il_boite
             !WRITE(il_ficloc,'(i8,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,i6,2x,&
             !               i6,2x,i6,2x,i6)',ADVANCE='yes') &
             !               il_prof, rl_lon, rl_lat, &
             !               il_ind,vertex(1),vertex(2),vertex(3),vertex(4),il_boite
             !CALL FLUSH(0)
          ENDIF
        ENDIF
     ENDDO
     CLOSE(il_ficloc)
     WRITE(0,*) "File OK"
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps de recherche :",REAL(il_t2 - il_t1) / il_ir
  ENDDO
  CLOSE(il_fic)

  il_nbdim=2
  ALLOCATE(rla_tmp(il_nbx,il_nby))
  ALLOCATE(cla_dimname(il_nbdim))
  ALLOCATE(ila_dimlen(il_nbdim))
  cla_dimname(1) = 'x' 
  cla_dimname(2)=  'y'
  ila_dimlen(1) = il_nbx 
  ila_dimlen(2) = il_nby
  rla_tmp(:,:)=rg_fillvalue
 
  cl_stats=TRIM(cl_filein(1:12))//'_Stats.nc' 

  call MIOL_create_file_NC(TRIM(cl_stats),&
                           il_nbdim,&
                           cla_dimname,&
                           ila_dimlen)
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
                            'Canvas',&
                            'XY',&
                             ilpa_kanvas)
  WHERE(rla_diff(:,:) .NE. 0) rla_tmp(:,:)= rla_diff(:,:)/rla_sum(:,:)
  call MIOL_write_field_NC (il_file_id,&
                            'mean_diff',&
                            'XY',&
                             rla_tmp(:,:))
  rla_tmp(:,:)=rg_fillvalue
  WHERE(rla_diff(:,:) .NE. 0) rla_tmp(:,:)=  SQRT(rla_sumsqrt(:,:)/rla_sum(:,:))
  call MIOL_write_field_NC (il_file_id,&
                            'rms_diff',&
                            'XY',&
                             rla_tmp(:,:))

  CALL MIOL_close_file_NC(il_file_id)

 
   WRITE(0,*) 'Nombre d indice : ',il_ind
  STOP
!!  !!*  Box Creation
!!  il_comp=0
!!  DO il_ji=1,il_nbx-1
!!    DO il_jj=1,il_nby-1
!!      il_comp=il_comp+1
!!   !   PRINT *,'Lonmin, latmin , lonmax, latmax ',il_comp,rla_longitude(il_ji),rla_latitude(il_jj),rla_longitude(il_ji),rla_latitude(il_jj+1),rla_longitude(il_ji+1)
!!  !    WRITE(0,*) "Valeurs : ",il_comp,rlpa_lonm(il_ji,il_jj),rlpa_latm(il_ji,il_jj),rlpa_lonm(il_ji+1,il_jj+1),rlpa_latm(il_ji+1,il_jj+1)
!!!      print *,'valeurs ::',il_comp,rla_longitude(il_ji),rla_latitude(il_jj),rla_longitude(il_ji+1),rla_latitude(il_jj+1)
!!    ENDDO
!!    print *,'valeurs ::',il_comp,il_ji,il_nbx
!!  ENDDO
!!  ig_nbregion=il_comp
!!  print *,'valeurs ::',il_comp
!!  ALLOCATE(rga_valeur1(il_comp))
!!  ALLOCATE(rga_info(4,il_comp)) 
!!  il_comp=0
!!  DO il_ji=1,il_nbx-1
!!    DO il_jj=1,il_nby-1
!!        il_comp=il_comp+1
!!        rga_valeur1(il_comp)=il_comp
!!        rga_info(1,il_comp)=rlpa_lonm(il_ji+1,il_jj+1)
!!        rga_info(2,il_comp)=rlpa_latm(il_ji+1,il_jj+1)
!!        rga_info(3,il_comp)=rlpa_lonm(il_ji,il_jj)
!!        rga_info(4,il_comp)=rlpa_latm(il_ji,il_jj)
!!    ENDDO 
!!  ENDDO 
!!  !print *,'Boites :: ',rga_valeur1(:)
!!  !print *,'rga_info 1:: ',rga_info(1,:)
!!  !** Identification BOX
!!  !** Boucle sur chaque profil
!!  IF ( ALLOCATED (rga_IDboite)) DEALLOCATE (rga_IDboite)
!!  ALLOCATE ( rga_IDboite(il_nbprof))
!!  DO il_prof = 1,il_nbprof
!!     ! IF ( ila_qcprofilel(il_prof) == 1 ) THEN
!!          !** recherche du numero de boite
!!          rl_lon=rlpa_lon(il_prof)
!!          rl_lat=rlpa_lat(il_prof)
!!          WRITE(0,*)  "Identification :: ",rl_lon,rl_lat
!!          CALL IdentifierBoiteBins(rl_lon,rl_lat,rl_IDboite,il_status)
!!          rga_IDboite(il_prof)=rl_IDboite
!!          WRITE(0,*)  "Boite :: ",rga_IDboite(il_prof)
!!         ! !** Attribution d un indice de boite
!!         ! il_IndReg=0
!!         ! !** Recherche de l'indice dans le tableau
!!         ! DO il_i=1,ig_nbregion
!!         !    IF (rga_valeur1(il_i).EQ.rga_IDboite(ib_p)) THEN
!!         !       il_IndReg=il_i
!!         !    ENDIF
!!         ! ENDDO
!!  ENDDO
     
END PROGRAM  Stats_aice
