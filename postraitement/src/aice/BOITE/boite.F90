MODULE BOITE

  !---------------------------------------------------------------------------------------
  !
  !                          ---   MODULE BOITE  --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Mars 2007
  ! ATTENTION: tout ce module provient des travaux et programmes developpes par
  !            Charles Emmanuel Testut a Mercator Ocean, avec ses stagiaires
  ! Je suis reparti du programme createcmz.F90 pour ecrire ce module
  !
  ! Ce module vise a:
  ! - Lire le fichier de definition des boites globales. Ces boites sont definies par
  !   une serie de points dans un sens direct ou indirect de facon a former un 
  !   polygone convexe (tres important pour les proprietes de detections par la suite).
  !   Chaque boite a un numero unique. L'ensemble des boites decrit completement
  !   l'ocean global. Propriete connexe: plusieurs boites vont definir des macros regions
  ! - Detection: Identifier si un point (lon,lat) se trouve dans une boite, et renvoyer
  !   le numero de la boite.Attention: apriori convention des longitudes: [-180,180]
  ! - Caracteriser chaque boite, en renvoyant, pour un numero de boite, les positions
  !   des points, ainsi que le barycentre


  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE  LireDefBoite --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Mars 2007
  ! Morceaux repris de createcmz.F90 (C.E. Testut)
  ! Lecture du fichier de definition des boites

  PRIVATE
  PUBLIC :: LireDefBoite,IdentifierBoite,CaracBoite
CONTAINS
  SUBROUTINE LireDefBoite (cd_fconfigtxt,jv_status)

    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 
    USE MIOL
    USE table_boite
    IMPLICIT NONE

    ! Arguments de la routine
    ! cd_fconfigtxt: IN/ nom du fichier de definition des boites
    ! jv_status : OUT/Status sur la routine

    CHARACTER(len=*),INTENT(in) :: cd_fconfigtxt
    INTEGER,INTENT(out) :: jv_status

    ! Variables locales: ouverture du fichier
    CHARACTER(len=255) :: cl_fname
    LOGICAL :: ll_err,ll_exist
    INTEGER :: il_numfil ! numero logique fichier cd_fconfigtxt

    ! variable de travail de lecture fichier
    CHARACTER(len=256) :: cl_text
    ! CHARACTER(len=256) :: readnextline
    CHARACTER(len=1), PARAMETER :: cp_textexclusion='#'
    INTEGER :: il_err
    ! lecture header
    INTEGER :: il_nbblocmax ! nbre max de bloc

    ! VARIABLES de travail sur la lecture DES REGIONS
    INTEGER, DIMENSION(1:3) :: ila_nbtype
    ! Caracteristiques pour les blocs compliques
    REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rla_listlon1
    REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rla_listlat1

    ! variable de travail
    INTEGER :: il_jregion,il_jregion1,il_jtyperegion,il_jbloc,il_jpoint
    INTEGER :: il_maxlistpoint,il_maxlistpoint1


!!$    INTERFACE
!!$       CHARACTER(len=256) FUNCTION readnextline(id_numfil,cd_textexclusion,id_err)
!!$         INTEGER, INTENT(in) :: id_numfil  
!!$         CHARACTER(len=*), INTENT(in) :: cd_textexclusion  
!!$         INTEGER,INTENT(out) :: id_err
!!$       END FUNCTION readnextline
!!$    END INTERFACE

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    ! Initialisation
    ! --------------
    jv_status = 0

    ! Verification existence fichiers et ouverture
    ! --------------------------------------------

    cl_fname=TRIM(cd_fconfigtxt)
    INQUIRE(FILE=TRIM(cl_fname),EXIST=ll_exist)
    IF (.NOT.ll_exist) THEN  ! sortie en erreur
       WRITE(0,*) 'error file ',TRIM(cl_fname),' does not exist'
       jv_status = -1
       GOTO 9999
    ENDIF
    CALL MIOL_getFreeLU(il_numfil)
    OPEN(UNIT=il_numfil,FILE=TRIM(cl_fname),status='old',form='formatted',&
         & iostat=il_err,action='read')
    IF ( il_err /= 0 ) THEN
       WRITE(0,*) 'error openeing file',TRIM(cl_fname)
       jv_status = -1
       GOTO 9999
    ENDIF


    ! FORMAT FICHIER TXT
    ! ------------------
    !
    ! header:
    ! ig_nbregion,il_nbblocmax, rg_valeur0

    cl_text=''
    il_err = 0
    cl_text=readnextline(il_numfil,cp_textexclusion,il_err)
    IF ( il_err /= 0 ) THEN
       WRITE(0,*) 'error readnextline:unavailable txt format'
       jv_status = -1
       CLOSE(UNIT=il_numfil)
       GOTO 9999
    ENDIF
    ! Lecture de l entete
    READ(cl_text,FMT=*,IOSTAT=il_err) ig_nbregion,il_nbblocmax, rg_valeur0
    IF (il_err/=0) THEN
       WRITE (0,*) 'error reading configtxt[',TRIM(cd_fconfigtxt),'], il_err=',il_err,' text=',TRIM(cl_text)
       jv_status = -1
       CLOSE(UNIT=il_numfil)
       GOTO 9999
    ENDIF
    ! Cas ou le nombre de region est negatif: erreur
    IF (ig_nbregion<0) THEN
       WRITE (0,*) 'error fileinfotxt[',TRIM(cd_fconfigtxt),'] ig_nbregion=',ig_nbregion
       jv_status = -1
       CLOSE(UNIT=il_numfil)
       GOTO 9999
    ENDIF
    ! Cas ou le nombre de region est nul: on sort (modif FHZ)
    IF (ig_nbregion==0) THEN
       WRITE (0,*) 'PB fileinfotxt[',TRIM(cd_fconfigtxt),'] ig_nbregion=',ig_nbregion
       CLOSE(UNIT=il_numfil)
       GOTO 9999
    ENDIF

    WRITE(0,*)'Nombre de regions=',ig_nbregion
    WRITE(0,*)'Valeur du fond1=',rg_valeur0

    ! Dans le cas (attendu) ou il y a un nombre positif de regions
    IF (ig_nbregion>=1) THEN

       ! Initialisation des variables "regions"
       IF (ALLOCATED(iga_typeregion)) DEALLOCATE(iga_typeregion)
       ALLOCATE(iga_typeregion(1:ig_nbregion),stat=il_err)
       IF (il_err/=0) THEN
          WRITE (0,*) 'error allocate iga_typeregion(',ig_nbregion,'), il_err=',il_err
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF
       iga_typeregion(1:ig_nbregion)=0

       IF (ALLOCATED(rga_valeur1)) DEALLOCATE(rga_valeur1)
       ALLOCATE(rga_valeur1(1:ig_nbregion),stat=il_err)
       IF (il_err/=0) THEN
          WRITE (0,*) 'error allocate rga_valeur1(',ig_nbregion,'), il_err=',il_err
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF
       rga_valeur1(1:ig_nbregion)=0.0

       IF (ALLOCATED(rga_info)) DEALLOCATE(rga_info)
       ALLOCATE(rga_info(1:4,1:ig_nbregion),stat=il_err)
       IF (il_err/=0) THEN
          WRITE (0,*) 'error allocate rga_info(',ig_nbregion,'), il_err=',il_err
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF
       rga_info(1:4,1:ig_nbregion)=0.0

       IF (ALLOCATED(iga_listnbbloc)) DEALLOCATE(iga_listnbbloc)
       ALLOCATE(iga_listnbbloc(1:ig_nbregion),stat=il_err)
       IF (il_err/=0) THEN
          WRITE (0,*) 'error allocate iga_listnbbloc(',ig_nbregion,'), il_err=',il_err
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF
       iga_listnbbloc(1:ig_nbregion)=0

       IF (ALLOCATED(iga_listnbpoint)) DEALLOCATE(iga_listnbpoint)
       ALLOCATE(iga_listnbpoint(1:ig_nbregion,1:il_nbblocmax),stat=il_err)
       IF (il_err/=0) THEN
          WRITE (0,*) 'error allocate iga_listnbpoint(',ig_nbregion,il_nbblocmax,'), il_err=',il_err
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF
       iga_listnbpoint(1:ig_nbregion,1:il_nbblocmax)=0

    ENDIF

    il_maxlistpoint=0
    ila_nbtype(1:3)=0


    ! lecture region: boucle sur le nombre de region (ig_nbregion)
    !
    ! SUITE FORMAT FICHIER TXT
    ! ------------------
    !
    ! iga_typeregion(il_jregion),iga_listnbbloc(il_jregion),rga_valeur1(il_jregion)

    DO il_jregion=1,ig_nbregion
       cl_text=''
       il_err = 0
       cl_text=readnextline(il_numfil,cp_textexclusion,il_err)
       IF ( il_err /= 0 ) THEN
          WRITE(0,*) 'error readnextline:unavailable txt format'
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF

       ! Lecture des caracteristiques de la region
       READ(cl_text,FMT=*,IOSTAT=il_err) &
            & iga_typeregion(il_jregion),iga_listnbbloc(il_jregion),rga_valeur1(il_jregion)
       IF (il_err/=0) THEN
          WRITE (0,*) 'error reading configtxt[',TRIM(cd_fconfigtxt),'], il_err=',&
               & il_err,' text=',TRIM(cl_text)
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF
       IF (rga_valeur1(il_jregion)==rg_valeur0) THEN
          WRITE (0,*) 'WARNING region(',il_jregion,') a meme valeur que fond=',rg_valeur0
       ENDIF
       ! test pour verifier si ce num. identite pas deja lu
       DO il_jregion1=1,il_jregion-1
          IF (rga_valeur1(il_jregion1)==rga_valeur1(il_jregion)) THEN
             WRITE (0,*) 'WARNING region(',il_jregion,') a meme valeur(',rga_valeur1(il_jregion1),&
                  & ') que region(',il_jregion1,')'
          ENDIF
       ENDDO
       ! test pour verifier si le nb. de bloc <= nb blocmax lu en header
       IF (iga_listnbbloc(il_jregion)>il_nbblocmax) THEN
          WRITE (0,*) 'error configtxt[',TRIM(cd_fconfigtxt),&
               '] [iga_listnbbloc(il_jregion)>il_nbblocmax]=',iga_listnbbloc(il_jregion),il_nbblocmax
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       ENDIF

       il_jtyperegion=iga_typeregion(il_jregion)
       ila_nbtype(il_jtyperegion)=ila_nbtype(il_jtyperegion)+1

       ! Choix en fonction du type de region

       ! SUITE FORMAT FICHIER TXT
       ! ------------------        
       ! rl_lonmin,rl_latmin,rl_lonmax,rl_latmax #cas rectangle
       ! rl_lonpos,rl_latpos,rl_distmin,rl_distmax #cas rond

       SELECT CASE (il_jtyperegion)

       CASE (1,2) ! cas rectangle ou rond

          ! pour ces deux cas, le nbr. de bloc vaut 1:
          IF (iga_listnbbloc(il_jregion)/=1) THEN
             WRITE (0,*) 'error reading configtxt[',TRIM(cd_fconfigtxt),&
                  '] [iga_listnbbloc(il_jregion)/=1]=',iga_listnbbloc(il_jregion)
             jv_status = -1
             CLOSE(UNIT=il_numfil)
             GOTO 9999
          ENDIF

          cl_text=''
          il_err = 0
          cl_text=readnextline(il_numfil,cp_textexclusion,il_err)
          IF ( il_err /= 0 ) THEN
             WRITE(0,*) 'error readnextline:unavailable txt format'
             jv_status = -1
             CLOSE(UNIT=il_numfil)
             GOTO 9999
          ENDIF
          ! Lecture des caracteristiques du bloc
          READ(cl_text,FMT=*,IOSTAT=il_err) rga_info(1:4,il_jregion)
          IF (il_err/=0) THEN
             WRITE (0,*) 'error reading configtxt[',TRIM(cd_fconfigtxt),&
                  & '], il_err=',il_err,' text=',TRIM(cl_text)
             jv_status = -1
             CLOSE(UNIT=il_numfil)
             GOTO 9999
          ENDIF

          ! SUITE FORMAT FICHIER TXT
          ! ------------------
          ! #do il_jbloc=1,iga_listnbbloc(il_jregion)
          ! iga_listnbpoint(il_jregion,il_jbloc)
          ! #do il_jpoint=1,iga_listnbpoint(il_jregion,il_jbloc)
          ! rga_listlon(il_jpoint,il_jregion,il_jbloc),rga_listlat(il_jpoint,il_jregion,il_jbloc)
          ! #enddo
          ! #enddo

       CASE (3) ! Cas d'une region a plusieurs bloc

          ! boucle sur les blocs de cette region
          DO il_jbloc=1,iga_listnbbloc(il_jregion)

             ! Lecture du nombre de points caracteristiques pour les blocs des regions "3"
             cl_text=''
             il_err = 0
             cl_text=readnextline(il_numfil,cp_textexclusion,il_err)
             IF ( il_err /= 0 ) THEN
                WRITE(0,*) 'error readnextline:unavailable txt format'
                jv_status = -1
                CLOSE(UNIT=il_numfil)
                GOTO 9999
             ENDIF
             READ(cl_text,FMT=*,IOSTAT=il_err) iga_listnbpoint(il_jregion,il_jbloc)
             IF (iga_listnbpoint(il_jregion,il_jbloc)<3) THEN
                WRITE (0,*) ' error configtxt[',TRIM(cd_fconfigtxt),&
                     '], (iga_listnbpoint(il_jregion)<1)=',iga_listnbpoint(il_jregion,il_jbloc),&
                     & il_jregion,il_jbloc
                jv_status = -1
                CLOSE(UNIT=il_numfil)
                GOTO 9999
             ENDIF

             ! gestion des allocations des points caracteristiques
             IF (il_maxlistpoint==0) THEN  ! premiere allocation

                il_maxlistpoint=MAXVAL(iga_listnbpoint(1:il_jregion,1:il_nbblocmax))+1

                IF (ALLOCATED(rga_listlon)) DEALLOCATE(rga_listlon)
                ALLOCATE(rga_listlon(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax),stat=il_err)
                IF (il_err/=0) THEN
                   WRITE (0,*) 'error allocate rga_listlon(',il_maxlistpoint,&
                        & ig_nbregion,il_nbblocmax,'), il_err=',il_err
                   jv_status = -1
                   CLOSE(UNIT=il_numfil)
                   GOTO 9999
                ENDIF
                rga_listlon(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax)=0.0

                IF (ALLOCATED(rga_listlat)) DEALLOCATE(rga_listlat)
                ALLOCATE(rga_listlat(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax),stat=il_err)
                IF (il_err/=0) THEN
                   WRITE (0,*) 'error allocate rga_listlat(',il_maxlistpoint,&
                        & ig_nbregion,il_nbblocmax,'), il_err=',il_err
                   jv_status = -1
                   CLOSE(UNIT=il_numfil)
                   GOTO 9999
                ENDIF
                rga_listlat(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax)=0.0

             ELSE ! sinon il faut re-allouer si nb. point plus important

                IF (il_maxlistpoint<(MAXVAL(iga_listnbpoint(1:il_jregion,1:il_nbblocmax))+1)) THEN

                   IF ((.NOT.ALLOCATED(rga_listlon)).OR.(.NOT.ALLOCATED(rga_listlat))) THEN
                      WRITE (0,*) 'error algo : not allocate rga_listlon or rga_listlat'
                      jv_status = -1
                      CLOSE(UNIT=il_numfil)
                      GOTO 9999
                   ENDIF
                   il_maxlistpoint1=MAXVAL(iga_listnbpoint(1:il_jregion,1:il_nbblocmax))+1

                   IF (ALLOCATED(rla_listlon1)) DEALLOCATE(rla_listlon1)
                   ALLOCATE(rla_listlon1(1:il_maxlistpoint1,1:ig_nbregion,1:il_nbblocmax),stat=il_err)
                   IF (il_err/=0) THEN
                      WRITE (0,*) 'error allocate rla_listlon1(',il_maxlistpoint1,&
                           & ig_nbregion,il_nbblocmax,'), il_err=',il_err
                      jv_status = -1
                      CLOSE(UNIT=il_numfil)
                      GOTO 9999
                   ENDIF
                   rla_listlon1(1:il_maxlistpoint1,1:ig_nbregion,1:il_nbblocmax)=0.0
                   rla_listlon1(1:il_maxlistpoint,1:il_jregion,1:il_nbblocmax) = &
                        & rga_listlon(1:il_maxlistpoint,1:il_jregion,1:il_nbblocmax)

                   IF (ALLOCATED(rla_listlat1)) DEALLOCATE(rla_listlat1)
                   ALLOCATE(rla_listlat1(1:il_maxlistpoint1,1:ig_nbregion,1:il_nbblocmax),stat=il_err)
                   IF (il_err/=0) THEN
                      WRITE (0,*) 'error allocate rla_listlat1(',il_maxlistpoint1,&
                           & ig_nbregion,il_nbblocmax,'), il_err=',il_err
                      jv_status = -1
                      CLOSE(UNIT=il_numfil)
                      GOTO 9999
                   ENDIF
                   rla_listlat1(1:il_maxlistpoint1,1:ig_nbregion,1:il_nbblocmax)=0.0
                   rla_listlat1(1:il_maxlistpoint,1:il_jregion,1:il_nbblocmax) = &
                        & rga_listlat(1:il_maxlistpoint,1:il_jregion,1:il_nbblocmax)

                   il_maxlistpoint=il_maxlistpoint1     
                   DEALLOCATE(rga_listlon)
                   ALLOCATE(rga_listlon(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax),stat=il_err)
                   IF (il_err/=0) THEN
                      WRITE (0,*) 'error allocate rga_listlon(',il_maxlistpoint,&
                           & ig_nbregion,il_nbblocmax,'), il_err=',il_err
                      jv_status = -1
                      CLOSE(UNIT=il_numfil)
                      GOTO 9999
                   ENDIF
                   rga_listlon(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax) = &
                        & rla_listlon1(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax)
                   DEALLOCATE(rla_listlon1)

                   DEALLOCATE(rga_listlat)
                   ALLOCATE(rga_listlat(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax),stat=il_err)
                   IF (il_err/=0) THEN
                      WRITE (0,*) 'error allocate rga_listlat(',il_maxlistpoint,&
                           & ig_nbregion,il_nbblocmax,'), il_err=',il_err
                      jv_status = -1
                      CLOSE(UNIT=il_numfil)
                      GOTO 9999
                   ENDIF
                   rga_listlat(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax) = &
                        & rla_listlat1(1:il_maxlistpoint,1:ig_nbregion,1:il_nbblocmax)
                   DEALLOCATE(rla_listlat1)

                ENDIF
             ENDIF  ! fin des allocations

             ! Lecture de la serie de points
             DO il_jpoint=1,iga_listnbpoint(il_jregion,il_jbloc)
                cl_text=''
                il_err = 0
                cl_text=readnextline(il_numfil,cp_textexclusion,il_err)
                IF ( il_err /= 0 ) THEN
                   WRITE(0,*) 'error readnextline:unavailable txt format'
                   jv_status = -1
                   CLOSE(UNIT=il_numfil)
                   GOTO 9999
                ENDIF
                READ(cl_text,FMT=*,IOSTAT=il_err) rga_listlon(il_jpoint,il_jregion,il_jbloc),&
                     & rga_listlat(il_jpoint,il_jregion,il_jbloc)
             ENDDO
             il_jpoint=iga_listnbpoint(il_jregion,il_jbloc)+1

             ! on rajoute un dernier point egale au premier
             rga_listlon(il_jpoint,il_jregion,il_jbloc)=rga_listlon(1,il_jregion,il_jbloc)
             rga_listlat(il_jpoint,il_jregion,il_jbloc)=rga_listlat(1,il_jregion,il_jbloc)

!!$           if (il_jbloc==1) then
!!$              print *, ' '
!!$              print '(a,i3)', 'num region =',il_jregion
!!$              print '(a,i3)', 'nb bloc    =',iga_listnbbloc(il_jregion)
!!$           endif
!!$           print '(a,i3,a,i3)', 'nbpoint[bloc=',il_jbloc,']=',&
!!$                & iga_listnbpoint(il_jregion,il_jbloc)

          ENDDO ! fin boucle bloc: il_jbloc=1,iga_listnbbloc(il_jregion)

       CASE default
          write(0,*)'erreur sur le type de region',il_jtyperegion
          jv_status = -1
          CLOSE(UNIT=il_numfil)
          GOTO 9999
       END SELECT

    ENDDO ! fin de la boucle: il_jregion=1,ig_nbregion

    ! fermeture du fichier
    CLOSE(UNIT=il_numfil)

    ! Test de sortie:
!!$  DO il_jregion=1,ig_nbregion
!!$     WRITE(*,'(2I8,F9.1)')iga_typeregion(il_jregion),iga_listnbbloc(il_jregion),rga_valeur1(il_jregion)
!!$     SELECT CASE (iga_typeregion(il_jregion))
!!$     CASE (1) ! cas rectangle
!!$        WRITE(*,'(4F9.2)')  rga_info(1:4,il_jregion)
!!$     CASE (2)! cas rond 
!!$        WRITE(*,'(4F9.2)')  rga_info(1:4,il_jregion)
!!$        WRITE(23,'(2I8,F9.1)')iga_typeregion(il_jregion),iga_listnbbloc(il_jregion),rga_valeur1(il_jregion)
!!$        WRITE(23,'(4F9.2)')  rga_info(1:4,il_jregion)
!!$     CASE (3) ! Cas d'une region a plusieurs bloc
!!$        DO il_jbloc=1,iga_listnbbloc(il_jregion)
!!$           WRITE(*,'(2i8)')il_jbloc,iga_listnbpoint(il_jregion,il_jbloc)
!!$           DO il_jpoint=1,iga_listnbpoint(il_jregion,il_jbloc)-1
!!$              WRITE(*,'(2f9.2)',advance="no")&
!!$                   & rga_listlon(il_jpoint,il_jregion,il_jbloc),&
!!$                   &rga_listlat(il_jpoint,il_jregion,il_jbloc)
!!$           ENDDO
!!$           il_jpoint=iga_listnbpoint(il_jregion,il_jbloc)
!!$           WRITE(*,'(2f9.2)')&
!!$                & rga_listlon(il_jpoint,il_jregion,il_jbloc),&
!!$                &rga_listlat(il_jpoint,il_jregion,il_jbloc)
!!$        ENDDO
!!$     END SELECT
!!$  ENDDO ! fin boucle: il_jregion=1,ig_nbregion 



9999 CONTINUE
  END SUBROUTINE LireDefBoite


  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE IdentifierBoite --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Mars 2007
  ! Morceaux repris de createcmz.F90 (C.E. Testut)
  ! A partir d'une longitude,latitude,renvoie le numero de la boite et un mode d erreur
  ! Attention: les longitudes sont passees en [-180,180[ )

  SUBROUTINE IdentifierBoite(rd_lon,rd_lat,rd_IDboite,id_err)

    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 

    USE table_boite
    IMPLICIT NONE

    REAL(kind=8),INTENT(in) :: rd_lon  ! longitude du point 
    REAL(kind=8),INTENT(in) :: rd_lat  ! latitude du point

    REAL(kind=8),INTENT(out) :: rd_IDboite  ! ID de la boite
    INTEGER,INTENT(out) :: id_err   ! flag d erreur

    ! Variables locales
    INTEGER :: il_numout1,il_numout2
    INTEGER :: ib_jregion,ib_jbloc,il_jpoint
    REAL(kind=8) :: rl_lon
    REAL(kind=8) :: rl_lonmin,rl_lonmax,rl_latmin,rl_latmax
    REAL(kind=8) :: rl_lonpos,rl_latpos,rl_distmax,rl_distmin
    INTEGER :: il_nbdoublepoint_bords,il_nbdoublepoint_int,il_nbdoublepoint
    REAL(kind=8) :: rl_rad,rl_dcoscos2,rl_dcossin2,rl_dsin2,rl_dist
    REAL(kind=8) :: rl_distmaxdiff,rl_distmindiff,rl_dcoscos,rl_dcossin,rl_dsin
    REAL(kind=8),PARAMETER :: rp_ra = 6371.229
    LOGICAL :: ll_inarea,ll_bords
    INTEGER :: il_err

!!$    INTERFACE
!!$       LOGICAL FUNCTION inarea(rd_lon,rd_lat,rda_listlon,rda_listlat,ld_bords,id_err)
!!$         IMPLICIT NONE
!!$         REAL(kind=8), INTENT(in) :: rd_lon,rd_lat
!!$         REAL(kind=8), DIMENSION(:), INTENT(in)  :: rda_listlon,rda_listlat
!!$         LOGICAL, INTENT(out) :: ld_bords
!!$         INTEGER,INTENT(out) :: id_err
!!$       END FUNCTION inarea
!!$    END INTERFACE

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    id_err = 0  ! initialisation du code d erreur
    il_numout1=0
    il_numout2=0
    rl_rad = 2. * ASIN( 1. )  / 180.

    rd_IDboite = rg_valeur0

    ! Verification des longitudes (entre [-180,180[ )
    rl_lon = rd_lon
    if ( rl_lon >= 180. ) rl_lon = rl_lon -360.
    if ( rl_lon < -180. ) rl_lon = rl_lon +360.

    ! Boucle sur les regions
    ! ----------------------
    DO ib_jregion=1,ig_nbregion

       ! Cas des regions quadrangles
       SELECT CASE (iga_typeregion(ib_jregion))
       CASE (1)

          ! on attribut des variables locales 
          ! plus simple a manipuler:
          rl_lonmin=rga_info(1,ib_jregion)
          rl_latmin=rga_info(2,ib_jregion)
          rl_lonmax=rga_info(3,ib_jregion)
          rl_latmax=rga_info(4,ib_jregion)

          ! test sur les limites du quadrangle
          IF ( (rl_lon <= rl_lonmax).AND.(rl_lon >= rl_lonmin)&
               .AND.(rd_lat <= rl_latmax).AND.(rd_lat >= rl_latmin) ) THEN

             ! test si valeur OK et si rd_IDboite attribuee deja pour une boite precedente
             IF ( (rga_valeur1(ib_jregion) /= rg_valeur0) .AND. (rd_IDboite /= rg_valeur0)) THEN

                ! point sur une limite ?
                IF ( (rl_lon == rl_lonmax).OR.(rl_lon == rl_lonmin)&
                     .OR.(rd_lat == rl_latmax).OR.(rd_lat == rl_latmin) ) THEN

                   il_nbdoublepoint_bords=il_nbdoublepoint_bords+1
                   WRITE (il_numout1,*) 'doublon bords en (lon,lat)=',rl_lon,rd_lat,&
                        &' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                        &')  et region(??,value=',rd_IDboite,')'
                ELSE ! sinon il est dans de la region
                   WRITE (il_numout2,*) 'doublon interne en (lon,lat)=',rl_lon,rd_lat,&
                        &' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                        &')  et region(??,value=',rd_IDboite,')'
                   il_nbdoublepoint_int=il_nbdoublepoint_int+1
                ENDIF
                il_nbdoublepoint=il_nbdoublepoint+1

             ENDIF
             rd_IDboite = rga_valeur1(ib_jregion)
          ENDIF

          ! cas des regions rondes
       CASE (2)
          ! on attribut des variables locales 
          ! plus simple a manipuler:
          rl_lonpos=rga_info(1,ib_jregion)
          rl_latpos=rga_info(2,ib_jregion)
          rl_distmin=rga_info(3,ib_jregion)
          rl_distmax=rga_info(4,ib_jregion)

          rl_lonpos=rl_rad*rl_lonpos
          rl_latpos=rl_rad*rl_latpos
          rl_dcoscos2=COS(rl_latpos)*COS(rl_lonpos)
          rl_dcossin2=COS(rl_latpos)*SIN(rl_lonpos)
          rl_dsin2=SIN(rl_latpos)

          rl_distmaxdiff=rl_distmax/rp_ra
          rl_distmaxdiff=rl_distmaxdiff*rl_distmaxdiff
          rl_distmindiff=rl_distmin/rp_ra
          rl_distmindiff=rl_distmindiff*rl_distmindiff

          rl_dcoscos=COS(rl_rad*rd_lat)*COS(rl_rad*rl_lon)-rl_dcoscos2
          rl_dcossin=COS(rl_rad*rd_lat)*SIN(rl_rad*rl_lon)-rl_dcossin2
          rl_dsin=SIN(rl_rad*rd_lat)-rl_dsin2
          rl_dist=rl_dcoscos**2+rl_dcossin**2+rl_dsin**2 

          IF ( rl_dist<=rl_distmaxdiff) THEN
             ! test de bordure du cercle
             IF (rl_dist==rl_distmaxdiff) THEN
                il_nbdoublepoint_bords=il_nbdoublepoint_bords+1
                WRITE (il_numout1,*) 'doublon bords en (lon,lat)=',rl_lon,rd_lat,&
                     & ' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                     & ')  et region(??,value=',rd_IDboite,')'
             ELSE
                WRITE (il_numout2,*) 'doublon interne en (lon,lat)=',rl_lon,rd_lat,&
                     & ' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                     & ')  et region(??,value=',rd_IDboite,')'
                il_nbdoublepoint_int=il_nbdoublepoint_int+1
             ENDIF
             il_nbdoublepoint=il_nbdoublepoint+1
          ENDIF
          IF (rl_dist<=rl_distmindiff) rd_IDboite=rga_valeur1(ib_jregion)
          IF ((rl_dist<=rl_distmaxdiff).AND.(rl_dist>rl_distmindiff)) &
               & rd_IDboite=(rga_valeur1(ib_jregion)-rg_valeur0)*&
               & (rl_distmax-rp_ra*SQRT(rl_dist))/&
               & (rl_distmax-rl_distmin)+rg_valeur0


          ! cas des regions polygones
       CASE(3)

          ! boucle sur les blocs de la region
          DO ib_jbloc=1,iga_listnbbloc(ib_jregion)

             ! commodite d ecriture           
             il_jpoint=iga_listnbpoint(ib_jregion,ib_jbloc)+1

             IF (rd_IDboite/=rga_valeur1(ib_jregion)) THEN

                ! appel a la fonction inarea              
                ll_inarea=inarea(rl_lon,rd_lat,rga_listlon(1:il_jpoint,ib_jregion,ib_jbloc),&
                     & rga_listlat(1:il_jpoint,ib_jregion,ib_jbloc),&
                     & ld_bords=ll_bords,id_err=il_err)
                IF ( il_err /= 0 ) THEN
                   id_err = -1
                   GOTO 9999
                ENDIF

                IF (ll_inarea) THEN
                   IF (rd_IDboite/=rg_valeur0) THEN
                      IF (ll_bords)THEN
                         il_nbdoublepoint_bords=il_nbdoublepoint_bords+1
                         WRITE (il_numout1,*) 'doublon bords en (lon,lat)=',rl_lon,rd_lat,&
                              & ' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                              & ')  et region(??,value=',rd_IDboite,')'
                      ELSE
                         WRITE (il_numout2,*) 'doublon interne en (lon,lat)=',rl_lon,rd_lat,&
                              & ' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                              & ')  et region(??,value=',rd_IDboite,')'
                         il_nbdoublepoint_int=il_nbdoublepoint_int+1
                      ENDIF
                      il_nbdoublepoint=il_nbdoublepoint+1
                   ENDIF
                   rd_IDboite=rga_valeur1(ib_jregion)
                ENDIF
             ENDIF

          ENDDO
       END SELECT
    ENDDO ! fin boucle regions: ib_jregion=1,ig_nbregion


9999 CONTINUE
  END SUBROUTINE IdentifierBoite

  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE CaracBoite --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Mars 2007
  ! Pour une boite (son IDboite), renvoie les points caracteristiques de la boite, ainsi
  ! que le barycentre
  ! Le nombre de point caracteristique sert a controler si on a effectivemetn trouve des
  ! caracteristiques pour cette boite

  SUBROUTINE CaracBoite(rd_IDboite,id_Ncarac,id_err)

    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 

    USE table_boite
    IMPLICIT NONE

    REAL(kind=8),INTENT(in) :: rd_IDboite  ! ID de la boite
    integer,intent(out) :: id_Ncarac ! Nombre de pt caracteristique (0 si rien trouve)
    INTEGER,INTENT(out) :: id_err   ! flag d erreur

    ! Variables locales
    integer :: il_jregion,il_jbloc,il_jpoint, ib_p
    real(kind=8)  :: rl_lonmin,rl_lonmax,rl_latmin,rl_latmax
    real(kind=8)  :: rl_lon_bary,rl_lat_bary

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    id_err = 0  ! initialisation du code d erreur

    ! test sur la valeur par defaut
    ! -----------------------------
    if ( rd_IDboite==rg_valeur0 ) then
       write(0,*)'CaracBoite:rd_IDboite = rg_valeur0 !', rd_IDboite,rg_valeur0
       id_err = -1
       goto 9999
    endif

    ! recherche de la boite
    ! ---------------------
    il_jregion=1
    do while ( (il_jregion <= ig_nbregion) .and. .not.(rd_IDboite==rga_valeur1(il_jregion)))
       il_jregion = il_jregion + 1
    end do
    ! cas ou on a rien trouve
    if ( il_jregion > ig_nbregion ) then
       id_Ncarac = 0
       goto 9999
    else
       SELECT CASE (iga_typeregion(il_jregion))
       CASE (1) ! cas rectangle
          id_Ncarac = 5
          rl_lonmin=rga_info(1,il_jregion)
          rl_latmin=rga_info(2,il_jregion)
          rl_lonmax=rga_info(3,il_jregion)
          rl_latmax=rga_info(4,il_jregion)
          if ( rl_lonmin > rl_lonmax ) then
             rl_lon_bary=rl_lonmin+rl_lonmax+360.
             rl_lon_bary=rl_lon_bary/2.
             if (rl_lon_bary .gt. 180. ) rl_lon_bary = rl_lon_bary -360.
          else
             rl_lon_bary=rl_lonmin+rl_lonmax
             rl_lon_bary=rl_lon_bary/2.
          endif
          rl_lat_bary = (rl_latmin + rl_latmax)/2.

          WRITE(*,'(4F9.2)')  rga_info(1:4,il_jregion)
          WRITE(*,'(2F9.2)')rl_lonmin,rl_latmin
          WRITE(*,'(2F9.2)')rl_lonmin,rl_latmax
          WRITE(*,'(2F9.2)')rl_lonmax,rl_latmax
          WRITE(*,'(2F9.2)')rl_lonmax,rl_latmin
          WRITE(*,'(2F9.2)')rl_lonmin,rl_latmin
          WRITE(*,'(2F9.2)')rl_lon_bary,rl_lat_bary

       CASE (2)! cas rond
          id_Ncarac = 1
!!$        WRITE(*,'(4F9.2)')  rga_info(1:4,il_jregion)
!!$        WRITE(23,'(2I8,F9.1)')iga_typeregion(il_jregion),iga_listnbbloc(il_jregion),rga_valeur1(il_jregion)
!!$        WRITE(23,'(4F9.2)')  rga_info(1:4,il_jregion)
       CASE (3) ! Cas d'une region a plusieurs bloc
          id_Ncarac = 0
          DO il_jbloc=1,iga_listnbbloc(il_jregion)
!!$           WRITE(*,'(2i8)')il_jbloc,iga_listnbpoint(il_jregion,il_jbloc)
             id_Ncarac = id_Ncarac + iga_listnbpoint(il_jregion,il_jbloc)
!!$           DO il_jpoint=1,iga_listnbpoint(il_jregion,il_jbloc)
!!$              WRITE(*,'(2f9.2)',advance="no")&
!!$                   & rga_listlon(il_jpoint,il_jregion,il_jbloc),&
!!$                   &rga_listlat(il_jpoint,il_jregion,il_jbloc)
!!$           ENDDO

          ENDDO
       END SELECT

       print*,rd_IDboite,il_jregion,rga_valeur1(il_jregion),iga_typeregion(il_jregion),id_Ncarac
    endif


9999 CONTINUE
  END SUBROUTINE CaracBoite

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

  !---------------------------------------------------------------------------------------
  !
  !                          ---   FUNCTION  inarea --- 
  !
  !---------------------------------------------------------------------------------------

  LOGICAL FUNCTION inarea(rd_lon,rd_lat,rda_listlon,rda_listlat,ld_bords,id_err)
    !
    !  Purpose : Test if a point is inside contour 
    !  -------
    !  Author: C.E. Testut (01/2005)
    ! Repris par FHZ; mars 2007, pour inclure des tests de sortie dans "id_err"
    !
    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 

    IMPLICIT NONE
    !
    REAL(kind=8), INTENT(in) :: rd_lon,rd_lat
    REAL(kind=8), DIMENSION(:), INTENT(in)  :: rda_listlon,rda_listlat
    LOGICAL, INTENT(out) :: ld_bords
    INTEGER,INTENT(out) :: id_err

    INTEGER :: il_jplist
    INTEGER, DIMENSION(:), ALLOCATABLE :: ila_cidx
    INTEGER :: il_err,il_cshift,il_jp,il_jp0,il_jp1,il_jk,il_jpk
    LOGICAL :: ll_nonborder
    INTEGER :: il_cinf,il_csup
    REAL(kind=8) :: rl_scont,rl_delta

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    id_err = 0  ! initialisation du code d erreur

    il_jplist=SIZE(rda_listlon,1)
    IF ((il_jplist/=SIZE(rda_listlat,1)).OR.(il_jplist<4)) THEN
       WRITE (0,*) 'inarea: error using this function: (il_jplist/=size(rda_listlat,1)) =',&
            & il_jplist,SIZE(rda_listlat,1)
       id_err = -1
       GOTO 9999
    ENDIF
    IF (rda_listlon(1)/=rda_listlon(il_jplist)) THEN
       WRITE (0,*) 'inarea: error using this function: (listlon(1)/=listlon(jplist)) =',&
            & rda_listlon(1),rda_listlon(il_jplist)
       WRITE (0,*) 'inarea: Contour is not closed!'
       id_err = -1
       GOTO 9999
    ENDIF
    IF (rda_listlat(1)/=rda_listlat(il_jplist)) THEN
       WRITE (0,*) 'inarea: error using this function: (listlat(1)/=listlat(jplist)) =',&
            & rda_listlat(1),rda_listlat(il_jplist)
       WRITE (0,*) 'inarea: Contour is not closed!'
       id_err = -1
       GOTO 9999
    ENDIF
    !
    IF (ALLOCATED(ila_cidx)) DEALLOCATE(ila_cidx)
    ALLOCATE (ila_cidx(1:il_jplist), stat=il_err )
    IF (il_err/=0) THEN
       WRITE (0,*) 'inarea: error allocate ila_cidx(',il_jplist,'), il_err=',il_err
       id_err = -1
       GOTO 9999
    ENDIF
    ila_cidx(1:il_jplist)=0
    !
    ll_nonborder=.FALSE.
    ll_nonborder= ll_nonborder.OR.(rd_lon/=rda_listlon(1))
    ll_nonborder= ll_nonborder.OR.(rd_lat/=rda_listlat(1))
    !
    IF (ll_nonborder) THEN
       ! on cherche le 1er pt tel que sa listlon/=lon
       il_jp=1
       DO WHILE (rd_lon==rda_listlon(il_jp).AND.(il_jp<il_jplist))
          il_jp=il_jp+1
       ENDDO
       IF (il_jp==il_jplist) THEN
          WRITE (0,*) 'inarea: error :All points of contour are colinear!'
          id_err = -1
          GOTO 9999
       ENDIF
       il_cshift = il_jp - 1
       DO il_jp=1,il_jplist
          ila_cidx(il_jp)=il_jp+il_cshift
          IF (ila_cidx(il_jp)>il_jplist) &
               & ila_cidx(il_jp)=ila_cidx(il_jp)-il_jplist+1
       ENDDO
    ENDIF

    il_cinf=0     
    il_csup=0     
    il_jp=1

    DO WHILE (ll_nonborder.AND.(il_jp<il_jplist) )
       !
       il_jp0=ila_cidx(il_jp)
       il_jp1=ila_cidx(il_jp+1)
       rl_scont=(rda_listlon(il_jp0)-rd_lon)*(rda_listlon(il_jp1)-rd_lon)
       !
       IF (rl_scont==0.0) THEN
          !
          il_jk=1
          DO WHILE (rl_scont==0.0)
             il_jk=il_jk+1
             il_jpk=ila_cidx(il_jp+il_jk)
             rl_scont=(rda_listlon(il_jp0)-rd_lon)*(rda_listlon(il_jpk)-rd_lon)
          ENDDO
          il_jpk=ila_cidx(il_jp+il_jk-1)
          IF (rl_scont<0.0) THEN
             rl_scont=(rda_listlat(il_jp1)-rd_lat)*(rda_listlat(il_jpk)-rd_lat)
             IF (rl_scont<=0.0) THEN
                ll_nonborder=.FALSE.
             ELSE
                IF (rda_listlat(il_jp1)>rd_lat) THEN
                   il_csup=il_csup+1
                ELSE 
                   il_cinf=il_cinf+1
                ENDIF
             ENDIF
          ELSE
             rl_scont=(rda_listlat(il_jp1)-rd_lat)*(rda_listlat(il_jpk)-rd_lat)
             IF (rl_scont<=0.) ll_nonborder=.FALSE.
          ENDIF
          il_jp=il_jp+il_jk
          !
       ELSE
          IF (rl_scont<0.0) THEN
             rl_scont=(rda_listlat(il_jp0)-rd_lat)*(rda_listlat(il_jp1)-rd_lat)
             IF (rl_scont>0.0) THEN
                IF (rda_listlat(il_jp0)>rd_lat) THEN
                   il_csup=il_csup+1
                ELSE 
                   il_cinf=il_cinf+1
                ENDIF
             ELSE
                rl_delta=(rda_listlat(il_jp1)-rda_listlat(il_jp))/&
                     & (rda_listlon(il_jp1)-rda_listlon(il_jp))
                rl_scont=rda_listlat(il_jp0)-rd_lat - rl_delta * &
                     & (rda_listlon(il_jp0)-rd_lon)
                IF (rl_scont==0.0) THEN
                   ll_nonborder=.FALSE.
                ELSE
                   IF (rl_scont>0.0) THEN
                      il_csup=il_csup+1
                   ELSE 
                      il_cinf=il_cinf+1
                   ENDIF
                ENDIF
             ENDIF
          ENDIF
          il_jp=il_jp+1
          !
       ENDIF
    ENDDO
    !
    DEALLOCATE(ila_cidx)
    !
    IF (ll_nonborder) THEN
       ld_bords=.FALSE.
       IF (MOD(il_csup,2)==0) THEN
          IF (MOD(il_cinf,2)==0) THEN
             inarea=.FALSE.
          ELSE
             WRITE(0,*)'inarea: error 1000'
             id_err = -1
             GOTO 9999
          ENDIF
       ELSE
          IF (MOD(il_cinf,2)==0) THEN
             WRITE(0,*)'inarea: error 1001'
             id_err = -1
             GOTO 9999
          ELSE
             inarea=.TRUE.
          ENDIF
       ENDIF
    ELSE
       ld_bords=.TRUE.
       inarea=.TRUE.
    ENDIF


9999 CONTINUE
    IF (ALLOCATED(ila_cidx)) DEALLOCATE(ila_cidx)
    RETURN

  END FUNCTION inarea
  !
  !========================================================
  !
END MODULE BOITE
