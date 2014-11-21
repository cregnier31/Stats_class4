!******************************************************************************
!
PROGRAM COLOCALIZE
  !!==============================================================================================================
  !> \brief    Description : Ce programme permet de colocaliser le position données in situ sur la grille modèle choisie
  !!  Il est utilisé pour la génération de fichiers MERSEA class4 contenant des donnees de températures et de salinité 
  !!  1) Collocalisation des profils sur la grille modèle adéquate grâce à une technique de dichotomie ou bien de recherche en spirale si
  !!     le point n'a pas été trouvé (exemple vers l'arctique ou la grille est tordue)
  !!  2) Calcul des poids associés à chacun des 4 points de la grille par la technique de l'inverse de la distance (IDW)
  !!  3) Ecriture des 4 points de grille entourant le point colocalisé dans la grille ainsi leurs poids associés
  !!
  !! History :
  !!        \n 10/2007      (F.MESSAL)  Creation du programme
  !!        \n 04/2008     (C.REGNIER)  grosses modification sur le code => passage operationnel
  !!        \n 02/2009     (C.REGNIER)  creation d'un nouveau pgr à partir du
  !!                                    pgr qui tourne en operationnel =>
  !!                                    changement majeur :: implémentation du
  !!                                    nouveau module de colloc optimisé
  !!        \n 03/03/2009  (C.REGNIER)  Ajout d'un argument pour indiquer la
  !!                                    config GLORYS => lecture tmask                 
  !!        \n 03/17/2009   (C.REGNIER) Version stable pour le calcul des class4
  !!                                    avec GLORYS sur CORA02
  !!        \n 03/26/2009   (C.REGNIER) Version CE pour NEATL  
  !!        \n 13/12/2013   (C.REGNIER) Modifications pour la lecture du masque d'entrée  
  !!        \n 06/06/2014   (C.REGNIER) Modifications pour lire un fichier de positions lon,lat et sortir le point de plus proche ainsi que sa distance                          !<
  !===================================================================================================================
  !
  USE Canvas
  USE netcdf
  USE Inf_NaN_Detection
  USE geomlibcha
  USE MCAL
  USE MIOL 
  USE MFT_error
  IMPLICIT NONE
  !
  !
  INTEGER                              :: il_narg, &
                                          iargc, &
                                          il_ji, &
                                          il_file_id, &
                                          il_nbdim, &
                                          il_nprof, &
                                          il_ndepth, &
                                          il_nlon, &
                                          il_nlat,&
                                          il_status,&
                                          il_jk,SWnode,il_tot,&
                                          il_fic,il_type,il_nbdim2,&
                                          il_error,il_varid,eof,eofbis,il_l,&
                                          il_nb_files,il_len
  INTEGER, DIMENSION(1)               ::  il_loc
  INTEGER, DIMENSION(4)               :: ila_vertxindex,ila_vertyindex,&
                                         vertex,ila_nbdim4D
  INTEGER, DIMENSION(3)               :: ila_nbdim3D
  INTEGER, DIMENSION(:), POINTER      :: ilpa_dimlen
  INTEGER, DIMENSION(:),POINTER       :: ilpa_igrd,ilpa_jgrd
  INTEGER, DIMENSION(:,:),POINTER     :: ilpa_kanvas
  INTEGER, DIMENSION(:,:,:), POINTER  :: ilpa_mask
  INTEGER(KIND=2), DIMENSION(:,:,:,:), POINTER :: ilpa_maskI2_4D
  INTEGER(KIND=2), DIMENSION(:,:,:), POINTER  :: ilpa_maskI2
  INTEGER(KIND=1), DIMENSION(:,:,:,:), POINTER  :: ilpa_maskI1_4D
  INTEGER(KIND=1), DIMENSION(:,:,:), POINTER    :: ilpa_maskI1_3D
  INTEGER, DIMENSION(:,:),ALLOCATABLE :: ila_mask,ila_xindex,ila_yindex
  INTEGER, DIMENSION(:),ALLOCATABLE   :: ila_findxindex,ila_findyindex
  REAL(KIND=4),DIMENSION(:),ALLOCATABLE  :: rla_findlon,rla_findlat,rla_finddist
  
  REAL(KIND=4),DIMENSION(:,:,:,:), POINTER   :: rlpa_mask_4D
  REAL(KIND=4),DIMENSION(:,:,:), POINTER     :: rlpa_mask_3D
  REAL(KIND=8), DIMENSION(:), POINTER      :: rlpa_colatvalue_R8, &
                                              rlpa_colonvalue_R8
  REAL(KIND=4), DIMENSION(:,:), POINTER    :: rlpa_gridlatvalue, &
                                              rlpa_gridlonvalue
  REAL(KIND=4), DIMENSION(:), ALLOCATABLE  :: rla_lonpos, &
                                              rla_latpos
  REAL,DIMENSION(:,:),ALLOCATABLE          :: rla_poids

  REAL(KIND=4), DIMENSION(4)               :: rla_poids_vertex,rla_dist_vertex
  REAL(KIND=4) :: rl_lonmin, &
                  rl_lonmax, &
                  rl_latmin, &
                  rl_latmax, &
                  rl_colonvalue, &
                  rl_colatvalue, &
                  rl_juld
 
  CHARACTER(LEN=1), DIMENSION(:), POINTER :: clpa_positionqcvalue
  CHARACTER(LEN=255) :: cl_input, &
                        cl_inputFile, &
                        cl_colocFile, &
                        cl_gridFile, &
                        cl_varname, &
                        cl_positionqc, &
                        cl_resFile,&
                        cl_tmp,&
                        cl_conf,cl_mask,&
                        cl_var
  CHARACTER(LEN=255), DIMENSION(:), POINTER :: clpa_dimname
 !optionnel
  LOGICAL :: ll_exist,ll_exist_grid,ll_lat,ll_lon,ll_mask
  LOGICAL,DIMENSION(4)                      :: lla_nbr_vertex
  CHARACTER(LEN=26)     ::   cl_fread                                                                                                                    
  DATA  cl_fread    /'(f12.5,2x,f12.5,2x,f12.5)'/

  !
  !------------------------------------------------------------------------
  ! Lecture arguments
  !
  il_narg=iargc()
  IF (il_narg.NE.8) THEN
     PRINT *,' '  
     PRINT *,' create_colocfile usage : '
     PRINT *,'     create_colocfile -i profile.nc ', &
          ' -g grid.nc -r namelist -c config' 
     PRINT *,' '
     PRINT *,' -g gridfile.nc     : The grid to localize on (-g Grid)'
     PRINT *,' -r namelist   :  path of data, path of colloc, nb_files'
     PRINT *,' -c config name        '
     STOP
  ELSE
     DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-g') THEN
           CALL getarg(il_ji+1, cl_gridFile)
        ELSE IF (cl_input .EQ. '-r') THEN
           CALL getarg(il_ji+1, cl_resFile)
        ELSE IF (cl_input .EQ. '-c ') THEN
           CALL getarg(il_ji+1, cl_conf)
        ELSE IF (cl_input .EQ. '-m ') THEN
           CALL getarg(il_ji+1, cl_mask)
        ENDIF
     ENDDO
  ENDIF
  !
  !
  !
  il_tot=0
  ll_exist=.FALSE. 
  ll_exist_grid=.FALSE.
  !------------------------------------------------------------------------
  ! Lecture du fichier contenant les positions 
  !
#if defined key_debug
  WRITE(0,*) 'Lecture du fichier contenant les positions',cl_resFile
#endif
  CALL MIOL_getFreeLU(il_fic)
!  OPEN(il_fic, file=TRIM(cl_resFile), &
!       status='old', &
!       form='formatted')
!
  eofbis=0
  eof=0
  OPEN(il_fic, file=TRIM(cl_resFile), &
        status='old', &
        form='formatted', &
        iostat=il_error)

  IF (il_error/=0) then
      WRITE (0,*) "Impossible d ouvrir le fichier ",trim(cl_resFile)
      STOP
  ENDIF
  il_l=0

  !** On compte le nombre de lignes du fichier

  DO WHILE (eof == 0 )
      READ(il_fic,*,iostat=eof) cl_var
      IF (eof==0) then !* la lecture s'est bien passee
         !* on incremente le compteur du nombre de lignes
         il_l=il_l+1
      ENDIF
  ENDDO
  CLOSE(il_fic)
#if defined key_debug
  WRITE(0,*) 'Nombre d enregistrements : ',il_l
#endif
  !** Nombre de fichiers à traiter
  il_nb_files=il_l

  !** Recuperation de la longueur de l'enregistrement
  CALL MIOL_getFreeLU(il_fic)

  OPEN(il_fic, file=TRIM(cl_resFile), &
         status='old', &
         form='formatted', &
         iostat=il_error)
   !** ALLOCATION
   il_ji=1
   ALLOCATE(rla_lonpos(il_nb_files))
   ALLOCATE(rla_latpos(il_nb_files))
   DO WHILE (eofbis == 0 )
       READ(il_fic,fmt=cl_fread,iostat=eofbis) &
         rl_colonvalue,rl_colatvalue,rl_juld
       IF (eofbis==0 .AND. il_ji/=0 ) THEN
          rla_lonpos(il_ji)=rl_colonvalue
          rla_latpos(il_ji)=rl_colatvalue
          il_ji=il_ji+1
       ENDIF
    ENDDO
    CLOSE(il_fic)
  !* Lecture de la grille modele
  ! chargement de la longitude, de la latitude et de la depth
#if defined key_debug
  WRITE(0,*) 'Longitude :: ',rla_lonpos
  WRITE(0,*) 'Latitude :: ',rla_latpos
  WRITE(0,*) ' lecture du fichier grillé ', TRIM(cl_gridFile)
  WRITE(0,*) 'Read dimension'
#endif
  INQUIRE (FILE=TRIM(cl_gridFile), EXIST=ll_exist_grid)
  IF ( ll_exist_grid ) THEN
     WRITE(0,*) 'File exist'
     CALL MIOL_openr_file_NC(TRIM(cl_gridFile), il_file_id)
     WRITE(0,*) 'File exist ok'
#if defined key_debug
  WRITE(0,*) 'Open OK'
#endif
  CALL MIOL_inquire_dimensions_NC(il_file_id, &
                                  il_nbdim, &
                                  clpa_dimname, &
                                  ilpa_dimlen)
  ELSE
     WRITE(0,*) 'File doesn t exist'
     STOP
  ENDIF
#if defined key_debug
  WRITE(0,*) 'Dimensions ::',ilpa_dimlen
#endif
  DO il_ji=1, il_nbdim
     IF (TRIM(clpa_dimname(il_ji)).EQ.'deptht' .OR. &
          TRIM(clpa_dimname(il_ji)).EQ.'depthu' .OR. &
          TRIM(clpa_dimname(il_ji)).EQ.'depthv'.OR. &
          TRIM(clpa_dimname(il_ji)).EQ.'depth'.OR. & 
          TRIM(clpa_dimname(il_ji)).EQ.'z') THEN
        il_ndepth = ilpa_dimlen(il_ji)
     ENDIF
     IF (TRIM(clpa_dimname(il_ji)).EQ.'x') THEN
        il_nlon = ilpa_dimlen(il_ji)
     ENDIF
     IF (TRIM(clpa_dimname(il_ji)).EQ.'y') THEN
        il_nlat = ilpa_dimlen(il_ji)
     ENDIF
  ENDDO
  !** 
  ! Recherche du nom et du type de la variable latitude
  cl_varname = 'nav_lat'
  CALL MIOL_inquire_type_NC(il_file_id, &
                            cl_varname ,&
                            il_type,&
                            il_nbdim,&
                            ll_lat)
  IF ( .NOT. ll_lat ) THEN
      cl_varname = 'latitude'
      CALL MIOL_inquire_type_NC(il_file_id, &
                                cl_varname ,&
                                il_type,&
                                il_nbdim,&
                                ll_lat)
      IF ( .NOT. ll_lat ) THEN
        WRITE(0,*) 'Warning : nav_lat or latitude not find in grid file'
        STOP
      ENDIF
   ENDIF
   CALL MIOL_read_field_NC(il_file_id, &
                           cl_varname, &
                           rlpa_gridlatvalue)
  rl_latmin = MINVAL(rlpa_gridlatvalue)
  rl_latmax = MAXVAL(rlpa_gridlatvalue)
  ! Recherche du nom et du type de la variable longitude
  cl_varname = 'nav_lon'
  CALL MIOL_inquire_type_NC(il_file_id, &
                            cl_varname ,&
                            il_type,&
                            il_nbdim,&
                            ll_lon)
  IF ( .NOT. ll_lon ) THEN
      cl_varname = 'longitude'
      CALL MIOL_inquire_type_NC(il_file_id, &
                                cl_varname ,&
                                il_type,&
                                il_nbdim,&
                                ll_lon)
      IF ( .NOT. ll_lon ) THEN
        WRITE(0,*) 'Warning : nav_lon or longitude not find in grid file'
        STOP
      ENDIF
  ENDIF
  CALL MIOL_read_field_NC(il_file_id, &
                          cl_varname, &
                          rlpa_gridlonvalue)
  rl_lonmin = MINVAL(rlpa_gridlonvalue)
  rl_lonmax = MAXVAL(rlpa_gridlonvalue)

  !* Lecture du mask
  cl_varname = cl_mask
  CALL MIOL_inquire_type_NC(il_file_id, &
                            cl_varname ,&
                            il_type,&
                            il_nbdim,&
                            ll_mask)
  IF (ll_mask) THEN 
#if defined key_debug
     WRITE(0,*) ' lecture du mask ...',cl_varname
#endif
    SELECT CASE (il_nbdim)
    CASE (4)
        SELECT CASE (il_type)
           CASE (NF90_FLOAT)
#if defined key_debug
      WRITE(0,*) 'Lecture en FLOAT'
#endif
             CALL MIOL_read_field_NC(il_file_id, &
                                     cl_varname, &
                                     rlpa_mask_4D)
             ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
             ila_mask=INT(rlpa_mask_4D(:,:,1,1))
             DEALLOCATE(rlpa_mask_4D)
      CASE (NF90_SHORT)
#if defined key_debug
      WRITE(0,*) 'Lecture en short'
#endif
             CALL MIOL_read_field_NC(il_file_id, &
                                     cl_varname, &
                                     ilpa_maskI2_4D,&
                                     ila_nbdim4D,&
                                     rlpa_mask_4D)
#if defined key_debug
      WRITE(0,*) 'Lecture OK'
#endif
             DEALLOCATE (rlpa_mask_4D) 
             ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
             ila_mask=ilpa_maskI2_4D(:,:,1,1)
             DEALLOCATE(ilpa_maskI2_4D) 
      
      CASE (NF90_BYTE)
#if defined key_debug
      WRITE(0,*) 'Lecture en Byte'
#endif
             CALL MIOL_read_field_NC(il_file_id, &
                                     cl_varname, &
                                     ilpa_maskI1_4D)
#if defined key_debug
      WRITE(0,*) 'Lecture OK'
#endif
             ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
             ila_mask=ilpa_maskI1_4D(:,:,1,1)
             DEALLOCATE(ilpa_maskI1_4D) 
      CASE default
          WRITE(0,*) 'Type non reconnu'
          STOP
      ENDSELECT


    CASE (3)
      SELECT CASE (il_type)
      CASE (NF90_FLOAT)
#if defined key_debug
      WRITE(0,*) 'Lecture en FLOAT'
#endif
          CALL MIOL_read_field_NC(il_file_id, &
                                  cl_varname, &
                                  rlpa_mask_3D)
          ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
          ila_mask=INT(rlpa_mask_3D(:,:,1))
          DEALLOCATE(rlpa_mask_3D)
      CASE (NF90_SHORT)
#if defined key_debug
      WRITE(0,*) 'Lecture en short'
#endif
          CALL MIOL_read_field_NC(il_file_id, &
                                  cl_varname, &
                                  ilpa_maskI2,&
                                  ila_nbdim3D,&
                                  rlpa_mask_3D)
#if defined key_debug
      WRITE(0,*) 'Lecture OK'
#endif
          DEALLOCATE (rlpa_mask_3D) 
          ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
          ila_mask=ilpa_maskI2(:,:,1)
          DEALLOCATE(ilpa_maskI2) 
      CASE (NF90_BYTE)
#if defined key_debug
      WRITE(0,*) 'Lecture en Byte'
#endif
          CALL MIOL_read_field_NC(il_file_id, &
                                  cl_varname, &
                                  ilpa_maskI1_3D)
#if defined key_debug
      WRITE(0,*) 'Lecture OK'
#endif
          ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
          ila_mask=ilpa_maskI1_3D(:,:,1)
          DEALLOCATE(ilpa_maskI1_3D) 
      CASE(NF90_INT)
#if defined key_debug
      WRITE(0,*) 'Lecture en Integer'
#endif
          CALL MIOL_read_field_NC(il_file_id, &
                                  cl_varname, &
                                  ilpa_mask)
          ALLOCATE(ila_mask(1:il_nlon,1:il_nlat))
          ila_mask(:,:)=0
          ila_mask=ilpa_mask(:,:,1)
          DEALLOCATE(ilpa_mask)
      CASE default
          WRITE(0,*) 'Type non reconnu'
          STOP
      ENDSELECT
    CASE default
          WRITE(0,*) 'Dimension non prise en compte :: ',il_nbdim
          STOP
    ENDSELECT
#if defined key_debug
    WRITE(0,*) 'Read mask ok'
#endif
   CALL MIOL_close_file_NC(il_file_id)
#if defined key_debug
    WRITE(0,*) ' Fin de lecture '
#endif
  ELSE 
      WRITE(0,*) 'Mask not Found'
      STOP
  ENDIF
  !** Generation du canevas
  CALL GenereCanvas(ila_mask(:,:),ilpa_kanvas,ilpa_igrd,ilpa_jgrd)
#if defined key_debug
    WRITE(0,*) 'Generation  Canevas ok '
#endif
  IF (ALLOCATED(ila_mask)) DEALLOCATE(ila_mask)
  il_len=len_trim(cl_resFile)
  cl_colocFile=TRIM(cl_resFile(1:il_len-3))//'dat'
#if defined key_debug
        WRITE (0,*) "Fichier de colloc :: ",cl_colocFile
#endif

  INQUIRE (FILE=cl_colocFile, EXIST=ll_exist)
  IF (ll_exist.EQV..FALSE.) THEN
    !* Allocation des indices et des poids
    ALLOCATE(ila_xindex(4,il_nb_files))
    ALLOCATE(ila_yindex(4,il_nb_files))
    ALLOCATE(rla_poids(4,il_nb_files))
    ALLOCATE(ila_findxindex(il_nb_files))
    ALLOCATE(ila_findyindex(il_nb_files))
    ALLOCATE(rla_findlon(il_nb_files))
    ALLOCATE(rla_findlat(il_nb_files))
    ALLOCATE(rla_finddist(il_nb_files))
    !* Initialisation
    ila_findxindex(:)=9999.
    ila_findyindex(:)=9999.
    rla_findlon(:)=9999.
    rla_findlat(:)=9999.
    rla_finddist(:)=0.
    rla_poids(4,:)=0.
    !
    !
    !* Lecture des positions
    !
    DO il_jk=1,il_nb_files
#if defined key_debug
          WRITE(0,*) ' nombre de profils : ', il_nb_files
#endif
             IF ( rla_lonpos(il_jk) > 180.0) rla_lonpos(il_jk)=rla_lonpos(il_jk)-360.
             !
             !---------------------------------------------------------------
             ! co-localisation spatiale
             ila_xindex(1:4,il_jk) = 9999
             ila_yindex(1:4,il_jk) = 9999
  !!           !
             IF ( rla_lonpos(il_jk) .EQ. 0 .AND. rla_latpos(il_jk) .EQ. 0 ) THEN 
  		 rla_lonpos(il_jk)=9999.0
  		 rla_latpos(il_jk)=9999.0
             ENDIF
             IF ((rla_lonpos(il_jk) .GE. rl_lonmin) .AND. &
                  (rla_lonpos(il_jk) .LE. rl_lonmax) .AND. &
                  (rla_latpos(il_jk) .GE. rl_latmin) .AND. &
                  (rla_latpos(il_jk) .LE. rl_latmax)) THEN
                   CALL getSWnode_orca_grid(rla_lonpos(il_jk),&
                        rla_latpos(il_jk),&
                        rlpa_gridlonvalue(:,:), &
                        rlpa_gridlatvalue(:,:), &
                        ilpa_kanvas(:,:),&
                        ilpa_igrd(:),&
                        ilpa_jgrd(:),&
                        il_nlon, &
                        il_nlat, &
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
#if defined key_debug
                      WRITE (0,*) "Nb lon Nb lat:: ",il_nlon,il_nlat
                      WRITE (0,*) "Profile :: ",il_jk
                      WRITE (0,*) "Position lon lat:: ",rla_lonpos(il_jk),rla_latpos(il_jk)
                      WRITE (0,*) "Valeurs vertxindex ::",ila_vertxindex(:)
                      WRITE (0,*) "Valeurs vertyindex ::",ila_vertyindex(:)
#endif
                      CALL MCAL_IDW(rla_lonpos(il_jk),&
                           rla_latpos(il_jk), &
                           rlpa_gridlonvalue(:,:), &
                           rlpa_gridlatvalue(:,:), &
                           rla_poids_vertex(:),&
                           il_nlon, &
                           il_nlat, &
                           ila_vertxindex(:),&
                           ila_vertyindex(:),&
                           lla_nbr_vertex(:),&
                           rla_dist_vertex(:))
  		      IF ( SUM(rla_poids_vertex(:)) > 1.01 ) THEN
  		           WRITE(0,*) 'Somme des poids > 1 :: ',SUM(rla_poids_vertex(:))
  		           WRITE(0,*) 'Valeur des vertex en x :: ',ila_vertxindex(:)
  		           WRITE(0,*) 'Valeur des vertex en y :: ',ila_vertyindex(:)
  		           WRITE(0,*) 'nombre de vextex :: ',lla_nbr_vertex(:)
  		           WRITE(0,*) 'position du point :: ',rla_lonpos(il_jk),rla_latpos(il_jk)
  		           STOP
  		      ! ELSE
  		      !     WRITE(0,*) 'nombre de vextex :: ',lla_nbr_vertex(:)
                      !     WRITE(0,*) 'poids associés :: ',rla_poids_vertex(:)
                      !     WRITE(0,*) 'distance associés :: ',rla_dist_vertex(:)
                      !     WRITE(0,*) 'Somme des poids associés :: ',SUM(rla_poids_vertex(:))
  		      ENDIF
                      il_loc=MAXLOC(rla_poids_vertex(:))
                      ila_findxindex(il_jk)=ila_vertxindex(il_loc(1))
                      ila_findyindex(il_jk)=ila_vertyindex(il_loc(1))
                      rla_findlon(il_jk)=rlpa_gridlonvalue(ila_vertxindex(il_loc(1)),ila_vertyindex(il_loc(1)))
                      rla_findlat(il_jk)=rlpa_gridlatvalue(ila_vertxindex(il_loc(1)),ila_vertyindex(il_loc(1)))
                      rla_finddist(il_jk)=rla_dist_vertex(il_loc(1))
                      ila_xindex(:,il_jk)=ila_vertxindex(:)
                      ila_yindex(:,il_jk)=ila_vertyindex(:)
                   ELSE
#if defined key_debug
  		      WRITE(0,*) 'position du point :: ',rla_lonpos(il_jk),rla_latpos(il_jk)
                      WRITE(0,*) 'Les 4 points se situent sur la terre!!'
                      WRITE(0,*) 'Valeur nulle'
#endif
                      rla_poids_vertex(:)=0.0
                   ENDIF
                   rla_poids(:,il_jk)=rla_poids_vertex(:)                   
#if defined key_debug
                   WRITE (0,*) 'Position du point le plus proche ::',ila_vertxindex(il_loc(1)),ila_vertyindex(il_loc(1))
                   WRITE (0,*) 'Poids le plus proche ::',rla_poids_vertex(il_loc(1))
                   WRITE (0,*) 'Distance la plus proche ::',rla_dist_vertex(il_loc(1))
#endif
             ELSE	
                !** When the file is not into the grid
#if defined key_debug
               WRITE(0,*) 'Not in the grid'
#endif
               ila_xindex(:,il_jk)=9999
               ila_yindex(:,il_jk)=9999
               rla_poids(:,il_jk)=0.0       		
             ENDIF   ! rla_colonvalue(il_ji) .GE. rl_lonmin ...
    ENDDO !il_nb_files
  ! Ecriture Position la plus proche
    CALL MIOL_getFreeLU(il_fic)
    OPEN(il_fic, file=TRIM(cl_colocFile), &
              status='new', &
              form='formatted')
             ! form='unformatted')

    !!* Case write with format
    DO il_ji=1,il_nb_files
    !!   WRITE(il_fic,'(i6,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,f12.9)',ADVANCE='yes') &
    !!         il_ji, rla_lonpos(il_ji),&
    !!         rla_latpos(il_ji),ila_xindex(1,il_ji),&
    !!         ila_yindex(1,il_ji),rla_poids(1,il_ji),&
    !!         ila_xindex(2,il_ji), ila_yindex(2,il_ji),rla_poids(2,il_ji),&
    !!         ila_xindex(3,il_ji), ila_yindex(3,il_ji),rla_poids(3,il_ji),&
    !!         ila_xindex(4,il_ji), ila_yindex(4,il_ji),rla_poids(4,il_ji)
    !!* Case write with unformatted format
!       WRITE(il_fic) il_ji, rla_lonpos(il_ji), rla_latpos(il_ji), &
       WRITE(il_fic,'(i6,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,&
                      f12.9,2x,i6,2x,i6,2x,f12.9,2x,i6,2x,i6,2x,&
                      f12.9,2x,i6,2x,i6,2x,f12.9,2x,f12.5,2x,f12.5)',ADVANCE='yes') &
                       il_ji, rla_lonpos(il_ji), rla_latpos(il_ji), &
           ila_xindex(1,il_ji), ila_yindex(1,il_ji),rla_poids(1,il_ji),&
           ila_xindex(2,il_ji), ila_yindex(2,il_ji),rla_poids(2,il_ji),&
           ila_xindex(3,il_ji), ila_yindex(3,il_ji),rla_poids(3,il_ji),&
           ila_xindex(4,il_ji), ila_yindex(4,il_ji),rla_poids(4,il_ji),&
           rla_findlon(il_ji),rla_findlat(il_ji)
    ENDDO

!! Case de test
!!
!!    DO il_ji=1,il_nb_files
!!       WRITE(il_fic,'(i6,2x,f12.5,2x,f12.5,2x,i6,2x,i6,2x,f12.5,2x,f12.5,2x,f12.9)',ADVANCE='yes') &
!!                     il_ji, rla_lonpos(il_ji), rla_latpos(il_ji), &
!!                     ila_findxindex(il_ji),ila_findyindex(il_ji),&
!!                     rla_findlon(il_ji),rla_findlat(il_ji),&
!!                     rla_finddist(il_ji)
!!       !WRITE(il_fic) il_ji, rla_lonpos(il_ji), rla_latpos(il_ji), &
!!       !              ila_findxindex(il_ji),ila_findyindex(il_ji),&
!!       !              rla_findlon(il_ji),rla_findlat(il_ji),&
!!       !              rla_finddist(il_ji)
!!    ENDDO
!! Case de test
    CLOSE(il_fic)
    IF (ALLOCATED(rla_latpos))  DEALLOCATE(rla_latpos)
    IF (ALLOCATED(rla_lonpos)) DEALLOCATE(rla_lonpos)
    IF (ALLOCATED(ila_xindex)) DEALLOCATE(ila_xindex)
    IF (ALLOCATED(ila_yindex)) DEALLOCATE(ila_yindex)
    IF (ALLOCATED(rla_poids)) DEALLOCATE(rla_poids)
  !
  ELSE
     WRITE (0,*) 'Fichier coloc existant :: ',cl_colocFile
  ENDIF
CALL EXIT(0)
END PROGRAM COLOCALIZE
!
!
!*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
