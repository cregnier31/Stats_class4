!***********************************************************************
    PROGRAM Create_MaskBoite_stereo
!
! Ce programme permet de générer un mask de numéro de boite sur la grille de
! concentration de glace de mer du CERSAT. A chaque point de la grille est donc
! associé un numéro de boite.
!
!-----------------------------------------------------------------------
!
use netcdf
use MIOL
use MIOL_util
use boite
use table_boite
implicit none
!
character(len=255) :: cl_filename_mask_in, cl_filename_boite_in, cl_filename_maskboite_out
character(len=255) :: cd_macro_filename
character(len=255) :: cl_varname
real(kind=4), dimension(:,:), pointer :: rlpa_longitude, rlpa_latitude
integer, dimension(:,:,:), pointer :: ilpa_mask
integer, dimension(:,:), allocatable :: ila_mask
real(kind=4), dimension(:,:), allocatable :: rla_longitude, rla_latitude
integer, dimension(:,:), allocatable :: ila_mask_boite, ila_mask_macroboite
integer, dimension(3) :: ila_dimlen
integer :: jv_status, ii, jj, il_err, il_nbdim
real(kind=8) :: rl_lon, rl_lat, rl_idboite
integer, dimension(2) :: ila_dimlen2
integer, parameter :: il_nbatt=5
character(len=255), dimension(il_nbatt) :: cla_attname
character(len=255), dimension(il_nbatt) :: cla_attvalue
character(len=255), dimension(:), allocatable :: cla_dimname
integer :: il_file_id1, il_file_id2

integer(kind=4), parameter :: il_nb_max=6 ! nbre max de sous-boites pour 1 macro boite
integer, parameter :: il_macro_region_num_max=20
integer :: id_macro_region_num
character(len=80), dimension(il_macro_region_num_max) :: cda_macro_region_name
integer(kind=4), dimension(il_macro_region_num_max) :: ida_subregion_count
integer(kind=4), dimension(il_macro_region_num_max,il_nb_max+1) :: ida_macro_region_def
CHARACTER(LEN=26),DIMENSION(16)                     :: cla_var1D
!
!---------------------------------------------------------------------------------------
!                          ---  code  --- 
!---------------------------------------------------------------------------------------
! read input data
!----------------------------------------
cl_filename_mask_in = '/homelocal-px/px-137/cregnier/DATA/static/Poles/low_res/Stereopolar_ARC_msk.nc'
cl_filename_boite_in = '/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/src/aice/BOITE/Region_boite_global.txt'
cl_filename_maskboite_out = '/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/src/aice/BOITE/MaskBoite_stereo_ARC_new.nc'
cd_macro_filename=  '/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/src/aice/BOITE/MacroBoiteArctic.txt'
!
! read cersat sea ice mask sea (1) /land (0) 
      call miol_openr_file_nc(trim(cl_filename_mask_in), il_file_id1)
!
      cl_varname = 'longitude'
      call miol_read_field_nc(il_file_id1, trim(cl_varname), rlpa_longitude)
      cl_varname = 'latitude'
      call miol_read_field_nc(il_file_id1, trim(cl_varname), rlpa_latitude)
      cl_varname = 'mask'
      call miol_read_field_nc(il_file_id1, trim(cl_varname), ilpa_mask, ila_dimlen)
!
      call miol_close_file_nc(il_file_id1)
!
! read boxes coordinates
      print*, cl_filename_mask_in
      print*, cl_filename_boite_in
      print*, cl_filename_maskboite_out
      call LireDefBoite (cl_filename_boite_in ,jv_status)
!
! allocate local variables
!---------------------------------------------------
      allocate(ila_mask(ila_dimlen(1), ila_dimlen(2)))
      allocate(rla_latitude(ila_dimlen(1), ila_dimlen(2)), rla_longitude(ila_dimlen(1), ila_dimlen(2)))
      ila_mask=ilpa_mask(:,:,1)
      rla_longitude=rlpa_longitude
      rla_latitude=rlpa_latitude
      deallocate(rlpa_latitude, rlpa_longitude, ilpa_mask)
!
      allocate(ila_mask_boite(ila_dimlen(1), ila_dimlen(2)))
      allocate(ila_mask_macroboite(ila_dimlen(1), ila_dimlen(2)))
! initialisation
      ila_mask_boite=0
!
!
! mask for boxes
! -------------------------------------------------
      do ii=1, ila_dimlen(1)
      do jj=1, ila_dimlen(2)
         if (ila_mask(ii,jj) /= 0) then
            rl_lon=rla_longitude(ii,jj)
            rl_lat=rla_latitude(ii,jj)     
            call IdentifierBoite(rl_lon,rl_lat,rl_idboite,il_err)
            if (il_err /= -1) then
            ila_mask_boite(ii,jj)=int(rl_idboite)
            else
            stop 'IdentifierBoite : code erreur'
            endif
         endif
      end do
      end do
!
!init variables
      id_macro_region_num = 0
      cda_macro_region_name = ''
      ida_subregion_count = 0
      ida_macro_region_def = 0
      ila_mask_macroboite = 0
      call LireMacroBoite(cd_macro_filename, id_macro_region_num, cda_macro_region_name,  &
           ida_subregion_count, ida_macro_region_def, jv_status)
      
! Macro boxes Mask
      do ii=1, id_macro_region_num
      do jj=1, ida_subregion_count(ii)
         where(ila_mask_boite .EQ. ida_macro_region_def(ii,jj+1)) &
               ila_mask_macroboite = ida_macro_region_def(ii,1)
     enddo
     enddo
!
     deallocate(ila_mask_boite)
!
! write output file
! -------------------------------------------------
      cla_var1D(1)='North_pole_Fosse_oceanique'
      cla_var1D(2)='Queen_Elisabeth_Islands'
      cla_var1D(3)='Beaufort_Sea'
      cla_var1D(4)='Chuckchi_Sea'
      cla_var1D(5)='Siberian_Sea'
      cla_var1D(6)='Laptev_Sea'
      cla_var1D(7)='Kara_Sea'
      cla_var1D(8)='Barents_Sea'
      cla_var1D(9)='Greenland_Basin'
      cla_var1D(10)='Southeast_Greenland'
      cla_var1D(11)='Bafin_Bay'
      cla_var1D(12)='Hudson_Bay'
      cla_var1D(13)='Labrador_Sea'
      cla_var1D(14)='Bering_Sea'
      cla_var1D(15)='Okhotsk_Sea'
      cla_var1D(16)='Baltic_Sea'


      il_nbdim = 4
      allocate(cla_dimname(il_nbdim))
      cla_dimname(1) = 'x'
      cla_dimname(2) = 'y'
      cla_dimname(3) = 'regions'
      cla_dimname(4)=  'string_length'

      !
      ila_dimlen2(1) = ila_dimlen(1)
      ila_dimlen2(2) = ila_dimlen(2)
      ila_dimlen2(3) = 16
      ila_dimlen2(4) = 26
      call miol_create_file_nc(trim(cl_filename_maskboite_out), il_nbdim, cla_dimname, ila_dimlen2)
! 
      call miol_openw_file_nc(trim(cl_filename_maskboite_out), il_file_id2)
!
      cl_varname = 'mask'
      call miol_write_field_nc(il_file_id2, cl_varname, 'XY', ila_mask_macroboite)
!
      cl_varname = 'latitude'
      call miol_write_field_nc(il_file_id2, cl_varname, 'XY', rla_latitude)
!
      cl_varname = 'longitude'
      call miol_write_field_nc(il_file_id2, cl_varname, 'XY', rla_longitude)
      call MIOL_write_field_NC (il_file_id2,&
                                'Regions',&
                                'SM',&
                                 cla_var1D(:),&
                                 ila_dimlen2(3))

      !
      cl_varname='global'
      cla_attname(1)='CONVENTIONS'
      cla_attname(2)='LONG_NAME'
      cla_attname(3)='PRODUCER_AGENCY'
      cla_attname(4)='NETCDF_VERSION_ID'
      cla_attname(5)='GRID'
      cla_attvalue(1)='coards'
      cla_attvalue(2)='boxes mask for cersat cice grid, north pole, resolution 12.5km'
      cla_attvalue(3)='mercator'
      cla_attvalue(4)='3.4'
      cla_attvalue(5)='NSIDC'
      call miol_write_attributeslist_nc(il_file_id2, cl_varname, il_nbatt, cla_attname, cla_attvalue)
!      
      call miol_close_file_nc(il_file_id2)

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
!
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


END PROGRAM Create_MaskBoite_stereo

