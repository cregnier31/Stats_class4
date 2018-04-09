MODULE DIAG_CLASS4

  !*======================================================================
  !                       ***  MODULE diag_class4  ***
  !                Ce module les operations de diagnostics             
  !                pour les classe4                                  *
  !                                                                  *
  !======================================================================
  !
  !
  PRIVATE 
  PUBLIC :: affect_table_class4,fermer_table_class4,definir_classe_profondeur,&
       & stat_boite_class4,fermer_stat_class4
  !
CONTAINS

  !
  !===============================================================
  !
  SUBROUTINE affect_table_class4(id_stat,cd_utils,cd_modele)
    !
    !**** affect_table_class4
    !
    !     Purpose:
    !     --------
    !     Affectation des tableaux/parametres globaux necessaires
    !     au calcul des Class 4
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item cd_filename
    !
    !     Output : \\
    !       id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !
    !     Externals:
    !     ----------
    !     table_class4,table_ARGO
    !
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0         C.REGNIER       09/13           Adaptation to reanalysis parameter 
    !     1.1         C.REGNIER       12/13           Parameters are now in a namelist 
    !
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE table_ARGO
    USE table_boite
    USE table_class4
    USE MIOL
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !

    !
    !**   0.3 Dummy variables
    !
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    INTEGER(KIND=4)                                    :: id_ParamFile,il_nbparams,&
                                                          il_status,il_ji,il_ind,il_i
    CHARACTER(LEN=255),INTENT(IN)                      :: cd_utils
    CHARACTER(LEN=30),INTENT(IN)                       :: cd_modele
    CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE        :: cda_ParamFile
    CHARACTER(LEN=255)                                 :: cl_tmp,cl_paramfile
    !
    !*--------------------------------------------------------------------------
    !
    !**  Lecture de la namelist
    cl_paramfile=TRIM(cd_utils)//TRIM(FP_ParamNameFile)//TRIM(cd_modele)//'.in'
    WRITE(0,*) 'Lecture param name ',cl_paramfile
    INQUIRE(FILE=cl_paramfile,EXIST=lg_ParamFile)
    IF ( lg_ParamFile ) THEN
       NAMELIST / liste_param  / il_nbparams 
       !** Ouverture du fichier avec le nom des paramètres LUS 
       CALL MIOL_getFreeLu(id_paramFile)
       OPEN (unit=id_ParamFile,file=cl_paramfile,&
             status='old',form='formatted',&
            & iostat=il_status)
       IF ( il_status /= 0 ) THEN
          WRITE(0,'(a,a)')'Cannot open param file ',cl_paramfile
          CLOSE(id_ParamFile)
          CALL EXIT(2)
       ENDIF
      ! Lecture de l entete
      READ(id_ParamFile,liste_param)
      ! alloc tableau avec nom des variables
      ALLOCATE(cda_ParamFile(il_nbparams), stat=il_status)
      IF ( il_status /= 0 ) THEN
        WRITE(0,*) 'Liste param memory allocation error.'
        CALL flush(0)
        CALL EXIT(1)
      ENDIF
      !WRITE(0,*) 'Nombre de variables ::',il_nbparams
      !** Remplit le tableaux avec le nom des fichiers selectionnés 
      ! boucle de lecture sur les fichiers        
      DO il_ji=1,il_nbparams
         READ(id_ParamFile,FMT='(A)') cl_tmp
         cda_ParamFile(il_ji)=TRIM(cl_tmp)
         !WRITE(0,*) 'Variable lue :: ',cda_ParamFile(il_ji)
      ENDDO
      CLOSE(id_ParamFile)
    ELSE
       WRITE(0,*) 'Param file don t exist'
       CALL EXIT(2)
    ENDIF
    !** initialisation
    id_stat = 0

    ! nombre de parametre traites
    ig_ParamStat = il_nbparams
    ! Attribution des parametres en fonction de la
    ! definition dans la table ARGO
    IF ( ALLOCATED (iga_IndParamStat) ) DEALLOCATE (iga_IndParamStat)
    ALLOCATE(iga_IndParamStat(ig_ParamStat))
    DO il_i=1,il_nbparams
      SELECT CASE(cda_ParamFile(il_i))
        CASE ('TEMP')
         il_ind=ip_TEMP
        CASE ('TEMP_ADJUSTED')
         il_ind=ip_TEMP
        CASE ('PSAL')
         il_ind=ip_PSAL
        CASE ('PSAL_ADJUSTED')
         il_ind=ip_PSAL
        CASE ('HDCST_TEMP')
         il_ind=ip_HDCST_TEMP
        CASE ('HDCST_PSAL')
         il_ind=ip_HDCST_PSAL
        CASE ('ANA_TEMP')
         il_ind=ip_ANA_TEMP
        CASE ('ANA_PSAL')
         il_ind=ip_ANA_PSAL
        CASE ('FRCST1D_TEMP')
         il_ind=ip_FRCST1D_TEMP
        CASE ('FRCST1D_PSAL')
         il_ind=ip_FRCST1D_PSAL 
        CASE ('FRCST3D_TEMP')
         il_ind=ip_FRCST3D_TEMP
        CASE ('FRCST3D_PSAL')
          il_ind=ip_FRCST3D_PSAL 
        CASE ('FRCST5D_TEMP')
         il_ind=ip_FRCST5D_TEMP
        CASE ('FRCST5D_PSAL')
         il_ind=ip_FRCST5D_PSAL 
        CASE ('FRCST6D_TEMP')
         il_ind=ip_FRCST6D_TEMP
        CASE ('FRCST6D_PSAL')
         il_ind=ip_FRCST6D_PSAL 
        CASE ('PERS_TEMP')
         il_ind=ip_PERS_TEMP
        CASE ('PERS_PSAL')
         il_ind=ip_PERS_PSAL
        CASE ('PERS3D_TEMP')
         il_ind=ip_PERS3D_TEMP
        CASE ('PERS3D_PSAL')
         il_ind=ip_PERS3D_PSAL 
        CASE ('PERS6D_TEMP')
         il_ind=ip_PERS6D_TEMP
        CASE ('PERS6D_PSAL')
         il_ind=ip_PERS6D_PSAL 
        CASE ('TMLEV05')
         il_ind=ip_TMLEV05
        CASE ('SMLEV05')
         il_ind=ip_SMLEV05
        CASE ('TMARV')
         il_ind=ip_TMARV
        CASE ('SMARV')
         il_ind=ip_SMARV
        CASE ('TMLEV09')
         il_ind=ip_TMLEV09
        CASE ('SMLEV09')
         il_ind=ip_SMLEV09
        CASE ('TMLEV13')
         il_ind=ip_TMLEV13
        CASE ('SMLEV13')
         il_ind=ip_SMLEV13
        CASE('TMARV11')
         il_ind=ip_TMARV11
        CASE('SMARV11')
         il_ind=ip_SMARV11
        CASE('TMLEV98')
         il_ind=ip_TMLEV98
        CASE('SMLEV98')
         il_ind=ip_SMLEV98
        CASE('TMMED')
         il_ind=ip_TMMED
        CASE('SMMED')
         il_ind=ip_SMMED
        CASE default
          WRITE(0,*) 'Variable not known :', cda_ParamFile(il_i)
          CALL EXIT(1)
      END SELECT
      iga_IndParamStat(il_i)=il_ind
    ENDDO 
    !** Valeur par defaut des numero de boite CLASS4
    rg_IDboiteVal_Def = 99999.    

    ! Affectation du nombre de donnees de stat de differences OK et NOK
    ! par classe de profondeur et parametre
    IF ( ALLOCATED (ig_StatOK) ) DEALLOCATE (ig_StatOK)
    ALLOCATE(ig_StatOK(ig_NbDepthDef+1,ig_ParamStat))
    ig_StatOK(:,:) = 0

    IF ( ALLOCATED (ig_StatNOK) ) DEALLOCATE (ig_StatNOK)
    ALLOCATE(ig_StatNOK(ig_NbDepthDef+1,ig_ParamStat))
    ig_StatNOK(:,:) = 0

    !** Definition et initialisation des tableaux de stat 
   ! IF ( ALLOCATED (iga_NbProfRejetBathyBoite) ) DEALLOCATE (iga_NbProfRejetBathyBoite)
   ! ALLOCATE(iga_NbProfRejetBathyBoite(ig_nbregion))
   ! iga_NbProfRejetBathyBoite(:)=0 
    IF ( ALLOCATED (iga_NbProfTempBoite) ) DEALLOCATE (iga_NbProfTempBoite) 
    ALLOCATE(iga_NbProfTempBoite(ig_nbregion))
    iga_NbProfTempBoite(:)=0
    IF ( ALLOCATED (iga_NbProfPsalBoite) ) DEALLOCATE (iga_NbProfPsalBoite)
    ALLOCATE(iga_NbProfPsalBoite(ig_nbregion))
    iga_NbProfPsalBoite(:)=0
    IF ( ALLOCATED (iga_NbVal) ) DEALLOCATE (iga_NbVal)
    ALLOCATE(iga_NbVal(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
    iga_NbVal(:,:,:) = 0
    IF ( ALLOCATED (rga_moy) ) DEALLOCATE (rga_moy)
    ALLOCATE(rga_moy(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
    rga_moy(:,:,:) = 0.
    IF ( ALLOCATED (rga_rms) ) DEALLOCATE (rga_rms)
    ALLOCATE(rga_rms(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
    rga_rms(:,:,:) = 0.
    IF ( ALLOCATED (rga_moy_diff) ) DEALLOCATE (rga_moy_diff)
    ALLOCATE(rga_moy_diff(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
    rga_moy_diff(:,:,:) = 0.
    IF ( ALLOCATED (rga_rms_diff) ) DEALLOCATE (rga_rms_diff)
    ALLOCATE(rga_rms_diff(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
    rga_rms_diff(:,:,:) = 0.

  END SUBROUTINE affect_table_class4
  !
  !===============================================================
  !

  SUBROUTINE definir_classe_profondeur(id_stat,cd_utils)
    !
    !**** definir_classe_profondeur
    !
    !     Purpose:
    !     --------
    !     Alloue les tableaux de classe de profondeur
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item cd_filename
    !
    !     Output : \\
    !       id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !
    !     Externals:
    !     ----------
    !     table_class4,MIOL_getFreeLu
    !
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        F. Hernandez     Mai 2008        Creation
    !     1.1        
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE miol
    USE mcal
    USE table_class4
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !
    INTEGER(kind=4)    :: il_DepthDefFile
    INTEGER(kind=4)    :: il_ib,il_status
    !
    !**   0.3 Dummy variables
    !
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    CHARACTER(LEN=255),INTENT(IN)                      :: cd_utils
    !
    !*--------------------------------------------------------------------------
    !
    !** initialisation
    id_stat = 0

    !** Classes de profondeurs attribuees en fonction de existence
    !** fichier classe de profondeur
    lg_DepthDefFile = .FALSE.
    INQUIRE(FILE=TRIM(cd_utils)//TRIM(FP_DepthDefFile),EXIST=lg_DepthDefFile)
    IF ( lg_DepthDefFile ) THEN

       !** Ouverture du fichier de classes de profondeurs
       CALL MIOL_getFreeLu(il_DepthDefFile)
       OPEN (unit=il_DepthDefFile,file=TRIM(cd_utils)//TRIM(FP_DepthDefFile),status='old',form='formatted',&
            & iostat=il_status,action='read')  
       IF ( il_status /= 0 ) THEN
          WRITE(0,'(a,a)')'Cannot open Depth file ',TRIM(cd_utils)//TRIM(FP_DepthDefFile)
          CLOSE(il_DepthDefFile)
          CALL EXIT(2)  
       ENDIF

       !** lecture du fichier: premier point qui donne la taille des classes de prof a lire
       READ(il_DepthDefFile,*) ig_NbDepthDef
       !** alloc dyn et lecture des classes de prof
       IF ( ALLOCATED(rga_DepthMin)) DEALLOCATE (rga_DepthMin)
       ALLOCATE ( rga_DepthMin (ig_NbDepthDef+1) )
       IF ( ALLOCATED(rga_DepthMax)) DEALLOCATE (rga_DepthMax)
       ALLOCATE ( rga_DepthMax (ig_NbDepthDef+1) )
       DO il_ib = 1 , ig_NbDepthDef
          READ(il_DepthDefFile,*) rga_DepthMin(il_ib),rga_DepthMax(il_ib)
       ENDDO
       !** fermeture du fichier
       CLOSE(il_DepthDefFile)

       !** on rajoute les valeurs par defaut
       rga_DepthMin(ig_NbDepthDef+1)=MINVAL(rga_DepthMin)
       rga_DepthMax(ig_NbDepthDef+1)=MAXVAL(rga_DepthMax)
       !rga_DepthMin(ig_NbDepthDef+1)=rg_DepthMin0
       !rga_DepthMax(ig_NbDepthDef+1)=rg_DepthMax0

    ELSE
       ig_NbDepthDef = 0
       IF ( ALLOCATED(rga_DepthMin)) DEALLOCATE (rga_DepthMin)
       ALLOCATE ( rga_DepthMin (ig_NbDepthDef+1) )
       IF ( ALLOCATED(rga_DepthMax)) DEALLOCATE (rga_DepthMax)
       ALLOCATE ( rga_DepthMax (ig_NbDepthDef+1) )
       rga_DepthMin(ig_NbDepthDef+1)=rg_DepthMin0
       rga_DepthMax(ig_NbDepthDef+1)=rg_DepthMax0
    ENDIF

END SUBROUTINE definir_classe_profondeur
  !
  !===============================================================
  !
  SUBROUTINE fermer_table_class4(id_stat)
    !
    !**** fermer_table_class4
    !
    !     Purpose:
    !     --------
    !     Des-allocation des tableaux/parametres globaux necessaires
    !     au calcul des Class 4
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item cd_filename
    !
    !     Output : \\
    !       id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !
    !     Externals:
    !     ----------
    !     table_class4
    !
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        F. Hernandez     Mai 2008        Creation
    !     1.1        
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE table_class4
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !

    !
    !**   0.3 Dummy variables
    !
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    !
    !*--------------------------------------------------------------------------
    !

    !** initialisation
    id_stat = 0


    !** Desallocation
    IF ( ALLOCATED (iga_IndParamStat) ) DEALLOCATE (iga_IndParamStat)
    IF ( ALLOCATED (ig_StatOK) ) DEALLOCATE (ig_StatOK)
    IF ( ALLOCATED (ig_StatNOK) ) DEALLOCATE (ig_StatNOK)
    IF ( ALLOCATED (rga_DepthMin)) DEALLOCATE (rga_DepthMin)
    IF ( ALLOCATED (rga_DepthMax)) DEALLOCATE (rga_DepthMax)
    IF ( ALLOCATED (iga_NbProfTempBoite) ) DEALLOCATE (iga_NbProfTempBoite)
    IF ( ALLOCATED (iga_NbProfPsalBoite) ) DEALLOCATE (iga_NbProfPsalBoite)
!    IF ( ALLOCATED (iga_NbProfRejetBathyBoite) ) DEALLOCATE (iga_NbProfRejetBathyBoite)
    IF ( ALLOCATED (iga_NbVal) ) DEALLOCATE (iga_NbVal)
    IF ( ALLOCATED (rga_moy) ) DEALLOCATE (rga_moy)
    IF ( ALLOCATED (rga_rms) ) DEALLOCATE (rga_rms)
    IF ( ALLOCATED (rga_moy_diff) ) DEALLOCATE (rga_moy_diff)
    IF ( ALLOCATED (rga_rms_diff) ) DEALLOCATE (rga_rms_diff)

  END SUBROUTINE fermer_table_class4
  !
  !===============================================================
  !
  SUBROUTINE stat_boite_class4(id_stat,cd_logdir)
    !
    !**** stat_boite_class4
    !
    !     Purpose:
    !     --------
    !     Renseigner et calculer les stats par profondeurs, boite et profils
    !       
    !
    !     Input : \\
    !     ------
    !
    !     Output : \\
    !       id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !     
    !     Externals:
    !     ----------
    !     table_ARGO,table_boite,table_class4,IdentifierBoite
    !
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        F. Hernandez     Avril 2008      Decouple la partie validation de profil
    !                                                 (dans valid_profile) et la partie
    !                                                 calcul des statistiques par boite
    !     1.1        F. Hernandez     Avril 2008      Prise en compte bathy et seuil
    !     2.0        FHZ              Mai 2008        Modification des tests
    !                                                 Passage dans module diag_class4
    !                                                 Recherche des boites
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE table_ARGO
    USE BOITE
    USE boite_bins
    USE table_boite
    USE table_class4
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !
    INTEGER(KIND=4)                                    :: ib_p,il_k,il_s,il_status,il_i,il_ii,il_IndReg
    INTEGER(KIND=4)                                    :: il_juld_qc_NOK,il_position_qc_NOK,il_j
    INTEGER(kind=4)                                    :: il_dsi_NOK,il_NO_PRES_DEPH,il_PRES_ET_DEPH
    
    !
    REAL(kind=8):: rl_lon,rl_lat,rl_IDboite
    !
    !
    !**   0.3 Dummy variables
    !

    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    CHARACTER(LEN=255),INTENT(IN)                      :: cd_logdir
    !
    !*--------------------------------------------------------------------------
    !
    !** initialisation
    id_stat = 0
#if defined key_debug
    WRITE(0,*) 'Routine stat_boite_class4 '
#endif
    !** allocation tableau des numeros de boite pour chaque profil
    IF ( ALLOCATED (rga_IDboite)) DEALLOCATE (rga_IDboite)
    ALLOCATE ( rga_IDboite(ig_nprof))
    rga_IDboite(:)=rg_IDboiteVal_Def

    !** allocation tableau nombre de valeur valide par profil,
    !   pour chaque parametre, et chaque classe de profondeur
    IF ( ALLOCATED (iga_NbValProf)) DEALLOCATE (iga_NbValProf)
    ALLOCATE (iga_NbValProf(ig_nprof,ig_ParamStat,ig_NbDepthDef+1))
    iga_NbValProf(:,:,:) = 0

    IF ( ALLOCATED (rga_StatProf)) DEALLOCATE (rga_StatProf)
    ALLOCATE (rga_StatProf(ig_nprof,ig_ParamStat,ig_NbDepthDef+1,IP_NbStat))
    rga_StatProf(:,:,:,:) = 0.
    !** Boucle sur chaque profil
    DO ib_p = 1,ig_nprof

    !** DEBUG
#if defined key_debug
    WRITE(0,*) 'Indice du profil ::',ib_p,iga_MesPsalVal(ib_p),iga_MesTempVal(ib_p)
#endif
       !** On traite le profil si il y a des mesures de temperatures ou de salinite valides
       IF ( iga_MesPsalVal(ib_p) > 0 .OR. iga_MesTempVal(ib_p) > 0 ) THEN
          !** recherche du numero de boite
          rl_lon=dgpa_LONGITUDE(ib_p)
          rl_lat=dgpa_LATITUDE(ib_p)
          SELECT CASE (ig_typegrid)
            CASE(1)
               CALL IdentifierBoite(rl_lon,rl_lat,rl_IDboite,il_status)
            CASE(2)
               CALL IdentifierBoiteBins(rl_lon,rl_lat,rl_IDboite,il_status)
          ENDSELECT
          IF ( il_status /= 0 ) THEN
             WRITE(*,*) 'Pb d Identification boite',rl_lon,rl_lat
             CALL EXIT(1)
          ENDIF
#if defined key_debug
    WRITE(0,*) 'Call IdentifierBoite ok ::',rl_lon,rl_lat,rl_IDboite
#endif          
          rga_IDboite(ib_p)=rl_IDboite
          !** Attribution d un indice de boite
          il_IndReg=0
          !** Recherche de l'indice dans le tableau
          DO il_i=1,ig_nbregion
             IF (rga_valeur1(il_i).EQ.rga_IDboite(ib_p)) THEN
                il_IndReg=il_i
             ENDIF
          ENDDO
#if defined key_debug
    WRITE(0,*) 'Coordonnées du point :  ',rl_lon,rl_lat
    WRITE(0,*) 'Valeur de la region :  ',il_IndReg
    WRITE(0,*) 'iga_MesTempVal(ib_p) :  ',iga_MesTempVal(ib_p)
#endif          
    
          !** test sur la bathymetrie
          IF ( iga_BathyProfil(ib_p) .LE. rg_BathySeuil ) THEN
#if defined key_debug
    WRITE(0,*) 'STATS TEMP '
#endif          
             !** STATISTIQUES sur la TEMPERATURE
             !** si il y a des valeurs valides dans le profil de temperature
             IF ( iga_MesTempVal(ib_p) > 0 .and. il_IndReg > 0 ) THEN
                !** on incremente le compteur du nb de profil T dans une boite
                iga_NbProfTempBoite(il_IndReg)=iga_NbProfTempBoite(il_IndReg)+1
                !** boucle sur TEMP et les indices de parametres associes a la temperature
                !DO il_i=1,ig_NbDepthDef+1
                !   !rga_diff_loc(1,il_i,ib_p+ig_indi)=dgpa_LONGITUDE(ib_p)
                !   !rga_diff_loc(2,il_i,ib_p+ig_indi)=dgpa_LATITUDE(ib_p)
                !   !   WRITE(17,'(a,1x,f10.2,5x)')'Longitude ::',dgpa_LONGITUDE(ib_p)
                !   !   WRITE(17,'(a,1x,f10.2,5x)')'Latitude ::',dgpa_LATITUDE(ib_p)
                !ENDDO
                DO il_s=1,ig_ParamStat,2
                   il_k = iga_IndParamStat(il_s)
                   IF ( iga_IndParam(ib_p,il_k) > 0) THEN
                      !** On remplit le tableau avec les valeurs des profils par classe de profondeur
                      DO il_i=1,ig_NbDepthDef+1
                            CALL remplir_tableau(rga_DepthMin(il_i),rga_DepthMax(il_i),&
                                 & ib_p,il_IndReg,il_s,il_i,&
                                 & iga_NbValProf(ib_p,il_s,il_i),rga_StatProf(ib_p,il_s,il_i,1),&
                                 & rga_StatProf(ib_p,il_s,il_i,2),rga_StatProf(ib_p,il_s,il_i,3),&
                                 & rga_StatProf(ib_p,il_s,il_i,4),1,cd_logdir)
                         !** Mise a jour des tableaux de resultats de statistiques par boite
                         iga_NbVal(il_IndReg,il_s,il_i)=iga_NbVal(il_IndReg,il_s,il_i)+&
                              & iga_NbValProf(ib_p,il_s,il_i)    
                         rga_moy(il_IndReg,il_s,il_i)=rga_moy(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,1)
                         rga_rms(il_IndReg,il_s,il_i)=rga_rms(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,2)
                         rga_moy_diff(il_IndReg,il_s,il_i)=rga_moy_diff(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,3)
                         rga_rms_diff(il_IndReg,il_s,il_i)=rga_rms_diff(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,4)
                        !* DEBUG
                    !    IF ( il_IndReg <= 22 .AND. il_i==1 ) WRITE(30,*) '----------------------------------------------------------'
                    !    IF ( il_IndReg <= 22 .AND. il_i==1 ) WRITE(30,*) 'valeur temp en MED::',rga_StatProf(ib_p,il_s,1,4)
                    !    IF ( il_IndReg <= 22 .AND. il_i==1 ) WRITE(30,*) 'valeur cumulée temp en MED::',rga_rms_diff(il_IndReg,il_s,1)
                    !    IF ( il_IndReg <= 22 .AND. il_i==1 ) WRITE(30,*) 'nb valeur temp en MED::',iga_NbVal(il_IndReg,il_s,il_i)
                    !    IF ( il_IndReg <= 22 .AND. il_i==1 ) WRITE(30,*) '----------------------------------------------------------'
                        !**
                        ! IF ( il_s .GT. 2) THEN
                        !     IF ( INT(iga_NbValProf(ib_p,il_s,il_i)) /= 0 ) THEN 
                        !       rga_diff_loc(il_s,il_i,ib_p+ig_indi)=rga_StatProf(ib_p,il_s,il_i,3)/&
                        !         & INT(iga_NbValProf(ib_p,il_s,il_i))
                        !     ELSE
                        !       rga_diff_loc(il_s,il_i,ib_p+ig_indi)=0.0
                        !     ENDIF
                        !  ENDIF

                      ENDDO
                   ENDIF
                ENDDO  ! il_s=1,ig_ParamStat,2
             ENDIF
             !** STATISTIQUES sur la SALINITE

             !** si il y a des valeurs valides dans le profil de salinite
             IF ( iga_MesPsalVal(ib_p) > 0 .and. il_IndReg > 0 ) THEN
                !** on incremente le compteur du nb de profil S dans une boite
                iga_NbProfPsalBoite(il_IndReg)=iga_NbProfPsalBoite(il_IndReg)+1
#if defined key_debug
    WRITE(0,*) 'STATS PSAL '
#endif          
                !** boucle sur PSAL et les indices de parametres associes a la salinite
              DO il_s=2,ig_ParamStat,2
                   il_k = iga_IndParamStat(il_s)
                   IF ( iga_IndParam(ib_p,il_k) > 0 ) THEN
                      !** On remplit le tableau avec les valeurs des profils par classe de profondeur
                      DO il_i=1,ig_NbDepthDef+1
                           CALL remplir_tableau(rga_DepthMin(il_i),rga_DepthMax(il_i),&
                                 & ib_p,il_IndReg,il_s,il_i,&
                                 & iga_NbValProf(ib_p,il_s,il_i),rga_StatProf(ib_p,il_s,il_i,1),&
                                 & rga_StatProf(ib_p,il_s,il_i,2),rga_StatProf(ib_p,il_s,il_i,3),&
                                 & rga_StatProf(ib_p,il_s,il_i,4),2,cd_logdir)
                         !** Mise a jour des tableaux de resultats de statistiques par boite
                         iga_NbVal(il_IndReg,il_s,il_i)=iga_NbVal(il_IndReg,il_s,il_i)+&
                              & iga_NbValProf(ib_p,il_s,il_i)    
                         rga_moy(il_IndReg,il_s,il_i)=rga_moy(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,1)
                         rga_rms(il_IndReg,il_s,il_i)=rga_rms(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,2)
                         rga_moy_diff(il_IndReg,il_s,il_i)=rga_moy_diff(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,3)
                         rga_rms_diff(il_IndReg,il_s,il_i)=rga_rms_diff(il_IndReg,il_s,il_i)+&
                              & rga_StatProf(ib_p,il_s,il_i,4)
                   !      IF ( il_s .GT. 2) THEN 
                   !         IF ( INT(iga_NbValProf(ib_p,il_s,il_i)) /= 0 ) THEN 
                   !           rga_diff_loc(il_s,il_i,ib_p+ig_indi)=rga_StatProf(ib_p,il_s,il_i,3)/&
                   !              & INT(iga_NbValProf(ib_p,il_s,il_i))
                   !         ELSE
                   !           rga_diff_loc(il_s,il_i,ib_p+ig_indi)=0.0
                   !         ENDIF
                   !      ENDIF
                      ENDDO
                   ENDIF
                ENDDO  ! il_s=2,ig_ParamStat,2

             ENDIF

             !** calcul des stats pour ce profil
             DO il_s = 1 , ig_ParamStat
                il_k = iga_IndParamStat(il_s)
                DO il_i=1,ig_NbDepthDef + 1
                   IF ( iga_NbValProf(ib_p,il_s,il_i) .NE. 0 ) THEN
                      rga_StatProf(ib_p,il_s,il_i,:) = rga_StatProf(ib_p,il_s,il_i,:) / &
                           & iga_NbValProf(ib_p,il_s,il_i)
                      rga_StatProf(ib_p,il_s,il_i,2) = SQRT(rga_StatProf(ib_p,il_s,il_i,2))
                      rga_StatProf(ib_p,il_s,il_i,4) = SQRT(rga_StatProf(ib_p,il_s,il_i,4))
                   ELSE
                      rga_StatProf(ib_p,il_s,il_i,:) = 0.
                   ENDIF
                ENDDO
             ENDDO

          ELSE
          ! iga_NbProfRejetBathyBoite(il_IndReg) = iga_NbProfRejetBathyBoite(il_IndReg) + 1
             ! Ecriture dans le fichier de rejet de profil
             OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicRejetBathy),form='FORMATTED',POSITION='APPEND',STATUS='old')
             WRITE(50,'(I8,2x,f9.4,2x,f9.4,2x,i8,2x,a,2x,a)',advance="yes") INT(rga_IDboite(ib_p)),&
                  & dgpa_LONGITUDE(ib_p),dgpa_LATITUDE(ib_p),&
                  iga_BathyProfil(ib_p),&
                  & TRIM(cgpa_PLATFORM_NUMBER(ib_p,1)),TRIM(cgpa_WMO_INST_TYPE(ib_p,1))
             CLOSE(50)

          ENDIF ! fin test sur la bathy

       ENDIF ! fin test sur valeurs valides T/S dans le profil

    ENDDO ! ib_p = 1,ig_nprof

  END SUBROUTINE stat_boite_class4
  !
  !
  !===============================================================
  !
  SUBROUTINE remplir_tableau(rd_DepthMin,rd_DepthMax,id_IndProf,id_IndReg,id_param,id_IndDepth,&
       &id_nval,dd_moy,dd_rms,dd_moy_diff,dd_rms_diff,id_var,cd_logdir)
    !
    !**** remplir_tableau
    !
    !     Purpose:
    !     --------
    !     Pour un profil (id_IndProf)
    !     Par classe de profondeur (rd_DepthMin,rd_DepthMax) avec un indice
    !     de classe de profondeur (id_IndDepth)
    !     calcule pour chaque region  (id_IndReg) et pour
    !     les parametres choisis (id_param):
    !     - le nombre de mesures valides dans la couche d eau
    !     - la valeur cumulee moyenne du parametre dans la couche d eau
    !     - la valeur cumulee quadratique du parametre dans la couche d eau
    !     Et par rapport a un parametre de reference (TEMP ou PSAL)
    !     - la difference cumulee moyenne dans la couche d eau
    !     - la difference cumulee quadratique dans la couche d eau
    !      en fonction des niveaux de profondeurs
    !     Renvoie aussi les valeurs cumulees pour les 4 stats:
    !            dd_moy,dd_rms,dd_moy_diff,dd_rms_diff
    !     Et le nb de points dans chaque boite : id_nval
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        C.REGNIER        Aout 2007       Validation plateform
    !     1.1        FHZ              Aout 2007      
    !     1.2        C.REGNIER        Fevrier 2008    - Modif pour tester des profils  
    !                                                 ayant un bon flag mais irréaliste
    !                                                 - On enleve les profils à 0 (flag mal mis)
    !     2.0        FHZ             Mai 2008         Modification des tests
    !                                                 Passage dans module diag_class4
    !*--------------------------------------------------------------------------
    !
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    USE table_ARGO
    USE table_boite
    USE table_class4  
    IMPLICIT NONE
    !
    !**   0.1 Include files and modules
    !
    INTEGER(KIND=4),INTENT(IN)  :: id_IndProf,id_var
    INTEGER(KIND=4),INTENT(IN)  :: id_IndReg,id_param,id_IndDepth
    REAL(KIND=4),INTENT(IN)     :: rd_DepthMin,rd_DepthMax
    CHARACTER(LEN=255),INTENT(IN) :: cd_logdir
    REAL(KIND=8),INTENT(OUT)    :: dd_moy,dd_rms,dd_moy_diff,dd_rms_diff
    INTEGER(KIND=4),INTENT(OUT) :: id_nval

    INTEGER(KIND=4)             :: il_i,il_count_clim
    REAL(KIND=4)                :: rl_var,rl_diff,rl_diff2,rl_diff3,rl_temp
    CHARACTER(LEN=255)          :: cl_TEMPHighDeph,cl_PSALHighDeph
    LOGICAL                     :: ll_exist_PSAL,ll_exist_TEMP,ll_exist_HighTEMP,ll_exist_HighPSAL
        
    !
    !*---------------------------------------------------------------------------
    !
    !** initialisation des variables statistiques en local
    ! (elle correspondent specifiquement au profil teste, sur la profondeur
    !  testee, sur la region testee, pour le parametre teste
    id_nval = 0
    dd_moy = 0.
    dd_rms = 0.
    dd_moy_diff = 0.
    dd_rms_diff = 0. 
    ll_exist_PSAL=.FALSE.
    ll_exist_TEMP=.FALSE.
    ll_exist_HighTEMP=.FALSE.
    ll_exist_HighPSAL=.FALSE.
700 FORMAT(a50,1x,a16,1x,f16.8,2x,f10.2,2x,2i5,2x,f9.4,2x,f9.4,2x,a,2x,a,2x,a)
750 FORMAT(a100,1x,a16,1x,i5,1x,i5,f16.8,2x,f10.2,2x,2i5,2x,f9.4,2x,f9.4,2x,a,2x,a,2x,a,2x,a,2x,i5)
760 FORMAT(a100,1x,a16,1x,i5,1x,i5,f16.8,2x,f16.8,2x,f16.8,2x,f10.2,2x,2i5,2x,f9.4,2x,f9.4,2x,a,2x,a,2x,a,2x,a,2x,i5)
800 FORMAT(a100,2x,i5,2x,i5,2x,f10.2,2x,f10.2,2x,f10.2,2x,f10.2,2x,f10.2)
!#if defined key_debug
!    WRITE(0,*) 'Remplir tableau'
!#endif

    !** boucle sur toutes les valeurs d un profil
    DO il_i=1,ig_nlevels
       !** test sur la profondeur
       IF ( rga_DepthVal(il_i,id_IndProf) > rd_DepthMin .AND. &
            & rga_DepthVal(il_i,id_IndProf) .LE. rd_DepthMax .AND. &
            & rga_DepthVal(il_i,id_IndProf) .NE. rg_DepthVal_Def ) THEN
!#if defined key_debug
!    WRITE(0,*) 'test sur la profondeur ::',rga_DepthVal(il_i,id_IndProf),rd_DepthMin,rd_DepthMax ,rg_DepthVal_Def
!#endif
         rl_diff2=9999.
         rl_diff3=9999.
         IF ( id_var == 1 ) THEN
            rl_temp=rga_TempVal(il_i,id_IndProf)
#if defined key_computePot
            rl_temp=rga_TempPotVal(il_i,id_IndProf)
#endif        
            IF (lg_TMLEV05) THEN
              rl_diff2=rgpa_TMLEV05(il_i,id_IndProf)-rl_temp
              il_count_clim=1
            ENDIF
            IF (lg_TMLEV09) THEN        
              rl_diff2=rgpa_TMLEV09(il_i,id_IndProf)-rl_temp
              il_count_clim=1
            ENDIF
            IF (lg_TMMED) THEN
              rl_diff2=rgpa_TMMED(il_i,id_IndProf)-rl_temp
              il_count_clim=1
            ENDIF
            IF (lg_TMARV)  THEN
              rl_diff3=rgpa_TMARV(il_i,id_IndProf)-rl_temp
              il_count_clim=2
            ENDIF
            IF (lg_TMARV11) THEN
              rl_diff3=rgpa_TMARV11(il_i,id_IndProf)-rl_temp
              il_count_clim=2
            ENDIF
!#if defined key_debug
!    WRITE(0,*) 'Diff clim ::',rl_diff2,rl_diff3,iga_IndParamStat(id_param)
!#endif
            SELECT CASE (iga_IndParamStat(id_param))
               CASE(ip_TEMP)
                  rl_var=rl_temp
               CASE(ip_HDCST_TEMP)
                  rl_var = rgpa_HDCST_TEMP(il_i,id_IndProf)
               CASE(ip_ANA_TEMP)
                  rl_var = rgpa_ANA_TEMP(il_i,id_IndProf)
               CASE(ip_FRCST1D_TEMP)
                  rl_var = rgpa_FRCST1D_TEMP(il_i,id_IndProf)
               CASE(ip_FRCST3D_TEMP)
                  rl_var = rgpa_FRCST3D_TEMP(il_i,id_IndProf)
               CASE(ip_FRCST5D_TEMP)
                  rl_var = rgpa_FRCST5D_TEMP(il_i,id_IndProf)
               CASE(ip_FRCST6D_TEMP)
                  rl_var = rgpa_FRCST6D_TEMP(il_i,id_IndProf)
               CASE(ip_PERS_TEMP)
                  rl_var = rgpa_PERS_TEMP(il_i,id_IndProf)
               CASE(ip_PERS3D_TEMP)
                  rl_var = rgpa_PERS3D_TEMP(il_i,id_IndProf)
               CASE(ip_PERS6D_TEMP)
                  rl_var = rgpa_PERS6D_TEMP(il_i,id_IndProf)
               CASE(ip_TMLEV05)
                  rl_var = rgpa_TMLEV05(il_i,id_IndProf)
                  rl_temp=rga_TempVal(il_i,id_IndProf)
               CASE(ip_TMLEV98)
                  rl_var = rgpa_TMLEV98(il_i,id_IndProf)
                  rl_temp=rga_TempVal(il_i,id_IndProf)
               CASE( ip_TMLEV09)
                  rl_var = rgpa_TMLEV09(il_i,id_IndProf) 
                  rl_temp=rga_TempVal(il_i,id_IndProf)
               CASE( ip_TMLEV13)
                  rl_var = rgpa_TMLEV13(il_i,id_IndProf) 
                  rl_temp=rga_TempVal(il_i,id_IndProf)
               CASE( ip_TMMED)
                  rl_var = rgpa_TMMED(il_i,id_IndProf) 
                  rl_temp=rga_TempVal(il_i,id_IndProf)
               CASE(ip_TMARV) 
                  rl_var = rgpa_TMARV(il_i,id_IndProf)
                  rl_temp=rga_TempVal(il_i,id_IndProf)
                CASE(ip_TMARV11)
                  rl_var = rgpa_TMARV11(il_i,id_IndProf)
                  rl_temp=rga_TempVal(il_i,id_IndProf)
            ENDSELECT
            IF ( rl_temp .NE. rg_TempVal_Def .AND. rl_var < 9999. ) THEN
                rl_diff = rl_var - rl_temp 
                IF (rl_diff2 /= 9999. .AND. rl_diff3 /= 9999.) THEN
                    IF ( ABS(rl_diff).GE.rg_EcartTempMax &
                          .AND. ABS(rl_diff2).GE.rg_EcartTempMax &
                          .AND. ABS(rl_diff3).GE.rg_EcartTempMax) THEN
                       ig_StatNOK(id_IndDepth,id_param) =ig_StatNOK(id_IndDepth,id_param) + 1
!#if defined key_debug
!    WRITE(0,*) 'Diff TEMP NOK ::',rl_diff,rl_diff2,rl_diff3
!#endif
                       ! Output: valeur a rejeter
                       ! note: on n ecrit pas les valeurs pour la colonne totale
                       ! (inutile car deja
                       ! dans un segment de profondeur)
                       IF ( id_IndDepth .LE. ig_NbDepthDef ) THEN
                          OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffTEMP),form='FORMATTED',&
                               & POSITION='APPEND',STATUS='old')
                          WRITE(50,FMT=700,advance="yes") &
                               & TRIM(cg_filename),&
                               & TRIM(cga_param(iga_IndParamStat(id_param))),&
                               & rl_diff,rga_DepthVal(il_i,id_IndProf), &
                               & id_IndDepth,id_IndReg,&
                               & dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                               TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                          CLOSE(50)
                       ENDIF
                    ELSE
                      !* DEBUG
                      IF ( ABS( rl_diff)  > 15. ) THEN
                             WRITE(0,*) 'PROBLEME TEMP !!!'
                             WRITE(0,*) ' Profil , Profondeur :: ',id_IndProf,il_i
                             WRITE(0,*) 'Valeur temp :: ',rga_TempVal(il_i,id_IndProf),rl_temp
                             IF (lg_TMLEV05) WRITE(0,*) 'Valeur Clim ::',rgpa_TMLEV05(il_i,id_IndProf),&
                             rl_var,rl_temp,il_i,id_IndProf
                             IF (lg_TMLEV09) WRITE(0,*) 'Valeur Clim 09 ::',rgpa_TMLEV09(il_i,id_IndProf),&
                             rl_var,rl_temp,il_i,id_IndProf
                             WRITE(0,*) 'Diff Valeur Clim ::',rl_diff3,rl_diff2,rl_diff
                             WRITE(0,*) 'Valeur modele +diff::',rg_EcartTempMax,rl_diff2,rl_diff3,rl_var,rl_temp,rl_diff
                             !IF ( iga_IndParamStat(id_param)== ip_HDCST_TEMP ) THEN
                             !   !* Test sur l'existence du fichier
                             !   INQUIRE(FILE=cg_FicDiffTEMP_2,EXIST=ll_exist_TEMP)
                             !   IF ( .NOT. ll_exist_TEMP) THEN
                             !     !* Create file      
                             !     OPEN(unit=50,file=cg_FicDiffTEMP_2,form='FORMATTED',STATUS='new')
                             !     CLOSE(50)
                             !     ll_exist_TEMP=.TRUE.
                             !   ENDIF
                             !   OPEN(unit=50,file=cg_FicDiffTEMP_2,form='FORMATTED',&
                             !         & POSITION='APPEND',STATUS='old')
                             !   WRITE(50,FMT=750,advance="yes") &
                             !         & TRIM(cg_filename),&
                             !         TRIM(cga_param(iga_IndParamStat(id_param))),&   
                             !         id_IndProf,il_i,rl_diff,rga_DepthVal(il_i,id_IndProf), &
                             !         id_IndDepth,id_IndReg,&
                             !         dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                             !         TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                             !   CLOSE(50)
                             ! ENDIF
                              ig_StatNOK(id_IndDepth,id_param) =ig_StatNOK(id_IndDepth,id_param) + 1
!#if defined key_debug
!    WRITE(0,*) 'Diff TEMP NOK ::',rl_diff,rl_diff2,rl_diff3
!#endif
                       ELSE
#if defined plot_high_depth
                          IF ( id_IndDepth > 40 .AND. id_IndDepth < 51 ) THEN  
                            IF ( iga_IndParamStat(id_param)== ip_HDCST_TEMP ) THEN
                                 !* Test sur l'existence du fichier
                                cl_TEMPHighDeph=TRIM(cg_ficlog)//'/List_AnoTEMPHighDeph_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
                                INQUIRE(FILE=cl_TEMPHighDeph,EXIST=ll_exist_HighTEMP)
                                IF ( .NOT. ll_exist_HighTEMP ) THEN
                                  !* Create file      
                                  OPEN(unit=50,file=cl_TEMPHighDeph,form='FORMATTED',STATUS='new')
                                  CLOSE(50)
                                  ll_exist_HighTEMP=.TRUE.
                                ENDIF
                                OPEN(unit=50,file=cl_TEMPHighDeph,form='FORMATTED',&
                                     & POSITION='APPEND',STATUS='old')
                                WRITE(50,FMT=760,advance="yes") &
                                & TRIM(cg_filename),&
                                  TRIM(cga_param(iga_IndParamStat(id_param))),&
                                  id_IndProf,il_i,rl_diff,rl_diff2,rl_diff3,rga_DepthVal(il_i,id_IndProf),&
                                  id_IndDepth,id_IndReg,&
                                  dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                                  TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                                  PRINT *,'Nom du fichier ::',TRIM(cg_filename)
                                  PRINT *,'Valeur du profil :: ',id_IndProf
                                  PRINT *,'Valeur prof du profil ::',rga_DepthVal(il_i,id_IndProf)
                                  PRINT *,'Valeur classe prof ::',rd_DepthMin,rd_DepthMax
                                  PRINT *,'Indice du profil :: ',il_i
                                  PRINT *,'Indice de la couche :: ',id_IndDepth
                            ENDIF
                           ENDIF
#endif
                          !**
                          ig_StatOK(id_IndDepth,id_param) =ig_StatOK(id_IndDepth,id_param) + 1
                          id_nval = id_nval + 1
                          dd_moy = dd_moy + rl_var
                          dd_rms = dd_rms + rl_var*rl_var
                          dd_moy_diff = dd_moy_diff + rl_diff
                          dd_rms_diff = dd_rms_diff + rl_diff*rl_diff
!#if defined key_debug
!    WRITE(0,*) 'Diff TEMP OK ::',TRIM(cga_param(iga_IndParamStat(id_param))),rl_diff,rl_diff2,rl_diff3
!#endif
                    ENDIF  
                    !**
                  ENDIF
                ELSE
                !**  Cas une clim 
                  IF (rl_diff2 /= 9999. .AND. il_count_clim == 1.) THEN   
                     IF ( ABS(rl_diff).GE.rg_EcartTempMax .AND. ABS(rl_diff2).GE.rg_EcartTempMax) THEN
                         ig_StatNOK(id_IndDepth,id_param)=ig_StatNOK(id_IndDepth,id_param) + 1
!#if defined key_debug
!    WRITE(0,*) 'Diff TEMP NOK 1 clim::',rl_diff,rl_diff2
!#endif
                         IF ( id_IndDepth .LE. ig_NbDepthDef ) THEN
                            OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffTEMP),form='FORMATTED',&
                                 & POSITION='APPEND',STATUS='old')
                            WRITE(50,FMT=700,advance="yes") &
                                 & TRIM(cg_filename),&
                                 & TRIM(cga_param(iga_IndParamStat(id_param))),&
                                 & rl_diff,rga_DepthVal(il_i,id_IndProf), &
                                 & id_IndDepth,id_IndReg,&
                                 & dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                                 TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                            CLOSE(50)
                         ENDIF
                    ELSE 
                         ig_StatOK(id_IndDepth,id_param)=ig_StatOK(id_IndDepth,id_param) + 1
                         id_nval = id_nval + 1
                         dd_moy = dd_moy + rl_var
                         dd_rms = dd_rms + rl_var*rl_var
                         dd_moy_diff = dd_moy_diff + rl_diff
                         dd_rms_diff = dd_rms_diff + rl_diff*rl_diff
!#if defined key_debug
!    WRITE(0,*) 'Diff TEMP OK 1 clim ::',TRIM(cga_param(iga_IndParamStat(id_param))),rl_diff,rl_diff2
!#endif
                    ENDIF
                  ELSE
                     !**  Cas pas de clim on vire les valeurs abhérentes seulement
                     IF ( ABS(rl_diff).GE.rg_EcartTempMax) THEN
                          ig_StatNOK(id_IndDepth,id_param) =ig_StatNOK(id_IndDepth,id_param) + 1
                          IF ( id_IndDepth .LE. ig_NbDepthDef ) THEN
                            OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffTEMP),form='FORMATTED',&
                                 & POSITION='APPEND',STATUS='old')
                             WRITE(50,FMT=700,advance="yes") &
                                  & TRIM(cg_filename),&
                                  & TRIM(cga_param(iga_IndParamStat(id_param))),&
                                  & rl_diff,rga_DepthVal(il_i,id_IndProf), &
                                  & id_IndDepth,id_IndReg,dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                                  TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                             CLOSE(50)
                          ENDIF
                     ELSE
!#if defined key_debug
!    WRITE(0,*) 'Diff TEMP OK ::',rl_diff,rl_diff2,rl_diff3
!#endif
                          ig_StatOK(id_IndDepth,id_param) =ig_StatOK(id_IndDepth,id_param) + 1
                          id_nval = id_nval + 1
                          dd_moy = dd_moy + rl_var
                          dd_rms = dd_rms + rl_var*rl_var
                          dd_moy_diff = dd_moy_diff + rl_diff
                          dd_rms_diff = dd_rms_diff + rl_diff*rl_diff
                     ENDIF !**  IF ( ABS(rl_diff).GE.rg_EcartTempMax)
                  ENDIF !** IF (rl_diff2 /= 9999. .AND. il_count_clim == 1.)
                ENDIF   !**IF (rl_diff2 /= 9999. .AND. rl_diff3 /= 9999.)

            ENDIF
         ENDIF
         IF ( id_var == 2 ) THEN
            IF ( lg_SMLEV98 ) rl_diff2=rgpa_SMLEV98(il_i,id_IndProf)-rga_PsalVal(il_i,id_IndProf)
            IF ( lg_SMLEV05 )  rl_diff2=rgpa_SMLEV05(il_i,id_IndProf)-rga_PsalVal(il_i,id_IndProf)
            IF ( lg_SMLEV09) rl_diff2=rgpa_SMLEV09(il_i,id_IndProf)-rga_PsalVal(il_i,id_IndProf)
            IF ( lg_SMMED )   rl_diff2=rgpa_SMMED(il_i,id_IndProf)-rga_PsalVal(il_i,id_IndProf)
            IF ( lg_SMARV )   rl_diff3=rgpa_SMARV(il_i,id_IndProf)-rga_PsalVal(il_i,id_IndProf)
            IF ( lg_SMARV11 ) rl_diff3=rgpa_SMARV11(il_i,id_IndProf)-rga_PsalVal(il_i,id_IndProf)
            SELECT CASE (iga_IndParamStat(id_param))
            CASE(ip_PSAL)
               rl_var=rga_PsalVal(il_i,id_IndProf)
            CASE(ip_HDCST_PSAL)
               rl_var = rgpa_HDCST_PSAL(il_i,id_IndProf)
            CASE(ip_ANA_PSAL)
               rl_var = rgpa_ANA_PSAL(il_i,id_IndProf)
            CASE(ip_FRCST1D_PSAL)
               rl_var = rgpa_FRCST1D_PSAL(il_i,id_IndProf)
            CASE(ip_FRCST3D_PSAL)
               rl_var = rgpa_FRCST3D_PSAL(il_i,id_IndProf)
            CASE(ip_FRCST5D_PSAL)
               rl_var = rgpa_FRCST5D_PSAL(il_i,id_IndProf)
            CASE(ip_FRCST6D_PSAL)
               rl_var = rgpa_FRCST6D_PSAL(il_i,id_IndProf)
            CASE(ip_PERS_PSAL)
               rl_var = rgpa_PERS_PSAL(il_i,id_IndProf)
            CASE(ip_PERS3D_PSAL)
               rl_var = rgpa_PERS3D_PSAL(il_i,id_IndProf)
            CASE(ip_PERS6D_PSAL)
               rl_var = rgpa_PERS6D_PSAL(il_i,id_IndProf)
            CASE( ip_SMLEV98)
              rl_var = rgpa_SMLEV98(il_i,id_IndProf)
            CASE(ip_SMLEV05)
               rl_var = rgpa_SMLEV05(il_i,id_IndProf)
            CASE( ip_SMLEV09)
              rl_var = rgpa_SMLEV09(il_i,id_IndProf)
            CASE( ip_SMLEV13)
              rl_var = rgpa_SMLEV13(il_i,id_IndProf)
            CASE( ip_SMMED)
              rl_var = rgpa_SMMED(il_i,id_IndProf)
            CASE(ip_SMARV)
              rl_var = rgpa_SMARV(il_i,id_IndProf)
            CASE(ip_SMARV11)
              rl_var = rgpa_SMARV11(il_i,id_IndProf)
            ENDSELECT
            IF ( rga_PsalVal(il_i,id_IndProf) .NE. rg_PsalVal_Def .AND. rl_var < 9999. .AND.  rga_PsalVal(il_i,id_IndProf) .NE. 0 ) THEN
                rl_diff = rl_var - rga_PsalVal(il_i,id_IndProf)
                IF (rl_diff2 /= 9999. .AND. rl_diff3 /= 9999.) THEN
                    IF ( ABS(rl_diff).GE.rg_EcartSalMax .AND. &
                         ABS(rl_diff2).GE. rg_EcartSalMax .AND. &
                         ABS(rl_diff3).GE.rg_EcartSalMax  ) THEN
                       ig_StatNOK(id_IndDepth,id_param) = ig_StatNOK(id_IndDepth,id_param) + 1
                       ! Output: valeur a rejeter
                       ! note: on n ecrit pas les valeurs pour la colonne totale (inutile car deja
                       ! dans un segment de profondeur)
                       IF ( id_IndDepth .LE. ig_NbDepthDef ) THEN
                          OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffPSAL),form='FORMATTED',&
                               & POSITION='APPEND',STATUS='old')
                          WRITE(50,FMT=700,advance="yes") &
                               & TRIM(cg_filename),&
                               & TRIM(cga_param(iga_IndParamStat(id_param))),&
                               & rl_diff,rga_DepthVal(il_i,id_IndProf),id_IndDepth,id_IndReg,&
                               & dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                               TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                          CLOSE(50)
                       ENDIF
!#if defined key_debug
!    WRITE(0,*) 'Diff PSAL NOK ::',rl_diff,rl_diff2,rl_diff3
!#endif
                    ELSE  
                         IF ( ABS( rl_diff)  > 3. )  THEN
                             WRITE(0,*) 'PROBLEME PSAL !!!'
                             WRITE(0,*) ' Profil , Profondeur :: ',id_IndProf, il_i
                             WRITE(0,*) ' Difference :: ',ABS( rl_diff)
                             IF (lg_SMLEV05) THEN
                               WRITE(0,*) 'Valeur Clim ::',rgpa_SMLEV05(il_i,id_IndProf), &
                                                           rl_var,rga_PsalVal(il_i,id_IndProf),il_i,id_IndProf
                             ENDIF
                             IF (lg_SMLEV09) THEN
                               WRITE(0,*) 'Valeur Clim ::',rgpa_SMLEV09(il_i,id_IndProf), &
                                                           rl_var,rga_PsalVal(il_i,id_IndProf),il_i,id_IndProf
                             ENDIF
                             WRITE(0,*) 'Diff Valeur Clim ::',rl_diff3,rl_diff2,rl_diff
                             !IF ( iga_IndParamStat(id_param)== ip_HDCST_PSAL )  THEN
                             !    !* Test sur l'existence du fichier
                             !    INQUIRE(FILE=TRIM(cd_logdir)//TRIM(cg_FicDiffPSAL_2),EXIST=ll_exist_PSAL)
                             !    IF ( .NOT. ll_exist_PSAL) THEN
                             !       !* Create file      
                             !       OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffPSAL_2),form='FORMATTED',STATUS='new')
                             !       CLOSE(50)
                             !       ll_exist_PSAL=.TRUE.
                             !    ENDIF
                             !    OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffPSAL_2),form='FORMATTED',&
                             !        & POSITION='APPEND',STATUS='old') 
                             !        WRITE(50,FMT=750,advance="yes") &
                             !         & TRIM(cg_filename),&
                             !         & TRIM(cga_param(iga_IndParamStat(id_param))),&
                             !         &  id_IndProf,il_i,rl_diff,rga_DepthVal(il_i,id_IndProf), &
                             !         &  id_IndDepth,id_IndReg,dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                             !         &  TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                             !    CLOSE(50)
                             !ENDIF
                         
                             ig_StatNOK(id_IndDepth,id_param) =ig_StatNOK(id_IndDepth,id_param) + 1
                         ELSE
#if defined plot_high_depth
                             IF ( id_IndDepth > 40 .AND. id_IndDepth < 51 ) THEN
                               IF ( iga_IndParamStat(id_param)== ip_HDCST_PSAL ) THEN
                                   !* Test sur l'existence du fichier
                                   cl_PSALHighDeph=TRIM(cg_ficlog)//'/List_AnoPSALHighDeph_'//TRIM(cg_modele)//'_R'//TRIM(cg_rundate)//'.txt'
                                   INQUIRE(FILE=cl_PSALHighDeph,EXIST=ll_exist_HighPSAL)
                                   IF ( .NOT. ll_exist_HighPSAL) THEN
                                     !* Create file      
                                     OPEN(unit=50,file=cl_PSALHighDeph,form='FORMATTED',STATUS='new')
                                     CLOSE(50)
                                     ll_exist_HighPSAL=.TRUE.
                                   ENDIF
                                   OPEN(unit=50,file=cl_PSALHighDeph,form='FORMATTED',&
                                        & POSITION='APPEND',STATUS='old')
                                   WRITE(50,FMT=760,advance="yes") &
                                   & TRIM(cg_filename),&
                                     TRIM(cga_param(iga_IndParamStat(id_param))),&
                                     id_IndProf,il_i,rl_diff,rl_diff2,rl_diff3,rga_DepthVal(il_i,id_IndProf),&
                                     id_IndDepth,id_IndReg,&
                                     dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                                     TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                               ENDIF
                             ENDIF
#endif
!#if defined key_debug
!    WRITE(0,*) 'Diff PSAL OK ::',rl_diff,rl_diff2,rl_diff3
!#endif
                             ig_StatOK(id_IndDepth,id_param) = ig_StatOK(id_IndDepth,id_param) + 1
                             id_nval = id_nval + 1
                             dd_moy = dd_moy + rl_var
                             dd_rms = dd_rms + rl_var*rl_var
                             dd_moy_diff = dd_moy_diff + rl_diff
                             dd_rms_diff = dd_rms_diff + rl_diff*rl_diff
                        ENDIF
                    ENDIF
                ELSE
                  !**  Cas une clim 
                  IF (rl_diff2 /= 9999. .AND. il_count_clim == 1.) THEN
                     IF ( ABS(rl_diff).GE.rg_EcartTempMax .AND.ABS(rl_diff2).GE.rg_EcartTempMax) THEN
                         ig_StatNOK(id_IndDepth,id_param)=ig_StatNOK(id_IndDepth,id_param)+ 1
!#if defined key_debug
!    WRITE(0,*) 'Diff PSAL NOK 1 clim::',rl_diff,rl_diff2
!#endif
                         IF ( id_IndDepth .LE. ig_NbDepthDef ) THEN
                            OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffTEMP),form='FORMATTED',&
                                 & POSITION='APPEND',STATUS='old')
                            WRITE(50,FMT=700,advance="yes") &
                                 & TRIM(cg_filename),&
                                 & TRIM(cga_param(iga_IndParamStat(id_param))),&
                                 & rl_diff,rga_DepthVal(il_i,id_IndProf), &
                                 & id_IndDepth,id_IndReg,&
                                 &dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                                 TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                            CLOSE(50)
                         ENDIF
                     ELSE
                         ig_StatOK(id_IndDepth,id_param)=ig_StatOK(id_IndDepth,id_param)+ 1
                         id_nval = id_nval + 1
                         dd_moy = dd_moy + rl_var
                         dd_rms = dd_rms + rl_var*rl_var
                         dd_moy_diff = dd_moy_diff + rl_diff
                         dd_rms_diff = dd_rms_diff + rl_diff*rl_diff
!#if defined key_debug
!    WRITE(0,*) 'Diff PSAL OK 1 clim ::',TRIM(cga_param(iga_IndParamStat(id_param))),rl_diff,rl_diff2
!#endif
                     ENDIF
                  ELSE
                     !**  Cas pas de clim on vire les valeurs abhérentes
                     !seulement
                     IF ( ABS(rl_diff).GE.rg_EcartSalMax) THEN
                          ig_StatNOK(id_IndDepth,id_param) =ig_StatNOK(id_IndDepth,id_param) + 1
                          IF ( id_IndDepth .LE. ig_NbDepthDef ) THEN
                           OPEN(unit=50,file=TRIM(cd_logdir)//TRIM(cg_FicDiffPSAL),form='FORMATTED',POSITION='APPEND',STATUS='old')
                           WRITE(50,FMT=700,advance="yes") TRIM(cg_filename),&
                                                          & TRIM(cga_param(iga_IndParamStat(id_param))),&
                                                          & rl_diff,rga_DepthVal(il_i,id_IndProf),id_IndDepth,id_IndReg,&
                                                          & dgpa_LONGITUDE(id_IndProf),dgpa_LATITUDE(id_IndProf),&
                                                          & TRIM(cgpa_PLATFORM_NUMBER(id_IndProf,1)),TRIM(cgpa_WMO_INST_TYPE(id_IndProf,1))
                           CLOSE(50)
                        ENDIF
                     ELSE
                        ig_StatOK(id_IndDepth,id_param) = ig_StatOK(id_IndDepth,id_param) + 1
                        id_nval = id_nval + 1
                        dd_moy = dd_moy + rl_var
                        dd_rms = dd_rms + rl_var*rl_var
                        dd_moy_diff = dd_moy_diff + rl_diff
                        dd_rms_diff = dd_rms_diff + rl_diff*rl_diff
!#if defined key_debug
!    WRITE(0,*) 'Diff PSAL OK ::',rl_diff,rl_diff2,rl_diff3
!#endif
                     ENDIF !**  IF ( ABS(rl_diff).GE.rg_EcartTempMax)
                  ENDIF !** IF (rl_diff2 /= 9999. .AND. il_count_clim == 1.)
                ENDIF  !**IF (rl_diff2 /= 9999. .AND. rl_diff3 /= 9999.)
            ENDIF !**IF ( rga_PsalVal(il_i,id_IndProf) .NE. rg_PsalVal_Def .AND. rl_var < 9999.
          ENDIF !**IF ( rga_PsalVal(il_i,id_IndProf) .NE. rg_PsalVal_Def .AND. rl_var < 9999.

       ENDIF ! fin test sur les profondeurs
    ENDDO ! il_i=1,ig_nlevels

  END SUBROUTINE remplir_tableau
  !
  !===============================================================
  !
  SUBROUTINE fermer_stat_class4(id_stat)
    !
    !**** fermer_stat_class4
    !
    !     Purpose:
    !     --------
    !     Des-allocation des tableaux/parametres necessaires
    !     au calcul des Class 4 par profil: donc pour chaque
    !     fichiers CORIOLIS lue
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item cd_filename
    !
    !     Output : \\
    !       id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !
    !     Externals:
    !     ----------
    !       table_class4,table_boite
    !
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        F. Hernandez     Mai 2008        Creation
    !     1.1        
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE table_boite
    USE table_class4
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !

    !
    !**   0.3 Dummy variables
    !
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    !
    !*--------------------------------------------------------------------------
    !

    !** initialisation
    id_stat = 0


    !** Desallocation

    IF ( ALLOCATED (rga_IDboite)) DEALLOCATE (rga_IDboite)
    IF ( ALLOCATED (iga_NbValProf)) DEALLOCATE (iga_NbValProf)
    IF ( ALLOCATED (rga_StatProf)) DEALLOCATE (rga_StatProf)


  END SUBROUTINE fermer_stat_class4
  !     
  !*--------------------------------------------------------------------------
  !
END MODULE DIAG_CLASS4
