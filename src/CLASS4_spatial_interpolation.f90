!
PROGRAM SPATIAL_INTERPOLATION
  !!==============================================================================================================
  !> \brief    Description : Ce programme permet de réaliser l'interpolation
  !!                          spatiale aux points de mouillage sur la colonne
  !!                          d'eau
  !!
  !! History :
  !!        \n 10/2007      (F.MESSAL)  Creation du programme
  !!        \n 04/2008     (C.REGNIER)  grosses modifications sur le code => passage operationnel
  !!
  !!        \n 01/2009     (C.REGNIER)  modification du pgr qui tourne en oper pour portage au CE et test sur
  !!                                    les sorties NEATL36
  !!        \n 03/17/2009   (C.REGNIER) Version stable pour le calcul des class4
  !!                                    avec GLORYS sur CORA02
  !!        \n 04/30/2009   (C.REGNIER) Correction bug sur les flags PRES_QC :
  !!                                    prise en compte correcte de 0 et 1
  !!        \n 04/21/2011   (C.REGNIER) Prise en compte des données
  !!                                    ENACT/ENSEMBLE avec la variable DEPH_CORRECTED
  !!                                    Ajout d'une clé débug 
  !!         \n 06/2013     (C.REGNIER) Adaptation pour les fichiers ARMOR insitu avec prise en compte de qc differents
  !!         \n 11/2013     (C.REGNIER) Réécriture du code pour prendre en compte à la fois T et S et convertir la temperature
  !!                                    potentielle du modèle en insitu
  !<
  !===================================================================================================================
  !
  !
  USE netcdf
  USE MCAL
  USE MIOL 
  USE MIOL_param
  USE table_CLASS4
  USE GSW_TEOS10 

  IMPLICIT NONE
  !
  INTEGER :: il_narg, &
       iargc, &
       il_ji, &
       il_file_id, &
       il_nbfile, &
       il_status, &
       il_jdateT0, &
       il_jdateT1

  CHARACTER(LEN=255) :: cl_input, &
       cl_inputFile, &
       cl_colocFile, &
       cl_modelFileT, &
       cl_modelFileS, &
       cl_outputVarname_T, &
       cl_outputVarname_S, &
       cl_colocRep, &
       cl_commandFile,&
       cl_inputVarname_T, &
       cl_inputVarname_S, &
       cl_modelVarname_T, &
       cl_modelVarname_S, &
       cl_input_type, &
       cl_input_typemod, &
       cl_modele,&
       cl_daterun,&
       cl_meshfile,& 
       cl_log

  CHARACTER(LEN=255), DIMENSION(:), ALLOCATABLE :: cla_inputFile
  LOGICAL :: ll_3Dinterpolation
  NAMELIST / interpolate_3D / cl_modelFileT, &
       cl_modelFileS, &
       cl_colocRep, &
       cl_inputVarname_T, &
       cl_inputVarname_S, &
       cl_modelVarname_T, &
       cl_modelVarname_S, &
       cl_outputVarname_T, &
       cl_outputVarname_S, &
       cl_input_type, &
       cl_input_typemod, &
       cl_meshfile, &
       il_nbfile
  !

  !
  ll_3Dinterpolation = .TRUE.
  !
  !
  !------------------------------------------------------------------------
  ! Lecture arguments
  !
  il_narg=iargc()
  IF ((il_narg .NE. 6) .AND. &
       (il_narg .NE. 8)) THEN
     PRINT *,' '  
     PRINT *,' interpolate_prof3d usage : '
     PRINT *,'     interpolate_prof3d -c commandfile.nml ' 
     PRINT *,' '
     PRINT *,' -c commandfile.nml   : The command file '
     PRINT *,' -t                   : Temporal interpolation '
     PRINT *,' Nb arguments  :: ',il_narg
     STOP
  ELSE
     DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-c') THEN
           CALL getarg(il_ji+1, cl_commandFile)
        ENDIF
        IF (cl_input .EQ. '-t') THEN
           ll_3Dinterpolation = .FALSE.
        ENDIF
        IF (cl_input .EQ. '-m') THEN
           CALL getarg(il_ji+1, cl_modele)
           cg_modele=cl_modele
        ENDIF
        IF (cl_input .EQ. '-r') THEN
           CALL getarg(il_ji+1, cl_daterun)
           cg_rundate=TRIM(cl_daterun)
        ENDIF
        IF (cl_input .EQ. '-l') THEN
           CALL getarg(il_ji+1, cl_log)
           cg_ficlog=TRIM(cl_log)
        ENDIF
     ENDDO

  ENDIF
  !
  !
  !------------------------------------------------------------------------
  ! Lecture du command file
  !
     WRITE(0,*) 'Lecture de la namelist',cl_commandFile
     OPEN(20, file=TRIM(cl_commandFile), &
          status='old', &
          form='formatted', &
          iostat=il_status)
     READ(20, interpolate_3D)
     ALLOCATE(cla_inputFile(il_nbfile), stat=il_status)
     IF ( il_status /= 0 ) THEN
        WRITE(0,*) ' interpolate_prof3D : memory allocation error.'
        CALL flush(0)
        STOP
     ENDIF
     DO il_ji=1, il_nbfile 
        READ(20,FMT='(A)') cla_inputFile(il_ji)
     ENDDO
     CLOSE(20)
#if defined key_debug
     WRITE(0,*) 'Read Namelist ok',cl_modelFileT, &
       cl_modelFileS, &
       cl_colocRep, &
       cl_inputVarname_T, &
       cl_inputVarname_S, &
       cl_modelVarname_T, &
       cl_modelVarname_S, &
       cl_outputVarname_T, &
       cl_outputVarname_S, &
       cl_input_type, &
       il_nbfile
#endif
     !
     !
     !------------------------------------------------------------------------
     ! Interpolation du modele
     !
     CALL interpolate_3D_model_field(cl_modelFileT, &
          cl_modelFileS,&
          cl_colocRep, &
          cl_inputVarname_T, &
          cl_inputVarname_S, &
          cl_modelVarname_T, &
          cl_modelVarname_S, &
          cl_outputVarname_T, &
          cl_outputVarname_S, &
          cl_input_type, &
          cl_input_typemod, &
          il_nbfile, &
          cla_inputFile,&
          cl_meshfile)
     !      
     IF (ALLOCATED(cla_inputFile)) DEALLOCATE(cla_inputFile, stat=il_status)
     IF ( il_status /= 0 ) THEN
        WRITE(0,*) ' interpolate_prof3D : memory deallocation error.'
        CALL flush(0)
        STOP
     ENDIF
     !
  !
CONTAINS
!ENDPROGRAM SPATIAL_INTERPOLATION
!
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE interpolate_3D_model_field(cd_modelFileT, &
                                      cd_modelFileS, &
                                      cd_colocRep, &
                                      cd_inputVarname_T, &
                                      cd_inputVarname_S, &
                                      cd_modelVarname_T, &
                                      cd_modelVarname_S, &
                                      cd_outputVarname_T, &
                                      cd_outputVarname_S, &
                                      cd_input_type, &
                                      cd_input_modtype, &
                                      id_nbfile, &
                                      cda_inputFile,&
                                      cd_meshfile)
  !==============================================================================================================
  !> \brief    Description : Routine principale qui réalise l'interpolation des profiles modèles colocalisés autour 
  !!                         des points d'observation
  !<
  !===================================================================================================================
  
  USE netcdf
  USE MCAL
  USE MIOL 
  IMPLICIT NONE
  !     
  INTEGER :: id_nbfile
  CHARACTER(LEN=255), DIMENSION(id_nbfile), INTENT(IN) :: cda_inputFile 
  CHARACTER(LEN=255), INTENT(IN)                       :: cd_colocRep, &
                                                          cd_modelFileT, &
                                                          cd_modelFileS, &
                                                          cd_inputVarname_T, &
                                                          cd_inputVarname_S, &
                                                          cd_modelVarname_T, &
                                                          cd_modelVarname_S, &            
                                                          cd_outputVarname_S,&
                                                          cd_outputVarname_T,&
                                                          cd_input_type,&
                                                          cd_input_modtype,&
                                                          cd_meshfile
  !
  INTEGER(KIND=4)                                       :: il_ji,il_jk,il_v,il_nbdim,il_nlon,il_nlat, &
                                                           il_fic,il_ndepth,il_nprof,il_nlevels,&
                                                           il_nbvar,il_t1,il_t2,il_ir,il_eof,il_status,il_nbrec,&
                                                           il_filid,il_outputVarname1,il_file_id,il_variable_id,il_parameterintid,il_offset
  INTEGER, DIMENSION(:,:), ALLOCATABLE                  :: ila_xindex,ila_yindex
  CHARACTER(LEN=255)                                    :: cl_depthvarname,cl_inputFile,&
                                                           cl_tmp,cl_colocFile,cl_outputfile,&
                                                           cl_outputVarname,cl_file,cl_varname,&
                                                           cl_param,cl_outputVarname1,cl_outputVarname2
  CHARACTER(LEN=25)                                     :: cl_cparam,cl_lparam
  CHARACTER(LEN=12)                                     :: cl_null
  CHARACTER(LEN=255), DIMENSION(2)                      :: cla_dimname
  CHARACTER(LEN=1), DIMENSION(:), ALLOCATABLE           :: cla_positionqc
  CHARACTER(LEN=20), DIMENSION(:), ALLOCATABLE          :: cla_dephvarname
  CHARACTER(LEN=12), DIMENSION(20)                      :: cla_parameterint
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE               :: rla_poids

  CHARACTER(LEN=255), DIMENSION(:), POINTER             :: clpa_varname
  INTEGER, DIMENSION(:), POINTER                        :: ilpa_dimlen,ilpa_nbdim

  REAL(KIND=4), DIMENSION(:,:), ALLOCATABLE             :: rla_depthvalue_T,rla_depthvalue_S,&
                                                           rla_depthadjustvalue,rla_interpValueT,&
                                                           rla_interpValueS,rla_temp,rla_psal
  REAL(KIND=4), DIMENSION(:,:,:), ALLOCATABLE           :: rla_modelvalue_T,rla_modelvalue_S
  REAL(KIND=4), DIMENSION(:), ALLOCATABLE               :: rla_modeldepth
  REAL(KIND=4)                                          :: rl_fillvalue,rl_var,rl_date,rl_pres,rl_temp,rl_psal
  REAL(KIND=8)                                          :: rl_date_R8,rl_lon,rl_lat
  REAL(KIND=8), DIMENSION(:), ALLOCATABLE               :: rla_juldvalue
  REAL(KIND=8), DIMENSION(:), ALLOCATABLE               :: rla_LON,rla_LAT

  LOGICAL                                               :: ll_isInputVarPresent_T,ll_isInputVarPresent_S,& 
                                                           ll_isDepth,ll_isPres,&
                                                           ll_isDepth_corr,ll_isdepthadj,&
                                                           ll_ispresadj,ll_param,&
                                                           ll_cparam,ll_lparam,ll_exist,ll_lon,ll_lat,&
                                                           ll_pres,ll_date,ll_temp,ll_psal
  !--------------------------------------------------------------------------
  ! Initialisation

  rl_fillvalue=99999.
  ll_isDepth_corr=.FALSE.
  ll_isdepthadj=.FALSE.
  ll_ispresadj=.FALSE.
  ll_isDepth_corr=.FALSE.
  ll_exist=.FALSE.
  ll_lon=.FALSE.
  ll_lat=.FALSE.
  ll_pres=.FALSE.
  ll_date=.FALSE.
  ll_temp=.FALSE.
  ll_psal=.FALSE.
  !
  !
  !---------------------------------------------------------------------
  ! Recherche des dimensions du fichier modele
  !
  IF (TRIM(cd_input_modtype) .EQ. "NETCDF") THEN
#if defined key_debug
     WRITE(0,*) ' Function inquire_model_Netcdf',TRIM(cd_modelFileT)
#endif
      cl_file=cd_modelFileT
      cl_varname=cd_modelVarname_T
  ELSE IF (TRIM(cd_input_modtype) .EQ. "ALLEGE") THEN
#if defined key_debug
     WRITE(0,*) ' Function inquire_model_file_allege ',TRIM(cd_meshfile)
#endif
      cl_file=cd_meshfile
      cl_varname='mask'
  ENDIF 
  CALL inquire_model_file(cl_file, &
                          cl_varname, &
                          il_nbdim, &
                          il_nlon, &
                          il_nlat, &
                          il_ndepth, &
                          cl_depthvarname)
#if defined key_debug
     WRITE(0,*) ' Function inquire_model_file OK '
#endif
  !
  !------------------------------------------------------------------------
  ! Boucle sur les fichiers d'entrée
  !
  DO il_ji=1, id_nbfile
     !
     cl_inputFile = cda_inputFile(il_ji)
     cl_tmp = TRIM(cl_inputFile(INDEX(cl_inputFile,'/',back=.true.)+1:LEN(TRIM(cl_inputFile))))
     cl_colocFile = TRIM(cd_colocRep)//TRIM(cl_tmp(1:LEN(TRIM(cl_tmp))-3))//'.dat'
     IF  (TRIM(cd_input_type) .EQ. "ASCII") THEN
        cl_colocFile = TRIM(cd_colocRep)//TRIM(cl_tmp(1:LEN(TRIM(cl_tmp))-4))//'.dat'
        cl_outputfile = TRIM(cd_colocRep(1:LEN(TRIM(cd_colocRep))-7))//TRIM(cl_tmp(1:LEN(TRIM(cl_tmp))-4))//'.nc'
     ELSE IF (TRIM(cd_input_type) .EQ. "NETCDF") THEN   
        cl_colocFile = TRIM(cd_colocRep)//TRIM(cl_tmp(1:LEN(TRIM(cl_tmp))-3))//'.dat'
     ELSE 
        WRITE(0,*) ' Type file not known '
     ENDIF
#if defined key_debug
     WRITE(0,*) ' fichier traite 3D : ',TRIM(cda_inputFile(il_ji))
     WRITE(0,*) ' fichier coloc : ',TRIM(cl_colocFile)
#endif
!     !------------------------------------------------------------------
!     !  Lecture des dimensions de parameterint
!     CALL read_parameterint_dim(cl_inputFile,ll_cparam,ll_lparam,ll_param)  
!#if defined key_debug
!     WRITE(0,*) 'read_parameterint_dim OK '
!#endif
     !
     !
     !---------------------------------------------------------------------
     ! Recherche des dimensions du fichier de données
     IF  (TRIM(cd_input_type) .EQ. "ASCII") THEN
        il_eof=0
        INQUIRE(FILE=cl_inputFile,EXIST=ll_exist)
        IF (ll_exist) THEN
           CALL MIOL_getFreeLU(il_fic)
           OPEN(il_fic, FILE=cl_inputFile,form='FORMATTED',STATUS='OLD',iostat=il_status)
           il_nbrec=0
           DO WHILE (il_eof == 0 )
              READ(il_fic,*,iostat=il_eof) rl_var
              IF (il_eof==0) then !* la lecture s'est bien passee
              !* on incremente le compteur du nombre de lignes
                 il_nbrec=il_nbrec+1
              ENDIF
           ENDDO              
           CLOSE(il_fic)
           il_nprof=1
           il_nlevels=il_nbrec
           ll_isInputVarPresent_T=.TRUE.
           ll_isInputVarPresent_S=.TRUE.
           ll_isPres=.TRUE.
        ELSE 
            WRITE(0,*) 'File doesn t exist: ',cl_inputFile
            STOP
        ENDIF
     ELSE IF (TRIM(cd_input_type) .EQ. "NETCDF") THEN
#if defined key_debug
        WRITE(0,*) ' inquire_coriolis_file '
#endif

         CALL inquire_coriolis_file(cl_inputFile, &
                                    cd_inputVarname_T, &
                                    cd_inputVarname_S, &
                                    il_nprof, &
                                    il_nlevels, &
                                    cla_dimname, &
                                    ll_isInputVarPresent_T, &
                                    ll_isInputVarPresent_S, &
                                    ll_isDepth,&
                                    ll_isPres,&
                                    ll_isdepthadj,&
                                    ll_ispresadj,&
                                    ll_isDepth_corr,&
                                    ll_param,&
                                    ll_cparam,&
                                    ll_lparam)
         !
         !------------------------------------------------------------------
         ! Ecriture de la nouvelle variable PARAMETERINT
         !
         IF ( .NOT. ll_param) CALL write_parameterint(cl_inputFile,ll_cparam,ll_lparam,ll_param)
#if defined key_debug
     WRITE(0,*) ' write_parameterint OK '
#endif
     ELSE
        WRITE(0,*) 'Input type not define ! '
        STOP
     ENDIF
     !
     !
     !---------------------------------------------------------------------
     ! Si la variable est presente dans le fichier Coriolis
     ! alors lecture des fichiers et calcul 
     !
     IF (ll_isInputVarPresent_T .OR. ll_isInputVarPresent_S ) THEN
        !
        !
        !------------------------------------------------------------------
        ! Lecture du fichier Coriolis
        !
        IF (ALLOCATED(rla_depthvalue_T)) DEALLOCATE(rla_depthvalue_T)
        ALLOCATE(rla_depthvalue_T(il_nlevels, il_nprof))
        IF (ALLOCATED(rla_depthvalue_S)) DEALLOCATE(rla_depthvalue_S)
        ALLOCATE(rla_depthvalue_S(il_nlevels, il_nprof))
        IF (ALLOCATED(rla_depthadjustvalue)) DEALLOCATE(rla_depthadjustvalue)
        ALLOCATE(rla_depthadjustvalue(il_nlevels, il_nprof))
        IF (ALLOCATED(cla_positionqc)) DEALLOCATE(cla_positionqc)
        ALLOCATE(cla_positionqc(il_nprof))
        IF (ALLOCATED(cla_dephvarname)) DEALLOCATE(cla_dephvarname)
        ALLOCATE(cla_dephvarname(il_nprof))
        IF (ALLOCATED(rla_juldvalue)) DEALLOCATE(rla_juldvalue)
        ALLOCATE(rla_juldvalue(il_nprof))
        IF (ALLOCATED(rla_LON)) DEALLOCATE(rla_LON)
        ALLOCATE(rla_LON(il_nprof))
        IF (ALLOCATED(rla_LAT)) DEALLOCATE(rla_LAT)
        ALLOCATE(rla_LAT(il_nprof))
#if defined key_debug
        WRITE(0,*) 'read_coriolis_file ::',cl_inputFile,cd_inputVarname_T,cd_inputVarname_S
#endif
#if defined key_cputime                                                                                      
     il_t1=0
     il_t2=0
     CALL SYSTEM_CLOCK(count=il_t1)
#endif
        IF  (TRIM(cd_input_type) .EQ. "ASCII") THEN
           IF (ALLOCATED(rla_temp)) DEALLOCATE(rla_temp)
           ALLOCATE(rla_temp(il_nlevels, il_nprof))
           IF (ALLOCATED(rla_psal)) DEALLOCATE(rla_psal)
           ALLOCATE(rla_psal(il_nlevels, il_nprof))
           il_eof=0
           !* Read ASCII file time/lon/lat/pres/temp/sal
           CALL MIOL_getFreeLU(il_fic)
           OPEN(il_fic, FILE=cl_inputFile,form='FORMATTED',STATUS='OLD',iostat=il_status)
           il_nbrec=0
           DO WHILE (il_eof == 0 )
              READ(il_fic,*,iostat=il_eof) rl_date,rl_lon,rl_lat,rl_pres,rl_temp,rl_psal
              IF ( il_eof == 0 ) THEN 
                 il_nbrec=il_nbrec+1
                 rla_LON(1)=rl_lon
                 rla_LAT(1)=rl_lat
                 rla_depthvalue_T(il_nbrec,1)=rl_pres
                 rla_depthvalue_S(il_nbrec,1)=rl_pres
                 rla_temp(il_nbrec,1)=rl_temp
                 rla_psal(il_nbrec,1)=rl_psal
                 rla_juldvalue(1)=rl_date
                 cla_positionqc(1)='1'
              ENDIF
           ENDDO              
           CLOSE(il_fic)
        ELSE IF (TRIM(cd_input_type) .EQ. "NETCDF") THEN
           CALL read_coriolis_file(cl_inputFile, &
                                   cd_inputVarname_T, &
                                   cd_inputVarname_S, &
                                   il_nprof, &
                                   il_nlevels, &
                                   ll_isInputVarPresent_T,&
                                   ll_isInputVarPresent_S, &
                                   ll_isDepth, &
                                   ll_isDepth_corr,&
                                   ll_isdepthadj,&
                                   ll_isPres, &
                                   ll_ispresadj,&
                                   rla_depthvalue_T, &
                                   rla_depthvalue_S, &
                                   cla_positionqc, &
                                   rla_juldvalue, &
                                   rl_fillvalue,&
                                   rla_LON,&
                                   rla_LAT,&
                                   cla_dephvarname)
        ELSE
          WRITE(0,*) 'Input type not define ! '
          STOP
        ENDIF
#if defined key_cputime                                                                                      
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps read_input file_file :",REAL(il_t2 - il_t1) / il_ir
#endif
#if defined key_debug
        WRITE(0,*) 'read_inputfile ok ::',cl_inputFile,ll_isDepth,ll_isPres
!        WRITE(0,*) 'Prof T ::',rla_depthvalue_T(:,10)
!        WRITE(0,*) 'Prof S ::',rla_depthvalue_S(:,10)
#endif
        !
        !
        !------------------------------------------------------------------
        ! Lecture du fichier de colocalisation
        !

        ALLOCATE(ila_xindex(4,il_nprof))
        ALLOCATE(ila_yindex(4,il_nprof))
        ALLOCATE(rla_poids(4,il_nprof))
	!** Initialisation
	rla_poids(1:4,il_nprof)=0.0
	ila_xindex(1:4,il_nprof)=9999.
        ila_yindex(1:4,il_nprof)=9999.
#if defined key_debug
        WRITE(0,*),'read_coloc_file ::',cl_colocFile
#endif
#if defined key_cputime                                                                                      
     il_t1=0
     il_t2=0
     CALL SYSTEM_CLOCK(count=il_t1)
#endif
        CALL read_coloc_file(cl_colocFile, &
                             il_nprof, &
                             ila_xindex, & 
                             ila_yindex, &
                             rla_poids, &
                             cla_positionqc)
#if defined key_cputime                                                                                      
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps read_coloc_file :",REAL(il_t2 - il_t1) / il_ir
#endif
#if defined key_debug
        WRITE(0,*),'read_coloc_file ok ::',cl_colocFile
#endif
        !------------------------------------------------------------------
        ! Lecture des fichiers modèle
        !
        IF (ALLOCATED (rla_modelvalue_T)) DEALLOCATE(rla_modelvalue_T)
        ALLOCATE(rla_modelvalue_T(4,il_nprof,il_ndepth))
        IF (ALLOCATED (rla_modelvalue_S)) DEALLOCATE(rla_modelvalue_S)
        ALLOCATE(rla_modelvalue_S(4,il_nprof,il_ndepth))
        IF (ALLOCATED (rla_modeldepth)) DEALLOCATE(rla_modeldepth)
        ALLOCATE(rla_modeldepth(il_ndepth))
#if defined key_debug
        WRITE(0,*),'Debut Read File '
        WRITE(0,*),'read_model_file T ',cd_modelFileT
        WRITE(0,*),'read_mode_field S ',cd_modelFileS
#endif
#if defined key_cputime                                                                                      
     il_t1=0
     il_t2=0
     CALL SYSTEM_CLOCK(count=il_t1)
#endif
        IF (TRIM(cd_input_modtype) .EQ. "NETCDF") THEN
#if defined key_debug
    WRITE(0,*) 'Read model file NETCDF'
#endif
            CALL read_model_file(cd_modelFileT, &
                                 cd_modelFileS, &
                                 cd_modelVarname_T, &
                                 cd_modelVarname_S, &
                                 cl_depthvarname, &
                                 ila_xindex,&
                                 ila_yindex,&
                                 rla_modelvalue_T, & 
                                 rla_modelvalue_S, & 
                                 rla_modeldepth, &
                                 il_nprof,&
                                 il_nlon, &
                                 il_nlat, &
                                 il_ndepth, &
                                 il_nbdim)
        ELSE IF (TRIM(cd_input_modtype) .EQ. "ALLEGE") THEN
#if defined key_debug
    WRITE(0,*) 'Read model file ALLEGE'
#endif
            CALL read_allege_model_file(cd_modelFileT, &
                                 cd_modelFileS, &
                                 cd_meshfile,&
                                 ila_xindex,&
                                 ila_yindex,&
                                 rla_modelvalue_T, & 
                                 rla_modelvalue_S, & 
                                 rla_modeldepth, &
                                 il_nprof,&
                                 il_nlon, &
                                 il_nlat, &
                                 il_ndepth, &
                                 il_nbdim)
        ENDIF
#if defined key_cputime
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps read_model_file :",REAL(il_t2 - il_t1) / il_ir
#endif
        !
        !------------------------------------------------------------------
        ! Calcul de l'interpolation en profondeur en prenant les 4 profiles colocalisés
        !
        IF (ALLOCATED (rla_interpValueT)) DEALLOCATE(rla_interpValueT)
        ALLOCATE(rla_interpValueT(il_nlevels, il_nprof))
        IF (ALLOCATED (rla_interpValueS)) DEALLOCATE(rla_interpValueS)
        ALLOCATE(rla_interpValueS(il_nlevels, il_nprof))
#if defined key_debug
        WRITE(0,*),'interp_model_field OK ',TRIM(cl_tmp)
#endif
#if defined key_cputime                                                                                      
     il_t1=0
     il_t2=0
     CALL SYSTEM_CLOCK(count=il_t1)
#endif
        CALL interp_model_field(rla_modelvalue_T, &
                                rla_modelvalue_S, &
                                rla_modeldepth, &
                                rla_interpValueT, &
                                rla_interpValueS, &
                                il_nlon, &
                                il_nlat, &
                                il_ndepth, &
                                ila_xindex, &
                                ila_yindex, &
                                rla_depthvalue_T, &
                                rla_depthvalue_S, &
                                rla_LON,&
                                rla_LAT,&
                                rla_juldvalue,&
                                cla_positionqc, &
                                il_nprof, &
                                il_nlevels, &
                                TRIM(cl_tmp),&
                                rla_poids,&
                                rl_fillvalue)
#if defined key_cputime                                                                                      
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps interp_model_file :",REAL(il_t2 - il_t1) / il_ir
#endif
#if defined key_debug
       WRITE(0,*),'interp_model_field ok'
       WRITE(0,*),'rla_modelValueT :: ',rla_modelvalue_T(1,1,:)
       WRITE(0,*),'rla_interpValueT :: ',rla_interpValueT(:,1)
       WRITE(0,*),'rla_modelValueS :: ',rla_modelvalue_S(1,1,:)
       WRITE(0,*),'rla_interpValueS :: ',rla_interpValueS(:,1)
#endif
        !
        !
        !------------------------------------------------------------------
        ! Ecriture des nouveaux champs
        !
#if defined key_debug
        WRITE(0,*),'write_interp_field ',TRIM(cd_outputVarname_T)
#endif

       IF (ll_isInputVarPresent_T) THEN 
#if defined key_cputime                                                                                      
     il_t1=0
     il_t2=0
     CALL SYSTEM_CLOCK(count=il_t1)
#endif
        IF  (TRIM(cd_input_type) .EQ. "ASCII") THEN
           CALL write_interp_field_ASCII_2D(cl_outputfile, &
                                         cd_outputVarname_T,&
                                         il_nprof, &
                                         il_nlevels, &
                                         rla_interpValueT)
           CALL write_interp_field_ASCII_2D(cl_outputfile, &
                                         cd_outputVarname_S,&
                                         il_nprof, &
                                         il_nlevels, &
                                         rla_interpValueS)

           CALL MIOL_inquire_variables_NC(cl_outputfile, &
                                          il_nbvar, &
                                          clpa_varname, &
                                          ilpa_nbdim)
           DO il_v=1, il_nbvar
              SELECT CASE (TRIM(clpa_varname(il_v)))
              CASE ('LONGITUDE')
                 ll_lon = .TRUE.
              CASE ('LATITUDE')
                 ll_lat=.TRUE.
              CASE ('PRES')
                 ll_pres= .TRUE.
              CASE ('JULD')
                 ll_date= .TRUE.
              CASE ('TEMP')
                 ll_temp= .TRUE.
              CASE ('PSAL')
                 ll_psal= .TRUE.
              ENDSELECT
           ENDDO
           !** Test the existence before write
           IF ( .NOT. ll_lon )  THEN 
               cl_outputVarname='LONGITUDE'
               rl_lon=rla_LON(1)
               CALL write_interp_field_ASCII_1D(cl_outputfile, &
                                             cl_outputVarname,&
                                             il_nprof, &
                                             rl_lon)
           ENDIF
           IF ( .NOT. ll_lat )  THEN 
              cl_outputVarname='LATITUDE'
              rl_lat=rla_LAT(1)
              CALL write_interp_field_ASCII_1D(cl_outputfile, &
                                            cl_outputVarname,&
                                            il_nprof, &
                                            rl_lat)
           ENDIF
           IF ( .NOT. ll_date )  THEN 
              cl_outputVarname='JULD'
              rl_date_R8=rla_juldvalue(1)
              print *,'DATE :: ',rl_date_R8
              CALL write_interp_field_ASCII_1D(cl_outputfile, &
                                            cl_outputVarname,&
                                            il_nprof, &
                                            rl_date_R8)
           ENDIF
           IF ( .NOT. ll_pres )  THEN 
              cl_outputVarname='PRES'
              CALL write_interp_field_ASCII_2D(cl_outputfile, &
                                            cl_outputVarname,&
                                            il_nprof, &
                                            il_nlevels, &
                                            rla_depthvalue_T)
#if defined key_debug
          WRITE(0,*) 'Write varname OK : ',cl_outputVarname
#endif
           ENDIF
           IF ( .NOT. ll_temp )  THEN 
              cl_outputVarname='TEMP'
              WHERE( isnan(rla_temp(:,:)) ) rla_temp(:,:)=rg_fillvalue
              CALL write_interp_field_ASCII_2D(cl_outputfile, &
                                            cl_outputVarname,&
                                            il_nprof, &
                                            il_nlevels, &
                                            rla_temp)
#if defined key_debug
          WRITE(0,*) 'Write varname OK : ',cl_outputVarname
#endif
           ENDIF
           IF ( .NOT. ll_psal )  THEN 
              cl_outputVarname='PSAL'
              WHERE( isnan(rla_psal(:,:)) ) rla_psal(:,:)=rg_fillvalue
              CALL write_interp_field_ASCII_2D(cl_outputfile, &
                                            cl_outputVarname,&
                                            il_nprof, &
                                            il_nlevels, &
                                            rla_psal)
#if defined key_debug
          WRITE(0,*) 'Write varname OK : ',cl_outputVarname
#endif
           ENDIF
        ELSE IF (TRIM(cd_input_type) .EQ. "NETCDF") THEN 
#if defined key_debug
           WRITE(0,*) 'Write interp field ',ll_param,ll_cparam,ll_lparam
#endif
           CALL write_interp_field(cl_inputFile, &
                                   cd_outputVarname_T, &
                                   il_nprof, &
                                   il_nlevels, &
                                   rla_interpValueT, &
                                   cla_dimname, &
                                   rg_fillValue,&
                                   ll_param,&
                                   ll_cparam,&
                                   ll_lparam)
#if defined key_debug
           WRITE(0,*) 'Write interp field OK'
#endif
           CALL MIOL_openw_file_NC(TRIM(cl_inputFile),il_file_id)
           cl_outputVarname1="HDCST_DEPH"
           il_status = NF90_INQ_VARID(il_file_id, &
                                      TRIM(cl_outputVarname1), &
                                      il_outputVarname1)
           IF (il_status .NE. NF90_NOERR) THEN
              CALL MIOL_write_field_NC (il_file_id, &
                                        cl_outputVarname1, &
                                        'ZP', &
                                        rla_depthvalue_T)
#if defined key_debug
              WRITE(0,*) 'Write OK ',cl_outputVarname1
#endif
              cl_outputVarname2="DEPH_VAR_CHOICE"
              CALL MIOL_write_field_NC (il_file_id, &
                                        cl_outputVarname2, &
                                        'CP', &
                                        cla_dephvarname(:),&
                                        20)
#if defined key_debug
              WRITE(0,*) 'Write OK ',cl_outputVarname2
#endif
              !** Write variable name in parameterint
              if ( .NOT. ll_cparam .AND. .NOT. ll_lparam .AND. .NOT. ll_param) THEN
                  cl_cparam='C_PARAMETERINT'
                  cl_lparam='L_PARAMETERINT'
                  cl_param='PARAMETERINT'
              ENDIF
              if ( ll_cparam .AND. ll_lparam .AND. .NOT. ll_param) THEN
                  cl_cparam='C_PARAMETERINT2'
                  cl_lparam='L_PARAMETERINT2'
                  cl_param='PARAMETERINT2'
              endif
              if ( ll_cparam .AND. ll_lparam .AND. ll_param) THEN
                  cl_cparam='C_PARAMETERINT'
                  cl_lparam='L_PARAMETERINT'
                  cl_param='PARAMETERINT'
              endif
              il_status = NF90_INQ_VARID(il_file_id, &
                                         TRIM(cl_param), &
                                         il_parameterintid)
              il_status = NF90_GET_VAR(il_file_id, &
                                       il_parameterintid, &
                                       cla_parameterint)
              il_offset=1
              cl_null = " "
              DO il_jk=1,20
                  IF (TRIM(cla_parameterint(il_jk)) .NE. cl_null) THEN
                     il_offset = il_offset + 1
                   ENDIF
              ENDDO
              cla_parameterint(il_offset) = TRIM(cl_outputVarname1)
              il_offset=1
              cl_null = " "
              DO il_jk=1,20
                  IF (TRIM(cla_parameterint(il_jk)) .NE. cl_null) THEN
                     il_offset = il_offset + 1
                   ENDIF
              ENDDO
              cla_parameterint(il_offset) = TRIM(cl_outputVarname2)
              il_status = NF90_PUT_VAR(il_file_id, &
                                       il_parameterintid, &
                                       cla_parameterint)
           ENDIF
           CALL MIOL_close_file_NC(il_file_id)
        ENDIF
#if defined key_cputime
     CALL SYSTEM_CLOCK(count=il_t2, count_rate=il_ir)
     WRITE(0,*) "Temps write_interp_field :",REAL(il_t2 - il_t1) / il_ir
#endif
       ENDIF
        IF (TRIM(cd_input_type) .EQ. "NETCDF") THEN 
           IF (ll_isInputVarPresent_S) THEN 
             CALL write_interp_field(cl_inputFile, &
                                     cd_outputVarname_S, &
                                     il_nprof, &
                                     il_nlevels, &
                                     rla_interpValueS, &
                                     cla_dimname, &
                                     rg_fillValue,&
                                     ll_param,&
                                     ll_cparam,&
                                     ll_lparam)

           ENDIF
        ENDIF
        !
        !
        !------------------------------------------------------------------
        ! Deallocation memoire
        !
        IF (ALLOCATED(ila_xindex)) DEALLOCATE(ila_xindex)
        IF (ALLOCATED(ila_yindex)) DEALLOCATE(ila_yindex)
        IF (ALLOCATED(rla_depthvalue_T)) DEALLOCATE(rla_depthvalue_T)
        IF (ALLOCATED(rla_depthvalue_S)) DEALLOCATE(rla_depthvalue_S)
        IF (ALLOCATED(rla_depthadjustvalue)) DEALLOCATE(rla_depthadjustvalue)
        IF (ALLOCATED(rla_interpValueT)) DEALLOCATE(rla_interpValueT)
        IF (ALLOCATED(rla_modelvalue_T)) DEALLOCATE(rla_modelvalue_T)
        IF (ALLOCATED(rla_modelvalue_S)) DEALLOCATE(rla_modelvalue_S)
        IF (ALLOCATED(rla_interpValueS)) DEALLOCATE(rla_interpValueS)
        IF (ALLOCATED(cla_positionqc)) DEALLOCATE(cla_positionqc)
        IF (ALLOCATED(rla_juldvalue)) DEALLOCATE(rla_juldvalue)
        IF (ALLOCATED(rla_LON)) DEALLOCATE(rla_LON)
        IF (ALLOCATED(rla_LAT)) DEALLOCATE(rla_LAT)
        IF (ALLOCATED(rla_poids)) DEALLOCATE(rla_poids)
        IF (ALLOCATED (rla_modeldepth)) DEALLOCATE(rla_modeldepth)
     ELSE
#if defined key_debug
        WRITE(0,*) 'Pas de variable TEMP ou PSAL : ',cd_inputVarname_T,cd_inputVarname_S
#endif
     ENDIF
     !
  ENDDO
  !
  !
  !
ENDSUBROUTINE interpolate_3D_model_field
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
SUBROUTINE write_interp_field_ASCII_2D(cd_outputFile, &
                                    cd_outputVarname,&
                                    id_nprof, &
                                    id_nlevels, &
                                    rda_interpValue)
   USE netcdf
   USE MCAL
   USE MIOL
   USE MFT_error
   USE MIOL_param
   USE table_CLASS4 
   IMPLICIT NONE
   !
   CHARACTER(LEN=255)                            :: cd_outputFile, &
                                                    cd_outputVarname
   INTEGER                                       :: id_nprof, &
                                                    id_nlevels
   REAL(KIND=4), DIMENSION(id_nlevels, id_nprof) :: rda_interpValue
   INTEGER                                       :: il_ji, &
                                                    il_status, &
                                                    il_nbdim, &
                                                    il_file_id,&
                                                    il_dimension
   INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE      :: ila_dimlen
   CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE   :: cla_dimname
   LOGICAL                                       :: ll_exist
   !
   ll_exist=.FALSE.
#if defined key_debug
  WRITE(0,*),' Write interp field'
#endif
   INQUIRE(FILE=cd_outputFile,EXIST=ll_exist)
   IF ( .NOT. ll_exist) THEN
      il_nbdim=2
      ALLOCATE(cla_dimname(il_nbdim))
      ALLOCATE(ila_dimlen(il_nbdim))
      ila_dimlen(1) = id_nlevels
      ila_dimlen(2) = id_nprof
      cla_dimname(1)= 'N_LEVELS'
      cla_dimname(2)= 'N_PROF'
      call MIOL_create_file_NC(TRIM(cd_outputFile),&
                               il_nbdim,&
                               cla_dimname,&
                               ila_dimlen)
   ENDIF
   CALL MIOL_openw_file_NC(TRIM(cd_outputFile),il_file_id)  
   CALL MIOL_write_field_NC (il_file_id,&
                             cd_outputVarname,&
                             'ZP',&
                             rda_interpValue)
   CALL MIOL_close_file_NC(il_file_id)
!
ENDSUBROUTINE write_interp_field_ASCII_2D

!******************************************************************************
!******************************************************************************
!******************************************************************************
SUBROUTINE write_interp_field_ASCII_1D(cd_outputFile, &
                                    cd_outputVarname,&
                                    id_nprof, &
                                    rd_interpValue)
   USE netcdf
   USE MCAL
   USE MIOL
   USE MFT_error
   USE MIOL_param
   USE table_CLASS4 
   IMPLICIT NONE
   !
   CHARACTER(LEN=255)                            :: cd_outputFile, &
                                                    cd_outputVarname
   INTEGER                                       :: id_nprof
   REAL(KIND=8)                                  :: rd_interpValue
   INTEGER                                       :: il_ji, &
                                                    il_status, &
                                                    il_nbdim, &
                                                    il_file_id,&
                                                    il_dimension
   INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE      :: ila_dimlen
   CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE   :: cla_dimname
   LOGICAL                                       :: ll_exist
   !
   ll_exist=.FALSE.
#if defined key_debug
  WRITE(0,*),' Write interp field'
#endif
   INQUIRE(FILE=cd_outputFile,EXIST=ll_exist)
   IF ( .NOT. ll_exist) THEN
      WRITE(0,*) 'File doesn t exist create first with 2D write'
      STOP
   ENDIF
   CALL MIOL_openw_file_NC(TRIM(cd_outputFile),il_file_id)  
   CALL MIOL_write_field_NC (il_file_id,&
                             cd_outputVarname,&
                             'P',&
                             rd_interpValue)
   CALL MIOL_close_file_NC(il_file_id)
!
ENDSUBROUTINE write_interp_field_ASCII_1D

!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE write_interp_field(cd_outputFile, &
                              cd_outputVarname, &
                              id_nprof, &
                              id_nlevels, &
                              rda_interpValue, &
                              cda_dimname, &
                              rd_fillValue,&
                              ld_param,&
                              ld_cparam,&
                              ld_lparam)
  !==============================================================================================================
  !> \brief    Description : Routine d'écriture des variables dans le fichier nectdf
  !<
  !===================================================================================================================
  !
  USE netcdf
  USE MCAL
  USE MIOL
  USE MFT_error
  USE MIOL_param
  USE table_CLASS4 
  IMPLICIT NONE
  !
  CHARACTER(LEN=255) :: cd_outputFile, &
       cd_outputVarname
  CHARACTER(LEN=255), DIMENSION(2) :: cda_dimname
!  CHARACTER(LEN=20), DIMENSION(id_nprof) :: cda_dephvarname

  INTEGER :: id_nprof, &
       id_nlevels,il_var
  REAL(KIND=4), DIMENSION(id_nlevels, id_nprof) :: rda_interpValue!,rda_depthvalue
  REAL(KIND=4) :: rd_fillValue
  LOGICAL,INTENT(IN)    :: ld_param,ld_cparam,ld_lparam !
  INTEGER :: il_ji, &
       il_status, &
       il_filid, &
       il_dimid, &
       il_cparameterintlen, &
       il_cparameterintid, &
       il_lparameterintlen, &
       il_lparameterintid, &
       il_parameterintid, &
       il_offset,&
       il_variable_id
  CHARACTER(LEN=255) :: cl_resatt, &
       cl_tmp
  REAL(KIND=4), DIMENSION(4) :: rla_specialvalue
  REAL(KIND=4) :: rl_resvalue
  CHARACTER(LEN=12), DIMENSION(20) :: cla_parameterint
  CHARACTER(LEN=12) :: cl_null
  CHARACTER(LEN=25)  :: cl_cparam,cl_lparam,cl_param
  INTEGER, DIMENSION(2) :: ila_dimids
  !
#if defined key_debug
  WRITE(0,*),' Write interp field normal'
#endif
  !
  cl_resatt = 'resolution'
  rl_resvalue = 0.001
  il_cparameterintlen = 12
  il_lparameterintlen = 20
  il_offset = 1
  cl_null = " "
  !
  !------------------------------------------------------------------------
  ! Definition des valeurs spéciales
  !
  rla_specialvalue(1) = MINVAL(rda_interpValue)
  IF (rla_specialvalue(2) .GE. 99999.0) THEN
     rla_specialvalue(2) = -99999.0
  ENDIF
  rla_specialvalue(2) = MAXVAL(rda_interpValue, mask= rda_interpValue .LT. 99999.0)
  IF (rla_specialvalue(2) .LE. -99999.0) THEN
     rla_specialvalue(2) = 99999.0
  ENDIF
  rla_specialvalue(3) = rd_fillValue
  rla_specialvalue(4) = rd_fillValue
  !        
  !
  !------------------------------------------------------------------------
  ! Creation des nouvelles dimensions
  !
  il_status = NF90_OPEN(cd_outputFile, &
       NF90_WRITE, &
       il_filid)
  il_status = NF90_REDEF(il_filid)
  IF (il_status .NE. NF90_NOERR) THEN
     WRITE(0,*) ' write_interp_field : problem encountered '
     CALL flush(0)
     STOP 
  ENDIF
  if ( .NOT. ld_cparam .AND. .NOT. ld_lparam .AND. .NOT. ld_param) THEN
      cl_cparam='C_PARAMETERINT'
      cl_lparam='L_PARAMETERINT'
      cl_param='PARAMETERINT'
  ENDIF
  if ( ld_cparam .AND. ld_lparam .AND. .NOT. ld_param) THEN
      cl_cparam='C_PARAMETERINT2'
      cl_lparam='L_PARAMETERINT2'
      cl_param='PARAMETERINT2'
  endif
  if ( ld_cparam .AND. ld_lparam .AND. ld_param) THEN
      cl_cparam='C_PARAMETERINT'
      cl_lparam='L_PARAMETERINT'
      cl_param='PARAMETERINT'
  endif


  il_status = NF90_INQ_DIMID(il_filid, &
       TRIM(cl_cparam), &
       il_cparameterintid)
  ila_dimids(1) = il_cparameterintid
  il_status = NF90_INQ_DIMID(il_filid, &
       TRIM(cl_lparam), &
       il_lparameterintid)
  ila_dimids(2) = il_lparameterintid
  !        
  !
  !------------------------------------------------------------------------
  ! Renseignement de la variable PARAMETERINT
  !
  il_status = NF90_INQ_VARID(il_filid, &
       TRIM(cl_param), &
       il_parameterintid)
  il_status = NF90_ENDDEF(il_filid)
  il_status = NF90_GET_VAR(il_filid, &
       il_parameterintid, &
       cla_parameterint)
!   WRITE(0,*) 'PARAMETERINT : ',cla_parameterint(:)
  IF (il_status .NE. NF90_NOERR) THEN
#if defined key_debug
     WRITE(0,*) ' write_interp_field : ', TRIM(NF90_STRERROR(il_status))
#endif
     CALL flush(0)
     STOP 
  ENDIF
  DO il_ji=1, il_lparameterintlen
     IF (TRIM(cla_parameterint(il_ji)) .NE. cl_null) THEN
        il_offset = il_offset + 1
     ENDIF
  ENDDO
  cla_parameterint(il_offset) = TRIM(cd_outputVarname)
  il_status = NF90_PUT_VAR(il_filid, &
       il_parameterintid, &
       cla_parameterint)
  !        
  !
  !------------------------------------------------------------------------
  ! Ecriture du champs interpole
  !
#if defined key_debug
  print *,'Write field '
  WRITE(0,*) 'Output varname ::',cd_outputVarname
#endif
   il_status = (NF90_INQ_VARID(il_filid, &
                TRIM(cd_outputVarname), &
                il_variable_id))
   IF (il_status .EQ. NF90_NOERR) THEN
#if defined key_debug
        WRITE(0,*) 'Variable existante  :: ',TRIM(cd_outputVarname)
#endif
   ELSE
      CALL MIOL_write_field_NC (il_filid, &
           cd_outputVarname, &
           'ZP', &
           rda_interpValue)!, &
#if defined key_debug
      WRITE(0,*) 'variable  OK :: ',TRIM(cd_outputVarname)
#endif
      !rla_specialvalue)
      !------------------------------------------------------------------------
      ! Ecriture attribut 
      !
      CALL MIOL_write_attribute_NC (il_filid, &
           cd_outputVarname, &
           cl_resatt, &
           rl_resvalue)
  ENDIF
  !      
  il_status = NF90_CLOSE(il_filid)
  !
ENDSUBROUTINE write_interp_field
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
SUBROUTINE read_parameterint_dim(cd_outputFile,ld_cparam,ld_lparam,ld_param)
  USE netcdf
  USE MCAL
  USE MIOL
  USE MIOL_util
  USE table_CLASS4
  USE MFT_error
  !==============================================================================================================
  !> \brief    Description : Routine permettant de voir si les fichiers insitu contiennent déjà la variable PARAMETERINT avec 
  !                          ses dimensions afin d'en créer une nouvelle si c'est la cas
  !<
  !===================================================================================================================

  IMPLICIT NONE
  !
  CHARACTER(LEN=255),INTENT(IN) :: cd_outputFile
  CHARACTER(LEN=255)            :: cl_param
  INTEGER             :: il_ji, &
                         il_status, &
                         il_filid,&
                         il_cparameterintid,&
                         il_lparameterintid,&
                         il_parameterintid,&
                         il_cnbdim,&
                         il_lnbdim,&
                         il_nbdim,&
                         il_type
  LOGICAL,INTENT(OUT) :: ld_cparam,ld_lparam,ld_param
  !
  !
  !------------------------------------------------------------------------
  ! Creation des nouvelles dimensions
  !
#if defined key_debug
  WRITE(0,*) ' read_parameterint'
  WRITE (0,*) 'OPEN file : ',cd_outputFile
#endif
  ld_cparam=.FALSE.
  ld_lparam=.FALSE.
  ld_param=.FALSE.
  CALL MIOL_openr_file_NC(cd_outputFile, &
                          il_filid)
  !** Inquire dimension C_PARAM 
  cl_param='C_PARAMETERINT'
  CALL MIOL_inquire_dimensions_var_NC(il_filid, &
                                      cl_param,&
                                      il_cnbdim,&
                                      ld_cparam)
  !** Inquire dimension L_PARAM 
  cl_param='L_PARAMETERINT'
  CALL MIOL_inquire_dimensions_var_NC(il_filid, &
                                      cl_param,&
                                      il_lnbdim,&
                                      ld_lparam)
  !** Inquire variable PARAMETERINT
  cl_param='PARAMETERINT'
  CALL MIOL_inquire_type_NC(il_filid, &
                            cl_param,&
                            il_type,&
                            il_nbdim,&
                            ld_param)
  print *,'param :: ',ld_cparam,ld_lparam,ld_param
  IF ( il_cnbdim .EQ. 12 .AND. il_lnbdim .EQ. 20 ) ld_param=.FALSE.
#if defined key_debug
  WRITE(0,*) ' read_parameterint OK '
  WRITE(0,*) 'C_PARAMETERINT ::  ',ld_cparam
  WRITE(0,*) 'L_PARAMETERINT ::  ',ld_lparam
  WRITE(0,*) 'PARAMETERINT ::  ',ld_param
#endif

ENDSUBROUTINE read_parameterint_dim

!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE write_parameterint(cd_outputFile,ld_cparam,ld_lparam,ld_param)
  !==============================================================================================================
  !> \brief    Description : Routine permettant d'ecrire la variable PARAMETERINT en fonction de ce qui est resorti
  !                          de la précédente routine read_parameterint_dim
  !<
  !===================================================================================================================
  !
  USE netcdf
  USE MCAL
  USE MIOL
  USE MIOL_util 
  IMPLICIT NONE
  !
  CHARACTER(LEN=255),INTENT(IN)   ::  cd_outputFile
  LOGICAL,INTENT(IN)              ::  ld_cparam,ld_lparam,ld_param
  !
  INTEGER                         ::  il_ji, &
                                      il_status, &
                                      il_filid, &
                                      il_dimid, &
                                      il_cparameterintlen, &
                                      il_cparameterintid, &
                                      il_lparameterintlen, &
                                      il_lparameterintid, &
                                      il_parameterintid
  CHARACTER(LEN=255)               :: cl_resatt, &
                                      cl_tmp,cl_param,cl_lparam,cl_cparam
  CHARACTER(LEN=12), DIMENSION(20) :: cla_parameterint
  CHARACTER(LEN=12)                :: cl_null
  INTEGER, DIMENSION(2)            :: ila_dimids
  !
  !
  il_cparameterintlen = 12
  il_lparameterintlen = 20
  cl_null = " "
  !
  !
  !------------------------------------------------------------------------
  ! Creation des nouvelles dimensions
  !
#if defined key_debug
  WRITE(0,*) ' write_parameterint'
  WRITE (0,*) 'OPEN file : ',cd_outputFile
#endif
  il_status = NF90_OPEN(cd_outputFile, &
       NF90_WRITE, &
       il_filid)
  il_status = NF90_REDEF(il_filid)
  if(il_status .NE. NF90_NOERR) THEN
#if defined key_debug
     WRITE(0,*) ' write_paramterint : problem encountered '
#endif
     CALL flush(0)
     STOP 
  endif 
  if ( ld_cparam ) THEN
      cl_cparam='C_PARAMETERINT2'
  else
      cl_cparam='C_PARAMETERINT'
  endif
  il_status = NF90_DEF_DIM(il_filid, &
                           cl_cparam, &
                           il_cparameterintlen, &
                           il_cparameterintid)
  ila_dimids(1) = il_cparameterintid
  
  if ( ld_lparam ) THEN
      cl_lparam='L_PARAMETERINT2'
  else
      cl_lparam='L_PARAMETERINT'
  endif
  il_status = NF90_DEF_DIM(il_filid, &
                            cl_lparam, &
                            il_lparameterintlen, &
                            il_lparameterintid)
  ila_dimids(2) = il_lparameterintid
  !        
  !
  !------------------------------------------------------------------------
  ! Renseignement de la variable PARAMETERINT
  !
  if ( ld_cparam .AND. ld_lparam ) THEN
      cl_param='PARAMETERINT2'
  else
      cl_param='PARAMETERINT'
  endif
  il_status = NF90_DEF_VAR(il_filid, &
                           cl_param, &
                           NF90_CHAR, &
                           ila_dimids, &
                           il_parameterintid)
  !WRITE(0,*) 'Write cl_param :: ',cl_param
  cla_parameterint(1:il_lparameterintlen) = cl_null
  il_status = NF90_ENDDEF(il_filid)
  il_status = NF90_PUT_VAR(il_filid, &
                           il_parameterintid, &
                           cla_parameterint)
  il_status = NF90_CLOSE(il_filid)
  !        
  !
#if defined key_debug
  WRITE (0,*) "write_parameterint OK :: ",cd_outputFile
#endif

ENDSUBROUTINE write_parameterint
!
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE inquire_model_file(cd_file, &
                              cd_varname, &
                              id_nbdim, &
                              id_nlon, &
                              id_nlat, &
                              id_ndepth, &
                              cd_depthvarname)
  !==============================================================================================================
  !> \brief    Description : Routine permettant de connaître les dimensions du fichier modèle lu
  !<
  !===================================================================================================================
  !
  USE netcdf
  USE MCAL
  USE MIOL 
  USE MIOL_util
  IMPLICIT NONE
  !
  !
  CHARACTER(LEN=255)                        :: cd_file, &
                                               cd_varname, &
                                               cd_depthvarname
  INTEGER(KIND=4)                           :: id_nlon, &
                                               id_nlat, &
                                               id_ndepth, &
                                               id_nbdim
  !
  INTEGER(KIND=4)                           :: il_file_id, &
                                               il_nbvar, &
                                               il_ji
  CHARACTER(LEN=255), DIMENSION(:), POINTER :: clpa_varname, &
                                               clpa_dimname
  INTEGER, DIMENSION(:), POINTER            :: ilpa_dimlen, &
                                               ilpa_nbdim
  LOGICAL                                   :: ll_isvarexist
  !
  id_nlon = -1
  id_nlat = -1
  id_ndepth = -1
  ll_isvarexist = .FALSE.
  cd_depthvarname = 'null'
  !
  !
  !---------------------------------------------------------------------
  ! Lecture du fichier modele
  !
#if defined key_debug
  WRITE (0,*) " open file :: ",cd_file
#endif
  CALL MIOL_openr_file_NC(cd_file, &
       il_file_id)
  CALL MIOL_inquire_dimensions_NC(il_file_id, &
       id_nbdim, &
       clpa_dimname, &
       ilpa_dimlen)
  CALL MIOL_inquire_variables_NC(il_file_id, &
       il_nbvar, &
       clpa_varname, &
       ilpa_nbdim)
  CALL MIOL_close_file_NC(il_file_id)
#if defined key_debug
  WRITE (0,*) " inquire ok :: ",ilpa_dimlen,ilpa_nbdim
#endif
  !
  !
  !------------------------------------------------------------------------
  ! Recherche des dimensions
  !
  DO il_ji=1, id_nbdim
     SELECT CASE (TRIM(clpa_dimname(il_ji)))

     CASE ('deptht', 'depthu', 'depthv', 'depth', 'z')
        id_ndepth = ilpa_dimlen(il_ji)

     CASE ('x', 'longitude', 'lon')
        id_nlon = ilpa_dimlen(il_ji)

     CASE ('y', 'latitude', 'lat')
        id_nlat = ilpa_dimlen(il_ji)

     ENDSELECT
  ENDDO
#if defined key_debug
  WRITE (0,*) " Find dim ok :: ",id_nlon,id_nlat,id_ndepth
#endif
  !
  !
  !------------------------------------------------------------------------
  ! Recherche des variables
  !
  DO il_ji=1, il_nbvar
     SELECT CASE (TRIM(clpa_varname(il_ji)))

     CASE ('deptht')
        cd_depthvarname = 'deptht'

     CASE ('depthu')
        cd_depthvarname = 'depthu'

     CASE ('depthv')
        cd_depthvarname = 'depthv'

     CASE ('depth')
        cd_depthvarname = 'depth'

     CASE ('nav_lev')
        cd_depthvarname = 'nav_lev'

     ENDSELECT
     IF (TRIM(clpa_varname(il_ji)) .EQ. TRIM(cd_varname)) THEN
        ll_isvarexist = .TRUE.
     ENDIF
  ENDDO
#if defined key_debug
  WRITE (0,*) "Find variable :: ",cd_depthvarname,ll_isvarexist
#endif
  !
  !
  !------------------------------------------------------------------------
  ! Deallocation
  !
  DEALLOCATE(ilpa_dimlen)
  DEALLOCATE(ilpa_nbdim)
  DEALLOCATE(clpa_dimname)
  DEALLOCATE(clpa_varname)
  !
  !
  !------------------------------------------------------------------------
  ! Verification des dimensions
  !
  IF ((id_nlon .EQ. -1) .OR. &
       (id_nlat .EQ. -1) .OR. &
       (id_ndepth .EQ. -1) .OR. &
       (.NOT. ll_isvarexist) .OR. &
       (TRIM(cd_depthvarname) .EQ. 'null') &
       ) THEN
     WRITE(0,*) ' inquire_model_file : problem encountered.'
     CALL flush(0)
     STOP
  ENDIF
  !
  !
ENDSUBROUTINE inquire_model_file

!
!******************************************************************************
!******************************************************************************
!******************************************************************************

SUBROUTINE read_allege_model_file(cd_fileT, &
                                  cd_fileS,&
                                  cd_meshfile, &
                                  ida_xindex,&
                                  ida_yindex,&
                                  rda_fieldvalue_T, &
                                  rda_fieldvalue_S, &
                                  rda_depthvalue, &
                                  id_nprofs,&
                                  id_nlon, &
                                  id_nlat, &
                                  id_ndepth, &
                                  id_nbdim)
    !==============================================================================================================
    !> \brief    Description : Routine permettant de lire les profiles modèles autour de chaque mesure insitu, la lecture 
    !                          est accéléré par le fait que l'on va chercher directement les vecteurs concernés en fonction
    !                          des vecteurs de positions en x et y (xindex et yindex), nous ne chargeons jamais le champs en entier
    !                          ce qui est beaucoup plus performant sur les grosses configurations. La conversion de la température
    !                          potentielle en insitu pour chacun des profiles est faite là, cette routine est adaptée pour la lecture
    !                          fichiers allégés
    !<
    !===================================================================================================================
    !
    USE netcdf
    USE MCAL
    USE MFT_error
    USE MIOL
    USE GSW_TEOS10  
    IMPLICIT NONE
    !
    CHARACTER(LEN=255)                                      :: cd_fileT, &
                                                               cd_fileS, &
                                                               cd_meshfile
    CHARACTER(LEN=255)                                        :: cl_dim
    INTEGER(KIND=4),INTENT(IN)                              :: id_nlon,id_nlat, &
                                                              id_ndepth,id_nbdim,id_nprofs
 !! INTEGER(KIND=4)                                        :: il_varid,il_type_T,il_type_S,&
 !!                                                           il_status,il_nbdim
    INTEGER (KIND=4), DIMENSION(4,id_nprofs)               :: ida_xindex,ida_yindex
    INTEGER, DIMENSION(1)                                  :: ila_indx,ila_indy
    INTEGER, DIMENSION(id_ndepth)                          :: ila_indz
    REAL(KIND=4), DIMENSION(4,id_nprofs,id_ndepth)         :: rda_fieldvalue_T,rda_fieldvalue_S
    REAL(KIND=4), DIMENSION(id_ndepth)                     :: rda_depthvalue
    INTEGER(KIND=4)                                        :: il_ji,il_jk,il_jl,il_fill
 !! !
 !! INTEGER(KIND=4)                                        :: il_fill,il_ji,il_jk,il_jl,il_file_id_T,il_file_id_S
 !! INTEGER(KIND=4),DIMENSION(3)                           :: ila_T_size_3D,ila_S_size_3D
 !! INTEGER(KIND=4),DIMENSION(4)                           :: ila_T_size,ila_S_size
 !! REAL(KIND=8), DIMENSION(2)                             :: rla_offsetvalue
 !! REAL(KIND=4), DIMENSION(:), POINTER                    :: rlpa_value_1D
    REAL(KIND=4),DIMENSION(:,:,:),POINTER                   :: rlpa_varT,rlpa_varS
    REAL(KIND=4),DIMENSION(:,:),POINTER                     :: rlpa_lon,rlpa_lat
    REAL(KIND=4),DIMENSION(:),POINTER                       :: rlpa_depth
 !! REAL(KIND=4), DIMENSION(:,:,:,:), POINTER              :: rlpa_valueT_4D,rlpa_valueS_4D
 !! REAL(KIND=8), DIMENSION(:,:,:,:), POINTER              :: rlpa_valueT_4D_R8,rlpa_valueS_4D_R8
 !! REAL(KIND=4), DIMENSION(:,:,:), POINTER                :: rlpa_valueT_3D,rlpa_valueS_3D
 !! REAL(KIND=8), DIMENSION(:,:,:), POINTER                :: rlpa_valueT_3D_R8,rlpa_valueS_3D_R8
    REAL(KIND=4)                                           :: rl_pres,rl_ref,rl_psal,rl_temp
    REAL(KIND=8)                                           :: rl_tempinsitu,rl_psal_R8,rl_temp_R8
 !! INTEGER(KIND=2), DIMENSION(:,:,:,:), POINTER           :: ilpa_valueT_4D,ilpa_valueS_4D
 !! INTEGER(KIND=2), DIMENSION(:,:,:), POINTER             :: ilpa_valueT_3D,ilpa_valueS_3D
    LOGICAL                                                 :: ll_exist_T,ll_exist_S,ll_write
    !
    !
    !---------------------------------------------------------------------
    il_fill=9999.
    !** Read allegés
    ll_write=.FALSE.
    cl_dim="3D"
#if defined key_debug
    WRITE(0,*) "------------------------"
    WRITE(0,*) 'Inside read_allege_model_file '
    WRITE(0,*) "------------------------"
    print *,cd_fileT,cl_dim,cd_meshfile
#endif
    !** Read temperature
    CALL read_lightout_withmask(cd_fileT,TRIM(cl_dim),cd_meshfile,rlpa_lon,rlpa_lat,rlpa_depth,rlpa_varT)
    !CALL read_lightout_test(cd_fileT,TRIM(cl_dim),cd_meshfile,rlpa_lon,rlpa_lat,rlpa_depth,rlpa_varT)
    !CALL read_lightout_test(cd_fileT,TRIM(cl_dim),cd_meshfile,rlpa_lat)
#if defined key_debug
  WRITE (0,*) "Read Temp OK "
#endif
    !** Read salinity 
    CALL read_lightout_withmask(cd_fileS,TRIM(cl_dim),cd_meshfile,rlpa_lon,rlpa_lat,rlpa_depth,rlpa_varS) 
#if defined key_debug
  WRITE (0,*) "Read psal OK "
#endif
    rda_depthvalue(1:id_ndepth) =  rlpa_depth(1:id_ndepth)
    DEALLOCATE(rlpa_depth)
    !  Boucle sur les profiles
    DO il_ji=1,id_nprofs 
#if defined key_debug
  WRITE (0,*) "Read model files "
#endif

        ! Lecture des variables à traiter
        !
        DO il_jk=1,4
            ila_indx(:)=ida_xindex(il_jk,il_ji)
            ila_indy(:)=ida_yindex(il_jk,il_ji)
            ila_indz(:)=(/1:id_ndepth/)
            IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                !** Lecture de la temperature
                rda_fieldvalue_T(il_jk,il_ji,:)=rlpa_varT(ila_indx(1),ila_indy(1),ila_indz)
                !** Lecture de la salinité
                rda_fieldvalue_S(il_jk,il_ji,:)=rlpa_varS(ila_indx(1),ila_indy(1),ila_indz)
                !** Conversion en temperature insitu
                DO il_jl=1,id_ndepth
                    rl_temp=rda_fieldvalue_T(il_jk,il_ji,il_jl)
                    rl_psal=rda_fieldvalue_S(il_jk,il_ji,il_jl)
                    rl_pres=rda_depthvalue(il_jl)
                    rl_ref=0
                    !WRITE (0,*) 'Avant correction :: ',rda_fieldvalue_T(il_jk,il_ji,il_jl) ,rl_temp,rl_psal
                    IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                        CALL gsw_pt_from_t(REAL(rl_psal,8),REAL(rl_temp,8),REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                        rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                    ENDIF
                ENDDO
            ELSE
                rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
            ENDIF
        ENDDO
#if defined key_debug
  WRITE (0,*) "Read model files OK profile/nbprofs : ",il_ji,id_nprofs
#endif
    ENDDO



END SUBROUTINE read_allege_model_file
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE read_model_file(cd_fileT, &
                           cd_fileS,&
                           cd_fieldname_T, &
                           cd_fieldname_S, &
                           cd_depthname, &
                           ida_xindex,&
                           ida_yindex,&
                           rda_fieldvalue_T, &
                           rda_fieldvalue_S, &
                           rda_depthvalue, &
                           id_nprofs,&
                           id_nlon, &
                           id_nlat, &
                           id_ndepth, &
                           id_nbdim)
  
  !==============================================================================================================
  !> \brief    Description : Routine permettant de lire les profiles modèles autour de chaque mesure insitu, la lecture 
  !                          est accéléré par le fait que l'on va chercher directement les vecteurs concernés en fonction
  !                          des vecteurs de positions en x et y (xindex et yindex), nous ne chargeons jamais le champs en entier
  !                          ce qui est beaucoup plus performant sur les grosses configurations. La conversion de la température
  !                          potentielle en insitu pour chacun des profiles est faite là
  !<
  !===================================================================================================================
  !
  USE netcdf
  USE MCAL
  USE MFT_error
  USE MIOL
  USE GSW_TEOS10  
  IMPLICIT NONE
  !
  CHARACTER(LEN=255)                                      :: cd_fileT, &
                                                             cd_fileS, &
                                                             cd_fieldname_T, &
                                                             cd_fieldname_S, &
                                                             cd_depthname
  INTEGER(KIND=4),INTENT(IN)                             :: id_nlon,id_nlat, &
                                                            id_ndepth,id_nbdim,id_nprofs
  INTEGER(KIND=4)                                        :: il_varid,il_type_T,il_type_S,&
                                                            il_status,il_nbdim
  INTEGER (KIND=4), DIMENSION(4,id_nprofs)               :: ida_xindex,ida_yindex
  INTEGER, DIMENSION(1)                                  :: ila_indx,ila_indy,ila_indt
  INTEGER, DIMENSION(id_ndepth)                          :: ila_indz
  REAL(KIND=4), DIMENSION(4,id_nprofs,id_ndepth)         :: rda_fieldvalue_T,rda_fieldvalue_S
  REAL(KIND=4), DIMENSION(id_ndepth)                     :: rda_depthvalue
  !
  INTEGER(KIND=4)                                        :: il_fill,il_ji,il_jk,il_jl,il_file_id_T,il_file_id_S
  INTEGER(KIND=4),DIMENSION(3)                           :: ila_T_size_3D,ila_S_size_3D
  INTEGER(KIND=4),DIMENSION(4)                           :: ila_T_size,ila_S_size
  REAL(KIND=8), DIMENSION(2)                             :: rla_offsetvalue
  REAL(KIND=4), DIMENSION(:), POINTER                    :: rlpa_value_1D
  REAL(KIND=4), DIMENSION(:,:,:,:), POINTER              :: rlpa_valueT_4D,rlpa_valueS_4D
  REAL(KIND=8), DIMENSION(:,:,:,:), POINTER              :: rlpa_valueT_4D_R8,rlpa_valueS_4D_R8
  REAL(KIND=4), DIMENSION(:,:,:), POINTER                :: rlpa_valueT_3D,rlpa_valueS_3D
  REAL(KIND=8), DIMENSION(:,:,:), POINTER                :: rlpa_valueT_3D_R8,rlpa_valueS_3D_R8
  REAL(KIND=4)                                           :: rl_pres,rl_ref,rl_psal,rl_temp
  REAL(KIND=8)                                           :: rl_tempinsitu,rl_psal_R8,rl_temp_R8
  INTEGER(KIND=2), DIMENSION(:,:,:,:), POINTER           :: ilpa_valueT_4D,ilpa_valueS_4D
  INTEGER(KIND=2), DIMENSION(:,:,:), POINTER             :: ilpa_valueT_3D,ilpa_valueS_3D
  LOGICAL                                                :: ll_exist_T,ll_exist_S,ll_clim
  !
  !
  !---------------------------------------------------------------------
  il_fill=9999.
  ll_clim=.FALSE.
  IF (TRIM(cd_fieldname_T(1:4)).EQ. 'temp') ll_clim=.TRUE.  
  !
  !  Recherche du type de la variable et de son existence
  CALL MIOL_inquire_type_NC(cd_fileT, &
                            cd_fieldname_T,&
                            il_type_T,&
                            il_nbdim,&
                            ll_exist_T)
  IF ( .NOT. ll_exist_T)  THEN
       WRITE (0,*) "Missing variable  :: ",cd_fieldname_T
       STOP
  ENDIF 
  !
  !
  !---------------------------------------------------------------------
  ! Lecture de la variable de profondeur
  
  CALL MIOL_read_field_NC(cd_fileT, &
                          cd_depthname, &
                          rlpa_value_1D)
  rda_depthvalue(1:id_ndepth) =  rlpa_value_1D(1:id_ndepth)
  DEALLOCATE(rlpa_value_1D)
  !
  !  Boucle sur les profiles
  DO il_ji=1,id_nprofs 
#if defined key_debug
  WRITE (0,*) "Read model files "
#endif

        ! Lecture des variables à traiter
        !
        IF (id_nbdim .EQ. 4) THEN
           DO il_jk=1,4
                ila_indx(:)=ida_xindex(il_jk,il_ji)
                ila_indy(:)=ida_yindex(il_jk,il_ji)
                ila_indz(:)=(/1:id_ndepth/)
                ila_indt(:)=1 
                SELECT CASE (il_type_T)
                CASE (NF90_DOUBLE)
                   IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                       !** Lecture de la temperature
                       call MIOL_read_field_NC(cd_fileT,cd_fieldname_T,rlpa_valueT_4D_R8,ila_T_size,ila_indx,ila_indy,ila_indz,ila_indt)
                       rda_fieldvalue_T(il_jk,il_ji,:)=REAL(rlpa_valueT_4D_R8(1,1,:,1),4)
                       !** Lecture de salinité
                       call MIOL_read_field_NC(cd_fileS,cd_fieldname_S,rlpa_valueS_4D_R8,ila_S_size,ila_indx,ila_indy,ila_indz,ila_indt)
                       rda_fieldvalue_S(il_jk,il_ji,:)=REAL(rlpa_valueS_4D_R8(1,1,:,1),4)
                       IF ( .NOT. ll_clim) THEN
                       !** Conversion en temperature insitu
                          DO il_jl=1,id_ndepth
                             rl_temp_R8=rlpa_valueT_4D_R8(1,1,il_jl,1)
                             rl_psal_R8=rlpa_valueS_4D_R8(1,1,il_jl,1)
                             rl_pres=rda_depthvalue(il_jl)
                             rl_ref=0
                             !WRITE (0,*) 'Avant correction :: ',rda_fieldvalue_T(il_jk,il_ji,il_jl) ,rl_temp,rl_psal
                             IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                               CALL gsw_pt_from_t(rl_psal_R8,rl_temp_R8,REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                               rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                             ENDIF
                          ENDDO 
                       ENDIF
                       DEALLOCATE(rlpa_valueS_4D_R8)
                       DEALLOCATE(rlpa_valueT_4D_R8)
                   ELSE 
                       WRITE(0,*) 'Cas ll clim pas de conversion'
                       rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                       rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
                   ENDIF
                CASE (NF90_FLOAT)
                   IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                       !** Lecture de la temperature
                       call MIOL_read_field_NC(cd_fileT,cd_fieldname_T,rlpa_valueT_4D,ila_T_size,ila_indx,ila_indy,ila_indz,ila_indt)
                       rda_fieldvalue_T(il_jk,il_ji,:)=rlpa_valueT_4D(1,1,:,1)
                       DEALLOCATE(rlpa_valueT_4D)
                       !** Lecture de salinité
                       call MIOL_read_field_NC(cd_fileS,cd_fieldname_S,rlpa_valueS_4D,ila_S_size,ila_indx,ila_indy,ila_indz,ila_indt)
                       rda_fieldvalue_S(il_jk,il_ji,:)=rlpa_valueS_4D(1,1,:,1)
                       DEALLOCATE(rlpa_valueS_4D)
                       IF ( .NOT. ll_clim) THEN
                       !WRITE(0,*) 'Cas du Modele'
                       !** Conversion en temperature insitu
                          DO il_jl=1,id_ndepth
                             rl_temp=rda_fieldvalue_T(il_jk,il_ji,il_jl)
                             rl_psal=rda_fieldvalue_S(il_jk,il_ji,il_jl)
                             rl_pres=rda_depthvalue(il_jl)
                             rl_ref=0
                             !WRITE (0,*) 'Avant correction :: ',rda_fieldvalue_T(il_jk,il_ji,il_jl) ,rl_temp,rl_psal
                             IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                               CALL gsw_pt_from_t(REAL(rl_psal,8),REAL(rl_temp,8),REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                               rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                             ENDIF
                          ENDDO
                       ELSE 
                            WRITE(0,*) 'Cas ll clim pas de conversion'
                       ENDIF
                   ELSE 
                       rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                       rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
                   ENDIF
!#if defined key_debug
!  WRITE (0,*) "Read field S OK :: ",rda_fieldvalue_S(il_jk,il_ji,:),shape(rlpa_valueS_4D)
!#endif
                CASE (NF90_SHORT)
                   WRITE(0,*) 'Cas short'
                   IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                       !** Lecture de la temperature
                       call MIOL_read_field_NC(cd_fileT,cd_fieldname_T,ilpa_valueT_4D,ila_T_size,rlpa_valueT_4D,&
                                               rla_offsetvalue,ila_indx,ila_indy,ila_indz,ila_indt)
                       rda_fieldvalue_T(il_jk,il_ji,:)=rlpa_valueT_4D(1,1,:,1)
                       DEALLOCATE(ilpa_valueT_4D)
                       !** Lecture de salinité
                       call MIOL_read_field_NC(cd_fileS,cd_fieldname_S,ilpa_valueS_4D,ila_S_size,rlpa_valueS_4D,&
                                               rla_offsetvalue,ila_indx,ila_indy,ila_indz,ila_indt)
                       rda_fieldvalue_S(il_jk,il_ji,:)=rlpa_valueS_4D(1,1,:,1)
                       DEALLOCATE(ilpa_valueS_4D)
                       IF ( .NOT. ll_clim) THEN
                       !** Conversion en temperature insitu
                         DO il_jl=1,id_ndepth
                            rl_temp=rda_fieldvalue_T(il_jk,il_ji,il_jl)
                            rl_psal=rda_fieldvalue_S(il_jk,il_ji,il_jl)
                            rl_pres=rda_depthvalue(il_jl)
                            rl_ref=0
                            IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                              CALL gsw_pt_from_t(REAL(rl_psal,8),REAL(rl_temp,8),REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                              rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                            ENDIF
                         ENDDO 
                       ENDIF 
                  ELSE
                      rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                      rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
                   ENDIF
                
                CASE default
                   WRITE(0,*) 'Type non reconnu'
                ENDSELECT
           ENDDO
        ELSE IF (id_nbdim .EQ. 3) THEN
           DO il_jk=1,4
                ila_indx(:)=ida_xindex(il_jk,il_ji)
                ila_indy(:)=ida_yindex(il_jk,il_ji)
                ila_indz(:)=(/1:id_ndepth/)
                SELECT CASE (il_type_T)
                CASE (NF90_DOUBLE)
                   IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                       !** Lecture de la temperature
                       call MIOL_read_field_NC(cd_fileT,cd_fieldname_T,rlpa_valueT_3D_R8,ila_T_size_3D,ila_indx,ila_indy,ila_indz)
                       rda_fieldvalue_T(il_jk,il_ji,:)=REAL(rlpa_valueT_3D_R8(1,1,:),4)
                       !** Lecture de salinité
                       call MIOL_read_field_NC(cd_fileS,cd_fieldname_S,rlpa_valueS_3D_R8,ila_S_size_3D,ila_indx,ila_indy,ila_indz)
                       rda_fieldvalue_S(il_jk,il_ji,:)=REAL(rlpa_valueS_3D_R8(1,1,:),4)
                       IF ( .NOT. ll_clim) THEN
                       !WRITE(0,*) 'Cas du Modele'
                       !** Conversion en temperature insitu
                          DO il_jl=1,id_ndepth
                             rl_temp_R8=rlpa_valueT_3D_R8(1,1,il_jl)
                             rl_psal_R8=rlpa_valueS_3D_R8(1,1,il_jl)
                             rl_pres=rda_depthvalue(il_jl)
                             rl_ref=0
                             !WRITE (0,*) 'Avant correction :: ',rda_fieldvalue_T(il_jk,il_ji,il_jl) ,rl_temp,rl_psal
                             IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                               CALL gsw_pt_from_t(rl_psal_R8,rl_temp_R8,REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                               rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                             ENDIF
                          ENDDO 
                       ENDIF
                       DEALLOCATE(rlpa_valueS_3D_R8)
                       DEALLOCATE(rlpa_valueT_3D_R8)
                   ELSE 
                       rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                       rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
                   ENDIF
                CASE (NF90_FLOAT)
                   IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                       !** Lecture de la temperature
                       call MIOL_read_field_NC(cd_fileT,cd_fieldname_T,rlpa_valueT_3D,ila_T_size_3D,ila_indx,ila_indy,ila_indz)
                       rda_fieldvalue_T(il_jk,il_ji,:)=rlpa_valueT_3D(1,1,:)
                       DEALLOCATE(rlpa_valueT_3D)
                       !** Lecture de salinité
                       call MIOL_read_field_NC(cd_fileS,cd_fieldname_S,rlpa_valueS_3D,ila_S_size_3D,ila_indx,ila_indy,ila_indz)
                       rda_fieldvalue_S(il_jk,il_ji,:)=rlpa_valueS_3D(1,1,:)
                       DEALLOCATE(rlpa_valueS_3D)
                       IF ( .NOT. ll_clim) THEN
                          WRITE(0,*) 'Conversion in situ'
                      ! WRITE(0,*) 'Cas du Modele'
                       !** Conversion en temperature insitu
                          DO il_jl=1,id_ndepth
                             rl_temp=rda_fieldvalue_T(il_jk,il_ji,il_jl)
                             rl_psal=rda_fieldvalue_S(il_jk,il_ji,il_jl)
                             rl_pres=rda_depthvalue(il_jl)
                             rl_ref=0
                             !WRITE (0,*) 'Avant correction :: ',rda_fieldvalue_T(il_jk,il_ji,il_jl) ,rl_temp,rl_psal
                             IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                               CALL gsw_pt_from_t(REAL(rl_psal,8),REAL(rl_temp,8),REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                               rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                             ENDIF
                          ENDDO
                       ENDIF
                   ELSE 
                       rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                       rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
                   ENDIF
!#if defined key_debug
!  WRITE (0,*) "Read field S OK :: ",rda_fieldvalue_S(il_jk,il_ji,:),shape(rlpa_valueS_4D)
!#endif
                CASE (NF90_SHORT)
                 !  WRITE(0,*) 'Cas short'
                   IF (ila_indx(1) .NE. il_fill .AND. ila_indy(1).NE. il_fill) THEN
                       !** Lecture de la temperature
                       call MIOL_read_field_NC(cd_fileT,cd_fieldname_T,ilpa_valueT_3D,ila_T_size_3D,rlpa_valueT_3D,&
                                               rla_offsetvalue,ila_indx,ila_indy,ila_indz)
                       rda_fieldvalue_T(il_jk,il_ji,:)=rlpa_valueT_3D(1,1,:)
                       DEALLOCATE(ilpa_valueT_3D)
                       !** Lecture de salinité
                       call MIOL_read_field_NC(cd_fileS,cd_fieldname_S,ilpa_valueS_3D,ila_S_size_3D,rlpa_valueS_3D,&
                                               rla_offsetvalue,ila_indx,ila_indy,ila_indz)
                       rda_fieldvalue_S(il_jk,il_ji,:)=rlpa_valueS_3D(1,1,:)
                       DEALLOCATE(ilpa_valueS_3D)
                       IF ( .NOT. ll_clim) THEN
                       !** Conversion en temperature insitu
                         DO il_jl=1,id_ndepth
                            rl_temp=rda_fieldvalue_T(il_jk,il_ji,il_jl)
                            rl_psal=rda_fieldvalue_S(il_jk,il_ji,il_jl)
                            rl_pres=rda_depthvalue(il_jl)
                            rl_ref=0
                            IF ( rl_temp .NE. rg_fillvalue .AND. rl_psal .NE. rg_fillvalue) THEN 
                              CALL gsw_pt_from_t(REAL(rl_psal,8),REAL(rl_temp,8),REAL(rl_ref,8),REAL(rl_pres,8),rl_tempinsitu)
                              rda_fieldvalue_T(il_jk,il_ji,il_jl)=REAL(rl_tempinsitu,4)
                            ENDIF
                         ENDDO 
                       ENDIF 
                  ELSE
                      rda_fieldvalue_T(il_jk,il_ji,:)=rg_fillvalue
                      rda_fieldvalue_S(il_jk,il_ji,:)=rg_fillvalue
                   ENDIF
                
                CASE default
                   WRITE(0,*) 'Type non reconnu'
                ENDSELECT
           ENDDO
        ELSE
           WRITE(0,*) 'Dimension non prise en compte :: ',id_nbdim
           STOP
        ENDIF
  !   WRITE (0,*) 'Profil lu OK :: ',il_ji,id_nprofs
#if defined key_debug
  WRITE (0,*) "Read model files OK profile/nbprofs : ",il_ji,id_nprofs
#endif
  ENDDO

ENDSUBROUTINE read_model_file
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE interp_model_field(rda_modelvalue_T, &
                              rda_modelvalue_S, &
                              rda_modeldepth, &
                              rda_modelvalueT_inter, &
                              rda_modelvalueS_inter, &
                              id_nlon, &
                              id_nlat, &
                              id_ndepth, &
                              ida_xindex, &
                              ida_yindex, &
                              rda_codepthvalueT, &
                              rda_codepthvalueS, &
                              rda_LON,&
                              rda_LAT,&
                              rda_juldvalue,&
                              cda_copositionqc, &
                              id_nprof, &
                              id_nlevels, &
                              cd_Inputfile,&
                              rda_poids,&
                              rd_emptyvalue)
  !==============================================================================================================
  !> \brief    Description : Routine permettant d'interpoler les 4 profiles modèles colocalisés autour de l'observation
  !                          in situ. L'interpolation se fait en prenant les poids des 4 points autour. En profondeur, 
  !                          un spline cubique est appliqué pour interpoler les profondeurs modèles sur les profondeurs du profile
  !<
  !===================================================================================================================
  !
  USE MCAL
  USE MIOL
  USE table_CLASS4
  IMPLICIT NONE
  !
  INTEGER,INTENT(IN)                                                    :: id_nlon, &
                                                                           id_nlat, &
                                                                           id_ndepth, &
                                                                           id_nprof, &
                                                                           id_nlevels
  INTEGER, DIMENSION(4,id_nprof),INTENT(IN)                             :: ida_xindex, &
                                                                           ida_yindex
  REAL(KIND=4), DIMENSION(4,id_nprof,id_ndepth),INTENT(IN)              :: rda_modelvalue_T,rda_modelvalue_S
  REAL(KIND=4), DIMENSION(id_ndepth),INTENT(IN)                         :: rda_modeldepth
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof),INTENT(IN)               :: rda_codepthvalueT,rda_codepthvalueS
  REAL(KIND=8), DIMENSION(id_nprof),INTENT(IN)                          :: rda_LON,rda_LAT,rda_juldvalue
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof),INTENT(OUT)              :: rda_modelvalueT_inter,rda_modelvalueS_inter
  REAL(KIND=4),DIMENSION(4,id_nprof),INTENT(IN)                         :: rda_poids
  REAL(KIND=4),INTENT(IN)                                               :: rd_emptyvalue
  CHARACTER(LEN=1), DIMENSION(id_nprof),INTENT(IN)                      :: cda_copositionqc
  CHARACTER(LEN=23),INTENT(IN)                                          :: cd_Inputfile
  CHARACTER(LEN=255)                                                    :: cl_file,cl_ficlog
  REAL(KIND=8)                                                          :: rl_lon,rl_lat,rl_IDboite
  !
  INTEGER                                                               :: il_ji,il_jj,il_jk,il_den,il_den2, &
                                                                           il_poids,il_status,il_ind,il_n,il_n2,&
                                                                           il_n3,il_jp,il_nbx,il_nby,il_ficlog
  REAL(KIND=4), DIMENSION(id_ndepth)                                    :: rla_modelvalueT_tmp,rla_modelvalueS_tmp
  REAL(KIND=4), DIMENSION(:),ALLOCATABLE                                :: rla_modelvalueT_tmp2,rla_modelvalueS_tmp2,&
                                                                           rla_modeldepth2,rla_codepthT_tmp2,&
                                                                           rla_codepthS_tmp2,rla_modeldepth_inter2
  REAL(KIND=4), DIMENSION(id_nlevels)                                   :: rla_codepthT_tmp, rla_codepthS_tmp,&
                                                                           rla_modelTdepth_inter,rla_modelSdepth_inter
  REAL(KIND=4)                                                          :: rl_tmp, &
                                                                           rl_emptyvalue
  INTEGER, PARAMETER                                                    :: NaN = Z"FFC00000"
  LOGICAL                                                               :: ll_exist_ficlog
  !

  rl_emptyvalue = 99999
  rl_emptyvalue = rg_fillvalue
  !------------------------------------------------------------------------
  ! Boucle pour le traitement de tous les fichiers coriolis
  DO il_ji=1, id_nprof
     rl_lon=rda_LON(il_ji)
     rl_lat=rda_LAT(il_ji)  
     !---------------------------------------------------------------------
     ! Test sur la valeur de la qualite de la position du profil
     !
     ! POSITION_QC =   0, 1 or 5 or 8
     ! 0=Unqualified
     ! 1=Correct value (all ckecks passed)
     ! 5=Value modified during quality control : delayed time corrected
     ! 8=value interpolated

     IF ( (cda_copositionqc(il_ji) .EQ. '0') .OR. &
          (cda_copositionqc(il_ji) .EQ. '1') .OR. &
          (cda_copositionqc(il_ji) .EQ. '5') .OR. &
          (cda_copositionqc(il_ji) .EQ. '8')) THEN
        ! (cda_copositionqc(il_ji) .EQ. '2')) THEN
        !
        !
        !------------------------------------------------------------------
        ! Interpolation spatiale (2D) par une moyenne des 4 plus proches voisins ponderÃ©s par IDW
        rla_modelvalueT_tmp(1:id_ndepth) = 0.0
        rla_modelvalueS_tmp(1:id_ndepth) = 0.0
        !
        il_nbx=COUNT(ida_xindex(:,il_ji) .EQ. 9999)
        il_nby=COUNT(ida_yindex(:,il_ji) .EQ. 9999)
        IF (il_nbx .NE. 4 .OR. il_nby .NE. 4) THEN  
           !
           DO il_jj = 1, id_ndepth

              il_den =  0	
              il_den2 = 0
              il_poids= 0
!#if defined key_debug
!              PRINT *, 'Profil lu  :: ',il_ji,id_nprof
!              PRINT *, 'valeur des poids :: ',rda_poids(1:4,il_ji)
!              PRINT *, 'valeur des xindex :: ',ida_xindex(1:4,il_ji)
!              PRINT *, 'valeur des yindex :: ',ida_yindex(1:4,il_ji)
!              PRINT *, 'valeur des lon lat :: ',rl_lon,rl_lat
!#endif        
              DO il_jp = 1, 4
                 IF ( ida_xindex(il_jp,il_ji) .NE. 9999 .AND. ida_yindex(il_jp,il_ji) .NE. 9999) THEN
                   IF (rda_modelvalue_T(il_jp,il_ji,il_jj) &
                         .LT. 1000.0.AND. rda_modelvalue_T(il_jp,il_ji,il_jj).NE.0 &
                         .AND. ida_xindex(il_jp,il_ji) .NE. 9999 ) THEN
                       il_den = il_den + 1
                    ENDIF
                    IF ((IEOR(TRANSFER(rda_poids(il_jp,il_ji),NaN), NaN) == 1).OR.rda_poids(il_jp,il_ji).NE.0) THEN
                       il_poids=il_poids+1
                    ENDIF
                 ENDIF
              ENDDO

              DO il_jk = 1, 4
                 !
                 !------------------------------------------------------------
                 ! Test pour savoir si la valeur est une fillvalue ou pas
                 IF ( ida_xindex(il_jk,il_ji) .NE. 9999 .AND. ida_yindex(il_jk,il_ji) .NE. 9999) THEN
                    IF (rda_modelvalue_T(il_jk,il_ji,il_jj) &
                         .LT. 1000.0.AND. rda_modelvalue_T(il_jk,il_ji,il_jj).NE.0) THEN

                       IF (il_den.EQ.il_poids) THEN              
                          !** 1er cas le nombre de poids valides correspond au nombre de valeurs valides
                          rla_modelvalueT_tmp(il_jj) = rla_modelvalueT_tmp(il_jj)+&
                               rda_poids(il_jk,il_ji)*rda_modelvalue_T(il_jk,il_ji,il_jj)
                          rla_modelvalueS_tmp(il_jj) = rla_modelvalueS_tmp(il_jj)+&
                               rda_poids(il_jk,il_ji)*rda_modelvalue_S(il_jk,il_ji,il_jj)
                       ELSE    	                     
                          rla_modelvalueT_tmp(il_jj) = rla_modelvalueT_tmp(il_jj) + &
                               rda_modelvalue_T(il_jk,il_ji,il_jj)
                          rla_modelvalueS_tmp(il_jj) = rla_modelvalueS_tmp(il_jj) + &
                               rda_modelvalue_S(il_jk,il_ji,il_jj)
                          il_den2 = il_den2 + 1
                       ENDIF
                    ENDIF
                 ENDIF
              ENDDO

              IF (il_den.NE.il_poids.AND.il_den2 .NE. 0) THEN
                 rla_modelvalueT_tmp(il_jj) = rla_modelvalueT_tmp(il_jj)/il_den2
                 rla_modelvalueS_tmp(il_jj) = rla_modelvalueS_tmp(il_jj)/il_den2
              ENDIF
           ENDDO
        ELSE
#if defined key_debug
           PRINT *,'les 4 index ne sont pas trouvés :: ',il_nbx,il_nby
           PRINT *, 'valeur des poids :: ',rda_poids(1:4,il_ji)
           PRINT *, 'valeur des xindex :: ',ida_xindex(1:4,il_ji)
           PRINT *, 'valeur des yindex :: ',ida_yindex(1:4,il_ji)
           PRINT *, 'Position Lon , Lat du profil : ',rl_lon,rl_lat
!           PRINT *, 'Nom du fichier d entrée :: ',TRIM(cd_Inputfile)
#endif        
           cl_ficlog=TRIM(cg_ficlog)//'/Position_bad_profils_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
           INQUIRE(FILE=TRIM(cl_ficlog),EXIST=ll_exist_ficlog)
           IF ( .NOT. ll_exist_ficlog ) THEN
	      CALL MIOL_getFreeLU(il_ficlog)
              OPEN(unit=il_ficlog,file=TRIM(cl_ficlog),form='FORMATTED',STATUS='new')
              CLOSE(il_ficlog)
              ll_exist_ficlog=.TRUE.
           ENDIF
	   CALL MIOL_getFreeLU(il_ficlog)
           OPEN(unit=il_ficlog,file=TRIM(cl_ficlog),form='FORMATTED',&
                & POSITION='APPEND',STATUS='old')
	  ! WRITE(0,*) 'Ecriture fic log :: ',TRIM(cd_Inputfile),rl_lon,rl_lat,il_nbx,il_nby
           WRITE(il_ficlog,FMT=800,advance="yes") TRIM(cd_Inputfile),rl_lon,rl_lat,il_nbx,il_nby
           CLOSE(il_ficlog)
        ENDIF

        !** Gestion du cas ou les fichiers sont abherents        
        IF ( rla_modelvalueT_tmp(1).ge.9999) rla_modelvalueT_tmp=rl_emptyvalue
        IF ( rla_modelvalueS_tmp(1).ge.9999) rla_modelvalueS_tmp=rl_emptyvalue

        !* Remplacement des zeros par une valeur abherente non physique (sinon le spline fait cree des abherations)

        WHERE (rla_modelvalueT_tmp(:).EQ.0) rla_modelvalueT_tmp=rl_emptyvalue
        WHERE (rla_modelvalueS_tmp(:).EQ.0) rla_modelvalueS_tmp=rl_emptyvalue
        !** Compte du nombre de valeurs nom abherentes
        il_n=COUNT(rla_modelvalueT_tmp(:)<rl_emptyvalue)


        !* Select valid profil
        !------------------------------------------------------------------
        ! 2D -> 1D pour la profondeur insitu
        !
        rla_codepthT_tmp(1:id_nlevels) = rda_codepthvalueT(1:id_nlevels,il_ji)
        rla_codepthS_tmp(1:id_nlevels) = rda_codepthvalueS(1:id_nlevels,il_ji)
        DO il_jj = 1, id_nlevels
           IF (rla_codepthT_tmp(il_jj).EQ.rd_emptyvalue ) THEN
              rla_codepthT_tmp(il_jj) = rl_emptyvalue
           ENDIF
           IF (rla_codepthS_tmp(il_jj).EQ.rd_emptyvalue ) THEN
              rla_codepthS_tmp(il_jj) = rl_emptyvalue
           ENDIF
        ENDDO

        !------------------------------------------------------------------
        ! Interpolation des profondeurs (1D)
        !
        rla_modelTdepth_inter(1:id_nlevels) = rd_emptyvalue
        rla_modelSdepth_inter(1:id_nlevels) = rd_emptyvalue

        IF (il_n.GT.0) THEN
           !** Construction de nouveaux tableaux avec des valeurs non abherentes
           IF (ALLOCATED(rla_modelvalueT_tmp2)) DEALLOCATE(rla_modelvalueT_tmp2)
           ALLOCATE(rla_modelvalueT_tmp2(il_n))
           IF (ALLOCATED(rla_modelvalueS_tmp2)) DEALLOCATE(rla_modelvalueS_tmp2)
           ALLOCATE(rla_modelvalueS_tmp2(il_n))

           IF (ALLOCATED(rla_modeldepth2)) DEALLOCATE(rla_modeldepth2)
           ALLOCATE(rla_modeldepth2(il_n))
           rla_modelvalueT_tmp2(:)=rla_modelvalueT_tmp(1:il_n)
           rla_modelvalueS_tmp2(:)=rla_modelvalueS_tmp(1:il_n)
           rla_modeldepth2(:)=rda_modeldepth(1:il_n)

           !** Selection de la profondeur coriolis valide
           il_n2=COUNT(rla_codepthT_tmp(:).LE.rla_modeldepth2(il_n))
           il_n3=COUNT(rla_codepthS_tmp(:).LE.rla_modeldepth2(il_n))

           IF (ALLOCATED(rla_codepthT_tmp2)) DEALLOCATE(rla_codepthT_tmp2) 
           ALLOCATE(rla_codepthT_tmp2(il_n2))
           IF (ALLOCATED(rla_codepthS_tmp2)) DEALLOCATE(rla_codepthS_tmp2) 
           ALLOCATE(rla_codepthS_tmp2(il_n3))
           rla_codepthT_tmp2(:)=rla_codepthT_tmp(1:il_n2)
           rla_codepthS_tmp2(:)=rla_codepthS_tmp(1:il_n3)

           IF (ALLOCATED(rla_modeldepth_inter2)) DEALLOCATE(rla_modeldepth_inter2) 
           ALLOCATE(rla_modeldepth_inter2(il_n2))
           !** Interpolation en T
           rla_modeldepth_inter2(1:il_n2)=rd_emptyvalue
           CALL MCAL_interp1D_cubicspline_R4(rla_modelvalueT_tmp2, &
                                             rla_modeldepth2, &
                                             il_n, &
                                             rla_modeldepth_inter2, &
                                             rla_codepthT_tmp2, &
                                             il_n2, &
                                             rl_emptyvalue)
           rla_modelTdepth_inter(1:il_n2)=rla_modeldepth_inter2(:)
           !** Interpolation en S
           IF (ALLOCATED(rla_modeldepth_inter2)) DEALLOCATE(rla_modeldepth_inter2) 
           ALLOCATE(rla_modeldepth_inter2(il_n3))
           rla_modeldepth_inter2(1:il_n3)=rd_emptyvalue
           !print *,'Valeurs rla_codepthS_tmp2 :: ',rla_codepthS_tmp2,il_n3,rla_modelvalueS_tmp2
           !print *,'Valeurs rla_modeldepth2  :: ',rla_modeldepth2
           !print *,'Valeurs il_n :: ',il_n
           !print *,'Valeurs il_n3 :: ',rla_codepthS_tmp2,il_n3,rla_modelvalueS_tmp2
           !print *,'Valeurs rla_modeldepth_inter2  :: ',rla_modeldepth_inter2
           !print *,'Valeurs rla_codepthS_tmp2  :: ',rla_codepthS_tmp2
           !PRINT *,'OK'
           CALL MCAL_interp1D_cubicspline_R4(rla_modelvalueS_tmp2, &
                                             rla_modeldepth2, &
                                             il_n, &
                                             rla_modeldepth_inter2, &
                                             rla_codepthS_tmp2, &
                                             il_n3, &
                                             rl_emptyvalue)
           rla_modelSdepth_inter(1:il_n3)=rla_modeldepth_inter2(:)
        ELSE
           CALL MCAL_interp1D_cubicspline_R4(rla_modelvalueT_tmp, &
                                             rda_modeldepth, &
                                             id_ndepth, &
                                             rla_modelTdepth_inter, &
                                             rla_codepthT_tmp, &
                                             id_nlevels, &
                                             rl_emptyvalue)
           CALL MCAL_interp1D_cubicspline_R4(rla_modelvalueS_tmp, &
                                             rda_modeldepth, &
                                             id_ndepth, &
                                             rla_modelSdepth_inter, &
                                             rla_codepthS_tmp, &
                                             id_nlevels, &
                                             rl_emptyvalue)
        ENDIF
        DO il_jj = 1, id_nlevels
           rl_tmp = rla_modelTdepth_inter(il_jj)
           IF ((IEOR(TRANSFER(rl_tmp,NaN), NaN) == 0) & 
                .OR. &
                (rl_tmp == rd_emptyvalue) &
                .OR. &
                (rl_tmp == rl_emptyvalue) &
                ) THEN
              rla_modelTdepth_inter(il_jj) =  rl_emptyvalue
           ENDIF
           rl_tmp = rla_modelSdepth_inter(il_jj)
           IF ((IEOR(TRANSFER(rl_tmp,NaN), NaN) == 0) & 
                .OR. &
                (rl_tmp == rd_emptyvalue) &
                .OR. &
                (rl_tmp == rl_emptyvalue) &
                ) THEN
              rla_modelSdepth_inter(il_jj) =  rl_emptyvalue
           ENDIF
           rda_modelvalueT_inter(il_jj, il_ji) = &
                rla_modelTdepth_inter(il_jj)
           rda_modelvalueS_inter(il_jj, il_ji) = &
                rla_modelSdepth_inter(il_jj)
        ENDDO !id_nlevels
     ELSE
        !            
        rda_modelvalueT_inter(1:id_nlevels, il_ji) = rl_emptyvalue
        rda_modelvalueS_inter(1:id_nlevels, il_ji) = rl_emptyvalue
        !
     ENDIF
     !
  ENDDO !il_ji

800 FORMAT(a35,2x,f7.2,2x,f7.2,2x,i5,2x,i5)
  !
  !
ENDSUBROUTINE interp_model_field
!
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE read_coloc_file (cd_colocFile, &
                            id_nprof, &
                            ida_xindex, & 
                            ida_yindex, & 
                            rda_poids,&
                            cda_positionqc)
  !==============================================================================================================
  !> \brief    Description : Routine permettant de lire la colocalisation des 4 points de grille modèles autour de
  !                          chaque observations insitu sous forme de positions x y avec leurs poids associés
  !<
  !===================================================================================================================
  !
  USE MIOL
  IMPLICIT NONE   
  !
  CHARACTER(LEN=255) :: cd_colocFile
  INTEGER :: id_nprof
  CHARACTER(LEN=1), DIMENSION(id_nprof) :: cda_positionqc
  INTEGER, DIMENSION(4,id_nprof) :: ida_xindex, ida_yindex
  REAL(KIND=4),DIMENSION(4,id_nprof) ::rda_poids
  !
  INTEGER :: il_ji, &
             il_jj, &
	     il_fic
  REAL(KIND=4) :: rl_lon, rl_lat,rl_coloc_lon,rl_coloc_lat
  !
  !
  !** Initialisation
  rda_poids(1:4,id_nprof)=0.0
  ida_xindex(1:4,id_nprof)=9999.
  ida_yindex(1:4,id_nprof)=9999.
  !
  !
  !------------------------------------------------------------------------
  ! Lecture du fichier de colocalisation
  !
  CALL MIOL_getFreeLU(il_fic)
  OPEN(il_fic, file=TRIM(cd_colocFile), &
       status='old', &
       form='formatted')
       !form='unformatted')
  !
  DO il_ji=1, id_nprof
   !! * Case Read with format   READ (il_fic,'(i6,2x,f9.3,2x,f9.3,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,f12.9)') il_jj, rl_lon, rl_lat, &
   !!  READ(il_fic) il_jj, rl_lon, rl_lat, &
   !!       ida_xindex(1,il_ji), ida_yindex(1,il_ji),rda_poids(1,il_ji),& 
   !!       ida_xindex(2,il_ji), ida_yindex(2,il_ji),rda_poids(2,il_ji),& 
   !!       ida_xindex(3,il_ji), ida_yindex(3,il_ji),rda_poids(3,il_ji),&
   !!       ida_xindex(4,il_ji), ida_yindex(4,il_ji),rda_poids(4,il_ji)
        READ(il_fic,'(i6,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,&
                      f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,&
                      f12.9,2x,i6,2x,i6,2x,f12.9,2x,f12.5,2x,f12.5)') &
                il_jj, rl_lon, rl_lat, &
                ida_xindex(1,il_ji), ida_yindex(1,il_ji),rda_poids(1,il_ji),&
                ida_xindex(2,il_ji), ida_yindex(2,il_ji),rda_poids(2,il_ji),&
                ida_xindex(3,il_ji), ida_yindex(3,il_ji),rda_poids(3,il_ji),&
                ida_xindex(4,il_ji), ida_yindex(4,il_ji),rda_poids(4,il_ji),&
                rl_coloc_lon,rl_coloc_lat

!#if defined key_debug
!     WRITE(0,*) 'Profil :: ',il_jj
!     WRITE(0,*) 'Position :: ',rl_lon, rl_lat
!     WRITE(0,*) 'Point 1 ::',ida_xindex(1,il_ji), ida_yindex(1,il_ji),rda_poids(1,il_ji)
!     WRITE(0,*) 'Point 2 ::',ida_xindex(2,il_ji), ida_yindex(2,il_ji),rda_poids(2,il_ji)
!     WRITE(0,*) 'Point 3 ::',ida_xindex(3,il_ji), ida_yindex(3,il_ji),rda_poids(3,il_ji)
!     WRITE(0,*) 'Point 4 ::',ida_xindex(4,il_ji), ida_yindex(4,il_ji),rda_poids(4,il_ji)
!     WRITE(0,*) 'Somme des poids ::',SUM(rda_poids(:,il_ji))
!#endif
     IF ( SUM(rda_poids(1:4,il_ji)) > 1.01 ) THEN
	 WRITE (0,*) "Somme des poids > 1"
	 STOP
     ENDIF
  ENDDO 
  !
  CLOSE(il_fic)
  !
  !
ENDSUBROUTINE read_coloc_file
!
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE inquire_coriolis_file (cd_inputFile, &
                                  cd_varname_T, &
                                  cd_varname_S, &
                                  id_nprof, &
                                  id_nlevels, &
                                  cda_dimname, &
                                  ld_istemp,&
                                  ld_ispsal,& 
                                  ld_isdepth,&
                                  ld_ispres,&
                                  ld_isdepthadj,&
                                  ld_ispresadj,&
                                  ld_isDepth_corr,&
                                  ld_parameterint,&
                                  ld_cparam,&
                                  ld_lparam)
  !==============================================================================================================
  !> \brief    Description : Routine permettant de lire un fichier insitu et de ressortir ses caractéristiques
  !<
  !===================================================================================================================
  !
  USE netcdf
  USE MIOL 
  IMPLICIT NONE 
  !
  CHARACTER(LEN=255) :: cd_inputFile
  CHARACTER(LEN=*)   :: cd_varname_T,cd_varname_S
  CHARACTER(LEN=255), DIMENSION(2) :: cda_dimname
  INTEGER :: id_nprof, &
       id_nlevels
  LOGICAL,INTENT(OUT) :: ld_istemp,&
                         ld_ispsal,&
                         ld_isdepth, &
                         ld_ispres, &
                         ld_isdepthadj,&
                         ld_ispresadj,&
                         ld_isDepth_corr,&
                         ld_parameterint,&
                         ld_cparam,&
                         ld_lparam

  !
  INTEGER :: il_file_id, &
       il_nbdim, &
       il_nbvar, &
       il_ji,&
       il_cnbdim,&
       il_lnbdim
  CHARACTER(LEN=255), DIMENSION(:), POINTER :: clpa_dimname, &
       clpa_varname
  INTEGER, DIMENSION(:), POINTER :: ilpa_dimlen, &
       ilpa_nbdim
  LOGICAL :: ll_flag_nprof, &
       ll_flag_nlevels, & 
       ll_isdepth, &
       ll_ispres, &
       ll_isvarexist_T,&
       ll_isvarexist_S,&
       ll_isdepth_corr,&
       ll_isdepthadj,&
       ll_ispresadj,&
       ll_parameterint,&
       ll_cparam,&
       ll_lparam

  !
  ll_flag_nprof = .FALSE.
  ll_flag_nlevels = .FALSE.
  ll_isvarexist_T = .FALSE.
  ll_isvarexist_S = .FALSE.
  ll_isdepth = .FALSE.
  ll_ispres = .FALSE.
  ll_isdepth_corr= .FALSE.
  ll_isdepthadj= .FALSE.
  ll_ispresadj= .FALSE.
  ld_lparam=.FALSE.
  ld_cparam=.FALSE.
  ld_parameterint=.FALSE.
  !      
  !
  !------------------------------------------------------------------------
  !
  ! Ouverture et lecture du fichiers
  CALL MIOL_openr_file_NC(cd_inputFile, &
       il_file_id)
  CALL MIOL_inquire_dimensions_NC(il_file_id, &
       il_nbdim, &
       clpa_dimname, &
       ilpa_dimlen)

  CALL MIOL_inquire_variables_NC(il_file_id, &
       il_nbvar, &
       clpa_varname, &
       ilpa_nbdim)
  IF ((il_nbdim .EQ. 0) .OR. &
       (il_nbvar .EQ. 0) ) THEN
     WRITE(0,*) ' inquire_coriolis_file : nbdim or nbvar equals zero.'
     CALL flush(0)
     STOP
  ENDIF
  !
  !
  ! Lecture du nombre de niveaux et de profondeurs
  DO il_ji=1, il_nbdim
     IF (TRIM(clpa_dimname(il_ji)).EQ. 'N_PROF') THEN
        id_nprof = ilpa_dimlen(il_ji)
        ll_flag_nprof = .TRUE.
        cda_dimname(2) = clpa_dimname(il_ji)
     ELSE IF (TRIM(clpa_dimname(il_ji)).EQ. 'N_LEVELS') THEN
        id_nlevels = ilpa_dimlen(il_ji)
        ll_flag_nlevels = .TRUE.
        cda_dimname(1) = clpa_dimname(il_ji)
     ELSE IF (TRIM(clpa_dimname(il_ji)).EQ. 'C_PARAMETERINT') THEN
        ld_cparam=.TRUE.
        il_cnbdim=ilpa_dimlen(il_ji) 
     ELSE IF (TRIM(clpa_dimname(il_ji)).EQ. 'L_PARAMETERINT') THEN
        ld_lparam=.TRUE.
        il_lnbdim=ilpa_dimlen(il_ji)    
     ENDIF
  ENDDO
  IF ((.NOT. ll_flag_nprof) .OR. &
       (.NOT. ll_flag_nlevels) ) THEN
     WRITE(0,*) ' inquire_coriolis_file : dimension N_PROF or N_LEVELS not found.'
     CALL flush(0)
     STOP
  ENDIF
  !
  !
  ! Nom de la variable de profondeur et existence de la variable
  DO il_ji=1, il_nbvar
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'DEPH') THEN
        ll_isdepth = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'DEPH_ADJUSTED') THEN
        ll_isdepthadj = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'PRES') THEN
        ll_ispres = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'PRES_ADJUSTED') THEN
        ll_ispresadj = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. TRIM(cd_varname_T)) THEN
        ll_isvarexist_T = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. TRIM(cd_varname_S)) THEN
        ll_isvarexist_S = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'DEPH_CORRECTED') THEN
        ll_isdepth_corr = .TRUE.
     ENDIF
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'PARAMETERINT') THEN
        ld_parameterint = .TRUE.
        IF ( il_cnbdim /= 12 .AND. il_lnbdim /= 20 ) ld_parameterint=.FALSE.
     ENDIF
  ENDDO
  !IF ( .NOT. ll_isvarexist ) THEN
  !   WRITE(0,*) ' inquire_coriolis_file : variable not found.'
  !   CALL flush(0)
  !   STOP
  !ENDIF
  !
  !
  ! Fermeture du fichier
  CALL MIOL_close_file_NC(il_file_id)
  !
  ld_isdepth       = ll_isdepth
  ld_ispres        = ll_ispres
  ld_istemp        = ll_isvarexist_T
  ld_ispsal        = ll_isvarexist_S
  ld_isdepthadj    = ll_isdepthadj
  ld_ispresadj     = ll_ispresadj
  ld_isDepth_corr  = ll_isDepth_corr
  !
  !
ENDSUBROUTINE inquire_coriolis_file
!

!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE read_coriolis_file (cd_inputFile, &
                               cd_inputVarname_T, &
                               cd_inputVarname_S,&
                               id_nprof, &
                               id_nlevels, &
                               ld_istemp,&
                               ld_ispsal,&
                               ld_isdepth, &
                               ld_isdepth_corr,&
                               ld_isdepthadj,&
                               ld_ispres, &
                               ld_ispresadj,&
                               rda_depthvalue_T, &
                               rda_depthvalue_S, &
                               cda_positionqc, &
                               rda_juldvalue, &
                               rd_fillvalue,&
                               rda_LON,&
                               rda_LAT,&
                               cda_depthvarname)
  !                                     
  USE netcdf
  USE MIOL 
  USE table_CLASS4
  !==============================================================================================================
  !> \brief    Description : Routine permettant de lire un fichier insitu et de ressortir certains paramètres
  !<
  !===================================================================================================================
  IMPLICIT NONE   
  !
  !
  CHARACTER(LEN=255),INTENT(IN)                            :: cd_inputFile
  CHARACTER(LEN=255),INTENT(IN)                            :: cd_inputVarname_T,cd_inputVarname_S
  INTEGER(KIND=4),INTENT(IN)                               :: id_nprof, &
                                                              id_nlevels
  LOGICAL,INTENT(IN)                                       :: ld_istemp,&
                                                              ld_ispsal,&
                                                              ld_isdepth, &
                                                              ld_isdepth_corr,&
                                                              ld_isdepthadj,&
                                                              ld_ispres, &
                                                              ld_ispresadj
  CHARACTER(LEN=20), DIMENSION(id_nprof),INTENT(OUT)     :: cda_depthvarname
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof),INTENT(OUT) :: rda_depthvalue_T,rda_depthvalue_S

  REAL(KIND=8), DIMENSION(id_nprof),INTENT(OUT)            :: rda_juldvalue,rda_LON,rda_LAT
  CHARACTER(LEN=1), DIMENSION(id_nprof),INTENT(OUT)        :: cda_positionqc
  CHARACTER(LEN=1), DIMENSION(id_nprof)                    :: cda_datamode
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof)             :: rla_depthadjustvalue,rla_presadjustvalue,rla_presvalue
  REAL(KIND=4),INTENT(OUT)                                 :: rd_fillvalue
  !  
  CHARACTER(LEN=255)                                       :: cl_ficlog,cl_ficlog2 
  INTEGER (KIND=4)                                         :: il_file_id, &
                                                              il_nbdim, &
                                                              il_nbvar, &
                                                              il_ji, &
                                                              il_jj, &
                                                              il_jk, &
                                                              il_nbatt,&
                                                              il_ind,il_pres,il_depth
  INTEGER (KIND=8)                                         :: il_max,&
                                                              il_min,&
                                                              il_pas
  INTEGER, DIMENSION(1)                                    :: il_pos
  INTEGER, DIMENSION(:), POINTER                           :: ilpa_dimlen, &
                                                              ilpa_nbdim
  CHARACTER(LEN=1), DIMENSION(:), POINTER                  :: clpa_1Dtmp
  CHARACTER(LEN=1), DIMENSION(id_nlevels,id_nprof)         :: cla_depthqc,cla_varqc_T,cla_varqc_S,cla_presqc,&
                                                              cla_presadjqc,cla_depthadjqc
  CHARACTER(LEN=1), DIMENSION(id_nlevels)                  :: cla_profqc
  CHARACTER(LEN=255)                                       :: cl_varname,cl_inputVarname_qc
  CHARACTER(LEN=255), DIMENSION(:), POINTER                :: clpa_dimname, &
                                                              clpa_varname, &
                                                              clpa_modelattname, &
                                                              clpa_modelattvalue
  CHARACTER(LEN=1), DIMENSION(:,:), POINTER                :: clpa_2Dtmp_T,clpa_2Dtmp_S,clpa_2Dtmp
  CHARACTER(len=8),DIMENSION(:,:),POINTER                  :: clpa_PLATFORM_NUMBER
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof)             :: rla_depthvalue
  REAL(KIND=4), DIMENSION(:,:), POINTER                    :: rlpa_tmp,rlpa_2D_TEMPtmp
  REAL(KIND=4), DIMENSION(:),ALLOCATABLE                   :: rla_prof
  REAL(KIND=4),DIMENSION(id_nlevels)                       :: rla_pres_theo
  REAL(KIND=4), DIMENSION(:), POINTER                      :: rlpa_modelattvalue
  REAL(KIND=8), DIMENSION(:), POINTER                      :: rlpa_1D_LON_tmp,rlpa_1D_LAT_tmp,rlpa_juldvalue
  REAL(KIND=4)                                             :: rl_pas,rl_missvalue
  LOGICAL                                                  :: ll_flag_nprof, &
                                                              ll_flag_nlevels,ll_exist_ficlog,ll_exist_ficlog2
  !
  !------------------------------------------------------------------------
  !
  ! Ouverture et lecture du fichiers
  CALL MIOL_openr_file_NC(cd_inputFile, &
                          il_file_id)
  CALL MIOL_inquire_dimensions_NC(il_file_id, &
                                  il_nbdim, &
                                  clpa_dimname, &
                                  ilpa_dimlen)
  CALL MIOL_inquire_variables_NC(il_file_id, &
                                 il_nbvar, &
                                 clpa_varname, &
                                 ilpa_nbdim)
  IF ((il_nbdim .EQ. 0) .OR. &
       (il_nbvar .EQ. 0) ) THEN
     WRITE(0,*) ' read_coriolis_file : nbdim or nbvar equals zero.'
     CALL flush(0)
     STOP
  ENDIF
  !
  ! Initialisation 
  rl_missvalue=rg_fillvalue
  rda_depthvalue_T(1:id_nlevels, 1:id_nprof) = rl_missvalue
  rda_depthvalue_S(1:id_nlevels, 1:id_nprof) = rl_missvalue
  rla_depthvalue(1:id_nlevels, 1:id_nprof) = rl_missvalue
  rla_presvalue(1:id_nlevels, 1:id_nprof) = rl_missvalue
  rda_LON(:)=rl_missvalue
  rda_LAT(:)=rl_missvalue
  cda_positionqc(1:id_nprof) = ' '
  cda_datamode(1:id_nprof) = ' '
  cla_depthqc(1:id_nlevels, 1:id_nprof) = ' '
  cla_presqc(1:id_nlevels, 1:id_nprof) = ' '
  cla_depthadjqc(1:id_nlevels, 1:id_nprof) = ' '
  cla_presadjqc(1:id_nlevels, 1:id_nprof) = ' '
  cla_varqc_T(1:id_nlevels, 1:id_nprof) = ' '
  cla_varqc_S(1:id_nlevels, 1:id_nprof) = ' '
  ll_exist_ficlog=.FALSE.
  ll_exist_ficlog2=.FALSE.
  !     
  !
  !Ajout C.REGNIER Lecture de la position du profil
  !* LONGITUDE 
  cl_varname = 'LONGITUDE'
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       rlpa_1D_LON_tmp)

  rda_LON(:)=rlpa_1D_LON_tmp(:)

  !* LATITUDE
  cl_varname = 'LATITUDE'
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       rlpa_1D_LAT_tmp)

  rda_LAT(:)=rlpa_1D_LAT_tmp(:)
  !*  DATA_MODE : definition du temps de la donnée réel, avec delai ou ajusté
  cl_varname = 'DATA_MODE'
  CALL MIOL_read_field_NC(il_file_id,&
                          cl_varname,&
                          clpa_1Dtmp,&
                          1)
  cda_datamode(1:id_nprof) = clpa_1Dtmp(1:id_nprof)
  !WRITE(0,*) 'Data mode : ',cda_datamode(:)
  ! Lecture du positionqc
  cl_varname = 'POSITION_QC'
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       clpa_1Dtmp, &
       1)
  cda_positionqc(1:id_nprof) = clpa_1Dtmp(1:id_nprof)
  DEALLOCATE(clpa_1Dtmp)

  IF (ld_istemp) THEN 
     cl_inputVarname_qc=TRIM(cd_inputVarname_T)//'_QC'
     !** Lecture du qc de la variable concerné
#if defined key_debug
     WRITE(0,*) 'READ variable QC:: ',TRIM(cl_inputVarname_qc)
#endif
     CALL MIOL_read_field_NC(il_file_id,&
          TRIM(cl_inputVarname_qc),&
          clpa_2Dtmp_T,&
          1)
     cla_varqc_T(1:id_nlevels, 1:id_nprof) = &
          clpa_2Dtmp_T(1:id_nlevels, 1:id_nprof)
     DEALLOCATE(clpa_2Dtmp_T) 
  ENDIF 

  IF (ld_ispsal) THEN 
     cl_inputVarname_qc=TRIM(cd_inputVarname_S)//'_QC'
     !** Lecture du qc de la variable concerné
#if defined key_debug
     WRITE(0,*) 'READ variable QC:: ',TRIM(cl_inputVarname_qc)
#endif
     CALL MIOL_read_field_NC(il_file_id,&
          TRIM(cl_inputVarname_qc),&
          clpa_2Dtmp_S,&
          1)
     cla_varqc_S(1:id_nlevels, 1:id_nprof) = &
          clpa_2Dtmp_S(1:id_nlevels, 1:id_nprof)
     DEALLOCATE(clpa_2Dtmp_S) 
  ENDIF
  !** Lecture plateform number 
  CALL MIOL_read_field_NC(il_file_id,&
                          'PLATFORM_NUMBER',&
                          clpa_PLATFORM_NUMBER,&
                           8)
! Lecture des profondeurs
  IF (ld_isdepth) THEN 
#if defined key_debug
     PRINT *,'Profondeur depth'
#endif
     cl_varname = 'DEPH'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          rlpa_tmp)
     rla_depthvalue(1:id_nlevels, 1:id_nprof) = &
          rlpa_tmp(1:id_nlevels, 1:id_nprof)
     cl_varname = 'DEPH_QC'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          clpa_2Dtmp, &
          1)
     cla_depthqc(1:id_nlevels, 1:id_nprof) = &
          clpa_2Dtmp(1:id_nlevels, 1:id_nprof)
     IF ( ld_isdepthadj) THEN
        cl_varname = 'DEPH_ADJUSTED'
        CALL MIOL_read_field_NC(il_file_id, &
             cl_varname, &
             rlpa_tmp)
        rla_depthadjustvalue(1:id_nlevels, 1:id_nprof) = &
             rlpa_tmp(1:id_nlevels, 1:id_nprof)
        cl_varname = 'DEPH_ADJUSTED_QC'
        CALL MIOL_read_field_NC(il_file_id, &
             cl_varname, &
             clpa_2Dtmp, &
             1)
        cla_depthadjqc(1:id_nlevels, 1:id_nprof) = &
               clpa_2Dtmp(1:id_nlevels, 1:id_nprof)
#if defined key_debug
     PRINT *,'OK DEPH_ADJUSTED'
#endif
     ENDIF
     IF (ld_isdepth_corr) THEN
       cl_varname = 'DEPH_CORRECTED'
       CALL MIOL_read_field_NC(il_file_id, &
            cl_varname, &
            rlpa_tmp)
       rla_depthvalue(1:id_nlevels, 1:id_nprof) = &
            rlpa_tmp(1:id_nlevels, 1:id_nprof)
       rla_depthadjustvalue(1:id_nlevels, 1:id_nprof)= &
            rla_depthvalue(1:id_nlevels, 1:id_nprof)
       !** QC mis à 1 par défaut car non renseigné
       cla_depthqc(1:id_nlevels, 1:id_nprof)='1'
#if defined key_debug
     PRINT *,'Profondeur depth corr :: Donnees EN3'
#endif
     ENDIF
#if defined key_debug
     PRINT *,'OK DEPH'
#endif
     DEALLOCATE(clpa_2Dtmp)  
  ENDIF
IF (ld_ispres) THEN
#if defined key_debug
     PRINT *,'Profondeur pres'
#endif
     rla_depthadjustvalue(1:id_nlevels, 1:id_nprof) = rl_missvalue
     cl_varname = 'PRES'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          rlpa_tmp)

     rla_presvalue(1:id_nlevels, 1:id_nprof) = &
          rlpa_tmp(1:id_nlevels, 1:id_nprof)

     cl_varname = 'PRES_QC'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          clpa_2Dtmp, &
          1 )
     cla_presqc(1:id_nlevels, 1:id_nprof) = &
          clpa_2Dtmp(1:id_nlevels, 1:id_nprof)
#if defined key_debug
     PRINT *,'Read PRES QC OK'
#endif

  DEALLOCATE(clpa_2Dtmp)
  IF ( ld_ispresadj) THEN
     rla_presadjustvalue(1:id_nlevels, 1:id_nprof) = rl_missvalue 
     cl_varname = 'PRES_ADJUSTED'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          rlpa_tmp)
     rla_presadjustvalue(1:id_nlevels, 1:id_nprof) = &
          rlpa_tmp(1:id_nlevels, 1:id_nprof)
     cl_varname = 'PRES_ADJUSTED_QC'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          clpa_2Dtmp, &
          1)
     cla_presadjqc(1:id_nlevels, 1:id_nprof) = &
            clpa_2Dtmp(1:id_nlevels, 1:id_nprof)
#if defined key_debug
   PRINT *,'Read PRES ADJUSTED OK'
#endif
  ENDIF
#if defined key_debug
   PRINT *,'Profondeur pres OK'
#endif
 ENDIF
 !** Lecture du jour julien
 cl_varname = 'JULD'
 CALL MIOL_read_field_NC(il_file_id, &
                         cl_varname, &
                         rlpa_juldvalue)
 rda_juldvalue(1:id_nprof) = &
      rlpa_juldvalue(1:id_nprof)
#if defined key_debug
   PRINT *,'Read JULD OK'
#endif

ALLOCATE(rla_prof(id_nlevels))

!** Partie du code qui filtre les données potentiellement erronées : profiles redondants et inversions

  DO il_jj=1, id_nprof
     il_pres=0
     il_depth=0
#if defined key_debug
     WRITE(0,*) 'Profil numéro :: ',il_jj
#endif
     IF ( ld_ispres .OR. ld_isdepth ) THEN

        IF ( ld_ispres .and. .not. ld_isdepth  ) THEN
            IF ( cda_datamode(il_jj) == 'R' )  THEN
               rla_prof(:)=rla_presvalue(:,il_jj)
               cla_profqc(:)=cla_presqc(:,il_jj)
               cda_depthvarname(il_jj)='PRES'
            ELSE
               IF ( ld_ispresadj) THEN
                  rla_prof(:)=rla_presadjustvalue(:,il_jj)
                  cla_profqc(:)=cla_presadjqc(:,il_jj)
                  cda_depthvarname(il_jj)='PRES_ADJUSTED'
               ELSE
                  rla_prof(:)=rla_presvalue(:,il_jj)
                  cla_profqc(:)=cla_presqc(:,il_jj)
                  cda_depthvarname(il_jj)='PRES'
               ENDIF
            ENDIF
        ENDIF
        !!IF (ld_isdepth_corr) THEN 
        !!  rla_prof(:)=rla_depthadjustvalue(:,il_jj)
        !!  cla_profqc(:)=cla_depthqc(:,il_jj)
        !!  cda_depthvarname(il_jj)='DEPH_CORR'
        !!ENDIF
        IF ( ld_isdepth .and. .not. ld_ispres ) THEN
           IF ( cda_datamode(il_jj) == 'R' )  THEN
              rla_prof(:)=rla_depthvalue(:,il_jj)
              cla_profqc(:)=cla_depthqc(:,il_jj)
              cda_depthvarname(il_jj)='DEPH'
           ELSE
              IF ( ld_isdepthadj) THEN
                 rla_prof(:)=rla_depthadjustvalue(:,il_jj)
                 cla_profqc(:)=cla_depthadjqc(:,il_jj)
                 cda_depthvarname(il_jj)='DEPH_ADJUSTED'
              ELSE
                 rla_prof(:)=rla_depthvalue(:,il_jj)
                 cla_profqc(:)=cla_depthqc(:,il_jj)
                 cda_depthvarname(il_jj)='DEPH'
              ENDIF
           ENDIF
        ENDIF
        IF ( ld_ispres .and. ld_isdepth ) THEN
          il_pres=COUNT(rla_presvalue(:,il_jj)<rl_missvalue)
          il_depth=COUNT(rla_depthvalue(:,il_jj)<rl_missvalue)
          IF ( il_pres > 0 .AND. il_depth > 0 ) THEN
             IF ( cda_datamode(il_jj) ==  'R' )  THEN
                rla_prof(:)=rla_depthvalue(:,il_jj)
                cla_profqc(:)=cla_depthqc(:,il_jj)
                cda_depthvarname(il_jj)='DEPH'
             ELSE
                IF ( ld_isdepthadj) THEN
                   rla_prof(:)=rla_depthadjustvalue(:,il_jj)
                   cla_profqc(:)=cla_depthadjqc(:,il_jj)
                   cda_depthvarname(il_jj)='DEPH_ADJUSTED'
                ELSE
                   rla_prof(:)=rla_depthvalue(:,il_jj)
                   cla_profqc(:)=cla_depthqc(:,il_jj)
                   cda_depthvarname(il_jj)='DEPH'
                ENDIF
            ENDIF
          !  WRITE(0,*) 'Pres et depth valable on garde depth'
          ELSE IF ( il_pres > 0 .AND. il_depth == 0 ) THEN
           ! WRITE(0,*) 'Pres valable on garde pres'
             IF ( cda_datamode(il_jj) == 'R' )  THEN
                rla_prof(:)=rla_presvalue(:,il_jj)
                cla_profqc(:)=cla_presqc(:,il_jj)
                cda_depthvarname(il_jj)='PRES'
             ELSE
                IF ( ld_ispresadj) THEN
                   rla_prof(:)=rla_presadjustvalue(:,il_jj)
                   cla_profqc(:)=cla_presadjqc(:,il_jj)
                   cda_depthvarname(il_jj)='PRES_ADJUSTED'
                ELSE
                   rla_prof(:)=rla_presvalue(:,il_jj)
                   cla_profqc(:)=cla_presqc(:,il_jj)
                   cda_depthvarname(il_jj)='PRES'
                ENDIF
             ENDIF
          ELSE IF (il_pres == 0 .AND. il_depth > 0 ) THEN
             IF ( cda_datamode(il_jj) == 'R' )  THEN
                rla_prof(:)=rla_depthvalue(:,il_jj)
                cla_profqc(:)=cla_depthqc(:,il_jj)
                cda_depthvarname(il_jj)='DEPH'
             ELSE
                IF ( ld_isdepthadj) THEN
                   rla_prof(:)=rla_depthadjustvalue(:,il_jj)
                   cla_profqc(:)=cla_depthadjqc(:,il_jj)
                   cda_depthvarname(il_jj)='DEPH_ADJUSTED'
                ELSE
                   rla_prof(:)=rla_depthvalue(:,il_jj)
                   cla_profqc(:)=cla_depthqc(:,il_jj)
                   cda_depthvarname(il_jj)='DEPH'
                ENDIF
             ENDIF
           ! WRITE(0,*) 'Depth valable on garde Depth'
          ELSE 
           !  WRITE(0,*) 'Probleme pres et depth non valable'
            rla_prof(:)=rl_missvalue
            cla_profqc(:)=cla_depthqc(:,il_jj)
            cda_depthvarname(il_jj)='None'
          ENDIF         
        ENDIF

        IF ( id_nlevels > 4 ) THEN
          !** Gestion des cas de profils inversés ou redondés avec un bon QC
          IF ( rla_prof(1) >= 0 .AND. rla_prof(5) < rl_missvalue &
               .AND. rla_prof(1) < 500 .AND. CEILING(rla_prof(5)-rla_prof(1)) > 0 &
               .AND. rla_prof(5) < 3000 ) THEN
             il_pas=CEILING((rla_prof(5)-rla_prof(1))/4)
             il_max=CEILING(rla_prof(1))+(il_pas*id_nlevels)
             rla_pres_theo=(/CEILING(rla_prof(1)):il_max:il_pas/)
          ELSE
             il_pas=2
             IF (ld_isdepth_corr) il_pas=1       
             il_max=il_pas*id_nlevels
             rla_pres_theo=(/0:il_max:il_pas/)                    
          ENDIF
        ELSE
           il_pas=2
           il_max=2*id_nlevels
           rla_pres_theo=(/0:il_max:il_pas/)
        ENDIF
     ENDIF
!#if defined key_debug
!           WRITE(0,*) 'Creation d un profile Profile theorique ::' 
!           WRITE(0,*) '-----------------------------------------------------------------------'
!           WRITE(0,*) 'Profondeur 1 a 5, max et pas :: ',rla_prof(1:5),il_max,il_pas
!           WRITE(0,*) 'rla_pres_theo :: ',rla_pres_theo
!           WRITE(0,*) '-----------------------------------------------------------------------'
!           WRITE(0,*) 'profondeurs :: ',rla_prof(:)
!#endif


! Test sur la valeur de la qualite du qc en profondeur
!
! DEPH_QC ou PRES_QC =   0, 1 or 7 (cas des ferry box  : profondeur
! théorique et non mesurée)
! 0=Unqualified
! 1=Correct value (all ckecks passed)
! 7=Value modified during quality control : delayed time corrected
! 8=value interpolated
     DO il_jk=1, id_nlevels
        IF ( (cla_profqc(il_jk) .EQ. '0') .OR. &
             (cla_profqc(il_jk) .EQ. '1') .OR. &
	      (cla_profqc(il_jk) .EQ. '7') ) THEN
#if defined key_inv_prof
              !** Gestion des profils inversés  
              IF ( il_jk < id_nlevels ) THEN
                 IF ( rla_prof(il_jk+1) < rl_missvalue .AND. rla_prof(il_jk) < rl_missvalue ) THEN
                    IF ( rla_prof(il_jk) <   rla_prof(il_jk))  THEN
                       IF (ld_isdepth_corr) THEN 
                          cl_ficlog=TRIM(cg_ficlog)//'/logout_EN3_invprof_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
                       ELSE
                          cl_ficlog=TRIM(cg_ficlog)//'/logout_CORIO_invprof_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
                       ENDIF
                       INQUIRE(FILE=TRIM(cl_ficlog),EXIST=ll_exist_ficlog)
                       IF ( .NOT. ll_exist_ficlog ) THEN
                          OPEN(unit=50,file=TRIM(cl_ficlog),form='FORMATTED',STATUS='new')
                          CLOSE(50)
                          ll_exist_ficlog=.TRUE.
                       ENDIF
                       OPEN(unit=50,file=TRIM(cl_ficlog),form='FORMATTED',&
                            & POSITION='APPEND',STATUS='old')
                       WRITE(50,FMT=600,advance="yes") TRIM(cd_inputFile),il_jj,il_jk,rla_prof(il_jk)
                       CLOSE(50)
                       rla_prof(il_jk) =rl_missvalue
                    ENDIF
                 ENDIF
              ENDIF
#endif
#if defined key_red_profil
              !** Gestion des Profils douteux en profondeur => profils recopiés
              IF (  il_jk > 60 .AND. rla_prof(il_jk) < rla_pres_theo(il_jk)/4 & 
                  .OR. il_jk > 1 .AND. rla_prof(il_jk) < rl_missvalue .AND. rla_prof(il_jk)  >  100*rla_pres_theo(il_jk) &
                   .AND. rla_prof(il_jk) > 0 ) THEN
                 !WRITE(0,*) 'Cas profil foireux plus au fond pres',rla_prof(il_jk),rla_pres_theo(il_jk)/4,il_pas,&
                 !                                                 rla_prof(1),rla_prof(5),clpa_PLATFORM_NUMBER(il_jj,1)(1:4),&
                 !                                                  100*rla_pres_theo(il_jk)
                 if (ld_isdepth_corr) then
                    cl_ficlog2=TRIM(cg_ficlog)//'/logout_EN3_redprof_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
                 else
                    cl_ficlog2=TRIM(cg_ficlog)//'/logout_CORIO_redprof_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
                 endif
                 INQUIRE(FILE=TRIM(cl_ficlog2),EXIST=ll_exist_ficlog2)
                 IF ( .NOT. ll_exist_ficlog2 ) THEN
                    OPEN(unit=60,file=TRIM(cl_ficlog2),form='FORMATTED',STATUS='new')
                    CLOSE(60)
                    ll_exist_ficlog2=.TRUE.
                 ENDIF
                 OPEN(unit=60,file=TRIM(cl_ficlog2),form='FORMATTED',&
                      & POSITION='APPEND',STATUS='old')
                 WRITE(60,FMT=710,advance="yes") TRIM(cd_inputFile),il_jj,il_jk,rla_presvalue(il_jk,il_jj),rla_pres_theo(il_jk)/5,100*rla_pres_theo(il_jk),il_pas,il_max,TRIM(cd_inputVarname_T)
                 CLOSE(60)
                 rla_prof(il_jk) =rl_missvalue
              ENDIF
#endif
        ELSE 
           rla_prof(il_jk)= rl_missvalue
        ENDIF
        rda_depthvalue_T(il_jk,il_jj)=rla_prof(il_jk) 
        rda_depthvalue_S(il_jk,il_jj)=rla_prof(il_jk) 
        !** Mise à nan des profondeurs non valables pour la variables considérée
        IF ( cla_varqc_T(il_jk, il_jj) .EQ. '4') THEN
!#if defined key_debug
!          WRITE(0,*),'Valeur non correcte :: ',cla_varqc_T(il_jk, il_jj)
!          WRITE(0,*),'Profil n° :: ',il_jj
!          WRITE(0,*),'Niveau n° :: ',il_jk
!#endif
         rda_depthvalue_T(il_jk, il_jj) = rl_missvalue
        ENDIF
        IF ( cla_varqc_S(il_jk, il_jj) .EQ. '4') THEN
!#if defined key_debug
!          WRITE(0,*),'Valeur non correcte :: ',cla_varqc_S(il_jk, il_jj)
!          WRITE(0,*),'Profil n° :: ',il_jj
!          WRITE(0,*),'Niveau n° :: ',il_jk
!#endif
         rda_depthvalue_S(il_jk, il_jj) = rl_missvalue
        ENDIF

     ENDDO  !** il_jk=1, id_nlevels

  ENDDO !** il_jj=1, id_nprof
  !** 
  !
  !
  ! Lecture des attributs
  CALL MIOL_read_attributeslist_NC (il_file_id, &
       cd_inputVarname_T, &
       il_nbatt, &
       clpa_modelattname, &
       clpa_modelattvalue, &
       rlpa_modelattvalue)
  !
  !
  ! Recherche de la fillvalue
  !
  DO il_ji=1, SIZE(clpa_modelattname)
     IF(TRIM(clpa_modelattname(il_ji)).EQ.'_FillValue') THEN
        rd_fillvalue = rlpa_modelattvalue(il_ji)
     ENDIF
  ENDDO
  !
  !
  ! Fermeture du fichier
  CALL MIOL_close_file_NC(il_file_id)
  !
700 FORMAT(a,2x,i5,2x,i5,2x,f11.4,2x,f11.4,2x,f11.4)
710 FORMAT(a,2x,i5,2x,i5,2x,f11.4,2x,f11.4,2x,f11.4,2x,i7,2x,i9,2x,a)
600 FORMAT(a,2x,i5,2x,i5,2x,f11.4,2x,f11.4)
  !
  !
ENDSUBROUTINE read_coriolis_file


!SUBROUTINE read_lightout_test(cd_filename,cd_dim,cd_meshfile,rdpa_lon,rdpa_lat,rdpa_var)
SUBROUTINE read_lightout_test(cd_filename,cd_dim,cd_meshfile,rdpa_lat)
    CHARACTER(LEN=255),INTENT(IN)                  :: cd_filename,cd_meshfile
    CHARACTER(LEN=2),INTENT(IN)                    :: cd_dim
    REAL(KIND=4),DIMENSION(:,:),POINTER,INTENT(IN) :: rdpa_lat
    REAL(KIND=4),DIMENSION(:,:),POINTER            :: rdpa_lon
    REAL(KIND=4),DIMENSION(:,:,:),POINTER          :: rdpa_var
    !CHARACTER(LEN=256)                             :: cl_outputfile
    WRITE(0,*) '----------- Inside read_lightout_test -----------'
    WRITE(0,*) cd_filename,cd_dim,cd_meshfile
END SUBROUTINE read_lightout_test

    !!=======================================================================
    !> \brief
    !!**** subroutine read_ligthout \n
    !!
    !!     Purpose:\n
    !!     --------\n
    !!     Program to read lightoutfile coded in bytes
    !!     Input : \n
    !!     ------\n
    !!     @filename : input filename
    !!     @dimension : input dimension in 2D or 3D
    !!     @variable : name of output variable 
    !!     @meshfile :  mesh file for lon lat construction
    !!     @sampling :  sampling of the lightout file (for ex 3 for PSY4 and 2 for PSY3)
    !!     @lon      : 2D pointer for output longitude
    !!     @lat      : 2D pointer for output latitude
    !!     @var      : 3D pointer for output variable
    !!     Output : \n
    !!     file in netcdf with lon/lat/depth
    !!     @lon      : 2D pointer for output longitude
    !!     @lat      : 2D pointer for output latitude
    !!     @var      : 3D pointer for output variable
    !!
    !!***  Method: \n
    !!     ------- \n
    !!     History: \n
    !!     -------- \n
    !!   \n Version    Programmer      Date            Description
    !!   \n -------    ----------      ----            -----------
    !!   \n  1.0        C. REGNIER     1st June 2016        Creation with jmi contribution
    !<
    !!=======================================================================
    !
SUBROUTINE read_lightout_withmask(cd_filename,cd_dim,cd_meshfile,&
                                  rdpa_lon,rdpa_lat,rdpa_depth,&
                                  rdpa_var)
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE MIOL
    IMPLICIT NONE
    !
    !
    !**   0.2 Local variables
    !
    !
    CHARACTER(LEN=255),INTENT(IN)                  :: cd_filename,cd_meshfile
    CHARACTER(LEN=2),INTENT(IN)                    :: cd_dim
    !CHARACTER(LEN=256)                             :: cl_outputfile
    CHARACTER(LEN=256)                             :: cl_lon,cl_lat,cl_depth
    REAL(KIND=4)                                   :: rl_dimiglo_sampling,rl_dimjglo_sampling,rl_dimk
    REAL(KIND=4)                                   :: rl_AUXMIN,rl_AUXMAX,rl_UNDEFO,rl_AUXMID,&
                                                      rl_scale,rl_ATANMAX,rl_ATANMIN
    REAL(KIND=4),DIMENSION(:,:),POINTER            :: rdpa_lon,rdpa_lat
    REAL(KIND=4),DIMENSION(:,:,:),POINTER          :: rdpa_var
    REAL(KIND=4),DIMENSION(:),POINTER              :: rdpa_depth
    REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE      :: rla_tab3D
    REAL(KIND=4),DIMENSION(:,:,:,:),ALLOCATABLE    :: rla_tab4D
    REAL(KIND=4), parameter                        :: rp_pi     = 3.14159265358979323846  
    CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE    :: cla_dimname
    INTEGER(KIND=4)  ,DIMENSION(:),ALLOCATABLE     :: ila_dimlen
    INTEGER(KIND=2)                                :: il_MAXINT,il_RMAXINT
    INTEGER(KIND=2), DIMENSION(:,:,:), ALLOCATABLE :: ila_AUXglo
    INTEGER(KIND=4)                                :: il_ji,il_err,il_dimiglo_sampling,il_dimjglo_sampling,&
                                                      il_nx,il_ny,il_nx_ini,il_ny_ini,il_nz,il_dim,il_dimk,il_unit_lu,il_narg,&
                                                      iargc,il_file_id,il_meshfile
    INTEGER(KIND=4),DIMENSION(2)                   :: ila_lon2D,ila_lat2D
    INTEGER(KIND=4),DIMENSION(2)                   :: ila_depth
    INTEGER(KIND=4),DIMENSION(3)                   :: ila_dim3D
    INTEGER(KIND=4),DIMENSION(4)                   :: ila_dim4D

#if defined key_debug
  WRITE (0,*) "Read lightout :: ",cd_filename
#endif

    CALL MIOL_getFreeLU(il_unit_lu)
    OPEN(il_unit_lu,file=TRIM(cd_filename),form='unformatted',access='sequential',action='READ',status='OLD',iostat=il_err)
    IF (il_err > 0) THEN
       WRITE (0,*) "read_lightout: Problem opening file "//TRIM(cd_filename)
       CALL flush(0)
       STOP
    ENDIF
!
    READ(il_unit_lu) rl_dimiglo_sampling
    READ(il_unit_lu) rl_dimjglo_sampling
    READ(il_unit_lu) rl_dimk
    READ(il_unit_lu) rl_AUXMIN,rl_AUXMAX,rl_UNDEFO,il_MAXINT
!
    il_dimiglo_sampling=INT(rl_dimiglo_sampling,4)
    il_dimjglo_sampling=INT(rl_dimjglo_sampling,4)
    il_dimk=INT(rl_dimk,4)
!
    ALLOCATE(ila_AUXglo(il_dimiglo_sampling,il_dimjglo_sampling,il_dimk))
!
    READ(il_unit_lu) ila_AUXglo
!   Convert with offset and scale factor
#if defined key_debug
    WRITE(0,*) 'Read OK : ',shape(ila_AUXglo)
    WRITE(0,*) 'Min : ',minval(ila_AUXglo)
    WRITE(0,*) 'Max : ',maxval(ila_AUXglo)
    WRITE(0,*) 'Dimensions : ',size(shape(ila_AUXglo))
#endif
    il_dim=size(shape(ila_AUXglo))
    IF ( cd_dim == '3D')  THEN
        IF ( il_dim /= 3 ) THEN
            WRITE(0,*) cd_filename,' is not a 3D file'
            STOP
        ENDIF 
        ila_dim3D=shape(ila_AUXglo)
        ALLOCATE(rdpa_var(ila_dim3D(1),ila_dim3D(2),ila_dim3D(3)))
        rdpa_var(:,:,:)=rg_fillValue
        il_nx=ila_dim3D(1)
        il_ny=ila_dim3D(2)
        il_nz=ila_dim3D(3)
    !ELSEIF ( cd_dim == '4D')  THEN
    !    IF ( il_dim /= 4 ) THEN
    !        WRITE(0,*) cd_filename,' is not a 3D file'
    !        STOP
    !    ENDIF 
    !    ila_dim4D=shape(ila_AUXglo)
    !    ALLOCATE(rla_tab4D(ila_dim4D(1),ila_dim4D(2),ila_dim4D(3),ila_dim4D(4)))
    !    rla_tab4D(:,:,:,:)=rg_fillValue
    ELSE 
        WRITE(0,*) 'Problem with dimensions : ',cd_dim
        STOP
    ENDIF
    rl_AUXMID = (rl_AUXMIN+rl_AUXMAX)/2.
    rl_scale = rl_AUXMAX-rl_AUXMID
    IF  (rl_scale .ne. 0.) THEN
        rl_scale = 4./rl_scale
    ELSE 
        rl_scale = 1.
    ENDIF
    rl_ATANMAX=atan( (rl_AUXMAX - rl_AUXMID )*rl_scale ) / rp_pi
    rl_ATANMIN=ATAN( (rl_AUXMIN - rl_AUXMID )*rl_scale ) / rp_pi
    il_RMAXINT=il_MAXINT-1
    IF ( il_dim == 3 ) THEN 
        WHERE (ila_AUXglo .ne. il_MAXINT) rdpa_var=TAN(ila_AUXglo/(il_RMAXINT/rl_ATANMAX)*rp_pi)/rl_scale+rl_AUXMID
  !!  ELSE IF ( il_dim == 4 ) THEN
  !!      WHERE (ila_AUXglo .ne. il_MAXINT) rla_tab4d=TAN(ila_AUXglo/(il_RMAXINT/rl_ATANMAX)*rp_pi)/rl_scale+rl_AUXMID
    ENDIF  
    cl_lon="longitude"
    cl_lat="latitude"
    cl_depth="depth"
   !! open mesh file
    CALL MIOL_openr_file_NC(cd_meshfile,il_meshfile)
    CALL MIOL_read_field_NC(il_meshfile,cl_lon,rdpa_lon,ila_lon2D)
    CALL MIOL_read_field_NC(il_meshfile,cl_lat,rdpa_lat,ila_lat2D)
    CALL MIOL_read_field_NC(il_meshfile,cl_depth,rdpa_depth,ila_depth)
    CALL MIOL_close_file_NC(il_meshfile)
#if defined key_debug
  WRITE (0,*) "Read lightout OK "
#endif

END SUBROUTINE read_lightout_withmask
ENDPROGRAM SPATIAL_INTERPOLATION
!
