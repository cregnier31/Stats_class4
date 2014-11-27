PROGRAM LireListe_Class4
  !
  !**** LireListe_Class4
  !
  !     Purpose :
  !     Lecture des fichiers argo class4 
  !
  !***  Method  :    Step 1
  !                  Lectures des fichiers
  !                  Step 2
  !                  
  !     Externals : MIOL_getFreeLu
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
  !       1.0       F. HERNANDEZ   17/04/2008    created
  !       1.1       
  !       1.2       
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
  USE READ_ARGO
  USE table_ARGO
  USE BOITE
  USE table_boite
  USE table_class4
  USE BATHY
  USE table_bathy
  !
  !** ++  Local Declarations 
  !
  IMPLICIT NONE
  INTEGER(KIND=4)                               :: il_i,il_ji,il_nbfile,il_status,il_stat,il_ib
  INTEGER(KIND=4)                               :: il_nbdim, il_ficliste,il_file_id,il_narg,iargc,il_proftot
  INTEGER(KIND=4)  ,DIMENSION(:),ALLOCATABLE    :: ila_dimlen
  CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE   :: cla_inputFile,cla_dimname
  CHARACTER(LEN=255)                            :: cd_commandFile,PATH,cl_tmp
  CHARACTER(LEN=255)                            :: cd_LogFile,cd_SynthFile
  INTEGER(kind=4)                               :: il_ficlog,il_ficsynth
  CHARACTER(LEN=255)                            :: cl_bathyfile, cl_bathytype
  REAL(KIND=4), DIMENSION(:),POINTER            :: rlpa_lon,rlpa_lat
  REAL(KIND=8), DIMENSION(:,:,:),ALLOCATABLE    :: rga_diff_loc2
  CHARACTER(LEN=80)           :: cl_filen1,cl_filen3,cl_filen4
  CHARACTER(LEN=255)                            :: cl_input,cl_input2,cl_choix
  INTEGER(kind=4)                               :: il_DepthDefFile
  LOGICAL                                       :: ll_DepthDefFile
  REAL(KIND=8) :: rl_pour
  !
  !*-------------------------------------------------------------
  !
  !** LECTURE DES ARGUMENTS
  il_narg=iargc()
  ! recup nom de la nameliste
  CALL getarg(1,cd_commandFile)
  ! recup du jour min.
  CALL getarg(2,cl_input)
  ! recup type de modele
  CALL getarg(3,cl_input2)
  cl_choix='non'

  !** LECTURE DE LA NAMELIST
  ! Definition de la structure de l entete
  NAMELIST / lireliste_corio / il_nbfile , PATH , cd_LogFile, cl_bathyfile, cl_bathytype 
  ! OUverture du fichier de nameliste  
  CALL MIOL_getFreeLu(il_ficliste)
  OPEN(il_ficliste, file=TRIM(cd_commandFile), &
       status='old', &
       form='formatted', &
       iostat=il_status)
  ! Lecture de l entete
  READ(il_ficliste,lireliste_corio)
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
  CALL LireDefBoite (FP_BoxDefFile,il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Box Def file reading error ',FP_BoxDefFile
     CALL flush(0)
     STOP
  ENDIF

  !** Ouverture du fichier LOG
  CALL MIOL_getFreeLu(il_ficlog)
  PRINT *,'fichier log: ',TRIM(cd_LogFile)
  OPEN(unit=il_ficlog,file=TRIM(cd_LogFile),form='FORMATTED',ACCESS='SEQUENTIAL',STATUS='REPLACE')

  !** Boucle de lecture des fichiers CORIOLIS
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'---------- Lecture Liste fichiers Class 4 ------------'
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a,a)')'Input File Directory : ',TRIM(PATH)
  WRITE(il_ficlog,'(a)')' '

  !** Definition des classes de profondeurs: lecture du fichier de classes de profondeur
  ll_DepthDefFile = .FALSE.
  INQUIRE(FILE=FP_DepthDefFile,EXIST=ll_DepthDefFile)
  IF ( ll_DepthDefFile ) THEN
     WRITE(il_ficlog,'(a,a)') 'TRI des profils par PROFONDEUR ',TRIM(FP_DepthDefFile)

     !** Ouverture du fichier de classes de profondeurs
     CALL MIOL_getFreeLu(il_DepthDefFile)
     OPEN (unit=il_DepthDefFile,file=FP_DepthDefFile,status='old',form='formatted',&
          & iostat=il_status,action='read')  
     IF ( il_status /= 0 ) THEN
        WRITE(0,'(a,a)')'Cannot open Depth file ',TRIM(FP_DepthDefFile)
        CLOSE(il_DepthDefFile)
        CALL flush(0)
        STOP
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
     rga_DepthMin(ig_NbDepthDef+1)=rg_DepthMin0
     rga_DepthMax(ig_NbDepthDef+1)=rg_DepthMax0
  ELSE
     WRITE(il_ficlog,'(a)') 'PAS de TRI des profils par PROFONDEUR'
     ig_NbDepthDef = 0
     IF ( ALLOCATED(rga_DepthMin)) DEALLOCATE (rga_DepthMin)
     ALLOCATE ( rga_DepthMin (ig_NbDepthDef+1) )
     IF ( ALLOCATED(rga_DepthMax)) DEALLOCATE (rga_DepthMax)
     ALLOCATE ( rga_DepthMax (ig_NbDepthDef+1) )
     rga_DepthMin(ig_NbDepthDef+1)=rg_DepthMin0
     rga_DepthMax(ig_NbDepthDef+1)=rg_DepthMax0
  ENDIF

  !** On ecrit les classes de profondeur dans le fichier log 
  WRITE(il_ficlog,'(a,i6)') 'Nb. classe de profondeur utilisees: ',ig_NbDepthDef 
  DO il_ib = 1 , ig_NbDepthDef+1
     WRITE(il_ficlog,*)rga_DepthMin(il_ib),rga_DepthMax(il_ib)
     print *,'Prof ::',rga_DepthMin(il_ib),rga_DepthMax(il_ib)
  ENDDO

  !** Gestion de la bathymetrie
  ! definition du nom et type de fichier bathy
  cg_BathyFile = cl_bathyfile
  if ( TRIM(cl_bathytype) == 'CLS' ) ig_BathyType = 1
  ! lecture du fichier bathy (bathy.f90)
  call ChargerBathy (il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Bathy file reading error ',trim(cg_BathyFile)
     CALL flush(0)
     STOP
  ENDIF
  ! Ecriture en Log
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a,a)')'Bathy File :',TRIM(cg_BathyFile)
  WRITE(il_ficlog,'(a,a)')'Bathy Type :',TRIM(cl_bathytype)


  !** Definition des parametres traites
  ig_ParamStat = 22
  ALLOCATE(iga_IndParamStat(ig_ParamStat))
  iga_IndParamStat(1)=ip_TEMP
  iga_IndParamStat(2)=ip_PSAL
  iga_IndParamStat(3)=ip_HDCST_TEMP
  iga_IndParamStat(4)=ip_HDCST_PSAL
  iga_IndParamStat(5)=ip_ANA_TEMP
  iga_IndParamStat(6)=ip_ANA_PSAL
  iga_IndParamStat(7)=ip_FRCST3D_TEMP
  iga_IndParamStat(8)=ip_FRCST3D_PSAL
  iga_IndParamStat(9)=ip_FRCST6D_TEMP
  iga_IndParamStat(10)=ip_FRCST6D_PSAL
  iga_IndParamStat(11)=ip_PERS3D_TEMP
  iga_IndParamStat(12)=ip_PERS3D_PSAL
  iga_IndParamStat(13)=ip_PERS6D_TEMP
  iga_IndParamStat(14)=ip_PERS6D_PSAL
  iga_IndParamStat(15)=ip_FSTGS_TEMP
  iga_IndParamStat(16)=ip_FSTGS_PSAL
  iga_IndParamStat(17)=ip_TMLEV
  iga_IndParamStat(18)=ip_SMLEV
  iga_IndParamStat(19)=ip_TMMED
  iga_IndParamStat(20)=ip_SMMED
  iga_IndParamStat(21)=ip_TMBAL
  iga_IndParamStat(22)=ip_SMBAL


  !** Definition et initialisation des tableaux de stat 
  ALLOCATE(iga_NbProfTempBoite(ig_nbregion))
  iga_NbProfTempBoite(:)=0
  ALLOCATE(iga_NbProfPsalBoite(ig_nbregion))
  iga_NbProfPsalBoite(:)=0
  ALLOCATE(iga_NbVal(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
  iga_NbVal(:,:,:) = 0
  ALLOCATE(rga_moy(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
  rga_moy(:,:,:) = 0.
  ALLOCATE(rga_rms(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
  rga_rms(:,:,:) = 0.
  ALLOCATE(rga_moy_diff(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
  rga_moy_diff(:,:,:) = 0.
  ALLOCATE(rga_rms_diff(ig_nbregion,ig_ParamStat,ig_NbDepthDef+1))
  rga_rms_diff(:,:,:) = 0.
  il_proftot=il_nbfile*1000 ! 1000 chiffre empirique indiquant le nombre max moyen de profils par fichier
  ALLOCATE(rga_diff_loc(ig_ParamStat,ig_NbDepthDef+1,il_proftot))
  rga_diff_loc(:,:,:)=9999.
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'


  !** Coriolis Input file loop :: Boucle sur les fichiers enrichis
  DO il_ji=1,il_nbfile
     PRINT *,'Inputfile',cla_inputFile(il_ji)
     !** Lecture du contenu du fichier CORIOLIS, fonction read_profile
     !   (lecture des profils du fichier)
     CALL read_profile(cla_inputFile(il_ji),il_ficlog,il_stat)
     WRITE(il_ficlog,'(a,i3,1x,a,i5)')'Fin de lecture du fichier, stat=',&
          &il_stat,'Levels=',ig_nlevels

     !** Tri des profils pour garder les profils valides :: fonction valid_profile
     IF ( il_stat >= 0 ) THEN 

        CALL valid_profile(il_ficlog,il_ficsynth,il_stat)

        WRITE(il_ficlog,'(3(a,i5))')'NB PROFIL :',ig_nprof,' T Valid:',&
             & COUNT(iga_MesTempVal(:) > 0),&
             & ' S valid :',COUNT(iga_MesPsalVal(:) > 0)
        ig_nbproftot=ig_nbproftot+ig_nprof
     ELSE
        WRITE(il_ficlog,'(a,a,a,i5)')'Pas de Valid et Tri sur :',TRIM(cla_inputFile(il_ji)),&
             & ' il_stat=',il_stat
     ENDIF
     CALL  fermer_table_argo(il_stat)
     WRITE (il_ficlog,'(a)'),'**************************************************'
  ENDDO ! end loop on Coriolis files : il_ji=1,il_nbfile

  !** Close bathy
  call FermerBathy (il_status)
  IF ( il_status /= 0 ) THEN
     WRITE(0,*) 'Bathy data closing error '
     CALL flush(0)
     STOP
  ENDIF
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'De-Allocage Bathy data'

  ALLOCATE(rga_diff_loc2(ig_ParamStat,ig_NbDepthDef+1,ig_nbproftot))
  PRINT*,'TAILLE :',size(rga_diff_loc2(1,1,:)),size(rga_diff_loc2(1,:,1)),size(rga_diff_loc2(:,1,1))

  rga_diff_loc2=rga_diff_loc(:,:,1:ig_nbproftot)
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')' FIN de la lecture des fichiers Class 4'
  WRITE(il_ficlog,'(a)')' '
  WRITE(il_ficlog,'(a)')'----------------------------------------------------'


  CLOSE(il_ficlog)
  !** Creation du fichier de sortie
  print *,' ---------Creation du fichier de sortie-------------------------------'

  cl_filen3='/home/cregnier/STATS/'//TRIM(cl_input2)//'_rms_diff_'//TRIM(cl_input)//'.nc'
  il_nbdim=3
  ALLOCATE(cla_dimname(il_nbdim))!ig_nbregion,ig_ParamStat-3,ig_NbDepthDef+1))
  ALLOCATE(ila_dimlen(il_nbdim))

  cla_dimname(1) = 'x'
  cla_dimname(2)=  'y'
  cla_dimname(3)=  'z'
  ila_dimlen(1) = ig_nbregion
  ila_dimlen(2) = ig_ParamStat
  ila_dimlen(3) = ig_NbDepthDef+1
  call MIOL_create_file_NC(TRIM(cl_filen3),&
       il_nbdim,&
       cla_dimname,&
       ila_dimlen)

  call MIOL_openw_file_NC(TRIM(cl_filen3), il_file_id)  

  call MIOL_write_field_NC (TRIM(cl_filen3),&
       'mean',&
       'XYZ',&
       rga_moy)
   call MIOL_write_field_NC (TRIM(cl_filen3),&
       'indice',&
       'XYZ',&
       iga_NbVal)

  call MIOL_write_field_NC (TRIM(cl_filen3),&
       'rms',&
       'XYZ',&
       rga_rms  )

  call MIOL_write_field_NC (TRIM(cl_filen3),&
       'rms_diff',&
       'XYZ',&
       rga_rms_diff  )
  
  call MIOL_write_field_NC (TRIM(cl_filen3),&
       'mean_diff',&
       'XYZ',&
       rga_moy_diff)
 
  call MIOL_write_field_NC (TRIM(cl_filen3),&
       'box',&
       'X',&
       rga_valeur1)
  
  CALL MIOL_close_file_NC(il_file_id)
  PRINT *, 'Fichier 1 ok'
  PRINT*,'TAILLE fic 1:',size(rga_moy_diff(:,1,1)),size(rga_moy_diff(1,:,1)),size(rga_moy_diff(1,1,:))
  PRINT*,'x y z',ig_nbregion,ig_ParamStat,ig_NbDepthDef+1
  cl_filen4='/home/cregnier/STATS/'//TRIM(cl_input2)//'_mean_diff_loc_'//TRIM(cl_input)//'.nc'
  print *,'cl_file4',cl_filen4
 il_nbdim=3                                                          
  IF ( ALLOCATED(cla_dimname)) DEALLOCATE(cla_dimname)
  ALLOCATE(cla_dimname(il_nbdim))!ig_nbregion,ig_ParamStat-3,ig_NbDepthDef+1))
  IF ( ALLOCATED(ila_dimlen)) DEALLOCATE(ila_dimlen)
  ALLOCATE(ila_dimlen(il_nbdim))

  cla_dimname(1) = 'x'
  cla_dimname(2)=  'y'
  cla_dimname(3)=  'z'
  ila_dimlen(1) = ig_ParamStat
  ila_dimlen(2) = ig_NbDepthDef+1
  ila_dimlen(3) = ig_nbproftot
  PRINT*,'TAILLE :',size(rga_diff_loc2(:,1,1)),size(rga_diff_loc2(1,:,1)),size(rga_diff_loc2(1,1,:))
  PRINT*,'TAILLE :',ig_ParamStat,ig_NbDepthDef+1,ig_nbproftot
  call MIOL_create_file_NC(TRIM(cl_filen4),&
       il_nbdim,&
       cla_dimname,&
       ila_dimlen)

  call MIOL_openw_file_NC(TRIM(cl_filen4), il_file_id)  
  call MIOL_write_field_NC (TRIM(cl_filen4),&
       'mean_diff',&
       'XYZ',&
       rga_diff_loc2)
 CALL MIOL_close_file_NC(il_file_id)
  PRINT *, 'Fichier 2 ok'

!** Stat sur les fichiers traités
!rl_pour=(REAL(ig_total_nok)/REAL(ig_total_nok+ig_total_ok))
!PRINT *,'Valeurs ok et nok ::', ig_total_ok,ig_total_nok
!PRINT *,'rl_pour::',rl_pour
!rl_pour=rl_pour*100
!PRINT *,'rl_pour::',rl_pour


  !** Desallocation
  IF ( ALLOCATED (cla_inputFile) ) DEALLOCATE (cla_inputFile)
  IF ( ALLOCATED(rga_DepthMin)) DEALLOCATE (rga_DepthMin)
  IF ( ALLOCATED(rga_DepthMax)) DEALLOCATE (rga_DepthMax)
  IF ( ALLOCATED (iga_IndParamStat) ) DEALLOCATE (iga_IndParamStat)
  IF ( ALLOCATED (iga_NbProfTempBoite) ) DEALLOCATE (iga_NbProfTempBoite)
  IF ( ALLOCATED (iga_NbProfPsalBoite) ) DEALLOCATE (iga_NbProfPsalBoite)
  IF ( ALLOCATED (iga_NbVal) ) DEALLOCATE (iga_NbVal)
  IF ( ALLOCATED (rga_moy) ) DEALLOCATE (rga_moy)
  IF ( ALLOCATED (rga_rms) ) DEALLOCATE (rga_rms)
  IF ( ALLOCATED (rga_moy_diff) ) DEALLOCATE (rga_moy_diff)
  IF ( ALLOCATED (rga_rms_diff) ) DEALLOCATE (rga_rms_diff)

  PRINT*,'FIN DU PROGRAMME'

END PROGRAM LireListe_Class4

