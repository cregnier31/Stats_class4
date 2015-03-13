!---------------------------------------------------------------------------------------
!
!                          ---   MODULE CLASS 4  --- 
!
!---------------------------------------------------------------------------------------

! Auteur: FHZ Sept 2007
! Ceci est le module des variables globales du module Lecture_class4

MODULE table_class4
  
  ! Repertoire log
  CHARACTER(len=255) :: cg_ficlog
  ! Modele 
  CHARACTER(len=30)  :: cg_modele
  ! Date de run
  CHARACTER(len=30)  :: cg_rundate
  ! Fichier boite par defaut
  CHARACTER(LEN=255),PARAMETER :: FP_BoxDefFile='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../utils/File_boxes.txt'

  ! Fichier par defaut des classes de profondeur
  CHARACTER(LEN=255),PARAMETER  :: FP_DepthDefFile ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../utils/fic_tri_prof.in'
  CHARACTER(LEN=255),PARAMETER  :: FP_Deptht ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../utils/deptht.in'
  CHARACTER(LEN=255),PARAMETER  :: FP_E3t ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../utils/e3t_0.in'
  CHARACTER(LEN=255),PARAMETER  :: FP_ParamNameFile ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../utils/param_names.in'
  ! Existence du fichier classe de profondeur
  LOGICAL  :: lg_DepthDefFile,lg_ParamFile

  ! Nombre de classes de profondeur
  INTEGER(kind=4) :: ig_NbDepthDef
  ! Tableau des classes de profondeur
  REAL(kind=4),DIMENSION(:), ALLOCATABLE :: rga_DepthMin,rga_DepthMax
  ! Profondeur par defaut en l absence de classes de profondeurs
  REAL(kind=4) :: rg_DepthMin0=0. , rg_DepthMax0=500.

  ! Seuil bathy pour les donnees
  REAL(kind=4) :: rg_BathySeuil
  ! Nombre de profils rejetes pour bathy par boite
  INTEGER, DIMENSION(:), ALLOCATABLE :: iga_NbProfRejetBathyBoite

  ! Nom par defaut du fichier log des profils rejet bathy
  CHARACTER(len=255) :: cg_FicRejetBathy ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/RejetProfilBathy.txt'
  ! Nom par defaut du fichier ASCII de sortie des stats par boite
  CHARACTER(len=255) :: cg_FicStatBoite ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/ResultStatBoite.txt'
  ! Nom par defaut du fichier ASCII de sortie des differences d ecart T
  ! superieure au seuil
  CHARACTER(len=255) :: cg_FicDiffTEMP ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/ResultAnoTEMP.txt'
  CHARACTER(len=255) :: cg_FicDiffTEMP_2 ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/Bad_points_TEMP_CORIO.txt'
  ! Nom par defaut du fichier ASCII de sortie des differences d ecart S
  ! superieure au seuil
  CHARACTER(len=255) :: cg_FicDiffPSAL ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/ResultAnoPSAL.txt'
  CHARACTER(len=255) :: cg_FicDiffPSAL_2 ='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/Bad_points_PSAL_CORIO.txt'
  CHARACTER(len=255) :: cg_file,cg_log='/home/cregnier/SVN/mo/TEP_CLASS4_V3/postraitement/src/../exe/pb_profils.txt'
  ! Ecart max pour les anomalies calculees en Temp et Sal:
  REAL(KIND=4) :: rg_EcartTempMax,rg_EcartSalMax

  ! Nombre de parametres traites
  INTEGER(kind=4) :: ig_ParamStat,ig_indi,ig_nbproftot

  ! Nombre de fichiers traites
  INTEGER(kind=4) :: ig_FicLus

  ! Indice de choix des parametres traites
  INTEGER(kind=4),DIMENSION(:), ALLOCATABLE :: iga_IndParamStat

  ! Nombre de profil valide (T et S) par boite
  INTEGER, DIMENSION(:), ALLOCATABLE :: iga_NbProfTempBoite,iga_NbProfPsalBoite

  ! Nombre de points rejetes par classe de profondeur et par parametre traite
  ! si les differences en TEMP ou SAL depassent les seuils 
  ! rg_EcartTempMax ou rg_EcartSalMax
  INTEGER(KIND=4),DIMENSION(:,:),ALLOCATABLE  :: ig_StatOK,ig_StatNOK


  ! RESULTATS statistiques Class 4 par classe de profondeurs par boite
  INTEGER, DIMENSION(:,:,:), ALLOCATABLE :: iga_NbVal
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_moy,rga_rms
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_moy_diff,rga_rms_diff
  ! RESULTATS statistiques par classe de profondeur pour chaque profil
  INTEGER, DIMENSION(:,:,:), ALLOCATABLE :: iga_NbValProf
  INTEGER,PARAMETER :: IP_NbStat = 4
  REAL(kind=8), DIMENSION(:,:,:,:), ALLOCATABLE :: rga_StatProf 
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_diff_loc 

  !! VERRUE: statistiques d ecart entre les deux formulations de
  !! temperature potentielle
  !REAL(kind=8), DIMENSION(:), ALLOCATABLE :: rga_DiffTetaProf,rga_DiffTetaProf2
  !INTEGER, DIMENSION(:), ALLOCATABLE :: iga_NbDiffTetaProf
  

END MODULE table_class4
