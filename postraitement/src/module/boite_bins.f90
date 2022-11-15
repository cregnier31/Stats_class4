MODULE boite_bins

  !---------------------------------------------------------------------------------------
  !
  !                          ---   MODULE BOITE  --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: CHR 09/2010
  
  ! Ce module vise a:
  ! - Lire le fichier de definition des boites globales de bins de boites régulières. Ces boites sont definies par
  !   une serie de points lonmin lonmax latmin latmax avec un numéro de boîte.
  !   Chaque boite a un numero unique. L'ensemble des boites decrit completement
  !   l'ocean global. Propriete connexe: plusieurs boites vont definir des macros regions
  ! - Detection: Identifier si un point (lon,lat) se trouve dans une boite, et renvoyer
  !   le numero de la boite.Attention: apriori convention des longitudes: [-180,180]
  ! - Caracteriser chaque boite, en renvoyant, pour un numero de boite, les positions
  !   des points, ainsi que le barycentre

  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE  LireDefBoitebins --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: CHR 09/2010
  ! Lecture du fichier de definition des boites

  PRIVATE
  PUBLIC :: LireDefBoitebins,IdentifierBoiteBins,CaracBoiteBins
CONTAINS
  SUBROUTINE LireDefBoitebins (cd_fconfigtxt,jv_status)

    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 
!    USE miol_util
!    USE miol_param
    USE miol
    USE mcal
    USE table_boite
    IMPLICIT NONE

    ! Arguments de la routine
    ! cd_fconfigtxt: IN/ nom du fichier de definition des boites
    ! jv_status : OUT/Status sur la routine

    CHARACTER(len=*),INTENT(in) :: cd_fconfigtxt
    INTEGER,INTENT(out) :: jv_status

    ! Variables locales: ouverture du fichier
    CHARACTER(len=256) :: cl_fname
    LOGICAL :: ll_err,ll_exist
    INTEGER :: il_numfil,eof,il_l,& ! numero logique fichier cd_fconfigtxt
               il_err,il_ji,eofbis
    REAL(KIND=4)  :: rl_essai,rl_box,rl_lonmin,rl_latmin,rl_lonmax,rl_latmax      

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
    CALL MIOL_getFreeLu(il_numfil)
    OPEN(UNIT=il_numfil,FILE=TRIM(cl_fname),status='old',form='formatted',&
         & iostat=il_err)
    IF ( il_err /= 0 ) THEN
       WRITE(0,*) 'error opening file',TRIM(cl_fname)
       jv_status = -1
       GOTO 9999
    ENDIF
    il_l=0
    eof=0
    !** Lecture du nombre de regions
    !** On compte le nombre de lignes du fichier
    DO WHILE (eof == 0 )
       READ(il_numfil,*,iostat=eof) rl_box
       IF (eof==0) then !* la lecture s'est bien passee
          !* on incremente le compteur du nombre de lignes
          il_l=il_l+1
       ENDIF
    ENDDO
   CLOSE(il_numfil)
   !** Recuperation de la longueur de l'enregistrement
    ig_nbregion=il_l
    !WRITE(0,*)'Nombre de regions=',ig_nbregion
    ! Dans le cas (attendu) ou il y a un nombre positif de regions
    IF (ig_nbregion>=1) THEN

       ! Initialisation des variables "regions"
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

    ENDIF

    ! lecture region: boucle sur le nombre de region (ig_nbregion)
    CALL MIOL_getFreeLu(il_numfil)
    OPEN(UNIT=il_numfil,FILE=TRIM(cl_fname),status='old',form='formatted',&
         & iostat=il_err,action='read')
    IF ( il_err /= 0 ) THEN
       WRITE(0,*) 'error opening file',TRIM(cl_fname)                                                                                                   
       jv_status = -1
       GOTO 9999
    ENDIF
        
    eofbis=0
    il_ji=1     
    !* Lecture Fichier 
    DO  WHILE (eofbis == 0 .AND. il_ji <= ig_nbregion )
       READ(il_numfil,*,iostat=eofbis) rl_box,rl_lonmin,rl_latmin,rl_lonmax,rl_latmax
       !WRITE(80,9001) il_ji,rl_lonmin,rl_latmin,rl_lonmax,rl_latmax
       IF (il_err/=0) THEN
          WRITE (0,*) 'error reading configtxt[',TRIM(cd_fconfigtxt)
          CLOSE(UNIT=il_numfil)
          GOTO 9999
        ELSE 
       ! print *,'Dans le else ::',il_ji
        rga_valeur1(il_ji)=rl_box
        rga_info(1,il_ji)=rl_lonmin 
        rga_info(2,il_ji)=rl_latmin 
        rga_info(3,il_ji)=rl_lonmax 
        rga_info(4,il_ji)=rl_latmax 
        il_ji=il_ji+1
        !WRITE(8,*) rl_box,rl_lonmin,rl_latmin,rl_lonmax,rl_latmax
        !WRITE(0,*) rl_box,rl_lonmin,rl_latmin,rl_lonmax,rl_latmax
       ENDIF 
    ENDDO ! fin de la boucle while
    ! fermeture du fichier
    CLOSE(UNIT=il_numfil)

!DO il_ji=1,ig_nbregion
!    PRINT*,'BOX,lon,lat,min,max',rga_valeur1(il_ji),rga_info(1,il_ji),rga_info(2,il_ji),rga_info(3,il_ji),rga_info(4,il_ji)
!ENDDO
9001 FORMAT(I5,' ',F6.1,' ',F6.1,' ',F6.1,' ',F6.1)
9999 CONTINUE
  END SUBROUTINE LireDefBoitebins


  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE IdentifierBoite --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: CHR Septembre 2010
  ! A partir d'une longitude,latitude,renvoie le numero de la boite et un mode d erreur
  ! Attention: les longitudes sont passees en [-180,180[ )

  SUBROUTINE IdentifierBoiteBins(rd_lon,rd_lat,rd_IDboite,id_err)

    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 

    USE table_boite
    IMPLICIT NONE

    REAL(kind=8),INTENT(in) :: rd_lon  ! longitude du point 
    REAL(kind=8),INTENT(in) :: rd_lat  ! latitude du point

    REAL(kind=8),INTENT(out) :: rd_IDboite  ! ID de la boite
    INTEGER,INTENT(out) :: id_err   ! flag d erreur

    ! Variables locales
    INTEGER :: ib_jregion,ib_jbloc,il_jpoint
    REAL(kind=8) :: rl_lon
    REAL(kind=8) :: rl_lonmin,rl_lonmax,rl_latmin,rl_latmax
    INTEGER :: il_nbdoublepoint_bords,il_nbdoublepoint_int,il_nbdoublepoint
    LOGICAL :: ll_inarea,ll_bords
    INTEGER :: il_err,il_numout1,il_numout2

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------
    il_numout1=0  
    il_numout2=0
    id_err = 0  ! initialisation du code d erreur
    il_nbdoublepoint_bords=0
    il_nbdoublepoint_int=0
    il_nbdoublepoint=0
    rg_valeur0=1
    rd_IDboite = rg_valeur0

    ! Verification des longitudes (entre [-180,180[ )
    rl_lon = rd_lon
    IF ( rl_lon >= 180. ) rl_lon = rl_lon -360.
    IF ( rl_lon < -180. ) rl_lon = rl_lon +360.

    ! Boucle sur les regions
    ! ----------------------
    DO ib_jregion=1,ig_nbregion
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
                   !WRITE (il_numout1,*) 'doublon bords en (lon,lat)=',rl_lon,rd_lat,&
                   !     &' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                   !     &')  et region(??,value=',rd_IDboite,')'
                ELSE ! sinon il est dans de la region
                   !WRITE (il_numout2,*) 'doublon interne en (lon,lat)=',rl_lon,rd_lat,&
                   !     &' pour region (',ib_jregion,',value=',rga_valeur1(ib_jregion),&
                   !     &')  et region(??,value=',rd_IDboite,')'
                   il_nbdoublepoint_int=il_nbdoublepoint_int+1
                ENDIF
                il_nbdoublepoint=il_nbdoublepoint+1

             ENDIF
             rd_IDboite = rga_valeur1(ib_jregion)
          ENDIF

    ENDDO ! fin boucle regions: ib_jregion=1,ig_nbregion


9999 CONTINUE
  END SUBROUTINE IdentifierBoiteBins

  !---------------------------------------------------------------------------------------
  !
  !                          ---   SUB ROUTINE CaracBoite --- 
  !
  !---------------------------------------------------------------------------------------

  ! Auteur: FHZ Mars 2007
  ! Pour une boite (son IDboite), renvoie les points caracteristiques de la boite, ainsi
  ! que le barycentre
  ! Le nombre de point caracteristique sert a controler si on a effectivement trouve des
  ! caracteristiques pour cette boite
  ! Modifs : C.REGNIER Septembre 2010

  SUBROUTINE CaracBoiteBins(rd_IDboite,id_Ncarac,id_err,rd_lon_bary,rd_lat_bary)

    !---------------------------------------------------------------------------------------
    !                          ---  Arguments  --- 

    USE table_boite
    IMPLICIT NONE

    REAL(kind=8),INTENT(in) :: rd_IDboite  ! ID de la boite
    INTEGER,INTENT(out) :: id_Ncarac ! Nombre de pt caracteristique (0 si rien trouve)
    INTEGER,INTENT(out) :: id_err   ! flag d erreur
    REAL(kind=8),INTENT(OUT),OPTIONAL  :: rd_lon_bary,rd_lat_bary

    ! Variables locales
    INTEGER :: il_jregion,il_jbloc,il_jpoint, ib_p
    REAL(kind=8)  :: rl_lonmin,rl_lonmax,rl_latmin,rl_latmax
    REAL(kind=8)  :: rl_lon_bary,rl_lat_bary

    !---------------------------------------------------------------------------------------
    !                          ---  CODE  --- 
    !---------------------------------------------------------------------------------------

    id_err = 0  ! initialisation du code d erreur

    ! test sur la valeur par defaut
    ! -----------------------------
    IF ( rd_IDboite==rg_valeur0 ) THEN
       WRITE(0,*)'CaracBoite:rd_IDboite = rg_valeur0 !', rd_IDboite,rg_valeur0
       id_err = -1
       GOTO 9999
    ENDIF

    ! recherche de la boite
    ! ---------------------
    il_jregion=1
    DO WHILE ( (il_jregion <= ig_nbregion) .AND. .NOT.(rd_IDboite==rga_valeur1(il_jregion)))
       il_jregion = il_jregion + 1
    END DO
    ! cas ou on a rien trouve
    IF ( il_jregion > ig_nbregion ) THEN
       id_Ncarac = 0
       GOTO 9999
    ELSE
          id_Ncarac = 5
          rl_lonmin=rga_info(1,il_jregion)
          rl_latmin=rga_info(2,il_jregion)
          rl_lonmax=rga_info(3,il_jregion)
          rl_latmax=rga_info(4,il_jregion)
          IF ( rl_lonmin > rl_lonmax ) THEN
             rl_lon_bary=rl_lonmin+rl_lonmax+360.
             rl_lon_bary=rl_lon_bary/2.
             IF (rl_lon_bary .GT. 180. ) rl_lon_bary = rl_lon_bary -360.
          ELSE
             rl_lon_bary=rl_lonmin+rl_lonmax
             rl_lon_bary=rl_lon_bary/2.
          ENDIF
          rl_lat_bary = (rl_latmin + rl_latmax)/2.

          !WRITE(*,'(4F9.2)'),rga_info(1:4,il_jregion)
          WRITE(*,'(2F9.2)')rl_lonmin,rl_latmin
          WRITE(*,'(2F9.2)')rl_lonmin,rl_latmax
          WRITE(*,'(2F9.2)')rl_lonmax,rl_latmin
          WRITE(*,'(2F9.2)')rl_lonmax,rl_latmax
          WRITE(*,'(2F9.2)')rl_lon_bary,rl_lat_bary
          IF (PRESENT(rd_lon_bary).AND. PRESENT(rd_lat_bary)) THEN     
            rd_lon_bary=rl_lon_bary
            rd_lat_bary=rl_lat_bary
          ENDIF
    ENDIF

9999 CONTINUE
  END SUBROUTINE CaracBoiteBins

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
END MODULE boite_bins
