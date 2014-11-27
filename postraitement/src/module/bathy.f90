MODULE BATHY

  !---------------------------------------------------------------------------------------
  !
  !                          ---   MODULE BATHY  --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Avril 2008
  !
  ! Ce module vise a gerer des interpolation de bathymetrie
  ! Je suis reparti de routines deja mises en place dans MIOL/MCAL par F. Messal
  ! Ce module se compose
  ! - D une ouverture et lecture du fichier de bathy necessaire
  ! - D une fermeture de ce fichier bathy et la gestion des variables associees
  ! - D une interpolation a un point precis de la bathymetrie a la position demandee
  !
  ! Ce module fait appel a table_bathy.f90 qui gere les variables globales
  ! Nota, les referencements de longitudes [-180,180[ ou [0,360[ sont tous geres en interne
  !

  INTERFACE InterpBathy
     MODULE PROCEDURE InterpBathy_R4, &
          InterpBathy_R8
  END INTERFACE


  PRIVATE
  PUBLIC :: ChargerBathy,InterpBathy,FermerBathy
CONTAINS


  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE  ChargerBathy --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Avril 2008
  ! Objet: ouvrir le fichier bathy, et placer les tableaux de bathy
  !        (igpa_BathyValue,rgpa_BathyLonValue,rgpa_BathyLatValue)
  !        en variable globale gerer par table_bathy.f90
  ! Nota: le georeferencement de la bathy est controle par
  !                      ig_LongitudeBound:180    [-180,180[
  !                      ig_LongitudeBound:360    [0,360[
  !
  ! Module externe: MIOL:
  !                     - MIOL_read_bathycls_NC


  SUBROUTINE ChargerBathy (id_status)

    !
    !** ++  MODULES used
    !
    USE miol
    USE table_bathy
    !
    !** ++  Local Declarations 
    !
    IMPLICIT NONE

    ! Arguments de la routine
    INTEGER,INTENT(out) :: id_status ! Status sur la routine

    ! Variables locales: ouverture du fichier
    LOGICAL :: ll_exist


    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    ! Initialisation
    ! --------------
    id_status = 0

    ! Verification existence fichier bathy
    ! ------------------------------------

    INQUIRE(FILE=TRIM(cg_BathyFile),EXIST=ll_exist)
    IF (.NOT.ll_exist) THEN  ! sortie en erreur
       WRITE(0,*) 'error file ',TRIM(cg_BathyFile),' does not exist'
       id_status = -1
       GOTO 9999
    ENDIF

    ! LECTURE de la bathy depend du type de fichier
    ! ---------------------------------------------
    SELECT CASE(ig_BathyType)

    CASE(1) 
       ! bathy CLS
       ig_LongitudeBound=180
       CALL MIOL_read_bathycls_NC(cg_BathyFile, &
            ig_LongitudeBound, igpa_BathyValue, &
            rgpa_BathyLonValue, &
            rgpa_BathyLatValue, &
            ig_nbBathyLon, &
            ig_nbBathyLat)
    CASE(2) 
       PRINT*,'Bathy Etopo2 a FAIRE'

    CASE(3)
       PRINT*,'Bathy Not Defined'
       id_status = -1

    CASE(4) 
       PRINT*,'Bathy Not Defined'
       id_status = -1

    CASE default
       id_status = -1

    END SELECT
    IF ( id_status /= 0 ) GOTO 9999


9999 CONTINUE
  END SUBROUTINE ChargerBathy


  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE  InterpBathy --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Avril 2008
  ! Objet:Interpolation a une position LON/LAT de la bathymetrie renvoie une valeur ENTIERE
  !
  ! il y a deux versions de cette routine de facon a prendre en compte
  ! un passage des arguments LON (rd_lonValue) et LAT (rd_latValue) en R4 ou R8
  ! 
  ! Nota: les tableaux de bathy (igpa_BathyValue,rgpa_BathyLonValue,rgpa_BathyLatValue)
  !       sont en variable globale gerer par table_bathy.f90
  ! Nota: le georeferencement de la bathy est gere en interne avec
  !                      ig_LongitudeBound:180    [-180,180[
  !                      ig_LongitudeBound:360    [0,360[
  !
  !
  ! Schema de l interpolation bilineaire sur 4 points:
  ! on va interpoler le point X dans la maille en utilisant
  ! les distances entre le point et les quatre bords de maille
  ! ayant chacun la valeur de bathy ba(x,y) correspondant:
  !
  !        iy1                       iy1
  !      ix O++++++++++++++++++++++++0 ix1     
  !         +         .          |   +
  !         +         .    D_iy1 |   +
  !         +         .          |   +
  !         +.........X..............+
  !         +         .          |   +
  !         +         .          |   +
  !         +         .          |   +
  !         +         .    D_iy  |   +
  !         +         .          |   +
  !         +<- D_ix->.<---D_ix1---->+
  !         +         .          |   +
  !      ix O++++++++++++++++++++++++O ix1
  !        iy                        iy
  !
  ! Chacun des poids inversement proportionnel a la distance:
  ! S'ecrivant sous la forme:
  !    
  !         P(ix,iy) = 1 / sqrt(D_ix**2 + D_iy**2)
  !
  ! Et l interpolation B(X) .AŽà la position X(lon,lat) etant le resultat de:
  !
  !         B(x) = [ P(ix,iy)*ba(ix,iy) + P(ix1,iy)*ba(ix1,iy) + 
  !                  P(ix,iy1)*ba(ix,iy1) + P(ix1,iy1)*ba(ix1,iy1) ] / 
  !                ( P(ix,iy) + P(ix1,iy) + P(ix,iy1) + P(ix1,iy1) )
  !
  !  Modif C.REGNIER Mai 2009 : add nearest neighbour approximation if there is
  !  earth points in the four points
  !
  ! ====  Version en R4 ====
  SUBROUTINE InterpBathy_R4 (rd_lonValue, &
       rd_latValue, &
       id_interpBathyValue, &
       id_status )

    !
    !** ++  MODULES used
    !
    USE table_bathy
    !
    !** ++  Local Declarations 
    !
    IMPLICIT NONE

    ! Arguments de la routine
    REAL(kind=4),INTENT(in) :: rd_lonValue ! long. pt a interpoler
    REAL(kind=4),INTENT(in) :: rd_latValue ! lat. pt a interpoler
    INTEGER,INTENT(out) :: id_interpBathyValue ! valeur bathy interpolee
    INTEGER,INTENT(out) :: id_status ! Status sur la routine


    ! Variables locales
    REAL(kind=8) :: rl_lonValue
    REAL(kind=8) :: rl_latValue,rl_min
    ! distance dans la maille
    REAL(kind=8) :: rl_D_ix,rl_D_ix1,rl_D_iy,rl_D_iy1 
    ! poids
    REAL(kind=8) :: rl_W_ix_iy,rl_W_ix1_iy,rl_W_ix_iy1,rl_W_ix1_iy1
    REAL(kind=8),DIMENSION(4) :: rla_W_4points
    ! indices de la maille
    INTEGER :: il_ix,il_ix1,il_iy,il_iy1
    INTEGER :: il_ji,il_pos
    ! variable interpolee
    REAL(kind=8) :: rl_interp

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    ! Initialisation
    ! --------------
    id_status = 0

    ! Verification de la validite des coordonnees
    ! -------------------------------------------
    IF ( rd_lonValue > 360. .OR. rd_lonValue < -180. ) THEN
       id_status = -1
       WRITE(*,'(a)')'InterpBathy_R4: lonValue Out of Range ',rd_lonValue
       CALL EXIT(1)
    ENDIF
    IF ( rd_latValue > 90. .OR. rd_latValue < -90. ) THEN
       id_status = -1
       WRITE(*,'(a)')'InterpBathy: latValue Out of Range',rd_latValue
       CALL EXIT(1)
    ENDIF



    ! Recherche des points de grilles en longitude
    ! --------------------------------------------

    ! Georeferencement en fonction de ig_LongitudeBound
    IF ( ig_LongitudeBound == 180 ) THEN

       ! on convertit si besoin la longitude entre [-180,180[
       IF ( rd_lonValue .GE. 180. ) THEN
          rl_lonValue = rd_lonValue - 360.d0
       ELSE
          rl_lonValue = rd_lonValue
       ENDIF

       ! recherche de la maille en longitude et
       ! calcul des distances
       IF ( rl_lonValue < 180. .AND. &
            & rl_lonValue .GE.rgpa_BathyLonValue(ig_nbBathyLon) ) THEN 
          ! 1. cas particulier si le point est juste au bord de 180.
          il_ix = ig_nbBathyLon
          il_ix1 = 1
          rl_D_ix = rl_lonValue - rgpa_BathyLonValue(il_ix)
          rl_D_ix1 = rl_lonValue - rgpa_BathyLonValue(il_ix1) - 360.d0
       ELSE
          ! 2. cas general
          il_ix = 0
          il_ix1 = 0
          il_ji = 1
          DO WHILE ( il_ji < ig_nbBathyLon .AND. il_ix == 0 )
             IF ( rl_lonValue .GE. rgpa_BathyLonValue(il_ji) .AND. &
                  & rl_lonValue < rgpa_BathyLonValue(il_ji+1)) THEN
                il_ix = il_ji
                il_ix1 = il_ji + 1
             ENDIF
             il_ji = il_ji + 1
          ENDDO
          rl_D_ix = rl_lonValue - rgpa_BathyLonValue(il_ix)
          rl_D_ix1 = rl_lonValue - rgpa_BathyLonValue(il_ix1)
       ENDIF

    ELSE IF ( ig_LongitudeBound == 360 ) THEN
       IF ( rd_lonValue < 0. ) THEN
          rl_lonValue = rd_lonValue + 360.d0
       ELSE
          rl_lonValue = rd_lonValue
       ENDIF
    ELSE
       id_status = -1
       WRITE(*,'(a)')'InterpBathy: ig_LongitudeBound Out of Range'
       CALL EXIT(1) 
    ENDIF


    ! Recherche des points de grilles en latitude
    ! -------------------------------------------
    rl_latValue = rd_latValue

    ! Recherche de la maille et calcul de distance
    IF ( rl_latValue .LE. 90. .AND. &
         &  rl_latValue .GE.rgpa_BathyLatValue(ig_nbBathyLat) ) THEN
       ! 1. cas particulier du bord proche du pole nord
       il_iy = ig_nbBathyLat
       il_iy1 = ig_nbBathyLat
       rl_D_iy = rl_latValue - rgpa_BathyLatValue(il_iy)
       rl_D_iy1 = rl_latValue - 90.d0
    ELSE IF ( rl_latValue < rgpa_BathyLatValue(1) .AND. &
         & rl_latValue .GE. -90. ) THEN
       ! 2. cas particulier proche du pole sud
       il_iy = 1
       il_iy1 = 1
       rl_D_iy = rl_latValue + 90.d0
       rl_D_iy1 = rl_latValue - rgpa_BathyLatValue(il_iy1)
    ELSE
       ! 3. cas general
       il_iy = 0
       il_iy1 = 0
       il_ji = 1
       DO WHILE ( il_ji < ig_nbBathyLat .AND. il_iy == 0 )
          IF ( rl_latValue .GE. rgpa_BathyLatValue(il_ji) .AND. &
               & rl_latValue < rgpa_BathyLatValue(il_ji+1)) THEN
             il_iy = il_ji
             il_iy1 = il_ji + 1
          ENDIF
          il_ji = il_ji + 1
       ENDDO
       rl_D_iy = rl_latValue - rgpa_BathyLatValue(il_iy)
       rl_D_iy1 = rl_latValue - rgpa_BathyLatValue(il_iy1)
    ENDIF


    ! Calcul des poids pour chaque point
    ! ----------------------------------
    rl_W_ix_iy = SQRT(rl_D_ix**2 + rl_D_iy**2)
    rl_W_ix1_iy = SQRT(rl_D_ix1**2 + rl_D_iy**2)
    rl_W_ix_iy1 = SQRT(rl_D_ix**2 + rl_D_iy1**2)
    rl_W_ix1_iy1 = SQRT(rl_D_ix1**2 + rl_D_iy1**2)
  
    IF ( rl_W_ix_iy == 0.d0 .OR. rl_W_ix1_iy == 0.d0 .OR. &
         & rl_W_ix_iy1 == 0.d0 .OR. rl_W_ix1_iy1 == 0.d0 ) THEN
 
    !**  Compute nearest neighbour
    rla_W_4points(1)=rl_W_ix_iy
    rla_W_4points(2)=rl_W_ix1_iy
    rla_W_4points(3)=rl_W_ix_iy1
    rla_W_4points(4)=rl_W_ix1_iy1
    rl_min=MINVAL(rla_W_4points,mask=rla_W_4points /= 0)
    il_pos=MINLOC(rla_W_4points,dim =1,mask = rla_W_4points .GT. 0)    
     SELECT CASE(il_pos)
       CASE(1)
           rl_interp = DBLE(igpa_BathyValue(il_ix,il_iy)) 
       CASE(2)
           rl_interp = DBLE(igpa_BathyValue(il_ix1,il_iy))
       CASE(3)
           rl_interp = DBLE(igpa_BathyValue(il_ix,il_iy1))
       CASE(4)  
           rl_interp = DBLE(igpa_BathyValue(il_ix1,il_iy1))
      ENDSELECT
      id_interpBathyValue = NINT(rl_interp)
     !WRITE(0,*) 'InterpBathy: nearest neighbour sol',id_interpBathyValue
   ELSE

    rl_W_ix_iy = 1. / rl_W_ix_iy
    rl_W_ix1_iy = 1. / rl_W_ix1_iy
    rl_W_ix_iy1 = 1. / rl_W_ix_iy1
    rl_W_ix1_iy1 = 1. / rl_W_ix1_iy

    ! Interpolation bilineaire sur 4 points
    ! -------------------------------------
    rl_interp = rl_W_ix_iy * DBLE(igpa_BathyValue(il_ix,il_iy)) + &
         & rl_W_ix1_iy * DBLE(igpa_BathyValue(il_ix1,il_iy)) + &
         & rl_W_ix_iy1 * DBLE(igpa_BathyValue(il_ix,il_iy1)) + &
         & rl_W_ix1_iy1 * DBLE(igpa_BathyValue(il_ix1,il_iy1))
    rl_interp =  rl_interp / &
         & ( rl_W_ix_iy+rl_W_ix1_iy+rl_W_ix_iy1+rl_W_ix1_iy1)


    id_interpBathyValue = NINT(rl_interp)
 ENDIF 
END SUBROUTINE InterpBathy_R4


  ! ====  Version en R8 ====
  !
  SUBROUTINE InterpBathy_R8 (rd_lonValue, &
       rd_latValue, &
       id_interpBathyValue, &
       id_status )

    !
    !** ++  MODULES used
    !
    !    USE mcal
    USE table_bathy
    !
    !** ++  Local Declarations 
    !
    IMPLICIT NONE

    !** Arguments de la routine
    REAL(kind=8),INTENT(in) :: rd_lonValue ! long. pt a interpoler
    REAL(kind=8),INTENT(in) :: rd_latValue ! lat. pt a interpoler
    INTEGER,INTENT(out) :: id_interpBathyValue ! valeur bathy interpolee
    INTEGER,INTENT(out) :: id_status ! Status sur la routine


    !** Variables locales
    REAL(kind=8) :: rl_lonValue
    REAL(kind=8) :: rl_latValue,rl_min
    ! distance dans la maille
    REAL(kind=8) :: rl_D_ix,rl_D_ix1,rl_D_iy,rl_D_iy1 
    ! poids
    REAL(kind=8) :: rl_W_ix_iy,rl_W_ix1_iy,rl_W_ix_iy1,rl_W_ix1_iy1
    REAL(kind=8),DIMENSION(4) :: rla_W_4points
    ! indices de la maille
    INTEGER :: il_ix,il_ix1,il_iy,il_iy1
    INTEGER :: il_ji,il_pos
    ! variable interpolee
    REAL(kind=8) :: rl_interp

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    ! Initialisation
    ! --------------
    id_status = 0

    ! Verification de la validite des coordonnees
    ! -------------------------------------------
    IF ( rd_lonValue > 360. .OR. rd_lonValue < -180. ) THEN
       id_status = -1
       WRITE(*,'(a)')'InterpBathy_R8: lonValue Out of Range',rd_lonValue
       STOP
      ! CALL EXIT(1)
    ENDIF
    IF ( rd_latValue > 90. .OR. rd_latValue < -90. ) THEN
       id_status = -1
       WRITE(*,'(a)')'InterpBathy: latValue Out of Range',rd_latValue
       STOP
     !  CALL EXIT(1)
    ENDIF


    ! Recherche des points de grilles en longitude
    ! --------------------------------------------

    ! Georeferencement en fonction de ig_LongitudeBound
    IF ( ig_LongitudeBound == 180 ) THEN

       ! on convertit si besoin la longitude entre [-180,180[
       IF ( rd_lonValue .GE. 180. ) THEN
          rl_lonValue = rd_lonValue - 360.d0
       ELSE
          rl_lonValue = rd_lonValue
       ENDIF

       ! recherche de la maille en longitude et
       ! calcul des distances
       IF ( rl_lonValue < 180. .AND. &
            & rl_lonValue .GE.rgpa_BathyLonValue(ig_nbBathyLon) ) THEN 
          ! 1. cas particulier si le point est juste au bord de 180.
          il_ix = ig_nbBathyLon
          il_ix1 = 1
          rl_D_ix = rl_lonValue - rgpa_BathyLonValue(il_ix)
          rl_D_ix1 = rl_lonValue - rgpa_BathyLonValue(il_ix1) - 360.d0
       ELSE
          ! 2. cas general
          il_ix = 0
          il_ix1 = 0
          il_ji = 1
          DO WHILE ( il_ji < ig_nbBathyLon .AND. il_ix == 0 )
             IF ( rl_lonValue .GE. rgpa_BathyLonValue(il_ji) .AND. &
                  & rl_lonValue < rgpa_BathyLonValue(il_ji+1)) THEN
                il_ix = il_ji
                il_ix1 = il_ji + 1
             ENDIF
             il_ji = il_ji + 1
          ENDDO
          rl_D_ix = rl_lonValue - rgpa_BathyLonValue(il_ix)
          rl_D_ix1 = rl_lonValue - rgpa_BathyLonValue(il_ix1)
       ENDIF

    ELSE IF ( ig_LongitudeBound == 360 ) THEN
       IF ( rd_lonValue < 0. ) THEN
          rl_lonValue = rd_lonValue + 360.d0
       ELSE
          rl_lonValue = rd_lonValue
       ENDIF
    ELSE
       id_status = -1
       WRITE(*,'(a)')'InterpBathy: ig_LongitudeBound Out of Range'
       CALL EXIT(1)
    ENDIF


    ! Recherche des points de grilles en latitude
    ! -------------------------------------------
    rl_latValue = rd_latValue

    ! Recherche de la maille et calcul de distance
    IF ( rl_latValue .LE. 90. .AND. &
         &  rl_latValue .GE.rgpa_BathyLatValue(ig_nbBathyLat) ) THEN
       ! 1. cas particulier du bord proche du pole nord
       il_iy = ig_nbBathyLat
       il_iy1 = ig_nbBathyLat
       rl_D_iy = rl_latValue - rgpa_BathyLatValue(il_iy)
       rl_D_iy1 = rl_latValue - 90.d0
    ELSE IF ( rl_latValue < rgpa_BathyLatValue(1) .AND. &
         & rl_latValue .GE. -90. ) THEN
       ! 2. cas particulier proche du pole sud
       il_iy = 1
       il_iy1 = 1
       rl_D_iy = rl_latValue + 90.d0
       rl_D_iy1 = rl_latValue - rgpa_BathyLatValue(il_iy1)
    ELSE
       ! 3. cas general
       il_iy = 0
       il_iy1 = 0
       il_ji = 1
       DO WHILE ( il_ji < ig_nbBathyLat .AND. il_iy == 0 )
          IF ( rl_latValue .GE. rgpa_BathyLatValue(il_ji) .AND. &
               & rl_latValue < rgpa_BathyLatValue(il_ji+1)) THEN
             il_iy = il_ji
             il_iy1 = il_ji + 1
          ENDIF
          il_ji = il_ji + 1
       ENDDO
       rl_D_iy = rl_latValue - rgpa_BathyLatValue(il_iy)
       rl_D_iy1 = rl_latValue - rgpa_BathyLatValue(il_iy1)
    ENDIF


    ! Calcul des poids pour chaque point
    ! ----------------------------------
    rl_W_ix_iy = SQRT(rl_D_ix**2 + rl_D_iy**2)
    rl_W_ix1_iy = SQRT(rl_D_ix1**2 + rl_D_iy**2)
    rl_W_ix_iy1 = SQRT(rl_D_ix**2 + rl_D_iy1**2)
    rl_W_ix1_iy1 = SQRT(rl_D_ix1**2 + rl_D_iy1**2)
    IF ( rl_W_ix_iy == 0.d0 .OR. rl_W_ix1_iy == 0.d0 .OR. &
         & rl_W_ix_iy1 == 0.d0 .OR. rl_W_ix1_iy1 == 0.d0 ) THEN
    !**  Compute nearest neighbour
    rla_W_4points(1)=rl_W_ix_iy
    rla_W_4points(2)=rl_W_ix1_iy
    rla_W_4points(3)=rl_W_ix_iy1
    rla_W_4points(4)=rl_W_ix1_iy1
    rl_min=MINVAL(rla_W_4points,mask=rla_W_4points /= 0)
    il_pos=MINLOC(rla_W_4points,dim =1,mask = rla_W_4points .GT. 0)    
     SELECT CASE(il_pos)
       CASE(1)
           rl_interp = DBLE(igpa_BathyValue(il_ix,il_iy)) 
       CASE(2)
           rl_interp = DBLE(igpa_BathyValue(il_ix1,il_iy))
       CASE(3)
           rl_interp = DBLE(igpa_BathyValue(il_ix,il_iy1))
       CASE(4)  
           rl_interp = DBLE(igpa_BathyValue(il_ix1,il_iy1))
      ENDSELECT

      id_interpBathyValue = NINT(rl_interp)
     !WRITE(*,*) 'InterpBathy: nearest neighbour sol',id_interpBathyValue
   ELSE
    rl_W_ix_iy = 1. / rl_W_ix_iy
    rl_W_ix1_iy = 1. / rl_W_ix1_iy
    rl_W_ix_iy1 = 1. / rl_W_ix_iy1
    rl_W_ix1_iy1 = 1. / rl_W_ix1_iy

    ! Interpolation bilineaire sur 4 points
    ! -------------------------------------
    rl_interp = rl_W_ix_iy * DBLE(igpa_BathyValue(il_ix,il_iy)) + &
         & rl_W_ix1_iy * DBLE(igpa_BathyValue(il_ix1,il_iy)) + &
         & rl_W_ix_iy1 * DBLE(igpa_BathyValue(il_ix,il_iy1)) + &
         & rl_W_ix1_iy1 * DBLE(igpa_BathyValue(il_ix1,il_iy1))
    rl_interp =  rl_interp / &
         & ( rl_W_ix_iy+rl_W_ix1_iy+rl_W_ix_iy1+rl_W_ix1_iy1)


    id_interpBathyValue = NINT(rl_interp)


    ENDIF
  END SUBROUTINE InterpBathy_R8


  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE  FermerBathy --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Avril 2008
  ! Objet: de-allocate les tableaux de bathy
  !        (igpa_BathyValue,rgpa_BathyLonValue,rgpa_BathyLatValue)


  SUBROUTINE FermerBathy (id_status)

    !
    !** ++  MODULES used
    !
    USE table_bathy
    !
    !** ++  Local Declarations 
    !
    IMPLICIT NONE

    ! Arguments de la routine
    INTEGER,INTENT(out) :: id_status ! Status sur la routine

    ! Variables locales:


    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    ! Initialisation
    ! --------------
    id_status = 0


    !** Desallocation
!    IF ( ALLOCATED (igpa_BathyValue) ) DEALLOCATE (igpa_BathyValue)
!    IF ( ALLOCATED (rgpa_BathyLonValue) ) DEALLOCATE (rgpa_BathyLonValue)
!    IF ( ALLOCATED (rgpa_BathyLatValue) ) DEALLOCATE (rgpa_BathyLatValue)
     DEALLOCATE (igpa_BathyValue)
     DEALLOCATE (rgpa_BathyLonValue)
     DEALLOCATE (rgpa_BathyLatValue)
9999 CONTINUE
  END SUBROUTINE FermerBathy

  !---------------------------------------------------------------------------------------
  !
  !                          ---   END MODULE BATHY  --- 
  !
  !---------------------------------------------------------------------------------------
  !
END MODULE BATHY
