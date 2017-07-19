! creation N. Verbrugge 2007
! passage operationnel arctique1 S. Besnard 12/2008
! Modification pour l'adapter à la nouvelle version de mft : C.REGNIER Avril 2010
!
! Objet du code : calculer les differences des moyennes et rms des donnees
! de concentration de glace modeles (PSY3) et observees (CERSAT) pour 
! pour les dates contenues dans le fichier a passer en argument de l executable
! C.REGNIER   22/10/2010 :: modification pour lire les fichiers PSY3V3R1
! --------------------------------------------------------------------
             PROGRAM MCAL_SEAICE_STATS
! --------------------------------------------------------------------
!
!  use stats
  use netcdf
  use MIOL
  use MIOL_util
  use netcdf
  !use constant

  implicit none
!
  character(len=255), dimension(:), allocatable          :: cl_file_mod, cl_file_obs
  character(len=255)                                     :: cl_file_mask, cl_file_out,cl_attname
  character(len=255)                                     :: cd_param_DiffDate_file, cl_arguments_file,&
                                                            cl_file_boxes,cl_text
  character(len=80)                                      :: cl_varname
  integer                                                :: il_nb_file, ni, il_err,&
                                                            narg,iargc,il_typevar,il_nbdim2,&
                                                            il_file_id1, il_file_id2, il_file_id3,&
                                                            il_file_id4, il_numfil, il_file_id5,&
                                                            il_dim_ts, il_dim_ts_old
  integer(KIND=1)                                        :: il_attvalue
  integer, dimension(3)                                  :: ila_dimlen
  integer, dimension(2)                                  :: ila_dim_old
  integer(kind=1), dimension(:,:,:), pointer             :: ilpa_obs, ilpa_qf_obs
  integer(kind=4), dimension(:,:), pointer               :: ilpa_mask_boxes
  integer(kind=1), dimension(:,:), allocatable           :: ila_mask
  integer(kind=4), dimension(:), pointer                 :: ilpa_time_obs
  real(kind=4), dimension(:,:,:), pointer                :: rlpa_mod
  real(kind=4), dimension(:,:), pointer                  :: rlpa_mod_2D
  real(kind=4), dimension(:,:), allocatable              :: rla_mod, rla_obs, rla_qf_obs
  real(kind=4), dimension(:), pointer                    :: rlpa_time_mod
  real(kind=8), dimension(:), pointer                    :: rlpa_time_old
  REAL(KIND=4),DIMENSION(:),POINTER                      :: rlpa_time
  real(kind=4), dimension(:,:,:,:), pointer                :: rlpa_meancumul,rlpa_rmscumul,rlpa_cumul
  real(kind=4), dimension(1)                             :: rla_time_mod 
  real(kind=8), dimension(:), allocatable                :: rla_time    ! date output array
  real(kind=4), dimension(:,:), allocatable              :: rla_diff
  real(kind=4), dimension(:,:), pointer                  :: rlpa_rms, rlpa_ave
  real(kind=8)                                           :: rd_time_mod, rd_time_obs
  real(kind=4), parameter                                        :: rl_flagvalue=998.0
  logical                                                :: ll_err, ll_exist, ld_test
!
! nbre max de sous-boites pour 1 macro boite
  integer(kind=4), parameter ::                            il_nb_max=6
  integer, parameter ::                                    il_macro_region_num_max=20
  integer ::                                               id_macro_region_num, jv_status,il_nbfile
  character(len=80), dimension(il_macro_region_num_max) :: cda_macro_region_name
  integer(kind=4), dimension(il_macro_region_num_max) :: ida_subregion_count
  integer(kind=4), dimension(il_macro_region_num_max,il_nb_max+1) :: ida_macro_region_def
!
  real(kind=4), dimension(:), allocatable ::                rda_vect_diff,rla_meantot,rla_rmstot
  integer ::                                                ii,jj,kk,ll
  real(kind=4), dimension(:,:), allocatable ::              rla_temporary_mtx,rla_temporary_mtx2
  integer ::                                                il_dimvect
  real(kind=4) ::                                           rd_rms
  real(kind=4), dimension(:,:), allocatable ::              rla_rms_boxes
  real(kind=4) ::                                           rd_ave,rl_attvalue
  real(kind=4), dimension(:,:), allocatable ::              rla_ave_boxes
!
!  integer, dimension(2) :: ila_dim_out = (/ 16, 7 /)
  integer, dimension(3) :: ila_dim_out
  integer,dimension(:),ALLOCATABLE  :: ila_sumtot 
  integer :: il_nb_echeance,il_status,il_fic,il_nbdim,il_narg,il_ji,il_j,il_nb_time,il_ind_time,il_ind_time2,il_k,il_nlon,il_nlat,il_nbtime,il_ech
  INTEGER(KIND=4),DIMENSION(2)                :: ila2D
  character(len=255)                            :: cl_conf,cl_mask,cl_path,cl_input,cl_namelist,cl_echeance
  character(len=255), dimension(:), allocatable :: cla_dimname
  CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE  ::  cla_dataFile
  REAL(KIND=4),DIMENSION(:,:,:,:,:),ALLOCATABLE ::  rla_mean_diff_cumul_time,rla_rms_diff_cumul_time,rla_nb_cumul_time
  INTEGER(KIND=4),DIMENSION(1)                :: ila_time
  INTEGER(KIND=4),DIMENSION(4)                :: ila4D
  REAL(KIND=4),DIMENSION(:,:,:),ALLOCATABLE     :: rla_meandiff,rla_rmsdiff,rla_sum

! --------------------------------------------------------------------------------
!            CODE
! -------------------------------------------------------------------------------
! FILES READING
! ---------------------------
!
! Read arguments
  NAMELIST / Liste_aice /il_nbfile,cl_conf,cl_mask,cl_file_boxes,cl_file_out,cl_echeance
  il_narg=iargc()
  IF (il_narg.NE.2) THEN

     PRINT *,' '
     PRINT *,' Compute seaice usage : '
     PRINT *,' -n namelist   : namelist file'
     STOP
  ELSE
     DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-n') THEN
           CALL getarg(il_ji+1, cl_namelist)
        ENDIF
     ENDDO
  ENDIF
  INQUIRE(FILE=TRIM(cl_namelist),EXIST=ll_exist)
  IF (.NOT.ll_exist) THEN  ! sortie en erreur
     WRITE(0,*) 'error file ',TRIM(cl_arguments_file),&
                                    ' does not exist'
     jv_status = -1
     STOP
  ENDIF
  !** Open Namelist
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

! Read Boxes mask
  print *,'mask : ',cl_mask 
  call MIOL_openr_file_NC(TRIM(cl_mask), il_file_id3)
  cl_varname = 'mask'
  call MIOL_read_field_NC(il_file_id3, TRIM(cl_varname), &
                            ilpa_mask_boxes,ila2D)
  call MIOL_close_file_NC(il_file_id3)
  il_nlon=ila2D(1)
  il_nlat=ila2D(2)
! Read Boxes Definition
! init variables
  id_macro_region_num = 0
  cda_macro_region_name = ''
  ida_subregion_count = 0
  ida_macro_region_def = 0
  CALL LireMacroBoite(cl_file_boxes, id_macro_region_num, &
  cda_macro_region_name, ida_subregion_count, &
  ida_macro_region_def, jv_status)
!
  il_dim_ts_old=0         ! First Index-1
  il_dim_ts=il_nbfile    ! End index

! Allocation
  ALLOCATE(rla_rms_boxes(id_macro_region_num, il_dim_ts))
  ALLOCATE(rla_ave_boxes(id_macro_region_num, il_dim_ts))
  ALLOCATE(rla_meantot(id_macro_region_num))
  ALLOCATE(rla_rmstot(id_macro_region_num))
  ALLOCATE(ila_sumtot(id_macro_region_num))
  ila_sumtot(:)=0
  rla_meantot(:)=0
  rla_rmstot(:)=0
  il_ind_time=1
  il_ind_time2=0
! 
! LOOP on files -------------------------------
!----------------------------------------------
  il_nbtime=0
  DO ni = 1, il_nbfile
     READ(il_fic,FMT='(A)') cla_dataFile(ni)
     call MIOL_openr_file_NC(TRIM(cla_dataFile(ni)), il_file_id1)
     CALL MIOL_read_field_NC(il_file_id1,'time',rlpa_time,ila_time)
     il_nbtime=il_nbtime+ila_time(1)
  ENDDO
  il_ind_time=1
  il_ind_time2=0

  DO ni = 1, il_nbfile
     print *,'loop : ',ni
!
! Read Stats File
     WRITE(0,*) cla_dataFile(ni)
     call MIOL_openr_file_NC(TRIM(cla_dataFile(ni)), il_file_id1)
     cl_varname='mean_diff_cumul_'//TRIM(cl_echeance)
     call MIOL_read_field_NC(il_file_id1, TRIM(cl_varname), rlpa_meancumul,ila4D)
     il_nb_echeance=ila4D(4)
     !il_nb_echeance=10
     WRITE(0,*) 'NB echeance :',il_nb_echeance
     WHERE(rlpa_meancumul > 1.e20) rlpa_meancumul=0
     WHERE(rlpa_meancumul < -1.e10) rlpa_meancumul=0
     cl_varname='rms_diff_cumul_'//TRIM(cl_echeance)
     call MIOL_read_field_NC(il_file_id1, TRIM(cl_varname), rlpa_rmscumul)
     WHERE(rlpa_rmscumul > 1.e20) rlpa_meancumul=0
     WHERE(rlpa_rmscumul < -1.e10) rlpa_meancumul=0
     cl_varname='nb_cumul'
     call MIOL_read_field_NC(il_file_id1, TRIM(cl_varname), rlpa_cumul)
     cl_varname='time'
     call MIOL_read_field_NC(il_file_id1, TRIM(cl_varname),rlpa_time,ila_time)
     !rla_time_mod(1)=rlpa_time_mod(1)
     IF ( ni ==1 ) THEN
         ALLOCATE(rla_mean_diff_cumul_time(il_nlon,il_nlat,id_macro_region_num,il_nbtime,il_nb_echeance))
         ALLOCATE(rla_rms_diff_cumul_time(il_nlon,il_nlat,id_macro_region_num,il_nbtime,il_nb_echeance))
         ALLOCATE(rla_nb_cumul_time(il_nlon,il_nlat,id_macro_region_num,il_nbtime,il_nb_echeance))
         ALLOCATE(rla_time(il_nbtime))
     ENDIF
     il_nb_time=ila_time(1)
     il_ind_time2=il_ind_time2+il_nb_time
     rla_time(il_ind_time:il_ind_time2)=rlpa_time(:)
     do il_ech=1,il_nb_echeance
       do ii = 1, id_macro_region_num    ! loop on the boxes
          do jj=1, il_nlon
             do kk=1, il_nlat
                  IF  ( ilpa_mask_boxes(jj,kk) .EQ. ida_macro_region_def(ii,1)) THEN
       !                WRITE(0,*) 'OK',ida_macro_region_def(ii,1)
                       rla_mean_diff_cumul_time(jj,kk,ii,il_ind_time:il_ind_time2,il_ech)=rlpa_meancumul(jj,kk,:,il_ech)
                       rla_rms_diff_cumul_time(jj,kk,ii,il_ind_time:il_ind_time2,il_ech)=rlpa_rmscumul(jj,kk,:,il_ech)
                       rla_nb_cumul_time(jj,kk,ii,il_ind_time:il_ind_time2,il_ech)=rlpa_cumul(jj,kk,:,il_ech)
                  ENDIF
             enddo
          enddo
       enddo ! end of boxes loop
     enddo
     il_ind_time=il_ind_time+il_nb_time
     call MIOL_close_file_NC(il_file_id1)
     DEALLOCATE(rlpa_meancumul)
     DEALLOCATE(rlpa_rmscumul)
     DEALLOCATE(rlpa_cumul)
  ENDDO ! end of files loop
!
! -----------------------------------------------------------
 !** Compute Final statistics
  ALLOCATE(rla_sum(il_nbtime,id_macro_region_num,il_nb_echeance),rla_meandiff(il_nbtime,id_macro_region_num,il_nb_echeance),rla_rmsdiff(il_nbtime,id_macro_region_num,il_nb_echeance))
  rla_meandiff(:,:,:)  = 0
  rla_rmsdiff(:,:,:)  =  0
  rla_sum(:,:,:)=0
  DO il_ech=1,il_nb_echeance
   DO il_k=1,id_macro_region_num
     DO il_j=1,il_nbtime
          IF (SUM(rla_nb_cumul_time(:,:,il_k,il_j,il_ech)) .GT. 0) THEN 
             rla_meandiff(il_j,il_k,il_ech)=SUM(rla_mean_diff_cumul_time(:,:,il_k,il_j,il_ech))/SUM(rla_nb_cumul_time(:,:,il_k,il_j,il_ech))
             IF ( rla_meandiff(il_j,il_k,il_ech) < -0.8 ) THEN
                WRITE(0,*) 'Problem with time ',il_j
                WRITE(0,*) rla_time(il_j)/86400
              ENDIF
              rla_rmsdiff(il_j,il_k,il_ech)=SQRT(SUM(rla_rms_diff_cumul_time(:,:,il_k,il_j,il_ech))/SUM(rla_nb_cumul_time(:,:,il_k,il_j,il_ech)))
              rla_sum(il_j,il_k,il_ech)=SUM(rla_nb_cumul_time(:,:,il_k,il_j,il_ech))
          ELSE 
              rla_meandiff(il_j,il_k,il_ech)=rg_FillValue
              rla_rmsdiff(il_j,il_k,il_ech)=rg_FillValue
              rla_sum(il_j,il_k,il_ech)=0
          ENDIF
     ENDDO
   ENDDO
  ENDDO

  il_nbdim = 3
  allocate(cla_dimname(il_nbdim))
  cla_dimname(1) = 'time_counter'
  cla_dimname(2) = 'box'
  cla_dimname(3) = 'z'

  ila_dim_out(1)=il_nbtime
  ila_dim_out(2)=id_macro_region_num
!  ila_dim_out(2)=il_dim_ts
  ila_dim_out(3)=il_nb_echeance
  WRITE(0,*) 'Write outputfile : ',TRIM(cl_file_out)   
  call MIOL_create_file_NC(TRIM(cl_file_out), il_nbdim, &
                               cla_dimname, ila_dim_out)
!
  call MIOL_openw_file_NC(TRIM(cl_file_out), il_file_id5)
!
  WRITE(0,*) 'Write rms : ',shape(rla_rmsdiff)   
  cl_varname = 'rms'
  call MIOL_write_field_NC(il_file_id5, trim(cl_varname), 'TBZ', &
                               rla_rmsdiff)
   
  print *,'rms ok '
  cl_varname = 'mean'
  WRITE(0,*) 'Write mean : ',shape(rla_meandiff)   
  call MIOL_write_field_NC(il_file_id5, cl_varname, 'TBZ', &
                               rla_meandiff)
  print *,'mean ok '
  cl_varname = 'time_counter'
  call MIOL_write_field_NC(il_file_id5, cl_varname, 'T', &
                               rla_time)
  print *,'time counter ok '
  cl_varname = 'nb_values'
  call MIOL_write_field_NC(il_file_id5, cl_varname, 'TBZ', &
                               rla_sum)

  print *,'nb_values ok '
!
  call MIOL_close_file_NC(il_file_id5)
!
!
CONTAINS
!--------------------------------------------------------------------------------
      SUBROUTINE LireMacroBoite(cd_ficname, id_num_macro, cda_name, ida_count, ida_num, jv_status)
!--------------------------------------------------------------------------------
! variables subroutine --------
! cd_ficname : macro boite input filename (.txt)
! cda_name : macro region name
! id_num_macro : number of macro region
! ida_count : number of sub-region per macro-region
! ida_num : ida_num(1)=macro region number ; ida_num(1:max)=sub-region number
! variables locales ---------
! ila_nb_max
!------------------------------------------------------------------------------
! declarations
! ---------------------------------------------------------
implicit none
character(len=255), intent(in) :: cd_ficname
character(len=80), dimension(:), intent(inout) :: cda_name  ! OUT
integer(kind=4), dimension(:), intent(inout) :: ida_count   ! OUT
integer(kind=4), dimension(:,:), intent(inout) :: ida_num   ! OUT
integer,intent(out) :: jv_status
logical :: ll_exist
integer :: il_numfil ! numero logique fichier cd_fic_name
character(len=1), parameter :: cl_textexclusion='#'
character(len=256) :: cl_text
integer :: ii, id_num_macro, jj
!
!------------------------------------------------------------------------------
!             code
!------------------------------------------------------------------------------
! initialisation
! --------------
    jv_status = 0
!
! verification existence fichiers et ouverture
! --------------------------------------------
      inquire(file=trim(cd_ficname),exist=ll_exist)
      if (.not.ll_exist) then  ! sortie en erreur
        jv_status = -1
        print*, 'error file ', trim(cd_ficname), ' does not exist'
        stop
      endif
      call MIOL_getfreelu(il_numfil)
      open(unit=il_numfil,file=trim(cd_ficname),status='old',form='formatted',&
         & iostat=il_err,action='read')
      if ( il_err /= 0 ) then
        jv_status = -1
        print*, 'error opening file', trim(cd_ficname)
        stop
      endif
!
! head reading + region number
! ---------------------------------------
      cl_text=''
      il_err = 0
      cl_text=readnextline(il_numfil,cl_textexclusion,il_err)
      if ( il_err /= 0 ) then
        jv_status = -1
        close(unit=il_numfil)
        stop 'error readnextline:unavailable txt format'
     endif
!     
     read(cl_text,fmt=*,iostat=il_err) id_num_macro
      if (il_err/=0) then
        jv_status = -1
        close(unit=il_numfil)
        stop 'liremacroboite: error reading number of macro regions'
     ENDIF
! 
! Read macro and sub region numbers
! ---------------------------------

      do ii=1, id_num_macro
           cl_text=readnextline(il_numfil,cl_textexclusion,il_err)
            IF ( il_err /= 0 ) THEN
              jv_status = -1
              CLOSE(UNIT=il_numfil)
              STOP'liremacroboite: error readnextline:unavailable txt format'
            ENDIF
          READ(cl_text,FMT=*,IOSTAT=il_err) cda_name(ii)
           IF (il_err/=0) THEN
             jv_status = -1
             CLOSE(UNIT=il_numfil)
            STOP 'liremacroboite: error in macro region name reading'
           ENDIF
          cl_text=readnextline(il_numfil,cl_textexclusion,il_err)
            IF ( il_err /= 0 ) THEN
              jv_status = -1
              CLOSE(UNIT=il_numfil)
              STOP'liremacroboite: error in sub region number reading'
            ENDIF
           READ(cl_text,FMT=*,IOSTAT=il_err) ida_count(ii)
           IF (il_err/=0) THEN
             jv_status = -1
             CLOSE(UNIT=il_numfil)
            STOP 'liremacroboite: error in sub region number reading'
           ENDIF
          cl_text=readnextline(il_numfil,cl_textexclusion,il_err)
            IF ( il_err /= 0 ) THEN
              jv_status = -1
              CLOSE(UNIT=il_numfil)
              STOP'liremacroboite: error in macro and sub-region numbers reading'
            ENDIF
          READ(cl_text,FMT=*,IOSTAT=il_err) (ida_num(ii,jj), jj=1,ida_count(ii)+1)
           IF (il_err/=0) THEN
             jv_status = -1
             CLOSE(UNIT=il_numfil)
            STOP'liremacroboite: error in macro and sub-region numbers reading'
           ENDIF
       end do
!
! Closing file
! -------------
      CLOSE(UNIT=il_numfil)
!             
END SUBROUTINE LireMacroBoite
!------------------------------------------
!
 !---------------------------------------------------------------------------------------
 !
 !                          ---   FUNCTION  readnextline --- 
 !
 !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Mars 2007

  ! Fonction de lecture ligne par ligne selective:
  ! toutes les lignes contenant cd_textexclusion sont lues pour passer a la
  ! suivante

  ! reprise de createcmz.F90 (C.E. Testut). Mais rajout d'une gestion des
  ! erreurs de facon a ne pas faire un stop brutal: en cas de probleme de
  ! lecture on attribut la valeur -1 a id_err (sinon O)

!!$  CHARACTER(len=256) FUNCTION readnextline(id_numfil,cd_textexclusion,id_err) 

  FUNCTION readnextline(id_numfil,cd_textexclusion,id_err)
  
    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 

    IMPLICIT NONE

    CHARACTER(len=256) :: readnextline
    INTEGER, INTENT(in) :: id_numfil  ! IN: numero logique du fichier
    CHARACTER(len=*), INTENT(in) :: cd_textexclusion  ! IN: texte d exclusion
    INTEGER,INTENT(out) :: id_err

    ! variables locales
    CHARACTER(len=256) :: cl_text
    INTEGER :: il_lentrim

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    id_err = 0  ! initialisation du code d erreur

    il_lentrim=LEN_TRIM(cd_textexclusion)
    cl_text=TRIM(cd_textexclusion)
    !  print *,'readnextline:',TRIM(cd_textexclusion),':',TRIM(cl_text)
    DO WHILE (cl_text(1:MIN(il_lentrim,LEN_TRIM(cl_text)))==TRIM(cd_textexclusion))
       READ(UNIT=id_numfil,FMT='(a)',ERR=10) cl_text
       !     print *,'readnextline:',TRIM(cd_textexclusion),':',TRIM(cl_text)
    ENDDO

    il_lentrim=SCAN(TRIM(cl_text),cd_textexclusion)
    IF (il_lentrim==0) THEN
       readnextline=TRIM(cl_text)
    ELSE
       readnextline=cl_text(1:il_lentrim-1)
    ENDIF
    RETURN

    ! Modification FHZ: retour en erreur
10  CONTINUE
    id_err = -1
!!$print *, "error readnextline:unavailable txt format"
    RETURN
  END FUNCTION readnextline
! ------------------------------------------
!
END PROGRAM MCAL_SEAICE_STATS    
