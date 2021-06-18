MODULE READ_ARGO

!*======================================================================
!               Merry  Christmas Everybody !
!
!   
!                   .,,,...                            :$L ;$  ,dP
!               ,!!!!!!!',cd$$$$$e,                 q  4$f,$$,z$"
!             ,!!!!!!!',c$$$$$$$$$$$$c              `$o`$$kuC3$$ .zf
!           ,!!!!!!!',c$$$$$$P**""**?$c              R$beeF?$$$$$"
!          ;!!!!!!! c$$$$$$",eed$$F"?t"               "$$$$bd$$$"
!         ;!!!!!!!.d$$$$$F j"j$3$bf""?b?e,             '$$$$$$P"
!        !!!!!!:  $$$$$$P J,f ,d$$b?$bde`$c          .$k<?????>'$b
!        !!!!!!!$$$$F".$$".u$$??P}"""^ ?$$c.       d$$$$$dd$$$$$>
!         `!!!!!  ?L e$$ $$$$$P'zee^"$$$$boc"$$,     R$$$$$$$$$$$$
!          '!!!   z$$$$$c,"$P'd$$F'zdbeereee$$$$$eu    "??$$$$PF"
!   Mn      !!   d$$$$$$$$ee z$P",d$$$$$$c?$$$$$$$$C  '!!!::::!!!>
!   MMM   ,cec, '^$$$$$$$$$c,",e$$C?$$$$$$bc?$$$$$$$k !!!!!!!!!!!!
!   MMM'.$$$$$$$, ?$$$$$$$$P$$$$$$$bc?T$$$$$$d$$$$$$$ . -.`!!!!!!!
!   nMM d$$$$$$$F  $$P???",e4$$$$$$$$bcc?$$$$$$$$$$$$ /~:.!!!!!!!!!
!   n.  "$$$$$$$'   ::,"??e,.-.?$$$$$$$$$$$$$$$$$$$$F.C"m.`!!!!!!!'
!   M":!:`"""""   :!!!!!!i:."?o. "? ?$$$??$$$"$$F"$P<$$$b/4.`4!!!
!   : 4!!!!h     <!!!!!!!!!!:  .CL.F'.zeElu. : ?eb o$$$$$$o(#c'`
!     '`~!!~.ud !!````'!''``zd$$$$$`d$$$CuuJ" !: 4$$$$$$$$$$c"$c
!   ." !~`z$$$":!!!~`..:i! d$$$$$$$`$$$$FCCJ" !!!: ?$$$$$$$$$b $L
!   $$"z$$$$$":!!! :!!!!!'4$$$$$$$$`$$$$$" "" !!!!!:`$$$$$$$$$$ "
!   ?o$$$$$$F !!!!!!!!!!! 4$$$$$$$$;?$P": JL \.~!!!!i $$$$P?"l.u-
!   $$$$$$$$F!!!!!!!!!!!!:'R$$$$$$$E.:! $.$$c3$%:`!!! .l==7Cuec^ <
!   $$$$$$$$ !!!!!!!!!!!!!i ?$$$$P"<!!! ?$`$$$$N.     Rk`$$$$$$r\
!   $$$$$$$$L`!!!!!!!!!!!!!!! .:::!!!''`   $$$$$$      $c"??"7u+? !
!   $$$$$$$$$ !!!!!!!!!!!'` :!!''`         '""        .'?b"l.4d$ !!!:
!   $$$$$$$$$b `!!!'''`.. '''`               ...:::!!!!!! $$$.?$b'!!!>
!   $$$$$$$$$$$beee@$$$$$$$$        ..:::!!!!!!!!!!!!!!!! 3$$b ?$c`!!!
!   $$$$$$$$$$$$$$$$$$$$$$$f .::!!!!!!!!!!!!!!!!!!!!!!!!! d$$$$`$$b !!!
!   $$$$$$$$$$$"3$$$$$$$$$":!!!!!!!!!!!!!!!!!!!!!!!!!!!!! $$$$$,$$$k !!!
!   $$$$$$$$$P,d$$$$$$$$F !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 3$$$$$ $$$i`!!! 3>
!   $$$$$$F$Fz$$$$$$$$$$ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! d$$$$$h`$$$,!!! $&
!   $$$$$FJFx$$$$$$$$$$ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'4$$$$$$$ 9$$$.'.$$$L
!   $$$$$ F.$$$$$$$$F.r !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! $$$$$$$F  ?$$$e$$$$F
!   $$$$F .$$$$$$$$"d$$bu,,.```''!!!!!!!!!!!!!!!!'''''`,d$$$$$$$F.! ?$$$$$$F
!   $$$$F d$$$$$$$$ $$$$$$$$$$$bc,,,,,,,,,,,,,,,,ccd$$$$$$$$$$$$ !!f ?$$$$"
!    "$$$e$$$$$$$$&'$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ !! $P"
!      `"?$$$$$$$$$e`?$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ !!'
!         `?$$$$$$$$$$e `""**???$$$$$$$$$$$$$$$$$$$$$$$P***""..:!!'
!            "?$$$$$$$$k`!!!!!!;;;;;;::,,,...... ,,,,,;;!!!!!!!!!!
!                ""???"" !!!!!!!!!!!!!!!!!!!!!!  !!!!!!!!!!!!!!!!!:
!                         !!!!!!!!!!!!!!!!!!!'   !!!!!!!!!!!!!!!!!!
!                          !!!!!!!!!!!!!!!!.   `!!!!!!!!!'''!!!!'
!                        :i !!!!!!!!!!!!!!!!   .``''`.,uu,,.```.
!                        !!!!!!!!!!!!!!!!!~`    d$$$$$$$$$$$$$$$$$>
!                       c.`~~~~~!!!!!:..        $$$$$$$$$$$$$$$$$$
!                       $$$$$eeeeeeeuuuee$      $$$$$$$$$$$$$$$$$"
!                       $$$$$$$$$$$$$$$$$$       """"...........
!                       ?$$$$$$$$$$$$$$$P"       '!!!!!!!!!!!!!!
!                        .."""""""""".:          !!!!!!!!!!!!!
!                       :!!!!!!!!!!!!!!          `!!!!!!!!!!!'
!                       i!!!!!!!!!!!!!'          !!!!!!!!!!!'::
!                       :!!!!!!!!!!!!!           !!!!!!!!!!:!!:.
!                       !!!!!!!!!!'!!!           . `!!!!!!!!!!!!`...
!                       `!!!!!!!! -'``           !!!!!!!!!!!!!!!!!!!!!::
!                        !!!!!!!!!i!!!:           `~~~~~```~~~~~~~~~~~~`
!                        !!!!!!!!!!!!!!!.
!                          ```'!!!!!!!'``::..
!                                `!!!!!!!!!!!'
!                                   `````


!*======================================================================
  !                       ***  MODULE Read_ARGO  ***
  !                Ce module realise la lecture des differents              
  !                fichiers ARGO pour les classe4                        
  !                                                                      
  !=======================================================================
  !
  !
  PRIVATE 
  PUBLIC :: read_profile,read_profile_ARMOR,valid_profile,fermer_table_argo
  !
CONTAINS
  SUBROUTINE read_profile(cd_filename,id_ficlog,id_stat)
    !
    !**** read_profile
    !
    !     Purpose:
    !     --------
    !     Lecture des fichiers ARGO
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item cd_filename
    !      \item id_ficlog
    !
    !     Output : \\
    !      \item id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !     Charge du fichier et extraction des paramètres qui nous intéressent
    !     Externals:
    !     ----------
    !     MCAL_SU_DATE
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        C.REGNIER        Aout 2007       Validation plateform
    !     1.1        C.REGNIER        Octobre 2007    Clean & ajout de lla_class4_2D et lga_2D_tab
    !     1.2        F.HERNANDEZ      Mai 2008        Forte simplification du code
    !     1.3        C.REGNIER        Janvier 2010    Nettoyage et corrections
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE MCAL_SU_DATE
    USE table_ARGO
    USE MIOL
    USE MCAL
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !
    INTEGER(KIND=4)                                    :: il_ji,il_i,il_ios,il_v,il_k
    INTEGER(kind=4)                                    :: il_C_PARAM,il_L_PARAM,il_nbval
    INTEGER(KIND=4)                                    :: il_stat,il_err,il_jk,il_taille
    INTEGER(KIND=4),DIMENSION(1)                       :: il_size,il_size2
    INTEGER(KIND=4)                                    :: il_param, il_jj,il_p,il_par
    CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE        :: cla_ParamLu
    INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE           :: ila_IdPar
    INTEGER, DIMENSION(:), POINTER                     :: ilpa_dimlen
    INTEGER(KIND=4)                                    :: il_nbvar,il_type,il_nbdim
    LOGICAL                                            :: ll_exist,ll_here
    INTEGER, DIMENSION(:), POINTER                     :: ilpa_vardim
    INTEGER, DIMENSION(:), POINTER                     :: ilpa_vartype
    CHARACTER(LEN=255),DIMENSION(:),POINTER            :: clpa_varname
    CHARACTER(LEN=255)                                 :: cl_test,cl_tmp,cl_att,cl_station
    LOGICAL                                            :: ll_TEMP,ll_DEPH,ll_PSAL,ll_PRES
    LOGICAL                                            :: ll_C_PARAM,ll_L_PARAM,ll_NLEVELS
    LOGICAL                                            :: ll_tri_prof,ll_NPROF,ll_NPARAM
    CHARACTER(len=6)                                   :: cl_dum1,cl_dum2,cl_dum3
    CHARACTER(LEN=1), DIMENSION(:,:), POINTER          :: clpa_PARAMETERINT

    ! Declaration des parametres usuels attendus dans station parameter

    !
    !**   0.3 Dummy variables
    !
    CHARACTER(LEN=255),INTENT(IN)                      :: cd_filename
    INTEGER(KIND=4) ,OPTIONAL ,INTENT(IN)              :: id_ficlog
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    !
    !*--------------------------------------------------------------------------
    !
    !** initialisation
    id_stat = 0
#if defined key_debug
    PRINT *,'Ouverture du fichier CORIOLIS ARGO : ',cd_filename
#endif
    !** Ouverture du fichier CORIOLIS ARGO      
    INQUIRE(FILE=cd_filename,EXIST=ll_tri_prof)
    IF ( .NOT. ll_tri_prof ) THEN
       id_stat=-1
       WRITE(id_ficlog,'(a,1x,a)'),'NOT EXIST FILE',TRIM(cd_filename)
       GOTO 9999
    ENDIF
    !
    !** Lecture des dimensions du fichier
    CALL MIOL_inquire_dimensions_NC(cd_filename,il_nbdim,clpa_dimname,ilpa_dimlen)
    !** Interrogation des variables du fichier
    CALL MIOL_inquire_variables_NC(cd_filename,il_nbvar,clpa_varname,ilpa_vardim,ilpa_vartype)
    ll_NPROF  = .FALSE.
    ll_NPARAM = .FALSE.
    ll_NLEVELS= .FALSE.
    ll_C_PARAM= .FALSE.
    ll_L_PARAM= .FALSE.
    lg_PLAT=.FALSE.
    lg_STATION_PARAMETERS=.FALSE.
    lg_INST_REFERENCE=.FALSE.
    lg_WMO_INST_TYPE=.FALSE.
    lg_DATA_STATE_INDICATOR=.FALSE.
    lg_JULD_QC=.FALSE.
    lg_POSITION_QC=.FALSE.
    lg_DATA_MODE=.FALSE.
    lg_DEPH=.FALSE.
    lg_PSAL=.FALSE.
    lg_PRES=.FALSE.
    lg_PERS3D_PSAL=.FALSE.
    lg_PERS3D_TEMP=.FALSE.
    lg_PERS6D_TEMP=.FALSE.
    lg_PERS6D_PSAL=.FALSE.
    lg_PERS_PSAL=.FALSE.
    lg_PERS_TEMP=.FALSE.
    lg_TEMP=.FALSE.
    lg_LON=.FALSE.
    lg_LAT=.FALSE.
    lg_JULD=.FALSE.
    lg_SMLEV05=.FALSE.
    lg_TMLEV05=.FALSE.
    lg_SMLEV98=.FALSE.
    lg_TMLEV98=.FALSE.
    lg_TMLEV09=.FALSE.
    lg_TMLEV13=.FALSE.
    lg_TMLEV18=.FALSE.
    lg_SMLEV09=.FALSE.
    lg_SMLEV13=.FALSE.
    lg_SMLEV18=.FALSE.
    lg_SMARV=.FALSE.
    lg_SMARV11=.FALSE.
    lg_TMARV=.FALSE.
    lg_TMARV11=.FALSE.
    lg_TMMED=.FALSE.
    lg_SMMED=.FALSE.
    lg_HDCT_TEMP=.FALSE.
    lg_HDCT_PSAL=.FALSE.
    lg_ANA_TEMP=.FALSE.
    lg_ANA_PSAL=.FALSE.
    lg_FCST1D_TEMP=.FALSE.
    lg_FCST1D_PSAL=.FALSE.
    lg_FCST3D_TEMP=.FALSE.
    lg_FCST3D_PSAL=.FALSE.
    lg_FCST5D_TEMP=.FALSE.
    lg_FCST5D_PSAL=.FALSE.
    lg_FCST6D_TEMP=.FALSE.
    lg_FCST6D_PSAL=.FALSE.
    !
    DO il_ji=1, il_nbdim
       !
       !** Test sur l'existence de NPROF et NPARAM et NLEVELS
       !   
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'N_PROF') THEN
          ll_NPROF = .TRUE. 
          ig_nprof= ilpa_dimlen(il_ji)
       ENDIF
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'N_PARAM') THEN
          il_param=ilpa_dimlen(il_ji)
          ll_NPARAM=  .TRUE.
       ENDIF
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'N_LEVELS') THEN
          ig_nlevels=ilpa_dimlen(il_ji)
          ll_NLEVELS=  .TRUE.
       ENDIF
       !
       !** Test sur l'existence de  L_PARAMETERINT et  C_PARAMETERINT  PARAMETERINT
       ! 
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'C_PARAMETERINT') THEN
          ll_C_PARAM = .TRUE. 
          il_C_PARAM= ilpa_dimlen(il_ji)
       ENDIF
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'L_PARAMETERINT') THEN
          ll_L_PARAM=  .TRUE.
          il_L_PARAM = ilpa_dimlen(il_ji)
       ENDIF
	
    ENDDO ! il_ji=1, il_nbdim
    !
    !** Si N_PROF et N_PARAM ET C_PARAM L_PARAM existent :CLASS4 on lit
    !   Si  N_PROF et N_PARAM existent coriolis classique : on lit ;  sinon on sort
    !
    IF ( .NOT. (ll_NPROF.AND.ll_NLEVELS) ) THEN
       il_stat = -1
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    IF ( ll_NPARAM ) THEN 
       il_stat=2
       WRITE(cl_dum1,'(i6)')ig_nprof
       WRITE(cl_dum2,'(i6)')il_param
       WRITE(id_ficlog,FMT='(a,1x,a,a,a,a,a,a,a)') TRIM(ADJUSTL(cl_argo_error(il_stat))),&
            &'N_PROF(',TRIM(ADJUSTL(cl_dum1)),') N_PARAM(',TRIM(ADJUSTL(cl_dum2)),')'
    ELSE
       il_stat=3
       WRITE(cl_dum1,'(i6)')ig_nprof
       WRITE(cl_dum2,'(i6)')il_nbvar
       WRITE(id_ficlog,FMT='(a,1x,a,a,a,a,a,a,a)') TRIM(ADJUSTL(cl_argo_error(il_stat))),&
            &'N_PROF(',TRIM(ADJUSTL(cl_dum1)),') Nb Var(',TRIM(ADJUSTL(cl_dum2)),')'
    ENDIF
    IF ( ll_L_PARAM ) THEN
       il_stat = 1
       WRITE(cl_dum3,'(i6)')il_L_PARAM
       WRITE(id_ficlog,FMT='(a,1x,a,a,a,a,a,a,a)') TRIM(ADJUSTL(cl_argo_error(il_stat))),&
            &' L_PARAMETERINT2(',TRIM(ADJUSTL(cl_dum3)),')'
    ENDIF
    !
    !** RECHERCHE DES PARAMETRES EXISTANTS DANS LE FICHIER
    !* initialisation nombre effectif de parametres used
    ig_param_use = 0
    IF ( ALLOCATED(cla_ParamLu) ) DEALLOCATE(cla_ParamLu)
    ALLOCATE (cla_ParamLu(ip_ParamTot))
    cla_ParamLu(:)=' '
    IF ( ALLOCATED(ila_IdPar) ) DEALLOCATE(ila_IdPar)
    ALLOCATE (ila_IdPar(ip_ParamTot))
    ila_IdPar(:)=0
#if defined key_debug
    WRITE(0,*) 'Lecture de ',TRIM(cg_station)
#endif
    !
    !** Lecture des parametres contenus dans tous les profils
    cl_station=cg_station
    CALL MIOL_inquire_type_NC(cd_filename,TRIM(cg_station),il_type,il_nbdim,ll_exist)
#if defined key_debug
    WRITE(0,*) 'Existence de  ',TRIM(cg_station),' ',ll_exist
#endif
    IF ( .not. ll_exist)  THEN
        WRITE(0,*) 'STATION_PARAMETERS not exist'
        cl_station="PARAMETERS"
        CALL MIOL_inquire_type_NC(cd_filename,TRIM(cl_station),il_type,il_nbdim,ll_exist)
    ENDIF
    IF ( .not. ll_exist)  THEN
        WRITE(0,*) 'PARAMETERS and STATION_PARAMETERS and PARAMETERS not exist'
        CALL EXIT(1)
        !!cg_station="PARAMETER"
        !!CALL MIOL_inquire_type_NC(cd_filename,TRIM(cg_station),il_type,il_nbdim,ll_exist)
    ENDIF
    IF ( ll_exist .AND. ll_NPARAM ) THEN
       WRITE(id_ficlog,fmt='(a,a,a,i5,a)')'Lecture de ',TRIM(cl_station),&
            &' dim(',il_nbdim,')'
       il_taille=16
       CALL MIOL_read_field_NC(TRIM(cd_filename),TRIM(cl_station),cgpa_STATION_PARAMETERS,il_taille)
       lg_STATION_PARAMETERS=.TRUE. 
!#if defined key_debug
!    WRITE(0,*) 'Lecture de ',TRIM(cg_station)
!    WRITE(0,*) 'STATION_PARAMETERS :: ',cgpa_STATION_PARAMETERS
!#endif
       !
       !* Recherche de tout les parametres contenus dans STATION_PARAMETERS
       ! on effectue une comparaison a la liste de parametres definis par defaut
       !* boucle sur les parametres usuels standards
       DO il_p = 1 , ip_ParamTot
          IF ( COUNT( cga_param(il_p) == cgpa_STATION_PARAMETERS(:,:,:) ) > 0 ) THEN
             ig_param_use = ig_param_use + 1
             cla_ParamLu(ig_param_use) = TRIM(cga_param(il_p))
             ila_IdPar(ig_param_use) = il_p
#if defined key_debug
             PRINT *,'ig_param_use :: ',ig_param_use
             PRINT *,'il_p :: ',il_p
             PRINT *,'cla_ParamLu(ig_param_use) :: ',cla_ParamLu(ig_param_use)
             PRINT *,'ila_IdPar(ig_param_use) :: ',ila_IdPar(ig_param_use) 
#endif
           ENDIF
       ENDDO
    ENDIF  ! fin ( ll_exist .and.ll_NPARAM )
    !
    !** Lecture des parametres CLASS4 contenus dans le fichier
    CALL MIOL_inquire_type_NC(cd_filename,TRIM(cg_stationCLASS4),il_type,il_nbdim,ll_exist)
    IF ( ll_exist .AND. ll_C_PARAM .AND. ll_L_PARAM ) THEN
       il_taille=1
       WRITE(id_ficlog,fmt='(a,a,a,i5,a)')'Lecture de ',cg_stationCLASS4,&
            &' dim(',il_nbdim,')'
       CALL MIOL_read_field_NC(cd_filename,TRIM(cg_stationCLASS4),cgpa_PARAMETERINT,il_taille)
       
       ALLOCATE(cga_PARAMETERINT(size(cgpa_PARAMETERINT(1,:))))
       DO il_ji=1,il_L_PARAM
          DO il_k=1,il_C_PARAM
             cga_PARAMETERINT(il_ji)(il_k:il_k)=cgpa_PARAMETERINT(il_k,il_ji)                             
          ENDDO
       ENDDO
       WRITE(id_ficlog,*)cgpa_PARAMETERINT
       !* on poursuit la recherche pour identifier les parametres CLASS4
       ! contenus dans ce fichier  et on continue de remplir les tableaux
       ! cla_ParamLu qui contient tous les paramètres contenus dans le fichier
       ! et ila_IdPar qui contient les indices des variables contenues dans le fichier
       ! pour faire la correspondance avec cga_param
       DO il_p = 1 , ip_ParamTot
          IF ( COUNT( cga_param(il_p) == cga_PARAMETERINT(:) ) > 0 ) THEN
             ig_param_use = ig_param_use + 1
             cla_ParamLu(ig_param_use) = TRIM(cga_param(il_p))
             ila_IdPar(ig_param_use) = il_p
#if defined key_debug
             PRINT *,'---------------------------------'
             PRINT *,'ig_param_use :: ',ig_param_use
             PRINT *,'il_p :: ',il_p
             PRINT *,'cla_ParamLu(ig_param_use) :: ',cla_ParamLu(ig_param_use)
             PRINT *,'ila_IdPar(ig_param_use) :: ',ila_IdPar(ig_param_use) 
#endif
          ENDIF
       ENDDO
    ELSE
       il_stat=-16
       WRITE (id_ficlog,FMT='(a50)')TRIM(cl_argo_error(il_stat))
    ENDIF ! fin ( ll_exist .AND. ll_C_PARAM .AND. ll_L_PARAM )
    !** Cas ou il manque ll_NPARAM ou ll_L_PARAM
    IF ( .NOT. (ll_NPARAM) .OR. .NOT. ( ll_C_PARAM .AND. ll_L_PARAM ) ) THEN

       !* on boucle sur les variables existentes et on test 
       !  les parametres d interet
       DO il_p = 1 , ip_ParamTot
          IF ( ANY ( clpa_varname(:) == TRIM(cga_param(il_p)) ) ) THEN
             ll_here = .FALSE.
             DO il_v = 1 , ig_param_use
                IF ( TRIM(cga_param(il_p)) == cla_ParamLu(il_v) ) ll_here = .TRUE.
             ENDDO
             IF ( .NOT. ll_here ) THEN
                ig_param_use = ig_param_use + 1
                cla_ParamLu(ig_param_use) = TRIM(cga_param(il_p))
                ila_IdPar(ig_param_use) = il_p
             ENDIF
          ENDIF

       ENDDO
       
    ENDIF ! fin ( .not. (ll_NPARAM .or. ( ll_C_PARAM .AND. ll_L_PARAM )) )
    
    !** On sort de la routine si aucun fichier utile !
    IF ( ig_param_use == 0 ) THEN
       il_stat = -17
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -17
       GOTO 9999
    ENDIF
    !
#if defined key_debug
     PRINT *,'Params lus :: ',cla_ParamLu(:)
#endif
    !** Bilan sur la recherche: on definit les parametres existants
    WRITE(id_ficlog,fmt='(a,i3)')'Nbr. parametre used: ',ig_param_use

    IF ( ALLOCATED(cga_param_use) ) DEALLOCATE(cga_param_use)
    ALLOCATE ( cga_param_use(ig_param_use) )
    DO il_p = 1 , ig_param_use
       cga_param_use(il_p) = TRIM(cla_ParamLu(il_p))
    ENDDO
    WRITE(id_ficlog,fmt='(a)',advance="no")'Par. Used = '
    IF ( ig_param_use > 1 ) THEN
       DO il_p = 1 , ig_param_use-1
          WRITE(id_ficlog,'(a,1x)',advance="no")TRIM(cga_param_use(il_p))
       ENDDO
    ENDIF
    WRITE(id_ficlog,'(a,1x)',advance="yes")TRIM(cga_param_use(ig_param_use))
 
    !** Allocation dynamique du tableau des correspondances d indices
    ! des parametres pour chaque profil
    IF ( ALLOCATED (iga_IndParam)) DEALLOCATE (iga_IndParam)
    ALLOCATE (iga_IndParam(ig_nprof,ip_ParamTot))
    iga_IndParam(:,:) = 0
#if defined key_debug
    PRINT *,'param use :: ',cga_param_use(:)
    PRINT *,'number of prof :: ',ig_nprof
    PRINT *,'number of param :: ',il_param
!    PRINT *,'cgpa_STATION_PARAMETERS :: ',cgpa_STATION_PARAMETERS
#endif
!!$!** Debut modif
    !** Pour chaque profil recherche des parametres standards (parmi ceux
    ! identifies ci-dessus comme etant effectivement presents dans le fichier)
    DO il_i=1,ig_nprof
       DO il_ji=1,il_param
          il_p = 1
          ll_exist = .FALSE.
          il_par = 0
          DO WHILE ( .NOT. ll_exist .AND. il_p <= ig_param_use)
             !PRINT *,'STATION_PARAMETERS, il_p :: ',cgpa_STATION_PARAMETERS(il_ji,il_i,1),il_ji,il_i,il_p,cga_param_use(il_p)
             IF (TRIM(cga_param_use(il_p)).EQ.TRIM(cgpa_STATION_PARAMETERS(il_ji,il_i,1))) THEN
                ll_exist = .TRUE. 
!#if defined key_debug
!                PRINT *,'TRIM(cga_param_use(il_p) :: ',TRIM(cga_param_use(il_p)) 
!#endif
                il_par = il_p
             ENDIF
             il_p = il_p + 1
          ENDDO
          IF ( ll_exist ) THEN 
             iga_IndParam(il_i,ila_IdPar(il_par)) = il_par
!#if defined key_debug
!             PRINT *,'ll_exist : ',il_i,ila_IdPar(il_par),il_par
!	     PRINT *,'iga_IndParam :: ',iga_IndParam(il_i,:)
!#endif
          ENDIF
       ENDDO ! il_ji=1,il_param
    ENDDO ! il_i=1,ig_nprof
    !** Pour chaque profil recherche des parametres CLASS4 (parmi ceux
    ! identifies ci-dessus comme etant effectivement presents dans le fichier)
  ! PRINT *,'cgpa_PARAMETERINT :: ',cgpa_PARAMETERINT
  ! PRINT *,'Taille ::',size(cgpa_PARAMETERINT(:,1)),size(cgpa_PARAMETERINT(1,:))
  ! PRINT *,'Valeurs ::',cgpa_PARAMETERINT(:,1),size(cgpa_PARAMETERINT(:,1))
  ! PRINT *,'Valeurs1 ::',cgpa_PARAMETERINT(:,2)

!#if defined key_debug
!    PRINT *,'ila_IdPar(il_par) :: ',ila_IdPar(:)
!#endif
    IF(ll_NPARAM.AND.ll_NPROF.AND.ll_C_PARAM.AND.ll_L_PARAM) THEN
       il_p = il_L_PARAM
       DO il_i=1,ig_nprof 
          DO il_ji=1,il_L_param
             il_p = 1
             ll_exist = .FALSE.
             il_par = 0
             DO WHILE ( .NOT. ll_exist .AND. il_p <= ig_param_use)
!#if defined key_debug
!               PRINT *,'PARAMS :: ',il_p,ig_param_use
!               PRINT *,'cga_PARAMETERINT ij :: ',cga_PARAMETERINT(il_ji),il_ji
!               PRINT *,'cga_param_use(il_p) :: ',cga_param_use(il_p)
!#endif
                IF (TRIM(cga_param_use(il_p)).EQ. TRIM(cga_PARAMETERINT(il_ji))) THEN
                   ll_exist = .TRUE.  
                   il_par = il_p
                ENDIF
                il_p = il_p + 1
             ENDDO
             IF ( ll_exist ) iga_IndParam(il_i,ila_IdPar(il_par)) = il_par                
          ENDDO ! il_ji=1,il_L_param
        ENDDO ! il_i=1,ig_nprof
    ENDIF        
!!$!** fin modif
#if defined key_debug
   PRINT *,'iga_IndParam :: ',iga_IndParam(1,:)
#endif

    !
    !** Lecture des infos generales des profils
    !   ---------------------------------------

    !*  PLATEFORM_NUMBER  : numero identificateur de la WMO
    cl_tmp = TRIM(cg_plateform)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=8
       lg_PLAT=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_PLATFORM_NUMBER,il_taille)
    ENDIF
    !*  DATA STATE INDICATOR : degré d'élaboration de la donnée
    cl_tmp = TRIM(cg_data_state)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=4
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_DATA_STATE_INDICATOR,il_taille)
       lg_DATA_STATE_INDICATOR = .true.
    else
       lg_DATA_STATE_INDICATOR = .false.
    ENDIF

    !*  INST_REFERENCE : reférence  de l'instrument
    cl_tmp = TRIM(cg_inst_reference)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=64
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_INST_REFERENCE,il_taille)
       lg_INST_REFERENCE=.TRUE.
    ENDIF

    !*  INST_REFERENCE : reférence  de l'instrument
    cl_tmp = TRIM(cg_inst_reference)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=64
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_INST_REFERENCE,il_taille)
       lg_INST_REFERENCE=.TRUE.
    ENDIF


    !*  WMO_INST_TYPE : type d'instrument dans la nomenclature WMO
    cl_tmp = TRIM(cg_wmo_inst_type)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=4
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_WMO_INST_TYPE,il_taille)
       lg_WMO_INST_TYPE=.TRUE. 
   ENDIF

    !* JULD : jour julien du profil
    cl_tmp = TRIM(cg_juld)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,dgpa_JULD)
       lg_JULD=.TRUE.
    ELSE
       il_stat = -20
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    !* LONGITUDE , LATITUDE : position du profile
    cl_tmp = TRIM(cg_lon)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,dgpa_LONGITUDE)
       cl_att='_FillValue'
       CALL MIOL_read_attribute_NC(cd_filename, &
                                   cl_tmp, &
                                   TRIM(cl_att), &
                                   rgp_missvalue)
       lg_LON=.TRUE.
    ELSE
       il_stat = -21
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    cl_tmp = TRIM(cg_lat)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       CALL MIOL_read_field_NC(cd_filename,cl_tmp, dgpa_LATITUDE)
       lg_LAT=.TRUE.
    ELSE
       il_stat = -22
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    !* JULD_QC : facteur qualité sur la date et le tps
    cl_tmp = TRIM(cg_juld_qc)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_JULD_QC,il_taille)
       lg_JULD_QC=.TRUE.
    endif
    !* POSITION_QC : facteur qualité sur la position
    cl_tmp = TRIM(cg_position_qc)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_POSITION_QC,il_taille)
       lg_POSITION_QC=.TRUE.
    endif
    !*  DATA_MODE : definition du temps de la donnée réel, avec delai ou ajusté
    cl_tmp = TRIM(cg_data_mode)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_DATA_MODE,il_taille)
       lg_DATA_MODE=.TRUE.
    endif
    !

    !* PSAL et ses variables associées
    cl_tmp = TRIM(cg_psal)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF( COUNT( iga_IndParam(:,ip_PSAL) > 0 ) > 0 ) THEN
       ll_PSAL=.TRUE.
       lg_PSAL=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_PSAL)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_psal_qc,cgpa_PSAL_QC,il_taille)
       CALL MIOL_inquire_type_NC(cd_filename,cg_psal_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_psal_adjusted,rgpa_PSAL_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_psal_adjusted_qc,cgpa_PSAL_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_psal_adjusted_error,rgpa_PSAL_ADJUSTED_ERROR)
       ENDIF
       DO il_i=1,ig_nprof
          if ( count (cgpa_PSAL_QC(:,il_i) .EQ. '1' .OR. cgpa_PSAL_QC(:,il_i) .EQ. '0' ) > 0  ) then
             iga_IndParam(il_i,ip_PSAL) = ip_PSAL
          endif
       ENDDO ! il_i=1,ig_nprof

    ELSE
       ll_PSAL=.FALSE.
       il_stat=-6
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF
    !
    !  TEMP et ses variables associées
    cl_tmp = TRIM(cg_temp)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF( COUNT( iga_IndParam(:,ip_TEMP) > 0 ) > 0 ) THEN
       ll_TEMP=.TRUE.
       lg_TEMP=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_TEMP)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_temp_qc,cgpa_TEMP_QC,il_taille)
       CALL MIOL_inquire_type_NC(cd_filename,cg_temp_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_temp_adjusted,rgpa_TEMP_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_temp_adjusted_qc,cgpa_TEMP_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_temp_adjusted_error,rgpa_TEMP_ADJUSTED
       ENDIF
       DO il_i=1,ig_nprof
          if ( count (cgpa_TEMP_QC(:,il_i) .EQ. '1' .OR. cgpa_TEMP_QC(:,il_i) .EQ. '0' ) > 0  ) then
             iga_IndParam(il_i,ip_TEMP) = ip_TEMP
          endif
       ENDDO ! il_i=1,ig_nprof

    ELSE
       il_stat=-5
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
       ll_TEMP=.FALSE.
    ENDIF
    !
    ! PRES ou DEPH et leurs variables asssociées
    cl_tmp = TRIM(cg_deph)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF ( COUNT( iga_IndParam(:,ip_DEPH) > 0 ) > 0 ) THEN
       ll_DEPH=.TRUE.
       lg_DEPH=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_DEPH)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_deph_qc,cgpa_DEPH_QC,il_taille)
       CALL MIOL_inquire_type_NC(cd_filename,cg_deph_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_deph_adjusted,rgpa_DEPH_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_deph_adjusted_qc,cgpa_DEPH_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_deph_adjusted_error,rgpa_DEPH_ADJUSTED_ERROR)
       ENDIF
       DO il_i=1,ig_nprof
          if ( count (cgpa_DEPH_QC(:,il_i) .EQ. '1' .OR. cgpa_DEPH_QC(:,il_i) .EQ. '0' ) > 0  ) then
             iga_IndParam(il_i,ip_DEPH) = ip_DEPH
          endif
       ENDDO ! il_i=1,ig_nprof


    ELSE
       ll_DEPH=.FALSE.
       il_stat=-9
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF

    cl_tmp = TRIM(cg_pres)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF ( COUNT( iga_IndParam(:,ip_PRES) > 0 ) > 0 ) THEN
       ll_PRES=.TRUE.
       lg_PRES=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_PRES)
       CALL MIOL_inquire_type_NC(cd_filename,cg_pres_adjusted,il_type,il_nbdim,ll_exist)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_pres_qc,cgpa_PRES_QC,il_taille)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_pres_adjusted,rgpa_PRES_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_pres_adjusted_qc,cgpa_PRES_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_pres_adjusted_error,rgpa_PRES_ADJUSTED_ERROR)
       ENDIF
       DO il_i=1,ig_nprof
          if ( count (cgpa_PRES_QC(:,il_i) .EQ. '1' .OR. cgpa_PRES_QC(:,il_i) .EQ. '0' ) > 0  ) then
             iga_IndParam(il_i,ip_PRES) = ip_PRES
          endif
       ENDDO ! il_i=1,ig_nprof



    ELSE
       ll_PRES=.FALSE.
       il_stat=-10
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF

    IF ( .NOT.(ll_DEPH).AND.(.NOT.ll_PRES)) THEN
       il_stat=-4
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
       id_stat = -4
    ENDIF
    !** Message d'erreur
    IF(.NOT.(ll_DEPH.OR.ll_PRES).AND.(.NOT.ll_TEMP).AND.(.NOT.ll_PSAL)) THEN
       il_stat=-7
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF
    !
    !------------------------------------------------------------------------------
    !
    IF(ll_NPARAM.AND.ll_NPROF.AND.ll_C_PARAM.AND.ll_L_PARAM) THEN


       !
       !** LECTURE des champs de type Class 4
       !
#if defined key_debug
 PRINT *,'Beginning of READ'
#endif
       IF (COUNT( iga_IndParam(:,ip_HDCST_TEMP) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_HDCST_TEMP,rgpa_HDCST_TEMP)   
          lg_HDCT_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_HDCST_PSAL) > 0 ) > 0) THEN
          lg_HDCT_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_HDCST_PSAL,rgpa_HDCST_PSAL)    
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_ANA_TEMP) > 0 ) > 0) THEN
          lg_ANA_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_ANA_TEMP,rgpa_ANA_TEMP)    
       ENDIF   
       IF (COUNT( iga_IndParam(:,ip_ANA_PSAL) > 0 ) > 0)  THEN
          lg_ANA_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_ANA_PSAL,rgpa_ANA_PSAL)    
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST1D_TEMP) > 0 ) > 0) THEN
          lg_FCST1D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST1D_TEMP,rgpa_FRCST1D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST1D_PSAL) > 0 ) > 0) THEN
          lg_FCST1D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST1D_PSAL,rgpa_FRCST1D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST3D_TEMP) > 0 ) > 0) THEN
          lg_FCST3D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST3D_TEMP,rgpa_FRCST3D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST3D_PSAL) > 0 ) > 0) THEN
          lg_FCST3D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST3D_PSAL,rgpa_FRCST3D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST5D_TEMP) > 0 ) > 0) THEN
          lg_FCST5D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST5D_TEMP,rgpa_FRCST5D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST5D_PSAL) > 0 ) > 0) THEN
          lg_FCST5D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST5D_PSAL,rgpa_FRCST5D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST6D_TEMP) > 0 ) > 0) THEN
          lg_FCST6D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST6D_TEMP,rgpa_FRCST6D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST6D_PSAL) > 0 ) > 0) THEN
          lg_FCST6D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST6D_PSAL,rgpa_FRCST6D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS_TEMP) > 0 ) > 0) THEN 
          CALL MIOL_read_field_NC(cd_filename,cl_PERS_TEMP,rgpa_PERS_TEMP)
          lg_PERS_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS_PSAL) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS_PSAL,rgpa_PERS_PSAL)
          lg_PERS_PSAL=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS3D_TEMP) > 0 ) > 0) THEN 
          CALL MIOL_read_field_NC(cd_filename,cl_PERS3D_TEMP,rgpa_PERS3D_TEMP)
          lg_PERS3D_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS3D_PSAL) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS3D_PSAL,rgpa_PERS3D_PSAL)
          lg_PERS3D_PSAL=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS6D_TEMP) > 0 ) > 0)  THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS6D_TEMP,rgpa_PERS6D_TEMP)
          lg_PERS6D_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS6D_PSAL) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS6D_PSAL,rgpa_PERS6D_PSAL)
          lg_PERS6D_PSAL=.TRUE.
       ENDIF

       IF (COUNT( iga_IndParam(:,ip_TMLEV05) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV05,rgpa_TMLEV05)
          lg_TMLEV05=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV05) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV05,rgpa_SMLEV05)
          lg_SMLEV05=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV98) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV98,rgpa_SMLEV98)
          lg_SMLEV98=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV09) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV09,rgpa_TMLEV09)
          lg_TMLEV09=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV98) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV98,rgpa_TMLEV98)
          lg_TMLEV98=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV13) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV13,rgpa_TMLEV13)
          lg_TMLEV13=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV18) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV18,rgpa_TMLEV18)
          lg_TMLEV18=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV09) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV09,rgpa_SMLEV09)
          lg_SMLEV09=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV13) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV13,rgpa_SMLEV13)
          lg_SMLEV13=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV18) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV18,rgpa_SMLEV18)
          lg_SMLEV18=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMMED) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMMED,rgpa_TMMED)
          lg_TMMED=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMMED) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMMED,rgpa_SMMED)
          lg_SMMED=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMARV) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMARV,rgpa_TMARV)
          lg_TMARV=.TRUE.
       ENDIF
        IF (COUNT( iga_IndParam(:,ip_TMARV11) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMARV11,rgpa_TMARV11)
          lg_TMARV11=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMARV) > 0 ) > 0) THEN 
          CALL MIOL_read_field_NC(cd_filename,cl_SMARV,rgpa_SMARV)
          lg_SMARV=.TRUE.
        ENDIF
        IF (COUNT( iga_IndParam(:,ip_SMARV11) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMARV11,rgpa_SMARV11)
          lg_SMARV11=.TRUE.
        ENDIF
    ENDIF
    cg_filename=TRIM(cd_filename)
#if defined key_debug
 PRINT *,'END of READ'
#endif
!!$    !
    !************************************************
    !

9999 CONTINUE

    IF ( ALLOCATED(cla_ParamLu) ) DEALLOCATE(cla_ParamLu)
    IF ( ALLOCATED(ila_IdPar) ) DEALLOCATE(ila_IdPar)
    ! 
    !*--------------------------------------------------------------------------
    !
    !
  END SUBROUTINE read_profile
  ! 
  !*--------------------------------------------------------------------------
  !

 SUBROUTINE read_profile_ARMOR(cd_filename,id_ficlog,id_stat)
    !
    !**** read_profile
    !
    !     Purpose:
    !     --------
    !     Lecture des fichiers ARGO
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item cd_filename
    !      \item id_ficlog
    !
    !     Output : \\
    !      \item id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !     Charge du fichier et extraction des paramètres qui nous intéressent
    !     Externals:
    !     ----------
    !     MCAL_SU_DATE
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        C.REGNIER        Aout 2007       Validation plateform
    !     1.1        C.REGNIER        Octobre 2007    Clean & ajout de lla_class4_2D et lga_2D_tab
    !     1.2        F.HERNANDEZ      Mai 2008        Forte simplification du code
    !     1.3        C.REGNIER        Janvier 2010    Nettoyage et corrections
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE MCAL_SU_DATE
    USE table_ARGO
    USE MIOL
    USE MCAL
    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !
    INTEGER(KIND=4)                                    :: il_ji,il_i,il_ios,il_v,il_k
    INTEGER(kind=4)                                    :: il_C_PARAM,il_L_PARAM,il_nbval
    INTEGER(KIND=4)                                    :: il_stat,il_err,il_jk,il_taille
    INTEGER(KIND=4),DIMENSION(1)                       :: il_size,il_size2
    INTEGER(KIND=4)                                    :: il_param, il_jj,il_p,il_par
    CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE        :: cla_ParamLu
    INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE           :: ila_IdPar
    INTEGER, DIMENSION(:), POINTER                     :: ilpa_dimlen
    INTEGER(KIND=4)                                    :: il_nbvar,il_type,il_nbdim
    LOGICAL                                            :: ll_exist,ll_here
    INTEGER, DIMENSION(:), POINTER                     :: ilpa_vardim
    INTEGER, DIMENSION(:), POINTER                     :: ilpa_vartype
    CHARACTER(LEN=255),DIMENSION(:),POINTER            :: clpa_varname
    CHARACTER(LEN=255)                                 :: cl_test,cl_tmp,cl_att
    LOGICAL                                            :: ll_TEMP,ll_DEPH,ll_PSAL,ll_PRES
    LOGICAL                                            :: ll_C_PARAM,ll_L_PARAM,ll_NLEVELS
    LOGICAL                                            :: ll_tri_prof,ll_NPROF,ll_NPARAM
    CHARACTER(len=6)                                   :: cl_dum1,cl_dum2,cl_dum3
    CHARACTER(LEN=1), DIMENSION(:,:), POINTER          :: clpa_PARAMETERINT

    ! Declaration des parametres usuels attendus dans station parameter

    !
    !**   0.3 Dummy variables
    !
    CHARACTER(LEN=255),INTENT(IN)                      :: cd_filename
    INTEGER(KIND=4) ,OPTIONAL ,INTENT(IN)              :: id_ficlog
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    !
    !*--------------------------------------------------------------------------
    !
    !** initialisation
    id_stat = 0
#if defined key_debug
    WRITE(0,*)  'READ profile ARMOR'
#endif
    !** Ouverture du fichier CORIOLIS ARGO      
    INQUIRE(FILE=cd_filename,EXIST=ll_tri_prof)
    IF ( .NOT. ll_tri_prof ) THEN
       id_stat=-1
       WRITE(id_ficlog,'(a,1x,a)'),'NOT EXIST FILE',TRIM(cd_filename)
       GOTO 9999
    ELSE
       WRITE(id_ficlog,'(a,1x,a)'),'READ FILE',TRIM(cd_filename)
    ENDIF
    !
    !** Lecture des dimensions du fichier
    CALL MIOL_inquire_dimensions_NC(cd_filename,il_nbdim,clpa_dimname,ilpa_dimlen)
    !** Interrogation des variables du fichier
    CALL MIOL_inquire_variables_NC(cd_filename,il_nbvar,clpa_varname,ilpa_vardim,ilpa_vartype)
    ll_NPROF  = .FALSE.
    ll_NPARAM = .FALSE.
    ll_NLEVELS= .FALSE.
    ll_C_PARAM= .FALSE.
    ll_L_PARAM= .FALSE.
    lg_PLAT=.FALSE.
    lg_STATION_PARAMETERS=.FALSE.
    lg_INST_REFERENCE=.FALSE.
    lg_WMO_INST_TYPE=.FALSE.
    lg_DATA_STATE_INDICATOR=.FALSE.
    lg_JULD_QC=.FALSE.
    lg_POSITION_QC=.FALSE.
    lg_DATA_MODE=.FALSE.
    lg_DEPH=.FALSE.
    lg_PSAL=.FALSE.
    lg_PRES=.FALSE.
    lg_PERS3D_PSAL=.FALSE.
    lg_PERS3D_TEMP=.FALSE.
    lg_PERS6D_TEMP=.FALSE.
    lg_PERS6D_PSAL=.FALSE.
    lg_PERS_PSAL=.FALSE.
    lg_PERS_TEMP=.FALSE.
    lg_TEMP=.FALSE.
    lg_LON=.FALSE.
    lg_LAT=.FALSE.
    lg_JULD=.FALSE.
    lg_SMLEV05=.FALSE.
    lg_SMLEV98=.FALSE.
    lg_TMLEV05=.FALSE.
    lg_TMLEV98=.FALSE.
    lg_TMLEV09=.FALSE.
    lg_TMLEV13=.FALSE.
    lg_TMLEV18=.FALSE.
    lg_SMLEV09=.FALSE.
    lg_SMLEV13=.FALSE.
    lg_SMLEV18=.FALSE.
    lg_SMARV=.FALSE.
    lg_SMARV11=.FALSE.
    lg_TMARV=.FALSE.
    lg_TMARV11=.FALSE.
    lg_HDCT_TEMP=.FALSE.
    lg_HDCT_PSAL=.FALSE.
    lg_ANA_TEMP=.FALSE.
    lg_ANA_PSAL=.FALSE.
    lg_FCST1D_TEMP=.FALSE.
    lg_FCST1D_PSAL=.FALSE.
    lg_FCST3D_TEMP=.FALSE.
    lg_FCST3D_PSAL=.FALSE.
    lg_FCST5D_TEMP=.FALSE.
    lg_FCST5D_PSAL=.FALSE.
    lg_FCST6D_TEMP=.FALSE.
    lg_FCST6D_PSAL=.FALSE.
    !
    DO il_ji=1, il_nbdim
       !
       !** Test sur l'existence de NPROF et NPARAM et NLEVELS
       !   
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'N_PROF') THEN
          ll_NPROF = .TRUE. 
          ig_nprof= ilpa_dimlen(il_ji)
       ENDIF
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'N_PARAM') THEN
          il_param=ilpa_dimlen(il_ji)
          ll_NPARAM=  .TRUE.
       ENDIF
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'N_LEVELS') THEN
          ig_nlevels=ilpa_dimlen(il_ji)
          ll_NLEVELS=  .TRUE.
       ENDIF
       !
       !** Test sur l'existence de  L_PARAMETERINT et  C_PARAMETERINT  PARAMETERINT
       ! 
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'C_PARAMETERINT2') THEN
          ll_C_PARAM = .TRUE. 
          il_C_PARAM= ilpa_dimlen(il_ji)
       ENDIF
       IF (TRIM(ADJUSTL(clpa_dimname(il_ji))).EQ.'L_PARAMETERINT2') THEN
          ll_L_PARAM=  .TRUE.
          il_L_PARAM = ilpa_dimlen(il_ji)
       ENDIF
    ENDDO ! il_ji=1, il_nbdim
    !
    !** Si N_PROF et N_PARAM ET C_PARAM L_PARAM existent :CLASS4 on lit
    !   Si  N_PROF et N_PARAM existent coriolis classique : on lit ;  sinon on sort
    !
    IF ( .NOT. (ll_NPROF.AND.ll_NLEVELS) ) THEN
       il_stat = -1
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    IF ( ll_NPARAM ) THEN 
       il_stat=2
       WRITE(cl_dum1,'(i6)')ig_nprof
       WRITE(cl_dum2,'(i6)')il_param
       WRITE(id_ficlog,FMT='(a,1x,a,a,a,a,a,a,a)') TRIM(ADJUSTL(cl_argo_error(il_stat))),&
            &'N_PROF(',TRIM(ADJUSTL(cl_dum1)),') N_PARAM(',TRIM(ADJUSTL(cl_dum2)),')'
    ELSE
       il_stat=3
       WRITE(cl_dum1,'(i6)')ig_nprof
       WRITE(cl_dum2,'(i6)')il_nbvar
       WRITE(id_ficlog,FMT='(a,1x,a,a,a,a,a,a,a)') TRIM(ADJUSTL(cl_argo_error(il_stat))),&
            &'N_PROF(',TRIM(ADJUSTL(cl_dum1)),') Nb Var(',TRIM(ADJUSTL(cl_dum2)),')'
    ENDIF
    IF ( ll_L_PARAM ) THEN
       il_stat = 1
       WRITE(cl_dum3,'(i6)')il_L_PARAM
       WRITE(id_ficlog,FMT='(a,1x,a,a,a,a,a,a,a)') TRIM(ADJUSTL(cl_argo_error(il_stat))),&
            &' L_PARAMETERINT2(',TRIM(ADJUSTL(cl_dum3)),')'
    ENDIF
    !
    !** RECHERCHE DES PARAMETRES EXISTANTS DANS LE FICHIER
    !* initialisation nombre effectif de parametres used
    ig_param_use = 0
    IF ( ALLOCATED(cla_ParamLu) ) DEALLOCATE(cla_ParamLu)
    ALLOCATE (cla_ParamLu(ip_ParamTot))
    cla_ParamLu(:)=' '
    IF ( ALLOCATED(ila_IdPar) ) DEALLOCATE(ila_IdPar)
    ALLOCATE (ila_IdPar(ip_ParamTot))
    ila_IdPar(:)=0


    !
    !** Lecture des parametres contenus dans tous les profils
#if defined key_debug
    PRINT *,'Inquire type station cg_station :: ',cg_station
#endif
    CALL MIOL_inquire_type_NC(cd_filename,TRIM(cg_station),il_type,il_nbdim,ll_exist)
    IF ( ll_exist .AND. ll_NPARAM ) THEN
       WRITE(id_ficlog,fmt='(a,a,a,i5,a)')'Lecture de ',TRIM(cg_station),&
            &' dim(',il_nbdim,')'
       il_taille=16
       CALL MIOL_read_field_NC(TRIM(cd_filename),TRIM(cg_station),cgpa_STATION_PARAMETERS,il_taille)
       lg_STATION_PARAMETERS=.TRUE. 
       !
       !* Recherche de tout les parametres contenus dans STATION_PARAMETERS
       ! on effectue une comparaison a la liste de parametres definis par defaut
       !* boucle sur les parametres usuels standards
       DO il_p = 1 , ip_ParamTot
          IF ( COUNT( cga_param(il_p) == cgpa_STATION_PARAMETERS(:,:,:) ) > 0 ) THEN
             ig_param_use = ig_param_use + 1
             cla_ParamLu(ig_param_use) = TRIM(cga_param(il_p))
             ila_IdPar(ig_param_use) = il_p
#if defined key_debug
             PRINT *,'ig_param_use :: ',ig_param_use
             PRINT *,'il_p :: ',il_p
             PRINT *,'cla_ParamLu(ig_param_use) :: ',cla_ParamLu(ig_param_use)
             PRINT *,'ila_IdPar(ig_param_use) :: ',ila_IdPar(ig_param_use) 
#endif
           ENDIF
       ENDDO
    ENDIF  ! fin ( ll_exist .and.ll_NPARAM )
    !
    !** Lecture des parametres CLASS4 contenus dans le fichier
    CALL MIOL_inquire_type_NC(cd_filename,TRIM(cg_stationCLASS4_ARMOR),il_type,il_nbdim,ll_exist)
    IF ( ll_exist .AND. ll_C_PARAM .AND. ll_L_PARAM ) THEN
       WRITE(id_ficlog,fmt='(a,a,a,i5,a)')'Lecture de',TRIM(cg_stationCLASS4_ARMOR),&
            &' dim(',il_nbdim,')'
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,TRIM(cg_stationCLASS4_ARMOR),cgpa_PARAMETERINT,il_taille)
       
       ALLOCATE(cga_PARAMETERINT(size(cgpa_PARAMETERINT(1,:))))
       DO il_ji=1,il_L_PARAM
          DO il_k=1,il_C_PARAM
             cga_PARAMETERINT(il_ji)(il_k:il_k)=cgpa_PARAMETERINT(il_k,il_ji)                             
          ENDDO
       ENDDO
       WRITE(id_ficlog,*)cgpa_PARAMETERINT
       !* on poursuit la recherche pour identifier les parametres CLASS4
       ! contenus dans ce fichier  et on continue de remplir les tableaux
       ! cla_ParamLu qui contient tous les paramètres contenus dans le fichier
       ! et ila_IdPar qui contient les indices des variables contenues dans le fichier
       ! pour faire la correspondance avec cga_param
       DO il_p = 1 , ip_ParamTot
          IF ( COUNT( cga_param(il_p) == cga_PARAMETERINT(:) ) > 0 ) THEN
             ig_param_use = ig_param_use + 1
             cla_ParamLu(ig_param_use) = TRIM(cga_param(il_p))
             ila_IdPar(ig_param_use) = il_p
#if defined key_debug
             PRINT *,'---------------------------------'
             PRINT *,'ig_param_use CLASS4 :: ',ig_param_use
             PRINT *,'il_p :: ',il_p
             PRINT *,'cla_ParamLu(ig_param_use) :: ',cla_ParamLu(ig_param_use)
             PRINT *,'ila_IdPar(ig_param_use) :: ',ila_IdPar(ig_param_use) 
#endif
          ENDIF
       ENDDO
    ELSE
       il_stat=-16
       WRITE (id_ficlog,FMT='(a50)')TRIM(cl_argo_error(il_stat))
    ENDIF ! fin ( ll_exist .AND. ll_C_PARAM .AND. ll_L_PARAM )
    !** Cas ou il manque ll_NPARAM ou ll_L_PARAM
    IF ( .NOT. (ll_NPARAM) .OR. .NOT. ( ll_C_PARAM .AND. ll_L_PARAM ) ) THEN

       !* on boucle sur les variables existentes et on test 
       !  les parametres d interet
       DO il_p = 1 , ip_ParamTot
          IF ( ANY ( clpa_varname(:) == TRIM(cga_param(il_p)) ) ) THEN
             ll_here = .FALSE.
             DO il_v = 1 , ig_param_use
                IF ( TRIM(cga_param(il_p)) == cla_ParamLu(il_v) ) ll_here = .TRUE.
             ENDDO
             IF ( .NOT. ll_here ) THEN
                ig_param_use = ig_param_use + 1
                cla_ParamLu(ig_param_use) = TRIM(cga_param(il_p))
                ila_IdPar(ig_param_use) = il_p
             ENDIF
          ENDIF

       ENDDO
       
    ENDIF ! fin ( .not. (ll_NPARAM .or. ( ll_C_PARAM .AND. ll_L_PARAM )) )
    
    !** On sort de la routine si aucun fichier utile !
    IF ( ig_param_use == 0 ) THEN
       il_stat = -17
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -17
       GOTO 9999
    ENDIF
    !
#if defined key_debug
     PRINT *,'Params lus :: ',cla_ParamLu(:)
#endif
    !** Bilan sur la recherche: on definit les parametres existants
    WRITE(id_ficlog,fmt='(a,i3)')'Nbr. parametre used: ',ig_param_use

    IF ( ALLOCATED(cga_param_use) ) DEALLOCATE(cga_param_use)
    ALLOCATE ( cga_param_use(ig_param_use) )
    DO il_p = 1 , ig_param_use
       cga_param_use(il_p) = TRIM(cla_ParamLu(il_p))
    ENDDO
    WRITE(id_ficlog,fmt='(a)',advance="no")'Par. Used = '
    IF ( ig_param_use > 1 ) THEN
       DO il_p = 1 , ig_param_use-1
          WRITE(id_ficlog,'(a,1x)',advance="no")TRIM(cga_param_use(il_p))
       ENDDO
    ENDIF
    WRITE(id_ficlog,'(a,1x)',advance="yes")TRIM(cga_param_use(ig_param_use))
 
    !** Allocation dynamique du tableau des correspondances d indices
    ! des parametres pour chaque profil
    IF ( ALLOCATED (iga_IndParam)) DEALLOCATE (iga_IndParam)
    ALLOCATE (iga_IndParam(ig_nprof,ip_ParamTot))
    iga_IndParam(:,:) = 0
#if defined key_debug
    PRINT *,'param use :: ',cga_param_use(:)
#endif
!!$!** Debut modif
    !** Pour chaque profil recherche des parametres standards (parmi ceux
    ! identifies ci-dessus comme etant effectivement presents dans le fichier)
    DO il_i=1,ig_nprof       
       DO il_ji=1,il_param
          il_p = 1
          ll_exist = .FALSE.
          il_par = 0
          DO WHILE ( .NOT. ll_exist .AND. il_p <= ig_param_use)
!             PRINT *,'STATION_PARAMETERS, il_p :: ',cgpa_STATION_PARAMETERS(il_ji,il_i,1),il_ji,il_i,il_p,cga_param_use(il_p)
             IF (TRIM(cga_param_use(il_p)).EQ.TRIM(cgpa_STATION_PARAMETERS(il_ji,il_i,1))) THEN
                ll_exist = .TRUE. 
!#if defined key_debug
!                PRINT *,'TRIM(cga_param_use(il_p) :: ',TRIM(cga_param_use(il_p)) 
!#endif
                il_par = il_p
             ENDIF
             il_p = il_p + 1
          ENDDO
          IF ( ll_exist ) THEN 
             iga_IndParam(il_i,ila_IdPar(il_par)) = il_par
!#if defined key_debug
!             PRINT *,'ll_exist : ',il_i,ila_IdPar(il_par),il_par
!	     PRINT *,'iga_IndParam :: ',iga_IndParam(il_i,:)
!#endif
          ENDIF
       ENDDO ! il_ji=1,il_param
    ENDDO ! il_i=1,ig_nprof
    !** Pour chaque profil recherche des parametres CLASS4 (parmi ceux
    ! identifies ci-dessus comme etant effectivement presents dans le fichier)
  ! PRINT *,'cgpa_PARAMETERINT :: ',cgpa_PARAMETERINT
  ! PRINT *,'Taille ::',size(cgpa_PARAMETERINT(:,1)),size(cgpa_PARAMETERINT(1,:))
  ! PRINT *,'Valeurs ::',cgpa_PARAMETERINT(:,1),size(cgpa_PARAMETERINT(:,1))
  ! PRINT *,'Valeurs1 ::',cgpa_PARAMETERINT(:,2)

!#if defined key_debug
!    PRINT *,'ila_IdPar(il_par) :: ',ila_IdPar(:)
!    PRINT *,'iga_IndParam ',iga_IndParam(0,:)
!#endif
    IF(ll_NPARAM.AND.ll_NPROF.AND.ll_C_PARAM.AND.ll_L_PARAM) THEN
       il_p = il_L_PARAM
       DO il_i=1,ig_nprof 
          DO il_ji=1,il_L_param
             il_p = 1
             ll_exist = .FALSE.
             il_par = 0
             DO WHILE ( .NOT. ll_exist .AND. il_p <= ig_param_use)
!#if defined key_debug
!               PRINT *,'PARAMS :: ',il_p,ig_param_use
!               PRINT *,'cga_PARAMETERINT ij :: ',cga_PARAMETERINT(il_ji),il_ji
!               PRINT *,'cga_param_use(il_p) :: ',cga_param_use(il_p)
!#endif
                IF (TRIM(cga_param_use(il_p)).EQ. TRIM(cga_PARAMETERINT(il_ji))) THEN
                   ll_exist = .TRUE.  
                   il_par = il_p
                ENDIF
                il_p = il_p + 1
             ENDDO
             IF ( ll_exist ) iga_IndParam(il_i,ila_IdPar(il_par)) = il_par                
          ENDDO ! il_ji=1,il_L_param
        ENDDO ! il_i=1,ig_nprof
    ENDIF        
!!$!** fin modif
#if defined key_debug
   PRINT *,'iga_IndParam ',iga_IndParam(1,:)
#endif
    !
    !** Lecture des infos generales des profils
    !   ---------------------------------------

#if defined key_debug
  WRITE (0,*) 'Lecture des infos generales des profils'
#endif 
    !*  PLATEFORM_NUMBER  : numero identificateur de la WMO
    cl_tmp = TRIM(cg_plateform)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=8
       lg_PLAT=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_PLATFORM_NUMBER,il_taille)
    ENDIF
#if defined key_debug
  WRITE (0,*) 'Lecture  PLATEFORM_NUMBER OK'
#endif 
    !*  DATA STATE INDICATOR : degré d'élaboration de la donnée
    cl_tmp = TRIM(cg_data_state)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=4
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_DATA_STATE_INDICATOR,il_taille)
       lg_DATA_STATE_INDICATOR = .true.
    else
       lg_DATA_STATE_INDICATOR = .false.
    ENDIF
#if defined key_debug
  WRITE (0,*) 'Lecture DATA STATE INDICATOR OK'
#endif 

    !*  INST_REFERENCE : reférence  de l'instrument
    cl_tmp = TRIM(cg_inst_reference)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=64
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_INST_REFERENCE,il_taille)
       lg_INST_REFERENCE=.TRUE.
    ENDIF
#if defined key_debug
  WRITE (0,*) 'Lecture INST_REFERENCE OK'
#endif 

    !*  WMO_INST_TYPE : type d'instrument dans la nomenclature WMO
    cl_tmp = TRIM(cg_wmo_inst_type)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=4
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_WMO_INST_TYPE,il_taille)
       lg_WMO_INST_TYPE=.TRUE. 
   ENDIF

#if defined key_debug
  WRITE (0,*) 'Lecture INST_TYPE OK'
#endif 

    !* JULD : jour julien du profil
    cl_tmp = TRIM(cg_juld)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,dgpa_JULD)
       lg_JULD=.TRUE.
    ELSE
       il_stat = -20
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    !* LONGITUDE , LATITUDE : position du profile
    cl_tmp = TRIM(cg_lon)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,dgpa_LONGITUDE)
       cl_att='_FillValue'
       CALL MIOL_read_attribute_NC(cd_filename, &
                                   cl_tmp, &
                                   TRIM(cl_att), &
                                   rgp_missvalue)
       lg_LON=.TRUE.
    ELSE
       il_stat = -21
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
    cl_tmp = TRIM(cg_lat)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       CALL MIOL_read_field_NC(cd_filename,cl_tmp, dgpa_LATITUDE)
       lg_LAT=.TRUE.
    ELSE
       il_stat = -22
       WRITE (id_ficlog,'(a)')TRIM(ADJUSTL(cl_argo_error(il_stat)))
       id_stat = -1
       GOTO 9999
    ENDIF
#if defined key_debug
  WRITE (0,*) 'Lecture JULD LON LAT OK'
#endif 
    !* JULD_QC : facteur qualité sur la date et le tps
    cl_tmp = TRIM(cg_juld_qc)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_JULD_QC,il_taille)
       lg_JULD_QC=.TRUE.
    endif
#if defined key_debug
  WRITE (0,*) 'Lecture JULD_QC OK'
#endif 
    !* POSITION_QC : facteur qualité sur la position
    cl_tmp = TRIM(cg_position_qc)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_POSITION_QC,il_taille)
       lg_POSITION_QC=.TRUE.
    endif
#if defined key_debug
  WRITE (0,*) 'Lecture POSITION_QC OK'
#endif 
    !*  DATA_MODE : definition du temps de la donnée réel, avec delai ou ajusté
    cl_tmp = TRIM(cg_data_mode)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,cgpa_DATA_MODE,il_taille)
       lg_DATA_MODE=.TRUE.
    endif
    !
#if defined key_debug
  WRITE (0,*) 'Lecture DATA_MODE OK'
#endif 

    !* PSAL et ses variables associées
    cl_tmp = TRIM(cg_psal)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF( COUNT( iga_IndParam(:,ip_PSAL) > 0 ) > 0 ) THEN
       ll_PSAL=.TRUE.
       lg_PSAL=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_PSAL)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_psal_qc,cgpa_PSAL_QC,il_taille)
#if defined key_debug
  WRITE (0,*) 'Lecture PSAL_QC OK'
#endif 
       CALL MIOL_inquire_type_NC(cd_filename,cg_psal_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_psal_adjusted_qc,cgpa_PSAL_ADJUSTED_QC,il_taille)
          CALL MIOL_read_field_NC(cd_filename,cg_psal_adjusted,rgpa_PSAL_ADJUSTED)
          !CALL MIOL_read_field_NC(cd_filename,cg_psal_adjusted_error,rgpa_PSAL_ADJUSTED_ERROR)
#if defined key_debug
  WRITE (0,*) 'Lecture PSAL_ADJUSTED_QC OK'
#endif 
       ENDIF
       DO il_i=1,ig_nprof
          if ( count (cgpa_PSAL_QC(:,il_i) .EQ. '1' .OR. cgpa_PSAL_QC(:,il_i) .EQ. '0' ) > 0  ) then
             iga_IndParam(il_i,ip_PSAL) = ip_PSAL
          endif
       ENDDO ! il_i=1,ig_nprof

    ELSE
       ll_PSAL=.FALSE.
       il_stat=-6
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF
    !
    !  TEMP et ses variables associées
    cl_tmp = TRIM(cg_temp)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF( COUNT( iga_IndParam(:,ip_TEMP) > 0 ) > 0 ) THEN
       ll_TEMP=.TRUE.
       lg_TEMP=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_TEMP)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_temp_qc,cgpa_TEMP_QC,il_taille)
#if defined key_debug
  WRITE (0,*) 'Lecture TEMP_QC OK'
#endif 
       CALL MIOL_inquire_type_NC(cd_filename,cg_temp_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_temp_adjusted,rgpa_TEMP_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_temp_adjusted_qc,cgpa_TEMP_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_temp_adjusted_error,rgpa_TEMP_ADJUSTED_ERROR)
#if defined key_debug
  WRITE (0,*) 'Lecture TEMP_ADJUSTED_QC OK'
#endif 
       ENDIF
       DO il_i=1,ig_nprof
          if ( count (cgpa_TEMP_QC(:,il_i) .EQ. '1' .OR. cgpa_TEMP_QC(:,il_i) .EQ. '0' ) > 0  ) then
             iga_IndParam(il_i,ip_TEMP) = ip_TEMP
          endif
       ENDDO ! il_i=1,ig_nprof

    ELSE
       il_stat=-5
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
       ll_TEMP=.FALSE.
    ENDIF
    !
    ! PRES ou DEPH et leurs variables asssociées
    cl_tmp = TRIM(cg_deph)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF ( COUNT( iga_IndParam(:,ip_DEPH) > 0 ) > 0 ) THEN
       ll_DEPH=.TRUE.
       lg_DEPH=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_DEPH)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_deph_qc,cgpa_DEPH_QC,il_taille)
       CALL MIOL_inquire_type_NC(cd_filename,cg_deph_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_deph_adjusted,rgpa_DEPH_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_deph_adjusted_qc,cgpa_DEPH_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_deph_adjusted_error,rgpa_DEPH_ADJUSTED_ERROR)
       ENDIF
     ! WRITE(id_ficlog,fmt='(a)')'DEPH OK '

     !  DO il_i=1,ig_nprof
     !     if ( count (cgpa_DEPH_QC(:,il_i) .EQ. '1' .OR. cgpa_DEPH_QC(:,il_i) .EQ. '0' ) > 0  ) then
     !        iga_IndParam(il_i,ip_DEPH) = ip_DEPH
     !        WRITE(id_ficlog,fmt='(a,2x,i4)')'DEPH OK ',il_i
     !     else
     !        WRITE(id_ficlog,fmt='(a,2x,i4)')'DEPH NOK ',il_i
     !     endif
     !  ENDDO ! il_i=1,ig_nprof

    ELSE
       ll_DEPH=.FALSE.
       il_stat=-9
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF

    cl_tmp = TRIM(cg_pres)
    CALL MIOL_inquire_type_NC(cd_filename,cl_tmp,il_type,il_nbdim,ll_exist)
    IF ( ll_exist ) THEN
!!$    IF ( COUNT( iga_IndParam(:,ip_PRES) > 0 ) > 0 ) THEN
       ll_PRES=.TRUE.
       lg_PRES=.TRUE.
       CALL MIOL_read_field_NC(cd_filename,cl_tmp,rgpa_PRES)
       il_taille=1
       CALL MIOL_read_field_NC(cd_filename,cg_pres_qc,cgpa_PRES_QC,il_taille)
       CALL MIOL_inquire_type_NC(cd_filename,cg_pres_adjusted,il_type,il_nbdim,ll_exist)
       IF ( ll_exist ) THEN
          CALL MIOL_read_field_NC(cd_filename,cg_pres_adjusted,rgpa_PRES_ADJUSTED)
          CALL MIOL_read_field_NC(cd_filename,cg_pres_adjusted_qc,cgpa_PRES_ADJUSTED_QC,il_taille)
          !CALL MIOL_read_field_NC(cd_filename,cg_pres_adjusted_error,rgpa_PRES_ADJUSTED_ERROR)
       ENDIF
     !  WRITE(id_ficlog,fmt='(a)')'Pres OK '
     !  DO il_i=1,ig_nprof
     !     if ( count (cgpa_PRES_QC(:,il_i) .EQ. '1' .OR. cgpa_PRES_QC(:,il_i) .EQ. '0' ) > 0  ) then
     !        iga_IndParam(il_i,ip_PRES) = ip_PRES
     !        WRITE(id_ficlog,fmt='(a,2x,i4)')'PRES OK ',il_i
     !     else
     !        WRITE(id_ficlog,fmt='(a,2x,i4)')'PRES NOK ',il_i
     !     endif
     !  ENDDO ! il_i=1,ig_nprof

    ELSE
       WRITE(id_ficlog,fmt='(a)')'Pres NOK '
       ll_PRES=.FALSE.
       il_stat=-10
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF

    IF ( .NOT.(ll_DEPH).AND.(.NOT.ll_PRES)) THEN
       il_stat=-4
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
       id_stat = -4
    ENDIF
#if defined key_debug
  WRITE (0,*) 'Lecture PRES DEPH OK'
#endif 
    !** Message d'erreur
    IF(.NOT.(ll_DEPH.OR.ll_PRES).AND.(.NOT.ll_TEMP).AND.(.NOT.ll_PSAL)) THEN
       il_stat=-7
       WRITE (id_ficlog,FMT='(a)')TRIM(cl_argo_error(il_stat))
    ENDIF
    !
    !------------------------------------------------------------------------------
    !
    IF(ll_NPARAM.AND.ll_NPROF.AND.ll_C_PARAM.AND.ll_L_PARAM) THEN


       !
       !** LECTURE des champs de type Class 4
       !
#if defined key_debug
 PRINT *,'Beginning of READ ARMOR'
#endif
       IF (COUNT( iga_IndParam(:,ip_HDCST_TEMP) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_HDCST_TEMP,rgpa_HDCST_TEMP)   
          lg_HDCT_TEMP=.TRUE.
!#if defined key_debug
! PRINT *,'READ Hindcast TEMP :',rgpa_HDCST_TEMP
!#endif
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_HDCST_PSAL) > 0 ) > 0) THEN
          lg_HDCT_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_HDCST_PSAL,rgpa_HDCST_PSAL)    
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_ANA_TEMP) > 0 ) > 0) THEN
          lg_ANA_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_ANA_TEMP,rgpa_ANA_TEMP)    
       ENDIF   
       IF (COUNT( iga_IndParam(:,ip_ANA_PSAL) > 0 ) > 0)  THEN
          lg_ANA_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_ANA_PSAL,rgpa_ANA_PSAL)    
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST1D_TEMP) > 0 ) > 0) THEN
          lg_FCST1D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST1D_TEMP,rgpa_FRCST1D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST1D_PSAL) > 0 ) > 0) THEN
          lg_FCST1D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST1D_PSAL,rgpa_FRCST1D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST3D_TEMP) > 0 ) > 0) THEN
          lg_FCST3D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST3D_TEMP,rgpa_FRCST3D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST3D_PSAL) > 0 ) > 0) THEN
          lg_FCST3D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST3D_PSAL,rgpa_FRCST3D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST5D_TEMP) > 0 ) > 0) THEN
          lg_FCST5D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST5D_TEMP,rgpa_FRCST5D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST5D_PSAL) > 0 ) > 0) THEN
          lg_FCST5D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST5D_PSAL,rgpa_FRCST5D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST6D_TEMP) > 0 ) > 0) THEN
          lg_FCST6D_TEMP=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST6D_TEMP,rgpa_FRCST6D_TEMP)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_FRCST6D_PSAL) > 0 ) > 0) THEN
          lg_FCST6D_PSAL=.TRUE.
          CALL MIOL_read_field_NC(cd_filename,cl_FRCST6D_PSAL,rgpa_FRCST6D_PSAL)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS_TEMP) > 0 ) > 0) THEN 
          CALL MIOL_read_field_NC(cd_filename,cl_PERS_TEMP,rgpa_PERS_TEMP)
          lg_PERS_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS_PSAL) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS_PSAL,rgpa_PERS_PSAL)
          lg_PERS_PSAL=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS3D_TEMP) > 0 ) > 0) THEN 
          CALL MIOL_read_field_NC(cd_filename,cl_PERS3D_TEMP,rgpa_PERS3D_TEMP)
          lg_PERS3D_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS3D_PSAL) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS3D_PSAL,rgpa_PERS3D_PSAL)
          lg_PERS3D_PSAL=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS6D_TEMP) > 0 ) > 0)  THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS6D_TEMP,rgpa_PERS6D_TEMP)
          lg_PERS6D_TEMP=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_PERS6D_PSAL) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_PERS6D_PSAL,rgpa_PERS6D_PSAL)
          lg_PERS6D_PSAL=.TRUE.
       ENDIF

       IF (COUNT( iga_IndParam(:,ip_TMLEV05) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV05,rgpa_TMLEV05)
          lg_TMLEV05=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV05) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV05,rgpa_SMLEV05)
          lg_SMLEV05=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV98) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV98,rgpa_SMLEV98)
          lg_SMLEV98=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV09) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV09,rgpa_TMLEV09)
          lg_TMLEV09=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV98) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV98,rgpa_TMLEV98)
          lg_TMLEV98=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMLEV13) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMLEV13,rgpa_TMLEV13)
          lg_TMLEV13=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV09) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV09,rgpa_SMLEV09)
          lg_SMLEV09=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMLEV13) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMLEV13,rgpa_SMLEV13)
          lg_SMLEV13=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMMED) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMMED,rgpa_TMMED)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMMED) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMMED,rgpa_SMMED)
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMARV) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMARV,rgpa_TMARV)
          lg_TMARV=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_TMARV11) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_TMARV11,rgpa_TMARV11)
          lg_TMARV11=.TRUE.
       ENDIF
       IF (COUNT( iga_IndParam(:,ip_SMARV) > 0 ) > 0) THEN 
          CALL MIOL_read_field_NC(cd_filename,cl_SMARV,rgpa_SMARV)
          lg_SMARV=.TRUE.
        ENDIF
        IF (COUNT( iga_IndParam(:,ip_SMARV11) > 0 ) > 0) THEN
          CALL MIOL_read_field_NC(cd_filename,cl_SMARV11,rgpa_SMARV11)
          lg_SMARV11=.TRUE.
        ENDIF
    ENDIF
    cg_filename=TRIM(cd_filename)
#if defined key_debug
 PRINT *,'END of READ'
#endif
!!$    !
    !************************************************
    !

9999 CONTINUE

    IF ( ALLOCATED(cla_ParamLu) ) DEALLOCATE(cla_ParamLu)
    IF ( ALLOCATED(ila_IdPar) ) DEALLOCATE(ila_IdPar)
    ! 
    !*--------------------------------------------------------------------------
    !
    !
  END SUBROUTINE read_profile_ARMOR

  !
  !========================================================
  !
  SUBROUTINE valid_profile(id_ficlog,id_ficsynth,id_stat,cd_file,cd_dirlog)
    !
    !**** valid_profile
    !
    !     Purpose:
    !     --------
    !     Trier les donnees lues d un fichier ARGO pour sortir les profils valides
    !     Trouver le numero de la boite regionale (Class 4)
    !       
    !
    !     Input : \\
    !     ------
    !      \item id_ficlog
    !
    !     Output : \\
    !      \item id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !     Trie en fonction des FLAGs
    !
    !     Externals: InterpBathy
    !     ----------
    !     
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        C.REGNIER        Juillet 2007       Validation plateform
    !     1.1        F. Hernandez     Aout 2007          Rajouter identification boite
    !     1.2        C.REGNIER        Octobre 2007       Nettoyage du code
    !     1.3        F. HERNANDEZ     Avril 2008         Add bathymetric test
    !     1.4        F. HERNANDEZ     Avril 2008         Add potential/in-situ temp
    !     1.5        F. HERNANDEZ     Mai 2008           Nettoyage du code , 
    !                                                     retrait identification boite
    !*--------------------------------------------------------------------------
    !
    !
    !**   0. DECLARATIONS
    !        ------------
    !
    !**   0.1 Include files and modules
    !
    USE table_ARGO
    USE BATHY
    USE table_bathy
    USE HYDRO_POTENTIEL
    USE MIOL
    USE MFT_Inf_NaN_Detection

    IMPLICIT NONE
    !
    !**   0.2 Local variables
    !
    CHARACTER(LEN=255)         :: cd_file,cd_dirlog
    INTEGER(KIND=4)            :: ib_p,il_k,il_s,il_status,il_i
    INTEGER(KIND=4)            :: il_juld_qc_NOK,il_position_qc_NOK,il_j
    INTEGER(kind=4)            :: il_dsi_NOK,il_NO_PRES_DEPH,il_PRES_ET_DEPH,&
				  il_DEPH_QC,il_PRES_QC,il_TEMP_NOK
    !
    REAL(kind=8)                                    :: rl_lon,rl_lat,rl_depth,rl_pres,rl_temp,rl_sal,rl_tempPot
    REAL(kind=4)                                    :: rl_div,rl_nbvaleur_1,rl_nbvaleur_2,rl_missvalue
    INTEGER :: il_bathy
    !
    !
    !**   0.3 Dummy variables
    !
    INTEGER(KIND=4) ,INTENT(IN)                        :: id_ficlog
    INTEGER(KIND=4) ,INTENT(IN)                        :: id_ficsynth
    INTEGER(KIND=4) ,INTENT(OUT)                       :: id_stat
    LOGICAL                                            :: ll_exist_TEMP,ll_exist_PSAL,ll_depth_QC_OK
    !
    !*--------------------------------------------------------------------------
    !

    !** initialisation
    id_stat = 0
    il_juld_qc_NOK = 0
    il_dsi_NOK = 0
    il_NO_PRES_DEPH = 0
    il_PRES_ET_DEPH = 0
    il_position_qc_NOK=0
    ll_depth_QC_OK=.FALSE.
    il_DEPH_QC=0
    il_TEMP_NOK=0
    il_PRES_QC=0
    rl_missvalue=1.e7
    IF ( ALLOCATED (iga_BathyProfil)) DEALLOCATE (iga_BathyProfil)
    ALLOCATE( iga_BathyProfil(ig_nprof))
    IF ( ALLOCATED (rga_DepthVal)) DEALLOCATE (rga_DepthVal)
    ALLOCATE ( rga_DepthVal(ig_nlevels,ig_nprof))
    IF ( ALLOCATED (rga_PresVal)) DEALLOCATE (rga_PresVal)
    ALLOCATE ( rga_PresVal(ig_nlevels,ig_nprof))
    IF ( ALLOCATED (rga_TempVal)) DEALLOCATE (rga_TempVal)
    ALLOCATE ( rga_TempVal(ig_nlevels,ig_nprof))
#if defined key_computePot
    IF ( ALLOCATED (rga_TempPotVal)) DEALLOCATE (rga_TempPotVal)
    ALLOCATE ( rga_TempPotVal(ig_nlevels,ig_nprof))
    rga_TempPotVal(:,:) = rg_TempVal_Def
#endif
    IF ( ALLOCATED (rga_PsalVal)) DEALLOCATE (rga_PsalVal)
    ALLOCATE ( rga_PsalVal(ig_nlevels,ig_nprof))
    IF ( ALLOCATED (iga_MesTempVal) ) DEALLOCATE (iga_MesTempVal)
    ALLOCATE ( iga_MesTempVal(ig_nprof) )
    iga_MesTempVal(:)=0
    IF ( ALLOCATED (iga_MesPsalVal) ) DEALLOCATE (iga_MesPsalVal)
    ALLOCATE ( iga_MesPsalVal(ig_nprof) )
    iga_MesPsalVal(:)=0
    IF ( ALLOCATED (rga_TempDepthMin) ) DEALLOCATE (rga_TempDepthMin)
    ALLOCATE ( rga_TempDepthMin(ig_nprof) )
    rga_TempDepthMin(:)=0.    
    IF ( ALLOCATED (rga_TempDepthMax) ) DEALLOCATE (rga_TempDepthMax)
    ALLOCATE ( rga_TempDepthMax(ig_nprof) )
    rga_TempDepthMax(:)=0.
    IF ( ALLOCATED (rga_PsalDepthMin) ) DEALLOCATE (rga_PsalDepthMin)
    ALLOCATE ( rga_PsalDepthMin(ig_nprof) )
    rga_PsalDepthMin(:)=0.    
    IF ( ALLOCATED (rga_PsalDepthMax) ) DEALLOCATE (rga_PsalDepthMax)
    ALLOCATE ( rga_PsalDepthMax(ig_nprof) )
    rga_PsalDepthMax(:)=0.

#if defined key_debug
 PRINT *,'Dans valid profil'
#endif


    !** Boucle sur chaque profil
    DO ib_p = 1,ig_nprof
    !PRINT *,'Numéro profil::',ib_p
#if defined key_debug
 PRINT *,'Numéro profil::',ib_p
#endif
       rl_lon=dgpa_LONGITUDE(ib_p)
       rl_lat=dgpa_LATITUDE(ib_p)
       !** test de validite de la date 
       !** Date Valide : 1 0 5 8 , good, no_control,corrected, interpolated
       !WRITE(id_ficlog,'(a,1x,4i)')'Profil',ib_p
       IF ( .NOT. (cgpa_JULD_QC(ib_p).EQ.'0' &
            .OR. cgpa_JULD_QC(ib_p).EQ.'1' & 
            .OR. cgpa_JULD_QC(ib_p).EQ.'2' & 
	    .OR.  cgpa_JULD_QC(ib_p).EQ.'5' &
	    .OR.  cgpa_JULD_QC(ib_p).EQ.'8')) THEN
          il_juld_qc_NOK = il_juld_qc_NOK + 1
         ! WRITE(id_ficlog,'(a,1x,a)')'Date non valide',TRIM(cgpa_JULD_QC(ib_p))
#if defined key_debug
 PRINT *,'Date non valide'
#endif
       !** test de validite sur la position
       !** Position Valide : 1 0 5 8 , good, no_control,corrected, interpolated
       ELSEIF (.NOT. (cgpa_POSITION_QC(ib_p).EQ.'0'.OR. &
            & cgpa_POSITION_QC(ib_p).EQ.'1' .OR. &
            & cgpa_POSITION_QC(ib_p).EQ.'5' .OR. &
            & cgpa_POSITION_QC(ib_p).EQ.'8'  ) &
            .OR. dgpa_LONGITUDE(ib_p) > rgp_missvalue &
            .OR. dgpa_LATITUDE(ib_p) > rgp_missvalue &
            .OR. dgpa_LONGITUDE(ib_p) <= -999 &
            .OR. dgpa_LATITUDE(ib_p) <= -999  &
                )  THEN
          il_position_qc_NOK = il_position_qc_NOK + 1
         ! WRITE(id_ficlog,'(a,1x,a)')'Position non valide',TRIM(cgpa_POSITION_QC(ib_p))
#if defined key_debug
 PRINT *,'Position non valide'
#endif
          !** test de validite du Data_State_Indicator
          ! FHZ 27/08/2007: il ne faut pas que DSI=0A
          ! FHZ 21/03/2009 teste DATA_STATE_INDICATOR existe
!!$       ELSEIF( lg_DATA_STATE_INDICATOR ) THEN
!!$          if ( TRIM(cgpa_DATA_STATE_INDICATOR(ib_p,1)) == '0A'  ) &
!!$               & il_dsi_NOK =  il_dsi_NOK + 1
!!$
       ELSE IF ( rl_lon > 360. .OR. rl_lon < -180. .OR. &
            & rl_lat >  90. .OR. rl_lat < -90.) THEN
            WRITE(0,*)' lon or lat value out of range'
            il_position_qc_NOK = il_position_qc_NOK + 1
       ELSE IF ( isnan(rl_lon)  .OR. isnan(rl_lat)) THEN
            WRITE(0,*)' lon or lat value out of range'
            il_position_qc_NOK = il_position_qc_NOK + 1
!!$          !** test de presence de PRES ou DEPH pour ce profil
       ELSE IF ( .NOT. ( iga_IndParam(ib_p,ip_PRES) > 0 .OR. &
            &            iga_IndParam(ib_p,ip_DEPH) > 0 ) ) THEN
          il_NO_PRES_DEPH = il_NO_PRES_DEPH + 1
!          WRITE(id_ficlog,'(a,1x,i4)')'Pression non valide',il_NO_PRES_DEPH
#if defined key_debug
 PRINT *,'Pression non valide'
#endif

      ! ELSE IF ( iga_IndParam(ib_p,ip_PRES) > 0 .AND. &
      !      &    iga_IndParam(ib_p,ip_DEPH) > 0 ) THEN
      !    il_PRES_ET_DEPH = il_PRES_ET_DEPH + 1
!     !    WRITE(id_ficlog,'(a,1x,i4)')'Pression valide',il_PRES_ET_DEPH
       ELSE
         !** test de presence de PRES ET DEPH pour ce profil
         IF ( iga_IndParam(ib_p,ip_PRES) > 0 .AND. &
            &    iga_IndParam(ib_p,ip_DEPH) > 0 ) il_PRES_ET_DEPH = il_PRES_ET_DEPH + 1
!         WRITE(id_ficlog,'(a,1x,i4)')'Pression valide',il_PRES_ET_DEPH
          !** recherche de la bathymetrie
#if defined key_debug
    WRITE(0,*) 'Profil number :: ',ib_p
    WRITE(0,*) 'Interp bathy :: ',rl_lon,rl_lat
#endif 
          CALL InterpBathy(rl_lon,rl_lat,il_bathy,il_status )
          IF ( il_status /= 0 ) THEN
             WRITE(*,*) 'Pb interp bathy ',rl_lon,rl_lat
             WRITE(*,*) 'Profile :',ib_p
             WRITE(*,*) 'Fichier :',cd_file
             CALL EXIT(1)
          ENDIF
          iga_BathyProfil(ib_p) = il_bathy
#if defined key_debug
 PRINT *,'DATA_MODE :: ',cgpa_DATA_MODE(ib_p)
#endif

      !    IF ( cgpa_DATA_MODE(ib_p) == 'A' ) &
      !         & WRITE(id_ficlog,'(a,1x,a)')'Profil ADJUSTED',TRIM(cgpa_PLATFORM_NUMBER(ib_p,1))

          !** gestion de la profondeur valide
          IF ( iga_IndParam(ib_p,ip_PRES) > 0 ) THEN
#if defined key_debug
 PRINT *,'iga_IndParam(ib_p,ip_PRES) > 0'
#endif
             IF ( cgpa_DATA_MODE(ib_p) == 'A' .OR. cgpa_DATA_MODE(ib_p) == 'D' ) THEN
#if defined key_debug
 PRINT *,'DANS DATA MODE == A  or DATA MODE == D  ADJUSTED:: ',TRIM(cgpa_DATA_MODE(ib_p))
#endif
                !** test de validite sur la pression
                !** Pression Valide : 1 0 7   , good, no_control,fixed
                WHERE ( cgpa_PRES_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. cgpa_PRES_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
			cgpa_PRES_ADJUSTED_QC(:,ib_p) .EQ. '7'  )
                   rga_DepthVal(:,ib_p) = rgpa_PRES_ADJUSTED(:,ib_p)
                   rga_PresVal(:,ib_p) = rgpa_PRES_ADJUSTED(:,ib_p)
                ELSEWHERE
                   rga_DepthVal(:,ib_p) = rg_DepthVal_Def
                END WHERE
                if ( count (cgpa_PRES_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. cgpa_PRES_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
			       & cgpa_PRES_ADJUSTED_QC(:,ib_p) .EQ. '7') < 1  ) il_PRES_QC = il_PRES_QC +1
             ELSE
#if defined key_debug
 PRINT *,'DANS PRES DATA MODE /= A or D :: ',TRIM(cgpa_DATA_MODE(ib_p))
#endif
                WHERE ( cgpa_PRES_QC(:,ib_p) .EQ. '1' .OR. cgpa_PRES_QC(:,ib_p) .EQ. '0' .OR. &
			cgpa_PRES_QC(:,ib_p) .EQ. '7')
                   rga_DepthVal(:,ib_p) = rgpa_PRES(:,ib_p)
                   rga_PresVal(:,ib_p) = rgpa_PRES(:,ib_p)
                ELSEWHERE
                   rga_DepthVal(:,ib_p) = rg_DepthVal_Def
                END WHERE
                if ( count (cgpa_PRES_QC(:,ib_p) .EQ. '1' .OR. cgpa_PRES_QC(:,ib_p) .EQ. '0' .OR. &
			  & cgpa_PRES_QC(:,ib_p) .EQ. '7') < 1  ) il_PRES_QC = il_PRES_QC +1
             ENDIF
          ENDIF
          IF ( iga_IndParam(ib_p,ip_DEPH) > 0 ) THEN
#if defined key_debug
 PRINT *,'iga_IndParam(ib_p,ip_DEPH) > 0'
#endif
             IF ( cgpa_DATA_MODE(ib_p) == 'A' .OR. cgpa_DATA_MODE(ib_p) == 'D' ) THEN
                !** test de validite sur la profondeur 
                !** Profondeur Valide : 1 0 7   , good, no_control,fixed
                WHERE ( cgpa_DEPH_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. cgpa_DEPH_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
			cgpa_DEPH_ADJUSTED_QC(:,ib_p) .EQ. '7' )
                   rga_DepthVal(:,ib_p) = rgpa_DEPH_ADJUSTED(:,ib_p)
                ELSEWHERE
                   rga_DepthVal(:,ib_p) = rg_DepthVal_Def
                END WHERE
#if defined key_debug
 PRINT *,'OK1'
#endif
                if ( count (cgpa_DEPH_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. cgpa_DEPH_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
                 cgpa_DEPH_ADJUSTED_QC(:,ib_p) .EQ. '7' ) < 1  ) il_DEPH_QC = il_DEPH_QC +1
#if defined key_debug
 PRINT *,'OK2 ',il_DEPH_QC
#endif
             ELSE
#if defined key_debug
 PRINT *,'DANS DEPH DATA MODE /= A or MODE /= D ',TRIM(cgpa_DATA_MODE(ib_p))
#endif
                WHERE ( cgpa_DEPH_QC(:,ib_p) .EQ. '1' .OR. cgpa_DEPH_QC(:,ib_p) .EQ. '0' .OR. &
			cgpa_DEPH_QC(:,ib_p) .EQ. '7' )
                   rga_DepthVal(:,ib_p) = rgpa_DEPH(:,ib_p)
                ELSEWHERE
                   rga_DepthVal(:,ib_p) = rg_DepthVal_Def
                END WHERE
                 if ( count (cgpa_DEPH_QC(:,ib_p) .EQ. '1' .OR. cgpa_DEPH_QC(:,ib_p) .EQ. '0' .OR. &
			      cgpa_DEPH_QC(:,ib_p) .EQ. '7' ) < 1  ) il_DEPH_QC = il_DEPH_QC +1
             ENDIF
!!            PRINT *,'Profondeur :: ', rga_DepthVal(:,ib_p)
             ! Calcul d une pression a partir de l immersion
#if defined key_debug
 PRINT *,'Calcul d une pression a partir de l immersion'
#endif

             DO il_i=1,ig_nlevels
                IF ( rga_DepthVal(il_i,ib_p) .NE. rg_DepthVal_Def &
                  & .AND. rga_DepthVal(il_i,ib_p) .NE. rg_fillvalue .AND. rga_DepthVal(il_i,ib_p) .lt. rl_missvalue &
                  .AND. rga_DepthVal(il_i,ib_p) .lt. 99000 ) THEN
                   rl_depth = rga_DepthVal(il_i,ib_p)
#if defined key_debug
 WRITE(*,*) 'Fichier :',cd_file
 PRINT *,'profile,level : ',ib_p,il_i
 !PRINT *,'rga_DepthVal(:,ib_p)',rga_DepthVal(:,ib_p)
 PRINT *,'Depth,il_i,lat : ',rl_depth,il_i,rl_lat
#endif
                   CALL imm2pres(rl_depth,rl_lat,rl_pres)
#if defined key_debug
 PRINT *,'pres : ',rl_pres
#endif
                   rga_PresVal(il_i,ib_p) = rl_pres
                ELSE
                   !IF  ( rga_DepthVal(il_i,ib_p) > rl_missvalue .and. rga_DepthVal(il_i,ib_p)  < rg_fillvalue ) THEN
                   !   WRITE(0,*) 'Prof value : ',rga_DepthVal(il_i,ib_p)
                   !   STOP 
                   !ENDIF
                   rga_PresVal(il_i,ib_p) = rg_DepthVal_Def
                ENDIF
             ENDDO
          ENDIF

#if defined key_debug
 PRINT *,'Correction ok'
 if (ib_p == 387) STOP
#endif

          rl_nbvaleur_1=0.
          rl_nbvaleur_2=0.
          rl_div=0.
          !** gestion de la temperature valide
#if defined key_debug
 PRINT *,'gestion de la temperature valide'
#endif
          IF ( iga_IndParam(ib_p,ip_TEMP) > 0 ) THEN
             IF ( cgpa_DATA_MODE(ib_p) == 'A' .OR. cgpa_DATA_MODE(ib_p) == 'D' ) THEN
#if defined key_debug
 PRINT *,'Gestion temp valide DATA MODE= A or MODE = D ADJUSTED'
#endif
                rl_nbvaleur_1=COUNT( cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '4' )
                rl_nbvaleur_2=COUNT( cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
                                     cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. &
                                     cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '2' .OR. &
                                     cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '3')
                !PRINT *,'Profil :: ',ib_p
                !PRINT *,'il_nbvaleur_1,il_nbvaleur_2, rl_div ::',rl_nbvaleur_1,rl_nbvaleur_2 
                IF ( rl_nbvaleur_1+rl_nbvaleur_2 > 0 ) THEN  
                  rl_div=rl_nbvaleur_1/(rl_nbvaleur_1+rl_nbvaleur_2)
                ELSE 
                  rl_div=0
                ENDIF
                IF ( rl_div > 0.2 ) THEN
                    WHERE ( cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
                            cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. &
                            cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '2' .OR. &
                            cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '3' ) cgpa_TEMP_ADJUSTED_QC(:,ib_p) = '4' 
!**           Ecriture fichier
                      INQUIRE(FILE=TRIM(cd_dirlog)//TRIM(cg_TEMP_badprof),EXIST=ll_exist_TEMP)
                      IF ( .NOT. ll_exist_TEMP) THEN
                        !* Create file      
                        OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_TEMP_badprof),form='FORMATTED',STATUS='new')
                        CLOSE(50)
                        ll_exist_TEMP=.TRUE.
                      ENDIF
                      OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_TEMP_badprof),form='FORMATTED',&
                           & POSITION='APPEND',STATUS='old')
                      WRITE(50,FMT=100,advance="yes") TRIM(cg_filename),ib_p,rl_nbvaleur_1,rl_nbvaleur_2,rl_div
                      CLOSE(50)
!**
                 if ( count (cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '1' ) < 1  ) il_TEMP_NOK = il_TEMP_NOK + 1
                ENDIF
               ! PRINT *,'Pourcentage mauvais :: ',rl_div*100
                WHERE ( cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. cgpa_TEMP_ADJUSTED_QC(:,ib_p) .EQ. '0' )
                   rga_TempVal(:,ib_p) = rgpa_TEMP_ADJUSTED(:,ib_p)
                ELSEWHERE
                   rga_TempVal(:,ib_p) = rg_TempVal_Def
                END WHERE
             ELSE
#if defined key_debug
 PRINT *,'Gestion temp valide DATA MODE/= A or /= D'
#endif
!                WRITE(id_ficlog,'(a)')'DANS TEMP DATA MODE /= A'
                rl_nbvaleur_1=COUNT( cgpa_TEMP_QC(:,ib_p) .EQ. '4' )
                rl_nbvaleur_2=COUNT( cgpa_TEMP_QC(:,ib_p) .EQ. '0' .OR. &
                                     cgpa_TEMP_QC(:,ib_p) .EQ. '1' .OR. &
                                     cgpa_TEMP_QC(:,ib_p) .EQ. '2' .OR. &
                                     cgpa_TEMP_QC(:,ib_p) .EQ. '3') 
               ! PRINT *,'Profil :: ',ib_p
               ! PRINT *,'il_nbvaleur_1,il_nbvaleur_2, rl_div ::',rl_nbvaleur_1,rl_nbvaleur_2 
                IF ( rl_nbvaleur_1+rl_nbvaleur_2 > 0 ) THEN  
                  rl_div=rl_nbvaleur_1/(rl_nbvaleur_1+rl_nbvaleur_2)
                ELSE 
                  rl_div=0
                ENDIF
               ! PRINT *,'Pourcentage mauvais :: ',rl_div*100
                IF ( rl_div > 0.2 ) THEN
#if defined key_debug
                      WRITE(0,*) 'CAS pourri TEMP !!!!!!',rl_div,ib_p,rl_nbvaleur_1,rl_nbvaleur_2
#endif
                       WHERE ( cgpa_TEMP_QC(:,ib_p) .EQ. '0' .OR. &
                            cgpa_TEMP_QC(:,ib_p) .EQ. '1' .OR. &
                            cgpa_TEMP_QC(:,ib_p) .EQ. '2' .OR. &
                            cgpa_TEMP_QC(:,ib_p) .EQ. '3' ) cgpa_TEMP_QC(:,ib_p) = '4'
!**           Ecriture fichier
                      INQUIRE(FILE=TRIM(cd_dirlog)//TRIM(cg_TEMP_badprof),EXIST=ll_exist_TEMP)
                      IF ( .NOT. ll_exist_TEMP) THEN
                        !* Create file      
                        OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_TEMP_badprof),form='FORMATTED',STATUS='new')
                        CLOSE(50)
                        ll_exist_TEMP=.TRUE.
                      ENDIF
                      OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_TEMP_badprof),form='FORMATTED',&
                           & POSITION='APPEND',STATUS='old')
                      WRITE(50,FMT=100,advance="yes") TRIM(cg_filename),ib_p,rl_nbvaleur_1,rl_nbvaleur_2,rl_div
                      CLOSE(50)
                      
!**
                 if ( count (cgpa_TEMP_QC(:,ib_p) .EQ. '1' ) < 1  ) il_TEMP_NOK = il_TEMP_NOK + 1
                ENDIF
!#if defined key_debug
! PRINT *, 'cgpa_TEMP_QC(:,ib_p) :: ',cgpa_TEMP_QC(:,ib_p),ib_p
!#endif
                WHERE ( cgpa_TEMP_QC(:,ib_p) .EQ. '1' .OR. cgpa_TEMP_QC(:,ib_p) .EQ. '0' )
                   rga_TempVal(:,ib_p) = rgpa_TEMP(:,ib_p)
                ELSEWHERE
                   rga_TempVal(:,ib_p) = rg_TempVal_Def
                END WHERE
!#if defined key_debug
! PRINT *, ' rga_TempVal(:,ib_p) :: ', rga_TempVal(:,ib_p),ib_p
!#endif
             ENDIF
!#if defined key_debug
! PRINT *, ' rga_DepthVal(:,ib_p) :: ', rga_DepthVal(:,ib_p)
! PRINT *,'COUNT: ',COUNT( (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.  (rga_TempVal(:,ib_p) .NE. rg_TempVal_Def ) )
!#endif

             !** Comptage des mesures valides (en tenant compte de la profondeur valide)
             iga_MesTempVal(ib_p)=COUNT( (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.&
                  &  (rga_TempVal(:,ib_p) .NE. rg_TempVal_Def ) )


             IF ( iga_MesTempVal(ib_p) > 0 ) THEN
                !** Recherche des profondeurs valides min/max (en tenant compte de la profondeur valide)
                rga_TempDepthMin(ib_p)=MINVAL(rga_DepthVal(:,ib_p),&
                     & (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.&
                     &  (rga_TempVal(:,ib_p) .NE. rg_TempVal_Def ) )
                rga_TempDepthMax(ib_p)=MAXVAL(rga_DepthVal(:,ib_p),&
                     & (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.&
                     &  (rga_TempVal(:,ib_p) .NE. rg_TempVal_Def ) )
             ENDIF
          ELSE  
            !WRITE(id_ficlog,'(a,1x,a)')'TEMPERATURE NON VALIDE'
            rga_TempVal(:,ib_p)=rg_TempVal_Def
          ENDIF ! fin de la gestion de la temperature 

          !** gestion de la salinite valide
          IF ( iga_IndParam(ib_p,ip_PSAL) > 0 ) THEN
             IF  ( cgpa_DATA_MODE(ib_p) == 'A' .OR.  cgpa_DATA_MODE(ib_p) == 'D' ) THEN
!                rl_nbvaleur_1=COUNT( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '4' )
!                rl_nbvaleur_2=COUNT( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR.&
!                                     cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR.&
!                                     cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '2' .OR.&
!                                     cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '3')
!
                rl_nbvaleur_1=COUNT( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '4' )
                rl_nbvaleur_2=COUNT( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR.&
                                     cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR.&
                                     cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '2' .OR.&
                                     cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '3')
                IF ( rl_nbvaleur_1+rl_nbvaleur_2 > 0 ) THEN  
                  rl_div=rl_nbvaleur_1/(rl_nbvaleur_1+rl_nbvaleur_2)
                ELSE 
                  rl_div=0
                ENDIF
                IF ( rl_div > 0.2 ) THEN
#if defined key_debug
                    PRINT *,'CAS pourri PSAL !!!!!!',rl_div,ib_p
#endif
                    !WHERE ( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
                    !        cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. &
                    !        cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '2' .OR. &
                    !        cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '3')  cgpa_PSAL_ADJUSTED_QC(:,ib_p) = '4'
                    WHERE ( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '0' .OR. &
                            cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. &
                            cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '2' .OR. &
                            cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '3')  cgpa_PSAL_ADJUSTED_QC(:,ib_p) = '4'
!**           Ecriture fichier
                      INQUIRE(FILE=TRIM(cd_dirlog)//TRIM(cg_PSAL_badprof),EXIST=ll_exist_PSAL)
                      IF ( .NOT. ll_exist_PSAL) THEN
                        !* Create file      
                        OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_PSAL_badprof),form='FORMATTED',STATUS='new')
                        CLOSE(50)
                        ll_exist_PSAL=.TRUE.
                      ENDIF
                      OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_PSAL_badprof),form='FORMATTED',&
                           & POSITION='APPEND',STATUS='old')
                      WRITE(50,FMT=100,advance="yes") TRIM(cg_filename),ib_p,rl_nbvaleur_1,rl_nbvaleur_2,rl_div
                      CLOSE(50)
!**
                ENDIF
                WHERE ( cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '1' .OR. cgpa_PSAL_ADJUSTED_QC(:,ib_p) .EQ. '0' )
                   rga_PsalVal(:,ib_p) = rgpa_PSAL_ADJUSTED(:,ib_p)
                ELSEWHERE
                   rga_PsalVal(:,ib_p) = rg_PsalVal_Def
                END WHERE
             ELSE
                rl_nbvaleur_1=COUNT( cgpa_PSAL_QC(:,ib_p) .EQ. '4' )
                rl_nbvaleur_2=COUNT( cgpa_PSAL_QC(:,ib_p) .EQ. '0' .OR.&
                                     cgpa_PSAL_QC(:,ib_p) .EQ. '1' .OR.&
                                     cgpa_PSAL_QC(:,ib_p) .EQ. '2' .OR.&
                                     cgpa_PSAL_QC(:,ib_p) .EQ. '3')
                IF ( rl_nbvaleur_1+rl_nbvaleur_2 > 0 ) THEN  
                  rl_div=rl_nbvaleur_1/(rl_nbvaleur_1+rl_nbvaleur_2)
                ELSE 
                  rl_div=0
                ENDIF
                IF ( rl_div > 0.2 ) THEN 
#if defined key_debug
                    PRINT *,'CAS pourri PSAL !!!!!!',rl_div,ib_p,rl_nbvaleur_1,rl_nbvaleur_2
#endif
                    WHERE ( cgpa_PSAL_QC(:,ib_p) .EQ. '0' .OR. &
                            cgpa_PSAL_QC(:,ib_p) .EQ. '1' .OR. &
                            cgpa_PSAL_QC(:,ib_p) .EQ. '2' .OR. &
                            cgpa_PSAL_QC(:,ib_p) .EQ. '3') cgpa_PSAL_QC(:,ib_p) = '4'
!**           Ecriture fichier
                      INQUIRE(FILE=TRIM(cd_dirlog)//TRIM(cg_PSAL_badprof),EXIST=ll_exist_PSAL)
                      IF ( .NOT. ll_exist_PSAL) THEN
                        !* Create file      
                        OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_PSAL_badprof),form='FORMATTED',STATUS='new')
                        CLOSE(50)
                        ll_exist_PSAL=.TRUE.
                      ENDIF
                      OPEN(unit=50,file=TRIM(cd_dirlog)//TRIM(cg_PSAL_badprof),form='FORMATTED',&
                           & POSITION='APPEND',STATUS='old')
                      WRITE(50,FMT=100,advance="yes") TRIM(cg_filename),ib_p,rl_nbvaleur_1,rl_nbvaleur_2,rl_div
                      CLOSE(50)
!**
                ENDIF
		!PRINT *, 'cgpa_PSAL_QC(:,ib_p) :: ',cgpa_PSAL_QC(:,ib_p),ib_p
                WHERE ( cgpa_PSAL_QC(:,ib_p) .EQ. '1' .OR. cgpa_PSAL_QC(:,ib_p) .EQ. '0' )
                   rga_PsalVal(:,ib_p) = rgpa_PSAL(:,ib_p)
                ELSEWHERE
                   rga_PsalVal(:,ib_p) = rg_PsalVal_Def
                END WHERE
             ENDIF
!#if defined key_debug
! PRINT *, ' rga_PsalVal :: ', rga_PsalVal(:,ib_p),ib_p
!#endif

             !** Comptage des mesures valides (en tenant compte de la profondeur valide)
             iga_MesPsalVal(ib_p)=COUNT( (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.&
                  &  (rga_PsalVal(:,ib_p) .NE. rg_PsalVal_Def ) )


             IF ( iga_MesPsalVal(ib_p) > 0 ) THEN
                !** Recherche des profondeurs valides min/max (en tenant compte de la profondeur valide)
                rga_PsalDepthMin(ib_p)=MINVAL(rga_DepthVal(:,ib_p),&
                     & (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.&
                     &  (rga_PsalVal(:,ib_p) .NE. rg_PsalVal_Def ) )
                rga_PsalDepthMax(ib_p)=MAXVAL(rga_DepthVal(:,ib_p),&
                     & (rga_DepthVal(:,ib_p) .NE. rg_DepthVal_Def) .AND.&
                     &  (rga_PsalVal(:,ib_p) .NE. rg_PsalVal_Def ) )
             ENDIF
          ELSE 
           ! WRITE(id_ficlog,'(a,1x,a)')'Pas de SALINITE'
            rga_PsalVal(:,ib_p)=rg_PsalVal_Def
          ENDIF ! fin de la gestion de la salinite

          !** Ecriture de la synthese
          WRITE(id_ficsynth,'(a8,1x,a4,2f9.3,1x,f11.5,1x,2I5)')&
               &TRIM(cgpa_PLATFORM_NUMBER(ib_p,1)),&
               &trim(cgpa_WMO_INST_TYPE(ib_p,1)),&
               &rl_lon,&
               &rl_lat,&
               &dgpa_JULD(ib_p),&
               &iga_MesTempVal(ib_p),iga_MesPsalVal(ib_p)
  
#if defined key_computePot
        !!** Correction potentielle
            DO il_i=1,ig_nlevels
               IF  (lg_PSAL) THEN 
                   IF ( rga_PsalVal(il_i,ib_p) .NE. rg_PsalVal_Def ) THEN
                     rl_sal=REAL(rga_PsalVal(il_i,ib_p),8)
                   ELSE
                     rl_sal=rg_PsalVal_Def_R8
                   ENDIF
                  !IF ( rl_sal .NE. rg_PsalVal_Def ) THEN
                  ! PRINT *,'Valeur salinité dans fichier ::',rl_sal,ib_p,il_i
                  ! PRINT *,'fichier :: ',cd_file
                  !ENDIF
               ELSE
                 IF (lg_SMLEV05) THEN
                   IF ( rgpa_SMLEV05(il_i,ib_p) .NE. rg_PsalVal_Def ) THEN
                      rl_sal=REAL(rgpa_SMLEV05(il_i,ib_p),8)
                   ELSE
                      rl_sal=rg_PsalVal_Def_R8
                   ENDIF
                  ! IF ( rl_sal .NE. rg_PsalVal_Def ) THEN
                  !   PRINT *,'Valeur Climato car pas PSAL :: ',rl_sal,ib_p,il_i
                  !   PRINT *,'fichier :: ',cd_file
                  !  ENDIF
                 ELSE IF (lg_SMLEV09) THEN
                   IF ( rgpa_SMLEV09(il_i,ib_p) .NE. rg_PsalVal_Def ) THEN
                      rl_sal=REAL(rgpa_SMLEV09(il_i,ib_p),8)
                   ELSE
                     rl_sal=rg_PsalVal_Def_R8
                   ENDIF
                  ENDIF
               ENDIF
               IF ( rga_DepthVal(il_i,ib_p) .NE. rg_DepthVal_Def .AND. &
                 & rga_PresVal(il_i,ib_p) .NE. rg_DepthVal_Def .AND. &
                 & rl_sal .NE. rg_PsalVal_Def_R8 .AND. &
                 & rga_TempVal(il_i,ib_p) .NE. rg_TempVal_Def ) THEN
                    rl_pres = rga_PresVal(il_i,ib_p)
                    rl_temp = rga_TempVal(il_i,ib_p)
                    if ( rl_sal < 1.e35) then 
                     rga_TempPotVal(il_i,ib_p)=hydro_tetai8(rl_pres,rl_temp,rl_sal,0.d0)
                    else
                     rga_TempPotVal(il_i,ib_p)=rl_temp
                    endif
                    IF (ABS(rga_TempPotVal(il_i,ib_p)-rga_TempVal(il_i,ib_p)) > 2 ) THEN
                          PRINT *,'Fichier :: ',cd_file
                          PRINT *,'Profile, Prof  :: ',ib_p,il_i
                          PRINT *,'Valeur Temp psal pres ::',rl_temp,rl_sal,rl_pres
                          PRINT *,'Valeur pot :: ',rga_TempPotVal(il_i,ib_p)
                          PRINT *,'Valeur insitu :: ',rga_TempVal(il_i,ib_p)
                          PRINT *,'PB !!! '
                          PRINT *,'Valeur salinité :: ',rga_PsalVal(:,ib_p)
                          CALL EXIT(45)
                    ENDIF
                ELSE
                    rga_TempPotVal(il_i,ib_p)=rg_TempVal_Def
                ENDIF
            ENDDO  ! il_i=1,ig_nlevels         
#endif
       ENDIF  ! fin test de validite du profil
    ENDDO  ! ib_p = 1,ig_nprof

    !** Info du traitement dans LOG
    WRITE(id_ficlog,'(a)')'Bilan de validite des profils:'
    IF ( il_juld_qc_NOK > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test date: ',il_juld_qc_NOK
    IF ( il_position_qc_NOK > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test position: ',il_position_qc_NOK
!    IF ( il_dsi_NOK > 0 ) WRITE(id_ficlog,'(a,i6)')&
!         &'- Rejet test DSI: ',il_dsi_NOK
    IF ( il_NO_PRES_DEPH > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test pas de profondeur: ',il_NO_PRES_DEPH
    IF ( il_PRES_ET_DEPH > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test PRES ET DEPH: ',il_PRES_ET_DEPH
    IF ( il_DEPH_QC > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test DEPH_QC /= 0,1,7 : ',il_DEPH_QC
    IF ( il_PRES_QC > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test PRES_QC /= 0,1,7 : ',il_PRES_QC
    IF ( il_TEMP_NOK > 0 ) WRITE(id_ficlog,'(a,i6)')&
         &'- Rejet test TEMP QC /= 1 : ',il_TEMP_NOK
100 FORMAT(a100,1x,i5,1x,f6.3,1x,f6.3,1x,f6.3)



  END SUBROUTINE valid_profile
  !
  !===============================================================
  !
  SUBROUTINE fermer_table_argo(id_stat)
    !
    !**** fermer_table_argo
    !
    !     Purpose:
    !     --------
    !     
    !       
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item ifile
    !      \item cd_filename
    !
    !     Output : \\
    !       id_stat : status de sortie
    !
    !***  Method:
    !     -------
    !     Trie en fonction des FLAGs
    !     Externals:
    !     ----------
    !     MCAL_SU_DATE
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        C.REGNIER        Mars 2007       Validation plateform
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

    !** de allocation variables globales

    IF (lg_STATION_PARAMETERS) DEALLOCATE (cgpa_STATION_PARAMETERS)
    IF (lg_PLAT) DEALLOCATE (cgpa_PLATFORM_NUMBER)
    IF (lg_INST_REFERENCE) DEALLOCATE (cgpa_INST_REFERENCE)
    IF (lg_WMO_INST_TYPE)  DEALLOCATE (cgpa_WMO_INST_TYPE)
    IF (lg_DATA_STATE_INDICATOR)  DEALLOCATE (cgpa_DATA_STATE_INDICATOR)

    IF (lg_JULD_QC) DEALLOCATE (cgpa_JULD_QC)
    IF (lg_POSITION_QC) DEALLOCATE (cgpa_POSITION_QC)
    IF (lg_DATA_MODE) DEALLOCATE (cgpa_DATA_MODE)
    IF (lg_PRES) THEN
      DEALLOCATE (rgpa_PRES)
      DEALLOCATE (cgpa_PRES_QC)
      DEALLOCATE (rgpa_PRES_ADJUSTED)
      DEALLOCATE (cgpa_PRES_ADJUSTED_QC)
    ENDIF
    IF (lg_DEPH)  THEN
      DEALLOCATE (rgpa_DEPH)
      DEALLOCATE (cgpa_DEPH_QC)
      DEALLOCATE (rgpa_DEPH_ADJUSTED)
      DEALLOCATE (cgpa_DEPH_ADJUSTED_QC)

    ENDIF
    IF (lg_TEMP) THEN 
      DEALLOCATE (rgpa_TEMP)
      DEALLOCATE (cgpa_TEMP_QC)
      DEALLOCATE (rgpa_TEMP_ADJUSTED)
      DEALLOCATE (cgpa_TEMP_ADJUSTED_QC)
      IF ( lg_TMARV) DEALLOCATE (rgpa_TMARV)
      IF ( lg_TMARV11) DEALLOCATE (rgpa_TMARV11)
      IF ( lg_TMLEV09) DEALLOCATE (rgpa_TMLEV09)
      IF ( lg_TMLEV13) DEALLOCATE (rgpa_TMLEV13)
      IF ( lg_TMLEV05) DEALLOCATE (rgpa_TMLEV05)
      IF ( lg_TMLEV98) DEALLOCATE (rgpa_TMLEV98)
      IF ( lg_HDCT_TEMP ) DEALLOCATE (rgpa_HDCST_TEMP)
      IF ( lg_ANA_TEMP ) DEALLOCATE (rgpa_ANA_TEMP)
      IF ( lg_FCST1D_TEMP )  DEALLOCATE (rgpa_FRCST1D_TEMP)
      IF ( lg_FCST3D_TEMP )  DEALLOCATE (rgpa_FRCST3D_TEMP)
      IF ( lg_FCST5D_TEMP )  DEALLOCATE (rgpa_FRCST5D_TEMP)
      IF ( lg_FCST6D_TEMP )  DEALLOCATE (rgpa_FRCST6D_TEMP)
   ENDIF

    IF (lg_PSAL) THEN 
      DEALLOCATE (rgpa_PSAL)
      DEALLOCATE (cgpa_PSAL_QC)
      DEALLOCATE (rgpa_PSAL_ADJUSTED)
      DEALLOCATE (cgpa_PSAL_ADJUSTED_QC)

      IF ( lg_HDCT_PSAL )DEALLOCATE (rgpa_HDCST_PSAL)
      IF ( lg_ANA_PSAL ) DEALLOCATE (rgpa_ANA_PSAL)
      IF ( lg_FCST1D_PSAL ) DEALLOCATE (rgpa_FRCST1D_PSAL)
      IF ( lg_FCST3D_PSAL ) DEALLOCATE (rgpa_FRCST3D_PSAL)
      IF ( lg_FCST5D_PSAL ) DEALLOCATE (rgpa_FRCST5D_PSAL)
      IF ( lg_FCST6D_PSAL ) DEALLOCATE (rgpa_FRCST6D_PSAL)
    ENDIF
    IF (lg_SMLEV05) DEALLOCATE (rgpa_SMLEV05)                                                   
    IF (lg_SMLEV09) DEALLOCATE (rgpa_SMLEV09)
    IF (lg_SMLEV13) DEALLOCATE (rgpa_SMLEV13)
    IF (lg_SMLEV98) DEALLOCATE (rgpa_SMLEV98)
    IF (lg_SMARV) DEALLOCATE (rgpa_SMARV)
    IF (lg_SMARV11) DEALLOCATE (rgpa_SMARV11)
    IF (lg_JULD) DEALLOCATE (dgpa_JULD)
    IF (lg_LON) DEALLOCATE (dgpa_LONGITUDE)
    IF (lg_lat) DEALLOCATE (dgpa_LATITUDE)

    IF ( ALLOCATED (cga_PARAMETERINT)) DEALLOCATE (cga_PARAMETERINT)
    IF ( ALLOCATED (rga_DepthVal)) DEALLOCATE (rga_DepthVal)
    IF ( ALLOCATED (rga_PresVal)) DEALLOCATE (rga_PresVal)
    IF ( ALLOCATED (rga_TempVal)) DEALLOCATE (rga_TempVal)
    IF ( ALLOCATED (rga_PsalVal)) DEALLOCATE (rga_PsalVal)

#if defined key_computePot
    IF ( ALLOCATED (rga_TempPotVal)) DEALLOCATE (rga_TempPotVal)
#endif

    IF ( ALLOCATED (iga_BathyProfil)) DEALLOCATE (iga_BathyProfil)

    IF (lg_PERS3D_PSAL) DEALLOCATE (rgpa_PERS3D_PSAL)
    IF (lg_PERS3D_TEMP) DEALLOCATE (rgpa_PERS3D_TEMP)
    IF (lg_PERS6D_PSAL) DEALLOCATE (rgpa_PERS6D_PSAL)
    IF (lg_PERS6D_TEMP) DEALLOCATE (rgpa_PERS6D_TEMP)
   
 
    IF (lg_PERS_TEMP) DEALLOCATE (rgpa_PERS_TEMP)
    IF (lg_PERS_PSAL) DEALLOCATE (rgpa_PERS_PSAL)

  END SUBROUTINE fermer_table_argo
  !
  !========================================================
  !
  FUNCTION cl_argo_error(il_error)
    !
    !** cl_argo_error
    !
    !  Purpose:
    !     --------
    !    Fonction erreur des fichiers ARGO
    !       
    !
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !     1.0        C.REGNIER        Mars 2007       Validation plateform
    !*-------------------------------
    !  
    CHARACTER(LEN=80)    :: cl_argo_error
    INTEGER(KIND=4)      :: il_error
    !
    SELECT CASE(il_error)
    CASE (1)
       cl_argo_error = "Fichier CLASS4 PARAMETERINT Defini"
    CASE (2)
       cl_argo_error=  "Fichier classique Coriolis avec N_PROF et N_PARAM"
    CASE (3)
       cl_argo_error=  "Fichier PAS classique Coriolis avec N_PROF mais pas N_PARAM"
    CASE (-1)
       cl_argo_error=  "Manque NPROF et NPARAM et NLEVEL"
    CASE (-2)
       cl_argo_error=  "PARAMETERINT vide !"
    CASE (-3)
       cl_argo_error=  "STATION PARAMETER VIDE"
    CASE (-4)
       cl_argo_error=  "PAS de DEPH et PAS de PRES"
    CASE (-5)
       cl_argo_error=  "PAS de TEMP"
    CASE (-6)
       cl_argo_error=  "PAS de PSAL"
    CASE (-7)
       cl_argo_error=  "PAS de DEPH ou PRES, pas de TEMP, pas de PSAL"
    CASE (-9)
       cl_argo_error=  "PAS de DEPH"
    CASE (-10)
       cl_argo_error=  "PAS de PRES"
    CASE (-11)
       cl_argo_error=  "PAS de FORECAST"
    CASE (-12)
       cl_argo_error=  "PAS de HINDCAST"
    CASE (-13)
       cl_argo_error=  "PAS d'ANALYSE "
    CASE (-14)
       cl_argo_error=  "PAS de PERSISTENCE"
    CASE (-15)
       cl_argo_error=  "PAS de CLIMATO"
    CASE (-16)
       cl_argo_error=  "PAS de PARAMETERINT : fichier non enrichi"
    CASE(-17)
       cl_argo_error=  "AUCUN parametre UTILE !"
    CASE(-20)
       cl_argo_error=  "PAS de JULD !"
    CASE(-21)
       cl_argo_error=  "PAS de LON !"
    CASE(-22)
       cl_argo_error=  "PAS de LON !"
    CASE default
       cl_argo_error=  "Unknown error"
       !  
       WRITE(*,*)cl_argo_error

    END SELECT
  END FUNCTION cl_argo_error
  !
  !========================================================
  !
END MODULE READ_ARGO
