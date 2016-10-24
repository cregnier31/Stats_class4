!******************************************************************************
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
  !!        \n 14/03/2013 (L.ZAWADZKI)  Adaptation pour fichiers CLASS4 Godae
  !!                                    (report.ship convertis ou CLASS4 FOAM)
  !!                                    Ajout nml_names, 
  !!                                    Ajout calcul SLA a partir SSH et MSSH 
  !!                                    Suppression de plusieurs tests QC
  !!                                    Suppression de l'interpolation temporelle
  !!        \n Juillet 2014 (CREGNIER)  Prise en compte des fichiers avec plusieurs échéances, merge avec ancien CLASS4
  !<
  !===================================================================================================================
  !
  !
  USE netcdf
  USE MCAL
  USE MIOL 
  USE MIOL_param
  USE table_CLASS4
  IMPLICIT NONE
  !
  INTEGER :: il_narg, &
       iargc,      &
       il_ji,      &
       il_file_id, &
       il_ncast,   &
       il_nvar,    &
       il_nbfile,  &
       il_status,  &
       il_jdateT0, &
       il_jdateT1
  
  LOGICAL :: ll_mssh,ll_compute
  REAL    :: rl_mssh_shift

  CHARACTER(LEN=255) :: cl_input, &
       cl_inputFile,     &
       cl_msshFile,      &
       cl_outputVarname, &
       cl_colocFile,     &
       cl_commandFile,   &
       cl_inputVarname,  &
       cl_modele,        &
       cl_daterun,       & 
       cl_log

  CHARACTER(LEN=255), DIMENSION(:), ALLOCATABLE :: cla_modelFile
  NAMELIST / interpolate_3D / cl_inputFile, &
       cl_msshFile,      &
       cl_colocfile,     &
       cl_inputVarname,  &
       cl_outputVarname, &
       il_ncast,         &
       il_nvar,          &
       ll_mssh,          &
       ll_compute,       &
       rl_mssh_shift,    &
       il_nbfile
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
     PRINT *,'     interpolate_prof3d -c commandfile.nml -m PSYxVxRx -r YYYYMMDD (-l logfile)' 
     PRINT *,' '
     PRINT *,' -c commandfile.nml   : The command file '
     PRINT *,' -m PSYxVxRx          : Model configuration '
     PRINT *,' -r YYYYMMDD          : Run Date '
     PRINT *,' -l logfile           : Log File '
     PRINT *,' Nb arguments  :: ',il_narg
     STOP
  ELSE
     DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-c') THEN
           CALL getarg(il_ji+1, cl_commandFile)
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
  !------------------------------------------------------------------------
  ! Lecture du command file
  !
  OPEN(20, file=TRIM(cl_commandFile), &
       status='old', &
       form='formatted', &
       iostat=il_status)
  READ(20, interpolate_3D)
  ALLOCATE(cla_modelFile(il_nbfile), stat=il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) ' interpolate_prof3D : memory allocation error.'
     CALL flush(0)
     STOP
  ENDIF
  DO il_ji=1, il_nbfile
     READ(20,FMT='(A)') cla_modelFile(il_ji)
  ENDDO
  CLOSE(20)
  !
  !
  !------------------------------------------------------------------------
  ! Interpolation du modele

  CALL interpolate_3D_model_field(cl_inputFile, &
       cl_colocFile,     &
       cl_inputVarname,  &
       cl_outputVarname, &
       il_ncast,         &
       il_nvar,          &
       il_nbfile,        &
       cla_modelFile,    &
       ll_mssh,          &
       ll_compute,       &
       rl_mssh_shift,    &
       cl_msshFile)
  !      
  DEALLOCATE(cla_modelFile, stat=il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) ' interpolate_prof3D : memory deallocation error.'
     CALL flush(0)
     STOP
  ENDIF
ENDPROGRAM SPATIAL_INTERPOLATION
!
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE interpolate_3D_model_field(cd_inputFile, &
     cd_colocFile,        &
     cd_inputVarname,     &
     cd_outputVarname,    &
     id_ncast,            &
     id_nvar,             &
     id_nbfile,           &
     cda_modelFile,       &
     ld_mssh,             &
     ld_compute,          &
     rd_mssh_shift,       &
     cd_msshFile)
  !
  USE netcdf
  USE MCAL
  USE MIOL 
  IMPLICIT NONE
  !     
  INTEGER ,INTENT(IN):: id_ncast,  &
       id_nvar,      &
       id_nbfile
  LOGICAL ,INTENT(IN):: ld_mssh,ld_compute
  CHARACTER(LEN=255), DIMENSION(id_nbfile), INTENT(IN) :: cda_modelFile 
  CHARACTER(LEN=255), INTENT(IN) :: cd_colocFile,&
       cd_inputFile,      &
       cd_outputVarname,  &
       cd_msshFile,       & !ne sert que si ld_mssh = .true.
       cd_inputVarname
  !
  INTEGER :: il_jf,   &
       il_jc,         &
       il_jv,         &
       il_nbdim,      &
       il_nbdimmssh,  &
       il_nlon,       &
       il_nlonmssh,   &
       il_nlat,       &
       il_nlatmssh,   &
       il_ndepth,     &
       il_ndepthmssh, &
       il_nprof,      &
       il_nlevels,    &
       il_ntime
  REAL(KIND=4) :: rl_fillValue,rd_mssh_shift,rl_juld
  INTEGER, DIMENSION(:,:), ALLOCATABLE :: ila_xindex, &
       ila_yindex
  CHARACTER(LEN=255)   :: cl_modelVarname
  CHARACTER(LEN=255) :: cl_depthvarname, &
       cl_modelFile,               &
       cl_msshVarname,             &
       cl_tmp
       
  CHARACTER(LEN=255), DIMENSION(1) :: cla_msshVarname
  CHARACTER(LEN=255), DIMENSION(2) :: cla_dimname
  CHARACTER(LEN=255), DIMENSION(:), ALLOCATABLE :: cla_modelVarname
  REAL(KIND=4), DIMENSION(:,:,:,:), ALLOCATABLE :: rla_modelvalue, &
       rla_msshvalue,    &
       rla_modelEquivValue,&
       rla_modelEquivValuemssh
  REAL(KIND=4), DIMENSION(:,:), ALLOCATABLE :: rla_depthvalue, &
       rla_interpValue,    &
       rla_interpMSSHValue,&
       rla_poids
  REAL(KIND=4), DIMENSION(:), ALLOCATABLE   :: rla_modeldepth, &
        rla_msshdepth,rla_juld_mod
  REAL(KIND=8), DIMENSION(:), ALLOCATABLE :: rla_LON, &
        rla_LAT, &
        rla_leadtimevalue,&
        rla_juld
  INTEGER(KIND=4)     :: il_file_id
  LOGICAL             :: ll_isDepthVar,ll_isdepthdim,ll_savevalue
  ll_isdepthdim = .TRUE.
 !
  rl_fillValue=99999.
  !
  !---------------------------------------------------------------------
  ! Recherche des dimensions du fichier Observations
#if defined key_debug
  WRITE(0,*) ' inquire_observation_file '
#endif

  CALL inquire_observation_file(cd_inputFile, &
       cd_inputVarname,   &
       il_nprof,          &
       il_nlevels,        &
       cla_dimname,       &
       ll_isDepthVar)


#if defined key_debug
  WRITE(0,*) 'Lecture du fichier Observations'
#endif
  !------------------------------------------------------------------
  ! Lecture du fichier Observations
  !
  ALLOCATE(rla_depthvalue   (il_nlevels, il_nprof) )
  ALLOCATE(rla_LON          (il_nprof            ) )
  ALLOCATE(rla_LAT          (il_nprof            ) )
  ALLOCATE(rla_juld         (il_nprof            ) )
  ALLOCATE(rla_leadtimevalue(id_ncast            ) )
  ALLOCATE(cla_modelVarname (id_nvar             ) )

#if defined key_debug
  WRITE(0,*) 'read_observation_file ::',cd_inputFile
#endif
  CALL read_observation_file(cd_inputFile, &
                   cd_inputVarname,        &
                   il_nprof,               &
                   id_ncast,               &
                   id_nvar,                &
                   il_nlevels,             &
                   ll_isDepthVar,          &
                   rla_depthvalue,         &
                   rla_leadtimevalue,      &
                   cla_modelVarname,       &
                   rl_fillValue,           &
                   rla_LON,                &
                   rla_LAT,                &
                   rla_juld)
  !
  

  WRITE(0,*) 'Model Varname :: ',cla_modelVarname
!#if defined key_debug
!  WRITE(0,*) 'read_observation_file ok ::',cd_inputFile
!  WRITE(0,*) 'Profondeur :: ',rla_depthvalue
!  WRITE(0,*) 'Model Varname :: ',cla_modelVarname
!#endif
  !
  !
  !
  !------------------------------------------------------------------
  ! Lecture du fichier de colocalisation
  !
  ALLOCATE(ila_xindex(4,il_nprof))
  ALLOCATE(ila_yindex(4,il_nprof))
  ALLOCATE(rla_poids(4,il_nprof))
#if defined key_debug
  WRITE(0,*),'read_coloc_file ::',cd_colocFile
#endif
  CALL read_coloc_file(cd_colocFile, &
                       il_nprof,   &
                       ila_xindex, &
                       ila_yindex, &
                       rla_poids)
        
#if defined key_debug
  WRITE(0,*),'read_coloc_file OK ::'
#endif
  !
  !
  !------------------------------------------------------------------
  ! Lecture du fichier de MSSH (MDT) si besoin
  !
  IF ( ld_mssh ) THEN
     ! Recherche des dimensions du fichier MSSH
#if defined key_debug
       WRITE(0,*),'inquire_mssh_file ::',cd_msshFile
#endif
     
     cla_msshVarname(:) = 'mssh'
     CALL inquire_model_file(cd_msshFile, &
          cla_msshVarname,  &
          1,                &
          cl_msshVarname,   &
          il_nbdimmssh,     &
          il_nlonmssh,      &
          il_nlatmssh,      &
          il_ndepthmssh,    &
          il_ntime,         &
          cl_depthvarname)

     IF (il_ndepthmssh .NE. 1) THEN
         WRITE(0,*) 'MSSH file depth dimension has unexpected length. Got ',il_ndepthmssh,' while expecting 1'
         CALL flush(0)
         STOP
     ENDIF
     !
     !
     !---------------------------------------------------------------------
     ! Lecture du fichier MSSH
     !
#if defined key_debug
      WRITE(0,*),'Read mssh file ::',cd_msshFile
#endif
     ALLOCATE(rla_msshvalue(il_nlonmssh,il_nlatmssh,il_ndepthmssh,1))
     ALLOCATE(rla_msshdepth(il_ndepthmssh))
     ll_isdepthdim = .FALSE.
     CALL read_model_file_2(cd_msshFile, &
          cl_msshVarname,           &
          cl_depthvarname,          &
          rla_msshvalue,            &
          rla_msshdepth,            &
          il_nlonmssh,              &
          il_nlatmssh,              &
          il_ndepthmssh,            &
          il_nbdimmssh,             &
          ll_isdepthdim)

#if defined key_debug
      WRITE(0,*),'Read mssh file OK'
#endif
     DEALLOCATE(rla_msshdepth)
  ENDIF
!  !------------------------------------------------------------------
!  !  Lecture des dimensions de parameterint
!  CALL read_parameterint_dim(cd_inputFile)  
!  !
!  !
!  !------------------------------------------------------------------
!  ! Ecriture de la nouvelle variable PARAMETERINT
!  !
!  CALL write_parameterint(cd_inputFile)
!#if defined key_debug
!  WRITE(0,*) ' write_parameterint OK '
!#endif
  !
  !
  ALLOCATE(rla_modelEquivValue(il_nlevels,id_ncast,id_nvar,il_nprof))
  IF ( ld_mssh .and. .not. ld_compute ) ALLOCATE(rla_modelEquivValuemssh(il_nlevels,id_ncast,id_nvar,il_nprof))
  !  modelEquiv(numdeps,numfcsts,numvars,numobs)
  !
  il_jc = 1
  DO il_jf=1,id_nbfile
#if defined key_debug
     WRITE(0,*) 'Nb files  : ',id_nbfile
#endif
     IF (il_jc .GT. id_ncast ) il_jc = 1
     cl_modelFile = cda_modelFile(il_jf)
     !
     !
     !---------------------------------------------------------------------
     ! Recherche des dimensions du fichier modele
     !
     CALL inquire_model_file(cl_modelFile, &
          cla_modelVarname, &
          id_nvar,          &
          cl_modelVarname,  &
          il_nbdim, &
          il_nlon, &
          il_nlat, &
          il_ndepth, &
          il_ntime,   &
          cl_depthvarname)
#if defined key_debug
     WRITE(0,*) 'ModelVarname : ',cl_modelVarname
#endif
     !
     !
     !---------------------------------------------------------------------
     ! Lecture du fichier modele
     !
     IF ( TRIM(cl_modelVarname) .EQ. 'sossheig' .OR. TRIM(cl_modelVarname) .EQ. 'ileadfra' ) THEN
        ll_isdepthdim = .FALSE.
        ALLOCATE(rla_modelvalue(il_nlon,il_nlat,1,il_ntime))
     ELSE
        ll_isdepthdim = .TRUE.
        ALLOCATE(rla_modelvalue(il_nlon,il_nlat,il_ndepth,il_ntime))
     ENDIF
     ALLOCATE(rla_modeldepth(il_ndepth))
     IF (ALLOCATED(rla_juld_mod)) DEALLOCATE(rla_juld_mod)
     ALLOCATE(rla_juld_mod(il_ntime))
#if defined key_debug
     WRITE(0,*),'read_model_file --',TRIM(cl_modelFile),'--'
#endif
     rl_juld=rla_juld(il_jf)
     CALL read_model_file(cl_modelFile, &
          cl_modelVarname, &
          cl_depthvarname,       &
          rla_modelvalue,        &
          rla_modeldepth,        &
          il_nlon,               &
          il_nlat,               &
          il_ndepth,             &
          il_nbdim,              &
          il_ntime,              &
          ll_isdepthdim,         &
          rla_juld_mod)
     !PRINT *,'rla_juld_mod :: ',rla_juld_mod
     !PRINT *,'rla_juld :: ',rla_juld
     !
     !
     !------------------------------------------------------------------
     ! Calcul
     !
     ALLOCATE(rla_interpValue(il_nlevels, il_nprof))
#if defined key_debug
     WRITE(0,*),'interp_model_field ',TRIM(cl_modelFile)
#endif
        
     IF ( TRIM(cl_modelVarname) .EQ. 'sossheig' .OR. TRIM(cl_modelVarname) .EQ. 'ileadfra') THEN
        IF ( ld_mssh .and. ld_compute ) THEN
                rla_modelvalue(:,:,:,:) = rla_modelvalue(:,:,:,:) - rla_msshvalue(:,:,:,:) - rd_mssh_shift
                !------------------------------------------------------------------
                ! Test pour valeurs abherentes de la MDT (dues au fichier MDT)
                ! 
                WHERE (rla_modelvalue .LT. -10) rla_modelvalue = rl_fillValue
        ENDIF
        ! 
        !---------------------------------------------------------------------
        CALL interp_model_field_2d(rla_modelvalue, &
                          rla_interpValue, &
                          il_nlon,         &
                          il_nlat,         &
                          ila_xindex,      &
                          ila_yindex,      &
                          rla_LON,         &
                          rla_LAT,         &
                          il_nprof,        &
                          rla_poids,       &
                          rl_fillValue)
        IF ( ld_mssh .and. .not. ld_compute ) THEN
                ALLOCATE(rla_interpMSSHValue(il_nlevels, il_nprof))
                CALL interp_model_field_2d(rla_msshvalue, &
                                  rla_interpMSSHValue, &
                                  il_nlon,         &
                                  il_nlat,         &
                                  ila_xindex,      &
                                  ila_yindex,      &
                                  rla_LON,         &
                                  rla_LAT,         &
                                  il_nprof,        &
                                  rla_poids,       &
                                  rl_fillValue)
                !------------------------------------------------------------------
                ! Test pour valeurs abherentes de la MDT (dues au fichier MDT)
                ! 
                WHERE (rla_interpMSSHValue .LT. -10) rla_interpMSSHValue = rl_fillValue
        ENDIF
        
     ELSE
        CALL interp_model_field_3d(rla_modelvalue, &
                          rla_modeldepth,  &
                          rla_interpValue, &
                          il_nlon,         &
                          il_nlat,         &
                          il_ndepth,       &
                          il_ntime,        &
                          ila_xindex,      &
                          ila_yindex,      &
                          rla_depthvalue,  &
                          rla_LON,         &
                          rla_LAT,         &
                          il_nprof,        &
                          il_nlevels,      &
                          rla_poids,       &
                          rl_fillValue,    &
                          rla_juld_mod,    &
                          rla_juld)
     ENDIF
#if defined key_debug
     WRITE(0,*),'interp_model_field ok'
#endif
     ll_savevalue = .FALSE.
     DO il_jv=1, id_nvar
        IF (TRIM(cla_modelVarname(il_jv)) .EQ. cl_modelVarname) THEN
          ll_savevalue = .TRUE.
          rla_modelEquivValue(:,il_jc,il_jv,:) = rla_interpValue(:,:)
          IF ( ld_mssh .and. .not. ld_compute ) rla_modelEquivValuemssh(:,il_jc,il_jv,:)=rla_interpMSSHValue(:,:)
          !  forecast(numdeps,numfcsts,numvars,numobs)
        ENDIF
     ENDDO
     IF ( .NOT. ll_savevalue ) THEN
        WRITE(0,*),'Could not save interpolated value, no varname match'
        CALL flush(0)
     ENDIF
     il_jc = il_jc+1
     !
     !
     !------------------------------------------------------------------
     ! Deallocation memoire
     !
     DEALLOCATE(rla_modelvalue)
     DEALLOCATE(rla_interpValue)
     DEALLOCATE(rla_modeldepth)

  ENDDO
  !
  !
  !------------------------------------------------------------------
  ! Ecriture des nouveaux champs
  !
  CALL write_interp_field(cd_inputFile, &
       cd_outputVarname, &
       il_nprof, &
       id_nvar,  &
       id_ncast, &
       il_nlevels, &
       rla_modelEquivValue, &
       cla_dimname, &
       rl_fillValue)
  IF ( ld_mssh .and. .not. ld_compute ) THEN 
        WRITE(0,*) 'Write MSSH'
        CALL write_interp_field(cd_inputFile, &
                                cl_msshVarname, &
                                il_nprof, &
                                id_nvar,  &
                                id_ncast, &
                                il_nlevels, &
                                -rla_modelEquivValuemssh, &
                                cla_dimname, &
                                rl_fillValue)
        CALL MIOL_openw_file_NC(TRIM(cd_inputFile), &
                                il_file_id)
        WRITE(0,*) 'Write MSSH shift'
        CALL MIOL_write_attribute_NC(il_file_id,&
                                    'mssh',&
                                    'add_offset',&
                                    -rd_mssh_shift)
        CALL MIOL_close_file_NC(il_file_id)
  ENDIF
  IF (ALLOCATED(rla_poids))         DEALLOCATE(rla_poids)
  IF (ALLOCATED(rla_depthvalue))    DEALLOCATE(rla_depthvalue)
  IF (ALLOCATED(ila_xindex))        DEALLOCATE(ila_xindex)
  IF (ALLOCATED(ila_yindex))        DEALLOCATE(ila_yindex)
  IF (ALLOCATED(rla_msshvalue))     DEALLOCATE(rla_msshvalue)
  IF (ALLOCATED(rla_leadtimevalue)) DEALLOCATE(rla_leadtimevalue)
  IF (ALLOCATED(cla_modelVarname))  DEALLOCATE(cla_modelVarname)
  IF (ALLOCATED(rla_LON))           DEALLOCATE(rla_LON)
  IF (ALLOCATED(rla_LAT))           DEALLOCATE(rla_LAT)

 
ENDSUBROUTINE interpolate_3D_model_field
!
!
!!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!     
SUBROUTINE write_interp_field(cd_outputFile, &
     cd_outputVarname, &
     id_nprof, &
     id_nvar,  &
     id_ncast, &
     id_nlevels, &
     rda_modelEquivValue_4D, &
     cda_dimname, &
     rd_fillValue)
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
  INTEGER :: id_nprof,   &
             id_nlevels, &
             id_nvar,    &
             id_ncast
  REAL(KIND=4), DIMENSION(id_nlevels,id_ncast,id_nvar,id_nprof) :: rda_modelEquivValue_4D
  REAL(KIND=4), DIMENSION(id_nlevels,id_nvar,id_nprof)          :: rda_modelEquivValue_3D
  REAL(KIND=4) :: rd_fillValue
  !
  INTEGER :: il_ji, &
       il_status, &
       il_filid, &
       il_dimid, &
!       il_cparameterintlen, &
!       il_cparameterintid, &
!       il_lparameterintlen, &
!       il_lparameterintid, &
!       il_parameterintid, &
       il_offset,&
       il_variable_id
  CHARACTER(LEN=255) :: cl_resatt, &
       cl_FillValueatt,&
       cl_nameatt,&
       cl_nameValatt,&
       cl_tmp                       
  REAL(KIND=4), DIMENSION(4) :: rla_specialvalue
  REAL(KIND=4) :: rl_resvalue
!  CHARACTER(LEN=ig_cparameterint), DIMENSION(ig_lparameterint) :: cla_parameterint
!  CHARACTER(LEN=ig_cparameterint) :: cl_null
  INTEGER, DIMENSION(2) :: ila_dimids
  !
#if defined key_debug
  WRITE(0,*),' Write interp field'
#endif
  !
  cl_resatt = 'resolution'
  rl_resvalue = 0.001
  cl_FillValueatt = '_FillValue'
  cl_nameatt =  'long_name'
  cl_nameValatt =  'Model '//TRIM(cd_outputVarname)//' counterpart of obs. value'
  
  !il_cparameterintlen = ig_cparameterint
  !il_lparameterintlen = ig_lparameterint
  !WRITE (0,*) 'Dimensions L C :: ',il_lparameterintlen,il_cparameterintlen
  il_offset = 1
  !cl_null = " "
  !
  !------------------------------------------------------------------------
  ! Definition des valeurs spéciales
  !
  rla_specialvalue(1) = MINVAL(rda_modelEquivValue_4D)
  IF (rla_specialvalue(2) .GE. 99999.0) THEN
     rla_specialvalue(2) = -99999.0
  ENDIF
  rla_specialvalue(2) = MAXVAL(rda_modelEquivValue_4D, mask= rda_modelEquivValue_4D .LT. 99999.0)
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
  CALL hdlerr(NF90_OPEN(cd_outputFile, &
                        NF90_WRITE, &
                        il_filid),'Pb open file')
  !CALL hdlerr(NF90_REDEF(il_filid),'Pb redefine')
!  CALL hdlerr(NF90_INQ_DIMID(il_filid, &
!                            'C_PARAMETERINT', &
!                            il_cparameterintid),'Pb inquire DIMID')
!  ila_dimids(1) = il_cparameterintid
!  CALL hdlerr(NF90_INQ_DIMID(il_filid, &
!                            'L_PARAMETERINT', &
!                             il_lparameterintid),'Pb inquire DIMID')
!  ila_dimids(2) = il_lparameterintid
!#if defined key_debug
!  WRITE(0,*),'inquire dim ok',il_cparameterintid,il_lparameterintid
!  WRITE(0,*) 'File :: ',cd_outputFile 
!#endif
  !        
  !
  !------------------------------------------------------------------------
!  ! Renseignement de la variable PARAMETERINT
!  !
!  CALL hdlerr(NF90_INQ_VARID(il_filid, &
!                            'PARAMETERINT', &
!                            il_parameterintid),'Pb inquire PARAMETERINT')
!  CALL hdlerr(NF90_ENDDEF(il_filid),'Pb enddef')
!  CALL hdlerr(NF90_GET_VAR(il_filid, &
!                           il_parameterintid, &
!                           cla_parameterint),'Pb NF90_GET_VAR')
!  DO il_ji=1, il_lparameterintlen
!     IF (TRIM(cla_parameterint(il_ji)) .NE. cl_null) THEN
!        il_offset = il_offset + 1
!     ENDIF
!  ENDDO
!#if defined key_debug
!  print *,'Offset  :: ',il_offset
!#endif
!  cla_parameterint(il_offset) = TRIM(cd_outputVarname)
!  CALL hdlerr(NF90_PUT_VAR(il_filid, &
!                           il_parameterintid, &
!                           cla_parameterint),'Pb NF90_PUT_VAR')
!  !        
!  !
!  !------------------------------------------------------------------------
  ! Ecriture du champs interpole
  !

#if defined key_debug
  print *,'Write field '
  WRITE(0,*) 'Output varname ::',TRIM(cd_outputVarname)
  !        WRITE(0,*) 'Value ::',rda_modelEquivValue_4D
#endif
   il_status = (NF90_INQ_VARID(il_filid, &
                TRIM(cd_outputVarname), &
                il_variable_id))
   IF (il_status .EQ. NF90_NOERR) THEN
#if defined key_debug
        WRITE(0,*) 'Variable existante  :: ',TRIM(cd_outputVarname)
#endif
   ELSE
!#if defined key_debug
!        WRITE(0,*) 'Variable shape  ::',TRIM(cd_outputVarname),SHAPE(rda_modelEquivValue_4D)
!#endif
      IF (id_ncast .GT. 1) THEN !case forecast, persistence
        CALL MIOL_write_field_NC (il_filid, &
             cd_outputVarname, &
             'ZFVP', &
             rda_modelEquivValue_4D)!, &
      ELSE IF (id_ncast .EQ. 1) THEN !case best_estimate
        rda_modelEquivValue_3D(1:id_nlevels,1:id_nvar,1:id_nprof) = rda_modelEquivValue_4D(1:id_nlevels,id_ncast,1:id_nvar,1:id_nprof)
        CALL MIOL_write_field_NC (il_filid, &
             cd_outputVarname, &
             'ZVP', &
             rda_modelEquivValue_3D)
      ENDIF
      !------------------------------------------------------------------------
      ! Ecriture attribut 
      !
      CALL MIOL_write_attribute_NC (il_filid, &
           cd_outputVarname, &
           cl_resatt, &
           rl_resvalue)
      CALL MIOL_write_attribute_NC (il_filid, &
           cd_outputVarname, &
           cl_FillValueatt, &
           rd_fillvalue)
      CALL MIOL_write_attribute_NC (il_filid, &
           cd_outputVarname, &
           cl_nameatt, &
           cl_nameValatt)
 
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
SUBROUTINE read_parameterint_dim(cd_outputFile)
  USE netcdf
  USE MCAL
  USE MIOL
  USE MIOL_util
  USE table_CLASS4
  USE MFT_error
  IMPLICIT NONE
  !
  CHARACTER(LEN=255) :: cd_outputFile
  INTEGER :: il_ji, &
             il_status, &
             il_filid,&
             il_cparameterintid,&
             il_cparameterintlen,&
             il_lparameterintid,&
             il_lparameterintlen
       
  !
  !
  !------------------------------------------------------------------------
  ! Creation des nouvelles dimensions
  !
#if defined key_debug
  WRITE(0,*) ' read_parameterint'
  WRITE (0,*) 'OPEN file : ',cd_outputFile
#endif
  il_status = NF90_OPEN(cd_outputFile, &
       NF90_WRITE, &
       il_filid)
  !** Inquire C_PARAMETERINT 
  il_status = NF90_INQ_DIMID(il_filid, &
                             'C_PARAMETERINT', &
                              il_cparameterintid)
  IF (il_status .NE. NF90_NOERR) THEN
     ig_lparameterint=0
  ELSE
     CALL hdlerr(NF90_INQUIRE_DIMENSION(il_filid, &
                                        il_cparameterintid, &
                                        len=il_cparameterintlen),'Pb Inquire Dimension C_PARAMETERINT')
     ig_cparameterint=il_cparameterintlen
  ENDIF
  !** Inquire L_PARAMETERINT 
  il_status = NF90_INQ_DIMID(il_filid, &
                             'L_PARAMETERINT_old', &
                             il_lparameterintid)
  IF (il_status .NE. NF90_NOERR) THEN
     ig_lparameterint=0
  ELSE
     CALL hdlerr(NF90_INQUIRE_DIMENSION(il_filid, &
                                        il_lparameterintid, &
                                        len=il_lparameterintlen),'Pb Inquire Dimension L_PARAMETERINT')
     ig_lparameterint=il_lparameterintlen
  ENDIF

ENDSUBROUTINE read_parameterint_dim

!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE write_parameterint(cd_outputFile)
  !
  USE netcdf
  USE MCAL
  USE MIOL
  USE MIOL_util 
  USE table_CLASS4
  USE MFT_error
  IMPLICIT NONE
  !
  CHARACTER(LEN=255) :: cd_outputFile
  !
  INTEGER :: il_ji, &
             il_status, &
             il_filid, &
             il_dimid, &
             il_cparameterintlen, &
             il_cparameterintid, &
             il_lparameterintlen, &
             il_lparameterintid, &
             il_parameterintid,il_parameterintid2,il_len,il_id
  CHARACTER(LEN=255) :: cl_resatt, &
                        cl_tmp
  CHARACTER(LEN=12), DIMENSION(20) :: cla_parameterint
  CHARACTER(LEN=ig_cparameterint),DIMENSION(ig_lparameterint) :: cla_parameterint_test
  CHARACTER(LEN=ig_cparameterint),DIMENSION(:),ALLOCATABLE    :: cla_parameterint_new
  CHARACTER(LEN=12) :: cl_null
  INTEGER, DIMENSION(2) :: ila_dimids
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
  IF (il_status .NE. NF90_NOERR) THEN
#if defined key_debug
     WRITE(0,*) ' write_parameterint : problem encountered '
#endif
     CALL flush(0)
     STOP 
  ENDIF
  il_status = NF90_INQ_DIMID(il_filid, &
                             'C_PARAMETERINT', &
                             il_cparameterintid)

  IF (il_status .NE. NF90_NOERR) THEN
     il_status = NF90_DEF_DIM(il_filid, &
                              'C_PARAMETERINT', &
                              il_cparameterintlen, &
                              il_cparameterintid)
                              ig_cparameterint=il_cparameterintlen
!  ELSE
!       il_status = NF90_DEF_DIM(il_filid, &
!                              'C_PARAMETERINT', &
!                              ig_cparameterint, &
!                              il_cparameterintid)
!     WRITE(0,*) 'Def dim C : ',ig_cparameterint
  ENDIF
  ila_dimids(1) = il_cparameterintid
  il_status = NF90_INQ_DIMID(il_filid, &
                             'L_PARAMETERINT_old', &
                             il_lparameterintid)
  IF (il_status .NE. NF90_NOERR) THEN
     il_status = NF90_DEF_DIM(il_filid, &
                              'L_PARAMETERINT', &
                              il_lparameterintlen, &
                              il_lparameterintid)
      ig_lparameterint=il_lparameterintlen
      ila_dimids(2) = il_lparameterintid
  ELSE
     il_len=ig_lparameterint+1
     CALL  hdlerr(NF90_DEF_DIM(il_filid, &
                               'L_PARAMETERINT', &
                               il_len, &
                               il_id),'Pb NF90_DEF_DIM')
     ila_dimids(2) = il_id
     ig_lparameterint=il_len
  !   CALL hdlerr(NF90_RENAME_DIM(il_filid,il_id,'L_PARAMETERINT_TEST4'),'NF90_RENAME_DIM error')
  ENDIF
  !        
  !
  !------------------------------------------------------------------------
  ! Renseignement de la variable PARAMETERINT
  !
  il_status = NF90_INQ_VARID(il_filid, &
       'PARAMETERINT_old', &
       il_parameterintid)
  IF (il_status .NE. NF90_NOERR) THEN
       CALL  hdlerr(NF90_DEF_VAR(il_filid, &
                    'PARAMETERINT', &
                    NF90_CHAR, &
                    ila_dimids, &
                    il_parameterintid),'Pb NF90_DEF_VAR')
       cla_parameterint(1:il_lparameterintlen) = cl_null
       CALL  hdlerr(NF90_ENDDEF(il_filid),'Pb ENDDEF')
       CALL  hdlerr(NF90_PUT_VAR(il_filid, &
                                 il_parameterintid, &
                                 cla_parameterint),'Pb put var')
       CALL  hdlerr(NF90_CLOSE(il_filid),'Pb NF90_CLOSE')
  ELSE
       CALL  hdlerr(NF90_DEF_VAR(il_filid, &
                    'PARAMETERINT', &
                    NF90_CHAR, &
                    ila_dimids, &
                    il_parameterintid2),'Pb NF90_DEF_VAR')
       CALL  hdlerr(NF90_ENDDEF(il_filid),'Pb ENDDEF')
#if defined key_debug
       PRINT *,'Lecture Parameterint'
       WRITE(0,*) ' Taille cla_parameterint_test :: ',shape(cla_parameterint_test)
#endif
       CALL hdlerr(NF90_GET_VAR(il_filid, &
                                il_parameterintid, &
                                cla_parameterint_test),'Pb NF90_GET_VAR')
#if defined key_debug
       PRINT *,'Lecture Parameterint'
       WRITE (0,*) 'pas d erreurs  read ok:: ',cla_parameterint_test
#endif
       !* TODO : rajouter le comptage du nombre de champs vides
       !* On rajoute une valeur au parameterint
       ALLOCATE(cla_parameterint_new(ig_lparameterint))
       cla_parameterint_new(1:ig_lparameterint-1)=cla_parameterint_test(:)
       cla_parameterint_new(ig_lparameterint)=cl_null
!#if defined key_debug
!       WRITE (0,*) 'New parameterint :: ',cla_parameterint_new(:)
!       WRITE(0,*) ' Taille cla_parameterint_new :: ',shape(cla_parameterint_new)
!#endif
       CALL hdlerr(NF90_PUT_VAR(il_filid, &
                                il_parameterintid2, &
                                cla_parameterint_new),'Pb Put_var')
       CALL hdlerr(NF90_CLOSE(il_filid),'Pb close file')
  ENDIF
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
     cda_isvarname,    &
     id_isnvar,        &
     cl_isvarname,     &
     id_nbdim,         &
     id_nlon,          &
     id_nlat,          &
     id_ndepth,        &
     id_ntime,         &
     cd_depthvarname)  
  !
  USE netcdf
  USE MCAL
  USE MIOL 
  USE MIOL_util
  IMPLICIT NONE
  !
  !
  CHARACTER(LEN=255) :: cd_file, &
       cl_isvarname, &
       cd_depthvarname
  INTEGER :: id_nlon, &
       id_isnvar,  &
       id_nlat,    &
       id_ndepth,  &
       id_ntime,   &
       id_nbdim
  !
  INTEGER :: il_file_id, &
       il_nbvar, &
       il_ji,    &
       il_jj
  CHARACTER(LEN=255), DIMENSION(id_isnvar)  :: cda_isvarname
  CHARACTER(LEN=255), DIMENSION(:), POINTER :: clpa_varname, &
       clpa_dimname
  INTEGER, DIMENSION(:), POINTER :: ilpa_dimlen, &
       ilpa_nbdim
  LOGICAL :: ll_isvarexist
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
  CALL MIOL_openr_file_NC(TRIM(cd_file), &
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
  !
  !
  !------------------------------------------------------------------------
  ! Recherche des dimensions
  !
  DO il_ji=1, id_nbdim
     SELECT CASE (TRIM(clpa_dimname(il_ji)))

     CASE ('deptht', 'depthu', 'depthv', 'depth')
        id_ndepth = ilpa_dimlen(il_ji)

     CASE ('x', 'LONGITUDE', 'longitude')
        id_nlon = ilpa_dimlen(il_ji)

     CASE ('y', 'LATITUDE' , 'latitude' )
        id_nlat = ilpa_dimlen(il_ji)

     CASE ('time_counter')
        id_ntime=ilpa_dimlen(il_ji)

     ENDSELECT
  ENDDO
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

     ENDSELECT
     DO il_jj=1, id_isnvar
        IF (TRIM(clpa_varname(il_ji)) .EQ. TRIM(cda_isvarname(il_jj))) THEN
           ll_isvarexist = .TRUE.
           cl_isvarname  = clpa_varname(il_ji)
        ENDIF
     ENDDO
  ENDDO
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
!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE read_model_file(cd_file, &
     cd_fieldname, &
     cd_depthname, &
     rda_fieldvalue, &
     rda_depthvalue, &
     id_nlon, &
     id_nlat, &
     id_ndepth, &
     id_nbdim, &
     id_time, &
     ld_isdepthdim, &
     rda_juld)
  !
  USE netcdf
  USE MCAL
  USE MCAL_SU_DATE
  USE MFT_error
  USE MIOL 
  IMPLICIT NONE
  !
  CHARACTER(LEN=255)            :: cd_file, &
                                   cd_fieldname, &
                                   cd_depthname
   CHARACTER(LEN=255)           :: cl_file_tmp, &
                                   cl_attname,&
                                   cl_value
  INTEGER(KIND=4)              :: id_nlon, &
                                   id_nlat, &
                                   id_ndepth, &
                                   id_nbdim,&
                                   id_time
  INTEGER (KIND=4)              :: il_varid, &
                                   il_type, &
                                   il_status, &
                                   il_jk
  REAL(KIND=4)   , DIMENSION(id_nlon,id_nlat,id_ndepth,id_time)  :: rda_fieldvalue
  REAL(KIND=4)   , DIMENSION(id_ndepth)                     :: rda_depthvalue
  REAL(KIND=4)   , DIMENSION(id_time)                       :: rda_juld
  !
  INTEGER                                        :: il_file_id,il_taille
  INTEGER(KIND=4),DIMENSION(1)                   :: ila_timelen
  INTEGER(KIND=4),DIMENSION(2)                   :: ila_nbdim2D
  INTEGER(KIND=4),DIMENSION(3)                   :: ila_nbdim3D
  INTEGER(KIND=4),DIMENSION(4)                   :: ila_nbdim4D
  REAL(KIND=4)   , DIMENSION(:)      , POINTER   :: rlpa_value_1D,rlpa_time_counter
  REAL(KIND=4)   , DIMENSION(:,:)    , POINTER   :: rlpa_value_2D
  REAL(KIND=4)   , DIMENSION(:,:,:)  , POINTER   :: rlpa_value_3D
  REAL(KIND=4)   , DIMENSION(:,:,:,:), POINTER   :: rlpa_value_4D
  INTEGER(KIND=2), DIMENSION(:,:)    , POINTER   :: ilpa_value_2D
  INTEGER(KIND=2), DIMENSION(:,:,:)  , POINTER   :: ilpa_value_3D
  INTEGER(KIND=2), DIMENSION(:,:,:,:), POINTER   :: ilpa_value_4D 
  CHARACTER(LEN=48)                              :: cl_tc_su_date_form_cal_BIO
  DATA cl_tc_su_date_form_cal_BIO /'(A1,I4.4,A1,A3,A1,I2.2,A1,I2.2,A1,I2.2,A1,I2.2)'/
  CHARACTER(LEN=44)                              :: cl_tc_su_date_form_cal_PSY3
  DATA cl_tc_su_date_form_cal_PSY3 /'(I4.4,A1,A3,A1,I2.2,A1,I2.2,A1,I2.2,A1,I2.2)'/
  CHARACTER(LEN=44)                              :: cl_tc_su_date_form_cal
  DATA cl_tc_su_date_form_cal /'(I2.2,A1,A3,A1,I4.4,A1,I2.2,A1,I2.2,A1,I2.2)'/

  CHARACTER(LEN=3)            :: cl_mois    ! nom du mois courant
  CHARACTER                   :: av_sep     ! caractere separateur dans date
  ! calendaire (lu mais ignore)
  INTEGER(KIND=4)             :: ev_annee   ! date calendaire decodees
  INTEGER(KIND=2)             :: ev_jour    ! heure/minute/seconde
  INTEGER(KIND=2)             :: ev_heure   ! en entier
  INTEGER(KIND=2)             :: ev_minute
  INTEGER(KIND=2)             :: ev_seconde
  INTEGER(KIND=4)             :: il_indice_min,il_var
  CHARACTER(LEN=27)           :: cl_date
  REAL(KIND=8)                :: rl_sec50,rl_offset
  REAL(KIND=4)                :: rl_diff_min,rl_diff
  LOGICAL                                        :: ld_isdepthdim
  !
  !
  !---------------------------------------------------------------------
  ! Lecture de la variable a traiter
  !
  CALL MIOL_openr_file_NC(TRIM(cd_file), &
       il_file_id)
  !
  il_status = fi_ncError(NF90_INQ_VARID(il_file_id,cd_fieldname,il_varid),'NF90_INQ_VARID')
  il_status = fi_ncError(NF90_INQUIRE_VARIABLE(il_file_id,il_varid,cd_fieldname,il_type),'NF90_INQ_VARIABLE')
#if defined key_debug
  WRITE(0,*) 'Read model file'
#endif
  !! Read time_counter
  CALL MIOL_read_field_NC(il_file_id, &
                          'time_counter',&
                           rlpa_time_counter,&
                           ila_timelen)
  
  ! lecture de la date de reference et conversion en jour julien
  cl_attname='time_origin'
  CALL MIOL_read_attribute_NC(il_file_id,&
                              'time_counter',&
                              TRIM(cl_attname),&
                              cl_value)
  il_taille=len(TRIM(cl_value))
  IF ( il_taille == 21 ) THEN
     WRITE (0,*) 'BIO'
     READ(cl_value,fmt=cl_tc_su_date_form_cal_BIO)&
     & av_sep,ev_annee,av_sep,cl_mois,av_sep,ev_jour,av_sep,&
     & ev_heure,av_sep,ev_minute,av_sep,ev_seconde
  ELSE
     READ(cl_value,fmt=cl_tc_su_date_form_cal_PSY3)&
     & ev_annee,av_sep,cl_mois,av_sep,ev_jour,av_sep,&
     & ev_heure,av_sep,ev_minute,av_sep,ev_seconde
  ENDIF
#if defined key_debug
  WRITE(0,*) ev_jour,'-',cl_mois,'-',ev_annee,' ',&
           & ev_heure,':',ev_minute,':',ev_seconde
#endif
  WRITE(cl_date,fmt=cl_tc_su_date_form_cal)ev_jour,'-',cl_mois,'-',ev_annee,'',&
           & ev_heure,':',ev_minute,':',ev_seconde
           ! transformation en date julien CNES (secondes)
  CALL SU_DATE_CAL_STU50(cl_date,rl_sec50,il_status)
  rda_juld(:)=(rlpa_time_counter(:)+rl_sec50)/86400
  IF (id_nbdim .EQ. 3) THEN
     IF (ld_isdepthdim) THEN
        SELECT CASE (il_type)
        CASE (NF90_FLOAT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                rlpa_value_3D)
        CASE (NF90_SHORT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                ilpa_value_3D,&
                ila_nbdim3D,&
                rlpa_value_3D)
           DEALLOCATE(ilpa_value_3D)
        CASE default
           PRINT *,'Type non reconnu'
        ENDSELECT
        rda_fieldvalue(1:id_nlon,1:id_nlat,1:id_ndepth,id_time) = &
             rlpa_value_3D(1:id_nlon,1:id_nlat,1:id_ndepth)

        DEALLOCATE(rlpa_value_3D)
     ELSE

        SELECT CASE (il_type)
        CASE (NF90_FLOAT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                rlpa_value_2D)
        CASE (NF90_SHORT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                ilpa_value_2D,&
                ila_nbdim2D,&
                rlpa_value_2D)
           DEALLOCATE(ilpa_value_2D)
        CASE default
           PRINT *,'Type non reconnu'
        ENDSELECT
        rda_fieldvalue(1:id_nlon,1:id_nlat,1,id_time) = &
             rlpa_value_2D(1:id_nlon,1:id_nlat)

        DEALLOCATE(rlpa_value_2D)
     ENDIF
  ELSE IF (id_nbdim .EQ. 4) THEN
     IF (ld_isdepthdim) THEN
       SELECT CASE (il_type)
       CASE (NF90_FLOAT)
          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               rlpa_value_4D)

       CASE (NF90_SHORT)

          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               ilpa_value_4D,&
               ila_nbdim4D,&
               rlpa_value_4D)
          DEALLOCATE(ilpa_value_4D)
       CASE default
          PRINT *,'Type non reconnu'
       ENDSELECT
       rda_fieldvalue(1:id_nlon,1:id_nlat,1:id_ndepth,:) = &
            rlpa_value_4D(1:id_nlon,1:id_nlat,1:id_ndepth,:)
       DEALLOCATE(rlpa_value_4D)
     ELSE
       SELECT CASE (il_type)
       CASE (NF90_FLOAT)

          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               rlpa_value_3D)

       CASE (NF90_SHORT)

          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               ilpa_value_3D,&
               ila_nbdim3D,&
               rlpa_value_3D)
          DEALLOCATE(ilpa_value_3D)
       CASE default
          PRINT *,'Type non reconnu'
       ENDSELECT



       rda_fieldvalue(1:id_nlon,1:id_nlat,1,:) = &
            rlpa_value_3D(1:id_nlon,1:id_nlat,:)

       DEALLOCATE(rlpa_value_3D)
     ENDIF
  ENDIF
  !
  !

  !---------------------------------------------------------------------
  ! Lecture de la variable de profondeur
  !
  CALL MIOL_read_field_NC(il_file_id, &
       cd_depthname, &
       rlpa_value_1D)
  rda_depthvalue(1:id_ndepth) = &
       rlpa_value_1D(1:id_ndepth)
  DEALLOCATE(rlpa_value_1D)
  !
  !
  !---------------------------------------------------------------------
  ! Fermeture du fichier
  !
  CALL MIOL_close_file_NC(il_file_id)
  !
  !
ENDSUBROUTINE read_model_file
!
!
!
!!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE read_model_file_2(cd_file, &
     cd_fieldname, &
     cd_depthname, &
     rda_fieldvalue, &
     rda_depthvalue, &
     id_nlon, &
     id_nlat, &
     id_ndepth, &
     id_nbdim,&
     ld_isdepthdim)
  !
  USE netcdf
  USE MCAL
  USE MFT_error
  USE MIOL
  IMPLICIT NONE
  !
  CHARACTER(LEN=255) :: cd_file, &
       cl_file_tmp, &
       cd_fieldname, &
       cd_depthname
  INTEGER :: id_nlon, &
       id_nlat, &
       id_ndepth, &
       id_nbdim, &
       il_varid, &
       il_type, &
       il_status, &
       il_jk
  REAL(KIND=4)   , DIMENSION(id_nlon,id_nlat,id_ndepth,1)    :: rda_fieldvalue
  REAL(KIND=4)   , DIMENSION(id_ndepth) :: rda_depthvalue
  !
  INTEGER                                        :: il_file_id
  INTEGER(KIND=4),DIMENSION(2)                   :: ila_nbdim2D
  INTEGER(KIND=4),DIMENSION(3)                   :: ila_nbdim3D
  INTEGER(KIND=4),DIMENSION(4)                   :: ila_nbdim4D
  REAL(KIND=4)   , DIMENSION(:)      , POINTER   :: rlpa_value_1D
  REAL(KIND=4)   , DIMENSION(:,:)    , POINTER   :: rlpa_value_2D
  REAL(KIND=4)   , DIMENSION(:,:,:)  , POINTER   :: rlpa_value_3D
  REAL(KIND=4)   , DIMENSION(:,:,:,:), POINTER   :: rlpa_value_4D
  INTEGER(KIND=2), DIMENSION(:,:)    , POINTER   :: ilpa_value_2D
  INTEGER(KIND=2), DIMENSION(:,:,:)  , POINTER   :: ilpa_value_3D
  INTEGER(KIND=2), DIMENSION(:,:,:,:), POINTER   :: ilpa_value_4D
  LOGICAL                                        :: ld_isdepthdim
  !
  !
  !---------------------------------------------------------------------
 !
  !---------------------------------------------------------------------
  ! Lecture de la variable a traiter
  !
  CALL MIOL_openr_file_NC(TRIM(cd_file), &
       il_file_id)

  !
  il_status = fi_ncError(NF90_INQ_VARID(il_file_id,cd_fieldname,il_varid),'NF90_INQ_VARID')
  il_status = fi_ncError(NF90_INQUIRE_VARIABLE(il_file_id,il_varid,cd_fieldname,il_type),'NF90_INQ_VARIABLE')
#if defined key_debug
  WRITE(0,*) 'Read model time no time'
#endif

  IF (id_nbdim .EQ. 3) THEN
     IF (ld_isdepthdim) THEN
        SELECT CASE (il_type)
        CASE (NF90_FLOAT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                rlpa_value_3D)
        CASE (NF90_SHORT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                ilpa_value_3D,&
                ila_nbdim3D,&
                rlpa_value_3D)
           DEALLOCATE(ilpa_value_3D)
        CASE default
           PRINT *,'Type non reconnu'
        ENDSELECT
        rda_fieldvalue(1:id_nlon,1:id_nlat,1:id_ndepth,1) = &
             rlpa_value_3D(1:id_nlon,1:id_nlat,1:id_ndepth)

        DEALLOCATE(rlpa_value_3D)
     ELSE

        SELECT CASE (il_type)
        CASE (NF90_FLOAT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                rlpa_value_2D)
        CASE (NF90_SHORT)
           CALL MIOL_read_field_NC(il_file_id, &
                cd_fieldname, &
                ilpa_value_2D,&
                ila_nbdim2D,&
                rlpa_value_2D)
           DEALLOCATE(ilpa_value_2D)
        CASE default
           PRINT *,'Type non reconnu'
        ENDSELECT
        rda_fieldvalue(1:id_nlon,1:id_nlat,1,1) = &
             rlpa_value_2D(1:id_nlon,1:id_nlat)

        DEALLOCATE(rlpa_value_2D)
     ENDIF
  ELSE IF (id_nbdim .EQ. 4) THEN
     IF (ld_isdepthdim) THEN
       SELECT CASE (il_type)
       CASE (NF90_FLOAT)
          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               rlpa_value_4D)

       CASE (NF90_SHORT)

          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               ilpa_value_4D,&
               ila_nbdim4D,&
               rlpa_value_4D)
          DEALLOCATE(ilpa_value_4D)
       CASE default
          PRINT *,'Type non reconnu'
       ENDSELECT
       rda_fieldvalue(1:id_nlon,1:id_nlat,1:id_ndepth,1) = &
            rlpa_value_4D(1:id_nlon,1:id_nlat,1:id_ndepth,1)
       DEALLOCATE(rlpa_value_4D)
     ELSE
       SELECT CASE (il_type)
       CASE (NF90_FLOAT)

          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               rlpa_value_3D)

       CASE (NF90_SHORT)

          CALL MIOL_read_field_NC(il_file_id, &
               cd_fieldname, &
               ilpa_value_3D,&
               ila_nbdim3D,&
               rlpa_value_3D)
          DEALLOCATE(ilpa_value_3D)
       CASE default
          PRINT *,'Type non reconnu'
       ENDSELECT



       rda_fieldvalue(1:id_nlon,1:id_nlat,1,1) = &
            rlpa_value_3D(1:id_nlon,1:id_nlat,1)
       DEALLOCATE(rlpa_value_3D)
     ENDIF
  ENDIF
  !
  !

  !---------------------------------------------------------------------
  ! Lecture de la variable de profondeur
  !
  CALL MIOL_read_field_NC(il_file_id, &
       cd_depthname, &
       rlpa_value_1D)
  rda_depthvalue(1:id_ndepth) = &
       rlpa_value_1D(1:id_ndepth)
  DEALLOCATE(rlpa_value_1D)
  !
  !
  !---------------------------------------------------------------------
  ! Fermeture du fichier
  !
  CALL MIOL_close_file_NC(il_file_id)
  !
  !
ENDSUBROUTINE read_model_file_2
!
!
!
!!******************************************************************************
!******************************************************************************
!******************************************************************************
!





SUBROUTINE interp_model_field_2d(rda_modelvalue, &
     rda_modelvalue_inter, &
     id_nlon, &
     id_nlat, &
     ida_xindex, &
     ida_yindex, &
     rda_LON,&
     rda_LAT,&
     id_nprof, &
     rda_poids,&
     rd_emptyvalue)
  !
  USE MCAL
  USE table_CLASS4
  IMPLICIT NONE
  !
  INTEGER,INTENT(IN)         :: id_nlon, &
       id_nlat, &
       id_nprof
  REAL(KIND=4), DIMENSION(id_nlon,id_nlat,1,1) :: rda_modelvalue
  REAL(KIND=4), DIMENSION(id_nprof) :: rda_modelvalue_inter
  REAL(KIND=8), DIMENSION(id_nprof),INTENT(IN) :: rda_LON,rda_LAT
  CHARACTER(LEN=255)                    :: cl_file,cl_ficlog
  INTEGER, DIMENSION(4,id_nprof) :: ida_xindex, &
       ida_yindex
  REAL(KIND=4),DIMENSION(4,id_nprof) :: rda_poids
  REAL(KIND=4),INTENT(IN)            :: rd_emptyvalue
  REAL(KIND=8)                       :: rl_lon,rl_lat,rl_IDboite
  !
  INTEGER :: il_ji, &
       il_jj, &
       il_jk, &
       il_den, &
       il_den2, &
       il_poids,il_status,il_ind,il_n,il_n2,il_jp,il_nbx,il_nby
  REAL(KIND=4) :: rl_modelvalue_tmp
  REAL(KIND=4) :: rl_tmp, &
       rl_emptyvalue
  INTEGER, PARAMETER :: NaN = Z"FFC00000"
  LOGICAL            :: ll_exist_ficlog
  !

  rl_emptyvalue = 99999
  !------------------------------------------------------------------------
  ! Boucle pour le traitement de tous les fichiers observation
  DO il_ji=1, id_nprof
     rl_lon=rda_LON(il_ji)
     rl_lat=rda_LAT(il_ji)  
     !
     !------------------------------------------------------------------
     ! Interpolation spatiale (2D) par une moyenne des 4 plus proches voisins ponderation par IDW
     rl_modelvalue_tmp = 0.0
     !
     il_nbx=COUNT(ida_xindex(:,il_ji) .EQ. 9999)
     il_nby=COUNT(ida_yindex(:,il_ji) .EQ. 9999)
     IF (il_nbx .NE. 4 .OR. il_nby .NE. 4) THEN  
        !
           il_den =  0
           il_den2 = 0
           il_poids= 0

           DO il_jp = 1, 4
              IF ( ida_xindex(il_jp,il_ji) .NE. 9999 .AND. ida_yindex(il_jp,il_ji) .NE. 9999) THEN
                 IF (rda_modelvalue(ida_xindex(il_jp,il_ji),ida_yindex(il_jp,il_ji),1,1) &
                      .LT. 1000.0.AND. rda_modelvalue(ida_xindex(il_jp,il_ji),ida_yindex(il_jp,il_ji),1,1).NE.0 &
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
              ! Test pour savoir si la valeur est une fillValue ou pas
              IF ( ida_xindex(il_jk,il_ji) .NE. 9999 .AND. ida_yindex(il_jk,il_ji) .NE. 9999) THEN
                 IF (rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),1,1) &
                      .LT. 1000.0 .AND. rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),1,1).NE.0) THEN

                    IF (il_den.EQ.il_poids) THEN              
                       !** 1er cas le nombre de poids valides correspond au nombre de valeurs valides
                       rl_modelvalue_tmp = rl_modelvalue_tmp+&
                            rda_poids(il_jk,il_ji)*rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),1,1)
                    ELSE
                       rl_modelvalue_tmp = rl_modelvalue_tmp + &
                            rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),1,1)
                       il_den2 = il_den2 + 1
                    ENDIF
                 ENDIF
              ENDIF
           ENDDO

           IF (il_den.NE.il_poids.AND.il_den2 .NE. 0) THEN
              rl_modelvalue_tmp = rl_modelvalue_tmp/il_den2
           ENDIF
     ENDIF

     !** Gestion du cas ou les fichiers sont abherents        
     IF ( rl_modelvalue_tmp.ge.9999) rl_modelvalue_tmp=rl_emptyvalue

     rda_modelvalue_inter(il_ji) = rl_modelvalue_tmp
#if defined key_debug
     WRITE(0,*),'Valeurs interpolées :: ',rda_modelvalue_inter(il_ji) 
     WRITE(0,*),'-----------------------------------------------------'
#endif
     !
  ENDDO !il_ji

  !
  !
ENDSUBROUTINE interp_model_field_2d

!
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE interp_model_field_3d(rda_modelvalue, &
     rda_modeldepth, &
     rda_modelvalue_inter, &
     id_nlon, &
     id_nlat, &
     id_ndepth, &
     id_ntime,  &
     ida_xindex, &
     ida_yindex, &
     rda_codepthvalue, &
     rda_LON,&
     rda_LAT,&
     id_nprof, &
     id_nlevels, &
     rda_poids,&
     rd_emptyvalue,&
     rda_juldmod,&
     rda_juld)
  !
  USE MCAL
  USE table_CLASS4
  IMPLICIT NONE
  !
  INTEGER,INTENT(IN)         :: id_nlon, &
       id_nlat, &
       id_ndepth, &
       id_nprof, &
       id_nlevels,&
       id_ntime
  REAL(KIND=4), DIMENSION(id_ntime)                    :: rda_juldmod
  REAL(KIND=4), DIMENSION(id_nprof)                    :: rda_juld
  REAL(KIND=4), DIMENSION(id_nlon,id_nlat,id_ndepth,id_ntime) :: rda_modelvalue
  REAL(KIND=4), DIMENSION(id_ndepth) :: rda_modeldepth
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof) :: rda_modelvalue_inter
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof) :: rda_codepthvalue
  REAL(KIND=8), DIMENSION(id_nprof),INTENT(IN) :: rda_LON,rda_LAT
  CHARACTER(LEN=255)                    :: cl_file,cl_ficlog
  INTEGER, DIMENSION(4,id_nprof) :: ida_xindex, &
       ida_yindex
  REAL(KIND=4),DIMENSION(4,id_nprof) :: rda_poids
  REAL(KIND=4),INTENT(IN)            :: rd_emptyvalue
  REAL(KIND=8)                       :: rl_lon,rl_lat,rl_IDboite
  REAL(KIND=4)                       :: rl_juld,rl_diff,rl_diff_min
  !
  INTEGER :: il_ji, &
       il_jj, &
       il_jk, &
       il_den, &
       il_den2, &
       il_poids,il_status,il_ind,il_n,il_n2,il_jp,il_nbx,il_nby,il_indice_min,il_var
  REAL(KIND=4),DIMENSION(id_ndepth)  :: rla_modelvalue_tmp
  REAL(KIND=4), DIMENSION(:),ALLOCATABLE ::rla_modelvalue_tmp2,rla_modeldepth2,rla_codepth_tmp2,rla_modeldepth_inter2
  REAL(KIND=4),DIMENSION(id_nlevels) :: rla_codepth_tmp, &
        rla_modeldepth_inter
  REAL(KIND=4) :: rl_tmp, &
       rl_emptyvalue
  INTEGER, PARAMETER :: NaN = Z"FFC00000"
  LOGICAL            :: ll_exist_ficlog
  !

  rl_emptyvalue = 99999
  !------------------------------------------------------------------------
  ! Boucle pour le traitement de tous les fichiers observation
  DO il_ji=1, id_nprof
#if defined key_debug
     WRITE(0,*) 'Profil n° ',il_ji
#endif
     rl_lon=rda_LON(il_ji)
     rl_lat=rda_LAT(il_ji)  
     rl_juld=rda_juld(il_ji)
     IF ( size(rda_juldmod(:)) == 1 ) THEN 
        il_indice_min=1
     ELSE
        ! Recherche de l'indice le plus proche
        rda_juldmod(:)=ABS(rda_juldmod(:)-(aint(rda_juldmod(:))))
        rl_juld=ABS(rl_juld-aint(rl_juld))
        rl_diff_min=ABS((rda_juldmod(1)-rl_juld))
        il_indice_min=1
        DO il_var=2,size(rda_juldmod(:))
          rl_diff=rda_juldmod(il_var)-rl_juld
          IF (ABS(rl_diff) < rl_diff_min) THEN
             rl_diff_min=ABS(rl_diff)
             il_indice_min=il_var
          ENDIF
        ENDDO
!#if defined key_debug
!       WRITE(0,*) 'Indice MIN : ',il_indice_min,rda_juldmod(il_indice_min)
!       WRITE(0,*) 'Juld  : ',rl_juld
!       WRITE(0,*) 'rda_juldmod ::',rda_juldmod
!#endif
     ENDIF
     !
     !------------------------------------------------------------------
     ! Interpolation spatiale (2D) par une moyenne des 4 plus proches voisins ponderation par IDW
     rla_modelvalue_tmp(1:id_ndepth) = 0.0
     !
     il_nbx=COUNT(ida_xindex(:,il_ji) .EQ. 9999)
     il_nby=COUNT(ida_yindex(:,il_ji) .EQ. 9999)
     IF (il_nbx .NE. 4 .OR. il_nby .NE. 4) THEN  
        !        IF ((MAXVAL(ida_xindex(:,il_ji)) .NE. 9999) .OR. &
        !             (MAXVAL(ida_yindex(:,il_ji)) .NE. 9999)) THEN
        !
        DO il_jj = 1, id_ndepth

           il_den =  0
           il_den2 = 0
           il_poids= 0

           DO il_jp = 1, 4
              IF ( ida_xindex(il_jp,il_ji) .NE. 9999 .AND. ida_yindex(il_jp,il_ji) .NE. 9999) THEN
                 !WRITE(0,*) 'modelvalue ::',rda_modelvalue(ida_xindex(il_jp,il_ji),ida_yindex(il_jp,il_ji),il_jj,il_indice_min)
                 !WRITE(0,*) 'indice ::',ida_xindex(il_jp,il_ji),ida_yindex(il_jp,il_ji),il_jj,il_indice_min
                 !WRITE(0,*) 'Taille ::',shape(rda_modelvalue) 
                 IF (rda_modelvalue(ida_xindex(il_jp,il_ji),ida_yindex(il_jp,il_ji),il_jj,il_indice_min) &
                      .LT. 1000.0.AND. rda_modelvalue(ida_xindex(il_jp,il_ji),ida_yindex(il_jp,il_ji),il_jj,il_indice_min).NE.0 &
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
              ! Test pour savoir si la valeur est une fillValue ou pas
              IF ( ida_xindex(il_jk,il_ji) .NE. 9999 .AND. ida_yindex(il_jk,il_ji) .NE. 9999) THEN
                 IF (rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),il_jj,il_indice_min) &
                      .LT. 1000.0 .AND. rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),il_jj,il_indice_min).NE.0) THEN

                    IF (il_den.EQ.il_poids) THEN              
                       !** 1er cas le nombre de poids valides correspond au nombre de valeurs valides
                       rla_modelvalue_tmp(il_jj) = rla_modelvalue_tmp(il_jj)+&
                            rda_poids(il_jk,il_ji)*rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),il_jj,il_indice_min)
                    ELSE
                       rla_modelvalue_tmp(il_jj) = rla_modelvalue_tmp(il_jj) + &
                            rda_modelvalue(ida_xindex(il_jk,il_ji),ida_yindex(il_jk,il_ji),il_jj,il_indice_min)
                       il_den2 = il_den2 + 1
                    ENDIF
                 ENDIF
              ENDIF
           ENDDO

           IF (il_den.NE.il_poids.AND.il_den2 .NE. 0) THEN
              rla_modelvalue_tmp(il_jj) = rla_modelvalue_tmp(il_jj)/il_den2
           ENDIF
        ENDDO
     ENDIF
     !PRINT *,'rla_modelvalue_tmp :: ',rla_modelvalue_tmp
     !** Gestion du cas ou les fichiers sont abherents        
     IF ( rla_modelvalue_tmp(1).ge.9999) rla_modelvalue_tmp=rl_emptyvalue
     !* Remplacement des zeros par une valeur abherente non physique (sinon le spline fait cree des abherations)

     WHERE (rla_modelvalue_tmp(:).EQ.0) rla_modelvalue_tmp=rl_emptyvalue
     !** Compte du nombre de valeurs nom abherentes
     il_n=COUNT(rla_modelvalue_tmp(:)<rl_emptyvalue)


     !* Select valid profil
     !------------------------------------------------------------------
     ! 2D -> 1D pour la profondeur insitu
     !

     rla_codepth_tmp(1:id_nlevels) = rda_codepthvalue(1:id_nlevels,il_ji)
     DO il_jj = 1, id_nlevels
        IF (rla_codepth_tmp(il_jj).EQ.rd_emptyvalue ) THEN
           rla_codepth_tmp(il_jj) = rl_emptyvalue
        ENDIF
     ENDDO

     !------------------------------------------------------------------
     ! Interpolation des profondeurs (1D)
     !
     rla_modeldepth_inter(1:id_nlevels) = rd_emptyvalue

     IF (il_n.GT.0) THEN
    
        !** Construction de nouveaux tableaux avec des valeurs non abherentes
        IF (ALLOCATED(rla_modelvalue_tmp2)) DEALLOCATE(rla_modelvalue_tmp2)
        ALLOCATE(rla_modelvalue_tmp2(il_n))
        IF (ALLOCATED(rla_modeldepth2)) DEALLOCATE(rla_modeldepth2)
        ALLOCATE(rla_modeldepth2(il_n))
        rla_modelvalue_tmp2(:)=rla_modelvalue_tmp(1:il_n)
        rla_modeldepth2(:)=rda_modeldepth(1:il_n)

        !** Selection de la profondeur observation valide
        il_n2=COUNT(rla_codepth_tmp(:).LE.rla_modeldepth2(il_n))

        IF (ALLOCATED(rla_codepth_tmp2)) DEALLOCATE(rla_codepth_tmp2) 
        ALLOCATE(rla_codepth_tmp2(il_n2))
        rla_codepth_tmp2(:)=rla_codepth_tmp(1:il_n2)
        DO il_jj = 1, il_n2
           IF ( rla_codepth_tmp2(il_jj) .GT. rl_emptyvalue ) rla_codepth_tmp2(il_jj) = rl_emptyvalue
        ENDDO
        IF (ALLOCATED(rla_modeldepth_inter2)) DEALLOCATE(rla_modeldepth_inter2) 
        ALLOCATE(rla_modeldepth_inter2(il_n2))

        !
        rla_modeldepth_inter2(1:il_n2)=rd_emptyvalue
!#if defined key_debug
!           WRITE(0,*),' Cas1 '
!           WRITE(0,*),'PROFONDEURS modele :: ',rla_modeldepth2(:)
!           WRITE(0,*),'-----------------------------------------------------'
!           WRITE(0,*),'Valeurs modele :: ',rla_modelvalue_tmp2
!           WRITE(0,*),'-----------------------------------------------------'
!           WRITE(0,*),'PROFONDEURS insitu :: ',rla_codepth_tmp2 
!           WRITE(0,*),'-----------------------------------------------------'
!#endif
           CALL MCAL_interp1D_cubicspline_R4(rla_modelvalue_tmp2, &
                rla_modeldepth2, &
                il_n, &
                rla_modeldepth_inter2, &
                rla_codepth_tmp2, &
                il_n2, &
                rl_emptyvalue)
           rla_modeldepth_inter(1:il_n2)=rla_modeldepth_inter2(:)

        ELSE
!#if defined key_debug
!           WRITE(0,*),' Cas2 '
!           WRITE(0,*),'PROFONDEURS modele :: ',rda_modeldepth(:)
!           WRITE(0,*),'-----------------------------------------------------'
!           WRITE(0,*),'Valeurs modele :: ',rla_modelvalue_tmp
!           WRITE(0,*),'-----------------------------------------------------'
!           WRITE(0,*),'PROFONDEURS insitu :: ',rla_codepth_tmp 
!           WRITE(0,*),'-----------------------------------------------------'
!#endif
           CALL MCAL_interp1D_cubicspline_R4(rla_modelvalue_tmp, &
                rda_modeldepth, &
                id_ndepth, &
                rla_modeldepth_inter, &
                rla_codepth_tmp, &
                id_nlevels, &
                rl_emptyvalue)
        ENDIF
        DO il_jj = 1, id_nlevels
          
           rl_tmp = rla_modeldepth_inter(il_jj)
           IF ((IEOR(TRANSFER(rl_tmp,NaN), NaN) == 0) & 
                .OR. &
                (rl_tmp == rd_emptyvalue) &
                .OR. &
                (rl_tmp == rl_emptyvalue) &
                ) THEN
              rla_modeldepth_inter(il_jj) = rd_emptyvalue
           ENDIF
           rda_modelvalue_inter(il_jj, il_ji) = &
                rla_modeldepth_inter(il_jj)
        ENDDO !id_nlevels
#if defined key_debug
    WRITE(0,*),'Valeurs interpolées :: ',rda_modelvalue_inter(:,il_ji) 
    WRITE(0,*),'-----------------------------------------------------'
#endif
     !
  ENDDO !il_ji

  !
  !
ENDSUBROUTINE interp_model_field_3d
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
     rda_poids)
  !
  USE MIOL
  IMPLICIT NONE   
  !
  CHARACTER(LEN=255) :: cd_colocFile
  INTEGER :: id_nprof
  INTEGER, DIMENSION(4,id_nprof) :: ida_xindex, ida_yindex
  REAL(KIND=4),DIMENSION(4,id_nprof) ::  rda_poids
  
  !
  INTEGER :: il_ji, &
             il_jj, il_fic
  REAL(KIND=4) :: rl_lon, rl_lat,rl_coloc_lon,rl_coloc_lat
  !
  !
  !------------------------------------------------------------------------
  ! Lecture du fichier de colocalisation
  !
#if defined key_debug
  WRITE(0,*) 'Inside read_coloc_file'
#endif
  CALL MIOL_getFreeLU(il_fic) 
  OPEN(il_fic, file=TRIM(cd_colocFile), &
       status='old', &
       form='formatted')
  !     form='unformatted')
  !
  DO il_ji=1, id_nprof
      READ(il_fic,'(i6,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,&
                      f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,&
                      f12.9,2x,i6,2x,i6,2x,f12.9,2x,f12.5,2x,f12.5)') &
                 il_jj, rl_lon, rl_lat, &
                 ida_xindex(1,il_ji), ida_yindex(1,il_ji),rda_poids(1,il_ji),& 
                 ida_xindex(2,il_ji), ida_yindex(2,il_ji),rda_poids(2,il_ji),& 
                 ida_xindex(3,il_ji), ida_yindex(3,il_ji),rda_poids(3,il_ji),&
                 ida_xindex(4,il_ji), ida_yindex(4,il_ji),rda_poids(4,il_ji),&
                 rl_coloc_lon,rl_coloc_lat
        
! Case formatted      
!     READ(il_fic) il_jj, rl_lon, rl_lat, &
!          ida_xindex(1,il_ji), ida_yindex(1,il_ji),rda_poids(1,il_ji),& 
!          ida_xindex(2,il_ji), ida_yindex(2,il_ji),rda_poids(2,il_ji),& 
!          ida_xindex(3,il_ji), ida_yindex(3,il_ji),rda_poids(3,il_ji),&
!          ida_xindex(4,il_ji), ida_yindex(4,il_ji),rda_poids(4,il_ji)
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
SUBROUTINE inquire_observation_file (cd_inputFile, &
     cd_varname, &
     id_nprof, &
     id_nlevels, &
     cda_dimname, &
     ld_isdepth )
  !
  USE netcdf
  USE MIOL 
  IMPLICIT NONE 
  !
  CHARACTER(LEN=255) :: cd_inputFile
  CHARACTER(LEN=*)   :: cd_varname
  CHARACTER(LEN=255), DIMENSION(2) :: cda_dimname
  INTEGER :: id_nprof, &
       id_nlevels
  LOGICAL :: ld_isdepth
  !
  INTEGER :: il_file_id, &
       il_nbdim, &
       il_nbvar, &
       il_ji
  CHARACTER(LEN=255), DIMENSION(:), POINTER :: clpa_dimname, &
       clpa_varname
  INTEGER, DIMENSION(:), POINTER :: ilpa_dimlen, &
       ilpa_nbdim
  LOGICAL :: ll_flag_nprof, &
       ll_flag_nlevels

  !
  ll_flag_nprof = .FALSE.
  ll_flag_nlevels = .FALSE.
  ld_isdepth = .FALSE.
  !      
  !
  !------------------------------------------------------------------------
  !
  ! Ouverture et lecture du fichiers
  CALL MIOL_openr_file_NC(TRIM(cd_inputFile), &
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
     WRITE(0,*) ' inquire_observation_file : nbdim or nbvar equals zero.'
     CALL flush(0)
     STOP
  ENDIF
  !
  !
  ! Lecture du nombre de niveaux et de profondeurs
  DO il_ji=1, il_nbdim
     IF (TRIM(clpa_dimname(il_ji)).EQ.'numobs') THEN
        id_nprof = ilpa_dimlen(il_ji)
        ll_flag_nprof = .TRUE.
        cda_dimname(2) = clpa_dimname(il_ji)
     ELSE IF (TRIM(clpa_dimname(il_ji)).EQ.'numdeps') THEN
        id_nlevels = ilpa_dimlen(il_ji)
        ll_flag_nlevels = .TRUE.
        cda_dimname(1) = clpa_dimname(il_ji)
     ENDIF
  ENDDO
  IF ((.NOT. ll_flag_nprof) .OR. &
       (.NOT. ll_flag_nlevels) ) THEN
     WRITE(0,*) ' inquire_observation_file : dimension numobs or numdeps not found.'
     CALL flush(0)
     STOP
  ENDIF
  !
  !
  ! Nom de la variable de profondeur et existence de la variable
  DO il_ji=1, il_nbvar
     IF (TRIM(clpa_varname(il_ji)) .EQ. 'depth') THEN
        ld_isdepth = .TRUE.
     ENDIF
  ENDDO
  !
  ! Fermeture du fichier
  CALL MIOL_close_file_NC(il_file_id)
  !
  !
ENDSUBROUTINE inquire_observation_file
!

!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!
SUBROUTINE read_observation_file (cd_inputFile, &
     cd_inputVarname,       &
     id_nprof,              &
     id_ncast,              &
     id_nvar,               &
     id_nlevels,            &
     ld_isdepth,            &
     rda_depthvalue,        &
     rda_leadtimevalue,     &
     cda_modelVarname,      &
     rd_fillValue,          &
     rda_LON,               &
     rda_LAT,               &
     rda_juld)
  !                                     
  USE netcdf
  USE MIOL 
  USE table_CLASS4
  IMPLICIT NONE   
  !
  !
  CHARACTER(LEN=255)                              :: cd_inputFile
  CHARACTER(LEN=255)                              :: cd_inputVarname
  INTEGER(KIND=4)                                 :: id_nprof,  &
                                                     id_nlevels,&
                                                     id_ncast,  &
                                                     id_nvar,   &
                                                     il_good
  LOGICAL                                         :: ld_isdepth
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof)    :: rda_depthvalue

  REAL(KIND=8), DIMENSION(id_nprof)               :: rda_LON,  &
                                                     rda_LAT,  &
                                                     rda_juld
  REAL(KIND=8), DIMENSION(id_ncast)               :: rda_leadtimevalue
  REAL(KIND=4), DIMENSION(id_nlevels,id_nprof)    :: rla_varqc
  REAL(KIND=4),INTENT(OUT)                        :: rd_fillValue
  !
  CHARACTER(LEN=255)                              :: cl_ficlog,  &
                                                     cl_ficlog2, & 
                                                     cl_varname, &
                                                     cl_qc,cl_time
  CHARACTER(LEN=255) , DIMENSION(id_nvar)         :: cda_modelVarname
  INTEGER(KIND=4)                                 :: il_file_id, &
                                                     il_nbdim, &
                                                     il_nbvar, &
                                                     il_ji,    &
                                                     il_jj,    &
                                                     il_jk,    &
                                                     il_nbatt, &
                                                     il_pas,   &
                                                     il_max
  LOGICAL                                         :: ll_flag_nprof, &
                                                     ll_flag_nlevels,     &
                                                     ll_exist_ficlog,     &
                                                     ll_exist_ficlog2,    &
                                                     ll_lon,ll_lat,ll_qc, &
                                                     ll_varname,ll_ld,ll_juld
  REAL(KIND=4), DIMENSION(:,:), POINTER           :: rlpa_tmp
  CHARACTER(LEN=255), DIMENSION(:)    , POINTER   :: clpa_dimname, &
                                                     clpa_varname,        &
                                                     clpa_modelattname,   &
                                                     clpa_modelattvalue
  CHARACTER(LEN=8) , DIMENSION(:,:)  , POINTER   :: clpa_2Dtmp
  INTEGER           , DIMENSION(:)    , POINTER   :: ilpa_dimlen, &
                                                     ilpa_nbdim
  REAL(KIND=4)      , DIMENSION(:)    , POINTER   :: rlpa_modelattvalue
  REAL(KIND=8)      , DIMENSION(:)    , POINTER   :: rlpa_1Dtmp,      &
                                                     rlpa_1D_LON_tmp, &
                                                     rlpa_1D_LAT_tmp
  REAL(KIND=4)      , DIMENSION(:,:)  , POINTER   :: rlpa_2D_TEMPtmp
  REAL(KIND=4)      , DIMENSION(:,:,:), POINTER   :: rlpa_3Dtmp
  !
  !------------------------------------------------------------------------
  !
  ! Ouverture et lecture du fichiers
  CALL MIOL_openr_file_NC(TRIM(cd_inputFile), &
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
     WRITE(0,*) ' read_observation_file : nbdim or nbvar equals zero.'
     CALL flush(0)
     STOP
  ENDIF
  !
  ! Initialisation 
  rda_depthvalue(1:id_nlevels, 1:id_nprof) = 99999.0
  rda_LON(:)=99999.0
  rda_LAT(:)=99999.0
  rla_varqc(1:id_nlevels,1:id_nprof) = 0.
  ll_exist_ficlog=.FALSE.
  ll_exist_ficlog2=.FALSE.
  ll_lon=.FALSE.
  ll_lat=.FALSE.
  ll_qc=.FALSE.
  ll_ld=.FALSE.
  ll_juld=.FALSE.
  ll_varname=.FALSE.
  !     
  DO il_ji=1, il_nbvar
      IF (TRIM(clpa_varname(il_ji)) .EQ. 'longitude') THEN
         ll_lon=.TRUE.
      ELSE IF (TRIM(clpa_varname(il_ji)) .EQ. 'latitude') THEN
         ll_lat=.TRUE.
      ELSE IF (TRIM(clpa_varname(il_ji)) .EQ. 'qc' .OR. TRIM(clpa_varname(il_ji)).EQ. 'QC02' ) THEN
         cl_qc=TRIM(clpa_varname(il_ji))
         ll_qc=.TRUE.
      ELSE IF (TRIM(clpa_varname(il_ji)) .EQ.'leadtime' ) THEN
         ll_ld=.TRUE.
      ELSE IF (TRIM(clpa_varname(il_ji)) .EQ.'juld' .OR. TRIM(clpa_varname(il_ji)) .EQ. 'obs_time') THEN
         ll_juld=.TRUE.
         cl_time= TRIM(clpa_varname(il_ji))
      ELSE IF (TRIM(clpa_varname(il_ji)) .EQ.'varname' ) THEN
         ll_varname=.TRUE.
      ENDIF
   ENDDO
  !
  IF ( .NOT. ll_lon .OR. .NOT. ll_lat .OR. .NOT. ll_qc .OR. .NOT. ll_ld .OR. .NOT. ll_juld .OR. .NOT. ll_varname ) THEN 
      WRITE (0,*) 'Problem Some variables are missing : '
      WRITE (0,*) 'longitude : ',ll_lon
      WRITE (0,*) 'latitude : ',ll_lat
      WRITE (0,*) 'qc : ',ll_qc
      WRITE (0,*) 'leadtime : ',ll_ld
      WRITE (0,*) 'juld : ',ll_juld
      WRITE (0,*) 'varname : ',ll_varname
      STOP 
  ENDIF
  !
  !Ajout C.REGNIER Lecture de la position du profil
  !* LONGITUDE 
  cl_varname = 'longitude' 
#if defined key_debug
  WRITE(0,*) 'READ variable :: ',TRIM(cl_varname)
#endif
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       rlpa_1D_LON_tmp)

  rda_LON(:)=rlpa_1D_LON_tmp(:)

  !* LATITUDE
  cl_varname = 'latitude' 
#if defined key_debug
  WRITE(0,*) 'READ variable :: ',TRIM(cl_varname)
#endif
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       rlpa_1D_LAT_tmp)

  rda_LAT(:)=rlpa_1D_LAT_tmp(:)

  !** Lecture du qc de la variable concernée
#if defined key_debug
  WRITE(0,*) 'READ variable QC:: ',TRIM(cl_qc)
#endif
  CALL MIOL_read_field_NC(il_file_id,&
       TRIM(cl_qc),&
       rlpa_3Dtmp)
! En supposant qu'il n'y ait qu'une
!seule variable...a implementer
  rla_varqc(1:id_nlevels,1:id_nprof) = &                
       rlpa_3Dtmp(1:id_nlevels,1, 1:id_nprof)  

!#if defined key_debug
!  WRITE(0,*) 'Variable QC :: ',rla_varqc(:,:)       
!#endif
  DEALLOCATE(rlpa_3Dtmp) 
  ! Lecture des profondeurs
  IF (ld_isdepth) THEN 
     cl_varname = 'depth'
     CALL MIOL_read_field_NC(il_file_id, &
          cl_varname, &
          rlpa_tmp)
     rda_depthvalue(1:id_nlevels, 1:id_nprof) = &
          rlpa_tmp(1:id_nlevels, 1:id_nprof)

     DEALLOCATE(rlpa_tmp)
  ENDIF
  !
  cl_varname = 'leadtime'
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       rlpa_1Dtmp)

  rda_leadtimevalue(:) = rlpa_1Dtmp(:)
  DEALLOCATE(rlpa_1Dtmp)
  !
  CALL MIOL_read_field_NC(il_file_id, &
       cl_time, &
       rlpa_1Dtmp)
  rda_juld(:)=rlpa_1Dtmp(:)
  !
  cl_varname = 'varname'
  WRITE(0,*) 'Read varname'
  CALL MIOL_read_field_NC(il_file_id, &
       cl_varname, &
       clpa_2Dtmp, &
       8)
  DO il_ji=1,id_nvar  
     cda_modelVarname(il_ji) = TRIM(clpa_2Dtmp(il_ji,1)(1:8))
  ENDDO
  WRITE(0,*) 'Read varname : ', cda_modelVarname(:)
  !cda_modelVarname(:)="ileadfra"
  WRITE(0,*) 'Read varname OK : ',clpa_2Dtmp(:,:)
  DEALLOCATE(clpa_2Dtmp)

  !** Test sur la valeur du QC de la variable
  IF (TRIM(cda_modelVarname(il_ji)) .EQ. 'ileadfra') THEN 
     il_good=1
  ELSE 
     il_good=0
  ENDIF

  DO il_jj=1, id_nprof
     DO il_jk=1, id_nlevels
        IF ( rla_varqc(il_jk, il_jj) .EQ. il_good) THEN
           !** Gestion des profils inversés  
           IF ( il_jk < id_nlevels ) THEN
              IF ( rda_depthvalue(il_jk+1, il_jj) /= 99999.0 .AND. rda_depthvalue(il_jk,il_jj) /= 99999.0 ) THEN
                 IF ( rda_depthvalue(il_jk+1, il_jj) < rda_depthvalue(il_jk,il_jj) )  THEN
                    rda_depthvalue(il_jk, il_jj) =99999.0
                 ENDIF
              ENDIF
           ENDIF
!           WRITE(0,*),'Valeur correcte :: ',rla_varqc(il_jk, il_jj)
        ELSE  
!#if defined key_debug
!            WRITE(0,*),'Profil n° :: ',il_jj
!            WRITE(0,*),'Niveau n ° :: ',il_jk
!#endif
            rda_depthvalue(il_jk, il_jj) = 99999.0
        ENDIF
     ENDDO
  ENDDO
  !** 
  !
  !
  ! Lecture des attributs
  CALL MIOL_read_attributeslist_NC (il_file_id, &
       cd_inputVarname, &
       il_nbatt, &
       clpa_modelattname, &
       clpa_modelattvalue, &
       rlpa_modelattvalue)
  !
  !
  ! Recherche de la fillValue
  !
  DO il_ji=1, SIZE(clpa_modelattname)
     IF(TRIM(clpa_modelattname(il_ji)).EQ.'_FillValue') THEN
        rd_fillValue = rlpa_modelattvalue(il_ji)
     ENDIF
  ENDDO
  !
  !
  ! Fermeture du fichier
  CALL MIOL_close_file_NC(il_file_id)
  !
600 FORMAT(a,2x,i5,2x,i5,2x,f11.4,2x,f11.4)
  !
  !
ENDSUBROUTINE read_observation_file

!******************************************************************************
!******************************************************************************
!******************************************************************************
