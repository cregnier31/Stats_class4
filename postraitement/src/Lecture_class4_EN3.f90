PROGRAM Lecture_class4
  !
  !**** Lecture_class4
  !
  !     Purpose :
  !     Lecture des fichiers argo class4 et lancement de
  !     la validation des fichiers enrichis
  !
  !***  Method  :    Step 1
  !                  Lectures des fichiers
  !                  Step 2
  !                  Stats
  !     Externals : affect_table_EN3, MIOL_getFreeLu
  !                 MIOL_read_field_NC,MIOL_create_file_NC,MIOL_openw_file_NC
  !                 MIOL_write_field_NC,MIOL_close_file_NC
  !                 read_profile,valid_profile,stat_boite_class4,fermer_table_argo
  !                 LireDefBoite,ChargerBathy,FermerBathy
  !     Files :
  !     References:
  !
  !     History
  !     -------
  !      Version    Programmer    Date       Description
  !      ---------------------------------------------
  !       1.0       C.REGNIER    30/03/2007    created
  !       1.1       F. HERNANDEZ 02/08/2007    add box identification
  !       1.2       C.REGNIER    02/10/2007    clean, work with all MERSEA files
  !       1.3       F. HERNANDEZ 18/04/2008    add bathy interpolation
  !
  !*-------------------------------------------------------------
  !

  !
  !** ++  MODULES used
  !  
!  USE miol_util
!  USE miol_param
  USE miol
  USE mcal
  USE netcdf

  USE MCAL_SU_DATE
  USE READ_EN3
  USE table_EN3
  USE BOITE
  USE boite_bins
  USE table_boite
  USE table_class4_EN3
  USE DIAG_CLASS4_EN3
  USE BATHY
  USE table_bathy
  !
  !** ++  Local Declarations 
  !
  IMPLICIT NONE
  INTEGER(KIND=4)                               :: il_i,il_ji,il_s,il_r,il_ib,il_par
  INTEGER(kind=4)                               :: il_nbfile,il_status,il_stat,il_ficStatBoite
  INTEGER(KIND=4)                               :: il_nbdim, il_ficliste,il_file_id,il_narg,iargc,il_proftot
  INTEGER(KIND=4)  ,DIMENSION(:),ALLOCATABLE    :: ila_dimlen
  CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE   :: cla_inputFile,cla_dimname
  CHARACTER(LEN=255)                            :: cd_commandFile,PATH,cl_tmp
  CHARACTER(LEN=255)                            :: cd_LogFile,cd_SynthFile
  INTEGER(kind=4)                               :: il_ficlog,il_ficsynth
  CHARACTER(LEN=255)                            :: cl_bathyfile, cl_bathytype
  REAL(KIND=4)                                  :: rl_bathyseuil
  REAL(KIND=4)                                  :: rl_EcartTempMax,rl_EcartSalMax,rl_pourcent
  REAL(KIND=4), DIMENSION(:),POINTER            :: rlpa_lon,rlpa_lat
  REAL(KIND=8), DIMENSION(:,:,:),ALLOCATABLE    :: rga_diff_loc2
  CHARACTER(len=6)                              :: cl_dum1,cl_dum2,cl_dum3


  ! Gestion des fichiers de stat en sortie
  CHARACTER(255)                                :: cl_RmsDiffFicOut,cl_MeanDiffFicOut
  CHARACTER(LEN=255)                            :: cl_input,cl_input2,cl_input3,cl_input4,cl_input5
  REAL(KIND=8) :: rl_pour
  !
  !*-------------------------------------------------------------
  !
  !** LECTURE DES ARGUMENTS
  il_narg=iargc()
  IF (il_narg.lt.6) THEN
     PRINT *,'USAGE :: cd_commandFile cl_input modele rep_in date_run il_typegrid'
     STOP 
  ENDIF
  ! recup nom de la nameliste
  CALL getarg(1,cd_commandFile)
  ! recup du jour min.
  CALL getarg(2,cl_input)
  ! recup type de modele
  CALL getarg(3,cl_input2)
  ! recup de repertoire de STATS Class 4
  CALL getarg(4,cl_input3)
  ! recup de repertoire de la date de RUN
  CALL getarg(5,cl_input4)
  ! Type de fichiers boite 
  CALL getarg(6,cl_input5)
  READ(cl_input5,*) ig_typegrid
  IF ( ig_typegrid /= 1 .AND. ig_typegrid /= 2) THEN
    PRINT *,'Grid type not valid'
     STOP 
  ENDIF
  !** Initialisation des tableaux de lecture EN3 
  CALL affect_table_EN3
  ! Definition de la structure de l entete
  NAMELIST / liste_corio /  il_nbfile , PATH , cd_LogFile, cd_SynthFile, &
       & cl_bathyfile, cl_bathytype , &
       & rl_bathyseuil , rl_EcartTempMax , rl_EcartSalMax
  ! Ouverture du fichier de nameliste  
  CALL MIOL_getFreeLu(il_ficliste)
  OPEN(il_ficliste, file=TRIM(cd_commandFile), &
       status='old', &
       form='formatted', &
       iostat=il_status)
  ! Lecture de l entete
  READ(il_ficliste,liste_corio)
  ! alloc tableau des fichiers Coriolis
  ALLOCATE(cla_inputFile(il_nbfile), stat=il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Liste argo memory allocation error.'
     CALL flush(0)
     STOP
  ENDIF

  !** Remplit le tableaux avec le nom des fichiers selectionnés 
  ! boucle de lecture sur les fichiers        
  DO il_ji=1,il_nbfile
     READ(il_ficliste,FMT='(A)') cl_tmp
     cla_inputFile(il_ji) = TRIM(PATH)//TRIM(cl_tmp)
  ENDDO
  CLOSE(il_ficliste)

  !** Ouverture et lecture du fichier BOITE et mise en memoire des zones
  SELECT CASE (ig_typegrid)
   CASE(1) 
     CALL LireDefBoite (FP_BoxDefFile,il_status)
   CASE(2)
     CALL LireDefBoitebins(FP_BoxDefFile,il_status)
   ENDSELECT
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Box Def file reading error ',FP_BoxDefFile
     CALL flush(0)
     STOP
  ENDIF

  !** prise en compte du seuil bathy
  rg_BathySeuil = rl_bathyseuil

  !** Ecarts mes pour les differences en temperature et salinite
  rg_EcartTempMax = rl_EcartTempMax
  rg_EcartSalMax = rl_EcartSalMax  
  !** Ouverture du fichier LOG
  CALL MIOL_getFreeLu(il_ficlog)
  OPEN(unit=il_ficlog,file=TRIM(cd_LogFile),form='FORMATTED',&
       &ACCESS='SEQUENTIAL',STATUS='REPLACE')

  !** Ouverture du fichier synthese
  CALL MIOL_getFreeLu(il_ficsynth)
  OPEN(unit=il_ficsynth,file=TRIM(cd_SynthFile),form='FORMATTED',&
       &ACCESS='SEQUENTIAL',STATUS='REPLACE')

  !** Boucle de lecture des fichiers CORIOLIS
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a)')'           Lecture des fichiers Class 4             '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a,a)')'Input File Directory : ',TRIM(PATH)
  WRITE(il_ficlog,'(a)')' '

  !** Traitement des classes de profondeur
  CALL definir_classe_profondeur(il_status)
  PRINT *,'OK definir_classe_profondeur',ig_NbDepthDef
  IF ( il_status /= 0 ) THEN
     WRITE(0,'(a)')'Error in definir_classe_profondeur'
     CALL flush(0)
     STOP
  ENDIF
  IF ( lg_DepthDefFile ) THEN
     WRITE(il_ficlog,'(a,a)') 'TRI des profils par PROFONDEUR ',TRIM(FP_DepthDefFile)
     WRITE(0,'(a,a)') 'TRI des profils par PROFONDEUR ',TRIM(FP_DepthDefFile)
  ELSE
     WRITE(il_ficlog,'(a)') 'PAS de TRI des profils par PROFONDEUR'
     WRITE(0,'(a)') 'PAS de TRI des profils par PROFONDEUR'
  ENDIF
  WRITE(0,'(a,i6)') 'Nb. classe de profondeur utilisees:',ig_NbDepthDef
  !** On ecrit les classes de profondeur dans le fichier log 
  WRITE(il_ficlog,'(a,i6)') 'Nb. classe de profondeur utilisees: ',ig_NbDepthDef 
  DO il_ib = 1 , ig_NbDepthDef+1
     WRITE(il_ficlog,*)rga_DepthMin(il_ib),rga_DepthMax(il_ib)
  ENDDO

  !** On ecrit les classes de profondeur dans le fichier synth
  WRITE(il_ficsynth,'(i6)') ig_NbDepthDef 
  DO il_ib = 1 , ig_NbDepthDef+1
     WRITE(il_ficsynth,*)rga_DepthMin(il_ib),rga_DepthMax(il_ib)
  ENDDO

  !** Gestion de la bathymetrie
  ! definition du nom et type de fichier bathy
  cg_BathyFile = cl_bathyfile
  IF ( TRIM(cl_bathytype) == 'CLS' ) ig_BathyType = 1
  ! lecture du fichier bathy (bathy.f90)
  CALL ChargerBathy (il_status)
  !PRINT *,'Bathy OK'
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Bathy file reading error ',TRIM(cg_BathyFile)
     CALL flush(0)
     STOP
  ENDIF
  ! Ecriture en Log
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a,a)')'Bathy File :',TRIM(cg_BathyFile)
  WRITE(il_ficlog,'(a,a)')'Bathy Type :',TRIM(cl_bathytype)
  WRITE(il_ficlog,'(a,f12.2)')'Bathy Seuil :',rg_BathySeuil
  WRITE(il_ficlog,'(a,f16.6)')'Anomalie Max de Temperature :',rg_EcartTempMax
  WRITE(il_ficlog,'(a,a)')'Fichier anomalies de Temperature :',TRIM(cg_FicDiffTEMP)
  WRITE(il_ficlog,'(a,f16.6)')'Anomalie Max de Salinite :',rg_EcartSalMax
  WRITE(il_ficlog,'(a,a)')'Fichier anomalies de Salinite :',TRIM(cg_FicDiffPSAL)
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  !** Definition des parametres traites
  CALL affect_table_class4(il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Error in affect_table_class4'
     CALL flush(0)
     STOP
  ENDIF
  IF ( il_nbfile > 1000 ) THEN
     il_proftot=il_nbfile*10 ! 10 chiffre empirique indiquant le nombre max moyen de profils par fichier
  ELSE
     il_proftot=il_nbfile*3000 ! 3000 chiffre empirique indiquant le nombre max moyen de profils par fichier
  ENDIF
  ALLOCATE(rga_diff_loc(ig_ParamStat,ig_NbDepthDef+1,il_proftot))
  rga_diff_loc(:,:,:)=9999.
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  !----------------------------------------------------------------------------
  !
  !    Coriolis Input file loop:: Boucle sur les fichiers enrichis
  !
  !----------------------------------------------------------------------------

  ig_FicLus = 0
  DO il_ji=1,il_nbfile

     WRITE(*,*)'Inputfile',trim(cla_inputFile(il_ji))
     WRITE(30,*)'Inputfile',trim(cla_inputFile(il_ji))
     !** Lecture du contenu du fichier CORIOLIS, fonction read_profile
     !   (lecture des profils dans le fichier)
      OPEN(unit=60,file="/home/qualif/CLASS4/Lecture_Class4_V2.0/log/pb_profils.txt",form='FORMATTED',&
                               & POSITION='APPEND',STATUS='old')
     WRITE(60,FMT='(a200)',advance="yes") TRIM(cla_inputFile(il_ji))
     CLOSE(60)
     CALL read_profile(cla_inputFile(il_ji),il_ficlog,il_stat)
     ig_FicLus = ig_FicLus + 1
     WRITE(il_ficlog,'(a,i4,a,i5)')'Fin de lecture du fichier num.',&
          &ig_FicLus,' Vertical Levels=',ig_nlevels

     IF ( il_ji .EQ. 1 ) THEN
        ig_indi=0
     ENDIF

     !** Tri des profils pour garder les profils valides :: fonction valid_profile
     IF ( il_stat >= 0 ) THEN 
        CALL valid_profile(il_ficlog,il_ficsynth,il_stat)
        WRITE(cl_dum1,'(i6)')ig_nprof
        WRITE(cl_dum2,'(i6)')COUNT(iga_MesTempVal(:) > 0)
        WRITE(cl_dum3,'(i6)')COUNT(iga_MesPsalVal(:) > 0)
        WRITE(il_ficlog,'(6a)')'NB PROFIL: ',TRIM(ADJUSTL(cl_dum1)),&
             & ' T Valid: ',TRIM(ADJUSTL(cl_dum2)),&
             & ' S valid: ',TRIM(ADJUSTL(cl_dum3))
        ig_nbproftot=ig_nbproftot+ig_nprof
        ig_indi=ig_indi+ig_nprof

     ELSE
        WRITE(il_ficlog,'(a,a)')'Pas de Valid/Tri sur :',TRIM(cla_inputFile(il_ji))
     ENDIF

     !** Classement des profils valides par boites et statistiques Class 4
     ! appel de stat_boite_class4
     IF ( il_stat >= 0 ) THEN
        CALL stat_boite_class4(il_stat)
     ENDIF


     !** Fermeture et des-allocation des tableaux pour le fichier Coriolis
     !   qui vient d etre lu et traite
     CALL  fermer_table_argo(il_stat)

     !** De-allocation des tableaux de stat CLASS4 qui depende du fichier lu
     CALL  fermer_stat_class4(il_stat)

     WRITE (il_ficlog,'(a)'),'**************************************************'
     WRITE (il_ficlog,'(a)'),' '

  ENDDO ! end loop on Coriolis files : il_ji=1,il_nbfile

  !** Close bathy
  CALL FermerBathy (il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Bathy data closing error '
     CALL flush(0)
     STOP
  ENDIF
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'De-Allocage Bathy data'

  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a)')'===   FIN de la lecture des fichiers Class 4    ===='
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'


  !---------------------------------------------------------------------------
  !
  !*                         TRAITEMENT PAR BOITE
  !
  !---------------------------------------------------------------------------

  !* VERRUE: statistique sur les temperatures potentielles
  
  DO il_ib = 1 , ig_NbDepthDef+1
     if ( iga_NbDiffTetaProf(il_ib) .ne. 0 ) then
        rga_DiffTetaProf(il_ib) = rga_DiffTetaProf(il_ib) / iga_NbDiffTetaProf(il_ib)
        rga_DiffTetaProf2(il_ib) = rga_DiffTetaProf2(il_ib) / iga_NbDiffTetaProf(il_ib)
        rga_DiffTetaProf2(il_ib) = sqrt(rga_DiffTetaProf2(il_ib))
        WRITE(*,'(2f6.0,1x,i8,2F12.6)')rga_DepthMin(il_ib),rga_DepthMax(il_ib),&
             & iga_NbDiffTetaProf(il_ib),rga_DiffTetaProf(il_ib),rga_DiffTetaProf2(il_ib)
     endif
  ENDDO
  ALLOCATE(rga_diff_loc2(ig_ParamStat,ig_NbDepthDef+1,ig_nbproftot))
  rga_diff_loc2=rga_diff_loc(:,:,1:ig_nbproftot)

  !** Creation du fichier de sortie par boite
  PRINT *,' ---------Creation du fichier de sortie-------------------------------'
  if ( cl_input4 /= '' ) then
     cl_RmsDiffFicOut=TRIM(cl_input3)//TRIM(cl_input2)//'_rms_diff_R'//TRIM(cl_input4)//'.nc'
     PRINT *,'cl_input :: ', cl_RmsDiffFicOut
  else
     cl_RmsDiffFicOut=TRIM(cl_input3)//TRIM(cl_input2)//'_rms_diff_'//TRIM(cl_input)//'.nc'
     PRINT *,'cl_input :: ',cl_RmsDiffFicOut
  endif

  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a)')'            Statistiques par boite'
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a,a)')'Fichier de sortie: ',TRIM(cl_RmsDiffFicOut)
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'Nbr. point rejetes par profondeur'
  WRITE(il_ficlog,'(a1,a13,a16,1x,a1,1x,a9,1x,a7,1x,a6,3x,a1)')'!',' Profondeurs ','     Parametre  ','!','    No-OK','  OK  ',&
  ' % OK ','!'


  DO il_par = 1 , ig_ParamStat
     DO il_ib = 1 , ig_NbDepthDef+1
        IF ( ig_StatNOK(il_ib,il_par)> 0 .OR.ig_StatOK(il_ib,il_par)>0 ) THEN
           rl_pourcent=(REAL(ig_StatOK(il_ib,il_par),4)/(REAL(ig_StatNOK(il_ib,il_par),4)+REAL(ig_StatOK(il_ib,il_par),4)))*100
           WRITE(il_ficlog,'(a1,2f6.0,1x,a16,1x,a1,1x,2I8,2x,f6.2,2x,a2)')'!',rga_DepthMin(il_ib),rga_DepthMax(il_ib),&
                & TRIM(cga_param(iga_IndParamStat(il_par))),'!',&
                & ig_StatNOK(il_ib,il_par),ig_StatOK(il_ib,il_par),rl_pourcent,' !'
        ENDIF
     ENDDO
  ENDDO


  il_nbdim=3
  ALLOCATE(cla_dimname(il_nbdim)) !ig_nbregion,ig_ParamStat-3,ig_NbDepthDef+1))
  ALLOCATE(ila_dimlen(il_nbdim))

  cla_dimname(1) = 'x'
  cla_dimname(2)=  'y'
  cla_dimname(3)=  'z'
  ila_dimlen(1) = ig_nbregion
  ila_dimlen(2) = ig_ParamStat
  ila_dimlen(3) = ig_NbDepthDef+1
  CALL MIOL_create_file_NC(TRIM(cl_RmsDiffFicOut),&
       il_nbdim,&
       cla_dimname,&
       ila_dimlen)

  CALL MIOL_openw_file_NC(TRIM(cl_RmsDiffFicOut), il_file_id)  
  CALL MIOL_write_field_NC (il_file_id,&
       'mean',&
       'XYZ',&
       rga_moy)
 CALL MIOL_write_field_NC (TRIM(cl_RmsDiffFicOut),&
       'indice',&
       'XYZ',&
       iga_NbVal)

  CALL MIOL_write_field_NC (TRIM(cl_RmsDiffFicOut),&
       'rms',&
       'XYZ',&
       rga_rms  )

  CALL MIOL_write_field_NC (TRIM(cl_RmsDiffFicOut),&
       'rms_diff',&
       'XYZ',&
       rga_rms_diff  )

  CALL MIOL_write_field_NC (TRIM(cl_RmsDiffFicOut),&
       'mean_diff',&
       'XYZ',&
       rga_moy_diff)

  CALL MIOL_write_field_NC (TRIM(cl_RmsDiffFicOut),&
       'box',&
       'X',&
       rga_valeur1)
  CALL MIOL_close_file_NC(il_file_id)

  !** ecriture en ASCII des resultats
  !   ------------------------------
  CALL MIOL_getFreeLu(il_ficStatBoite)
  OPEN(il_ficStatBoite, file=TRIM(cg_FicStatBoite), &
       status='old', &
       form='formatted', &
       iostat=il_status)
  DO il_r=1,ig_nbregion
     !IF (iga_NbProfRejetBathyBoite(il_r) .NE. 0 ) THEN
     !   WRITE(16,*)rga_valeur1(il_r),iga_NbProfRejetBathyBoite(il_r)
     !ENDIF
     DO il_s=3,ig_ParamStat
        IF ( MAXVAL(iga_NbVal(il_r,il_s,:)) > 0 ) THEN
           WRITE(il_ficStatBoite,'(I6,a12)',advance="no")INT(rga_valeur1(il_r)),TRIM(cga_param(iga_IndParamStat(il_s)))
           DO il_i=1,ig_NbDepthDef
              WRITE(il_ficStatBoite,'(i9,2f16.3)',advance="no")iga_NbVal(il_r,il_s,il_i),&
                   & rga_moy_diff(il_r,il_s,il_i),rga_rms_diff(il_r,il_s,il_i)
           ENDDO ! il_s=1,ig_ParamStat
           il_i=ig_NbDepthDef+1
           WRITE(il_ficStatBoite,'(i9,2f16.3)',advance="yes")iga_NbVal(il_r,il_s,il_i),&
                & rga_moy_diff(il_r,il_s,il_i),rga_rms_diff(il_r,il_s,il_i)
        ENDIF
     ENDDO ! il_s=1,ig_ParamStat
  ENDDO ! il_r=1,ig_nbregion
  CLOSE(il_ficStatBoite)

   IF ( cl_input4 /= '' ) THEN
      cl_MeanDiffFicOut=TRIM(cl_input3)//TRIM(cl_input2)//'_mean_diff_loc_R'//TRIM(cl_input4)//'.nc'
   ELSE
      cl_MeanDiffFicOut=TRIM(cl_input3)//TRIM(cl_input2)//'_mean_diff_loc_'//TRIM(cl_input)//'.nc'
   ENDIF

  PRINT *,TRIM(cl_MeanDiffFicOut)
  il_nbdim=3                                                          
  IF ( ALLOCATED(cla_dimname)) DEALLOCATE(cla_dimname)
  ALLOCATE(cla_dimname(il_nbdim)) !ig_nbregion,ig_ParamStat-3,ig_NbDepthDef+1))
  IF ( ALLOCATED(ila_dimlen)) DEALLOCATE(ila_dimlen)
  ALLOCATE(ila_dimlen(il_nbdim))

  cla_dimname(1) = 'x'
  cla_dimname(2)=  'y'
  cla_dimname(3)=  'z'
  ila_dimlen(1) = ig_ParamStat
  ila_dimlen(2) = ig_NbDepthDef+1
  ila_dimlen(3) = ig_nbproftot
  CALL MIOL_create_file_NC(TRIM(cl_MeanDiffFicOut),&
       il_nbdim,&
       cla_dimname,&
       ila_dimlen)

  CALL MIOL_openw_file_NC(TRIM(cl_MeanDiffFicOut), il_file_id)  
  CALL MIOL_write_field_NC (TRIM(cl_MeanDiffFicOut),&
       'mean_diff',&
       'XYZ',&
       rga_diff_loc2)
  CALL MIOL_close_file_NC(il_file_id)

  !** desallocation des tableaux de diag class4
  CALL fermer_table_class4(il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Error in fermer_table_class4'
     CALL flush(0)
     STOP
  ENDIF

  !** Fermeture du fichier LOG et SYNTH
  CLOSE(il_ficlog)
  CLOSE(il_ficsynth)


  !** Desallocation tableaux CORIOLIS
  IF ( ALLOCATED (cla_inputFile) ) DEALLOCATE (cla_inputFile)


  write(*,*)'FIN DU PROGRAMME'

END PROGRAM Lecture_class4

