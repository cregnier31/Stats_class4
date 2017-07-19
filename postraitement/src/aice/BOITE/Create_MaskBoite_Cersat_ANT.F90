!***********************************************************************
    PROGRAM Create_MaskBoite_Cersat_ANT
!
! Ce programme permet de générer un mask de numéro de boite sur la grille de
! concentration de glace de mer du CERSAT. A chaque point de la grille est donc
! associé un numéro de boite.
!
!-----------------------------------------------------------------------
!
use netcdf
USE Canvas
USE geomlibcha
USE MFT_error
use MIOL
use MCAL
implicit none
!
character(len=255) :: cl_filename_mask_in, cl_filename_boite_in, cl_filename_maskboite_out
character(len=255) :: cd_macro_filename
character(len=255) :: cl_varname,cl_filename_in,cl_mask
real(kind=4), dimension(:,:), pointer :: rlpa_longitude, rlpa_latitude
integer, dimension(:,:,:), pointer :: ilpa_mask
integer(KIND=1), dimension(:,:,:), pointer :: ilpa_areas
INTEGER, DIMENSION(:,:,:), POINTER  :: ilpa_mask_mod 
INTEGER, DIMENSION(:,:),POINTER     :: ilpa_kanvas
INTEGER, DIMENSION(:),POINTER       :: ilpa_igrd,ilpa_jgrd
REAL(KIND=4), DIMENSION(:,:), POINTER    :: rlpa_gridlatvalue, &
                                            rlpa_gridlonvalue
INTEGER, DIMENSION(4)               :: ila_vertxindex,ila_vertyindex,vertex
REAL(KIND=4), DIMENSION(4)          :: rla_poids_vertex
integer, dimension(:,:), allocatable :: ila_mask,ila_mask1
real(kind=4), dimension(:,:), allocatable :: rla_longitude, rla_latitude
integer, dimension(:,:), allocatable :: ila_mask_boite
integer, dimension(3) :: ila_dimlen
integer :: jv_status, ii, jj, il_err, il_nbdim
real(kind=4) :: rl_lon, rl_lat
INTEGER(KIND=4),DIMENSION (2) :: ila_dimlen2
integer, dimension(3) :: ila_dimlen3D
integer, parameter :: il_nbatt=5
character(len=255), dimension(il_nbatt) :: cla_attname
character(len=255), dimension(il_nbatt) :: cla_attvalue
character(len=255), dimension(:), allocatable :: cla_dimname
integer :: il_file_id1, il_file_id2,il_file_id,SWnode
integer(kind=4), dimension(1) :: il_valeur_max
integer(kind=4), parameter :: il_nb_max=6 ! nbre max de sous-boites pour 1 macro boite
integer, parameter :: il_macro_region_num_max=20
integer :: id_macro_region_num,il_i
character(len=80), dimension(il_macro_region_num_max) :: cda_macro_region_name
integer(kind=4), dimension(il_macro_region_num_max) :: ida_subregion_count
integer(kind=4), dimension(il_macro_region_num_max,il_nb_max+1) :: ida_macro_region_def
LOGICAL,DIMENSION(4)                      :: lla_nbr_vertex

!
!---------------------------------------------------------------------------------------
!                          ---  code  --- 
!---------------------------------------------------------------------------------------
! read input data
!----------------------------------------
cl_filename_mask_in = '/home/qualif/SEAICE/BOITE/MASK_SIC_ANT_CERSAT.nc'
cl_filename_boite_in = '/home/qualif/SEAICE/BOITE/Region_boite_global.txt'
cl_filename_maskboite_out = '/home/qualif/SEAICE/BOITE/MaskBoite_SIC_ANT_CERSAT.nc'
cl_filename_in='/home/qualif/SEAICE/BOITE/zones_ice_orca025.nc'
cl_mask='/homelocal-px/px-130/cregnier/DATA_SGPS/static/init_grid/PSY3V3R1_T_origin.nc'
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
       call miol_openr_file_nc(trim(cl_filename_in), il_file_id1)
       cl_varname = 'areas'
       call miol_read_field_nc(il_file_id1,trim(cl_varname),ilpa_areas,ila_dimlen3D)
       call miol_close_file_nc(il_file_id1)

!** masque modèle
     cl_varname = 'mask'
     WRITE(0,*) ' lecture du mask ...'
     CALL MIOL_openr_file_NC(cl_mask, il_file_id)
     CALL MIOL_read_field_NC(il_file_id, &
                            cl_varname, &
                            ilpa_mask_mod,&
                            ila_dimlen3D)
     PRINT *,'Dimensions :: ',ila_dimlen3D(1),ila_dimlen3D(2)
     ALLOCATE(ila_mask1(ila_dimlen3D(1),ila_dimlen3D(2)))
     !*
     PRINT *,'Read lon'
     cl_varname='longitude'
     CALL MIOL_read_field_NC(il_file_id, &
                             cl_varname, &
                             rlpa_gridlonvalue)
     PRINT *,'Read lat'
     cl_varname='latitude'
     CALL MIOL_read_field_NC(il_file_id, &
                             cl_varname, &
                             rlpa_gridlatvalue)

     !* Masque en surface
     ila_mask1=ilpa_mask_mod(:,:,1)
     DEALLOCATE(ilpa_mask_mod)
     !** Generation du canevas
     print *,'Generation  Canevas '
     CALL GenereCanvas(ila_mask1(:,:),ilpa_kanvas,ilpa_igrd,ilpa_jgrd)
     print *,'Generation  Canevas ok '
     IF (ALLOCATED(ila_mask1)) DEALLOCATE(ila_mask1)

! read boxes coordinates
      print*, cl_filename_mask_in
      print*, cl_filename_boite_in
      print*, cl_filename_maskboite_out
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

! initialisation
      ila_mask_boite=0
!
!
! mask for boxes
! -------------------------------------------------
      do ii=1, ila_dimlen(1)
         do jj=1, ila_dimlen(2)
            lla_nbr_vertex(:)=.FALSE.
            rl_lon=rla_longitude(ii,jj)
            rl_lat=rla_latitude(ii,jj)
            CALL getSWnode_orca_grid(rl_lon,&
                                     rl_lat,&
                                     rlpa_gridlonvalue(:,:), &
                                     rlpa_gridlatvalue(:,:), &
                                     ilpa_kanvas(:,:),&
                                     ilpa_igrd(:),&
                                     ilpa_jgrd(:),&
                                     ila_dimlen3D(1), &
                                     ila_dimlen3D(2), &
                                     SWnode,&
                                     vertex)
             ila_vertxindex(:)=9999
             ila_vertyindex(:)=9999
             rla_poids_vertex(:)=0.0
             IF (ANY (vertex(1:4) /=0) ) THEN
                    WHERE(vertex(:) /=0)
                       lla_nbr_vertex= .TRUE.
                       ila_vertxindex(:)=ilpa_igrd(vertex(:))
                       ila_vertyindex(:)=ilpa_jgrd(vertex(:))
                    ELSEWHERE
                       ila_vertxindex(:)=9999
                       ila_vertyindex(:)=9999
                       lla_nbr_vertex(:)=.FALSE. 
                    ENDWHERE
                   !PRINT *,'vertex :: ',vertex
                   !PRINT *,'Lon ,alt  :: ',rl_lon,rl_lat
                   !PRINT *,'ila_vertxindex ::' ,ila_vertxindex(:)
                   !PRINT *,'ila_vertyindex ::' ,ila_vertyindex(:)
                   !PRINT *,'Lon ::',rlpa_gridlonvalue(ila_vertxindex(:),ila_vertyindex(:))
                   !PRINT *,'Lat ::',rlpa_gridlatvalue(ila_vertxindex(:),ila_vertyindex(:))
                   CALL MCAL_IDW(rl_lon,&
                                 rl_lat, &
                                 rlpa_gridlonvalue(:,:), &
                                 rlpa_gridlatvalue(:,:), &
                                 rla_poids_vertex(:),&
                                 ila_dimlen3D(1), &
                                 ila_dimlen3D(2), &
                                 ila_vertxindex(:),&
                                 ila_vertyindex(:),&
                                 lla_nbr_vertex(:))
                    il_valeur_max=MAXLOC(rla_poids_vertex(:),mask=rla_poids_vertex(:) .NE. 9999.0 )
                   ! PRINT *,'valeur max::',il_valeur_max(1),ila_vertxindex(il_valeur_max(1)),ila_vertyindex(il_valeur_max(1))
                    ila_mask_boite(ii,jj)=ilpa_areas(ila_vertxindex(il_valeur_max(1)),ila_vertyindex(il_valeur_max(1)),1)              
             ELSE
                   ! WRITE(0,*) 'Les 4 points se situent sur la terre!!'
                   ! print *,'Valeur nulle'
                    ila_mask_boite(ii,jj)=0 
             ENDIF

         enddo
         PRINT *,'ii ila_dimlen(1)',ii,ila_dimlen(1)
     enddo
!
!
! write output file
! -------------------------------------------------
      il_nbdim = 2
      allocate(cla_dimname(il_nbdim))
      cla_dimname(1) = 'x'
      cla_dimname(2) = 'y'
!
      ila_dimlen2(1) = ila_dimlen(1)
      ila_dimlen2(2) = ila_dimlen(2)
      call miol_create_file_nc(trim(cl_filename_maskboite_out), il_nbdim, cla_dimname, ila_dimlen2)
! 
      call miol_openw_file_nc(trim(cl_filename_maskboite_out), il_file_id2)
!
      cl_varname = 'mask'
      call miol_write_field_nc(il_file_id2, cl_varname, 'XY', ila_mask_boite )
      deallocate(ila_mask_boite)
!
      cl_varname = 'latitude'
      call miol_write_field_nc(il_file_id2, cl_varname, 'XY', rla_latitude)
!
      cl_varname = 'longitude'
      call miol_write_field_nc(il_file_id2, cl_varname, 'XY', rla_longitude)
!
      cl_varname='global'
      cla_attname(1)='CONVENTIONS'
      cla_attname(2)='LONG_NAME'
      cla_attname(3)='PRODUCER_AGENCY'
      cla_attname(4)='NETCDF_VERSION_ID'
      cla_attname(5)='GRID'
      cla_attvalue(1)='coards'
      cla_attvalue(2)='boxes mask for cersat cice grid, south pole, resolution 12.5km'
      cla_attvalue(3)='mercator'
      cla_attvalue(4)='3.4'
      cla_attvalue(5)='NSIDC'
      call miol_write_attributeslist_nc(il_file_id2, cl_varname, il_nbatt, cla_attname, cla_attvalue)
!      
      call miol_close_file_nc(il_file_id2)

!
!
END PROGRAM Create_MaskBoite_Cersat_ANT

