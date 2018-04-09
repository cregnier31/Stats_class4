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
  CHARACTER(LEN=255),PARAMETER :: FP_BoxDefFile='File_boxes.txt'

  ! Fichier par defaut des classes de profondeur
  CHARACTER(LEN=255),PARAMETER  :: FP_DepthDefFile ='fic_tri_prof.in'
  CHARACTER(LEN=255),PARAMETER  :: FP_Deptht ='deptht.in'
  CHARACTER(LEN=255),PARAMETER  :: FP_E3t ='e3t_0.in'
  CHARACTER(LEN=255),PARAMETER  :: FP_ParamNameFile ='param_names_'
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
  CHARACTER(len=255) :: cg_FicRejetBathy ='RejetProfilBathy.txt'
  ! Nom par defaut du fichier ASCII de sortie des stats par boite
  CHARACTER(len=255) :: cg_FicStatBoite ='ResultStatBoite.txt'
  ! Nom par defaut du fichier ASCII de sortie des differences d ecart T
  ! superieure au seuil
  CHARACTER(len=255) :: cg_FicDiffTEMP ='ResultAnoTEMP.txt'
  CHARACTER(len=255) :: cg_FicDiffTEMP_2 ='Bad_points_TEMP_CORIO.txt'
  ! Nom par defaut du fichier ASCII de sortie des differences d ecart S
  ! superieure au seuil
  CHARACTER(len=255) :: cg_FicDiffPSAL ='ResultAnoPSAL.txt'
  CHARACTER(len=255) :: cg_FicDiffPSAL_2 ='Bad_points_PSAL_CORIO.txt'
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
  INTEGER, DIMENSION(:,:), ALLOCATABLE   :: iga_NbVal2D_mod,iga_NbVal2D_mod_MLP
  INTEGER, DIMENSION(:,:), ALLOCATABLE   :: iga_NbVal2D_data,iga_NbVal2D_data_MLP
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_moy,rga_rms
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_moy_diff,rga_rms_diff
  REAL(kind=8), DIMENSION(:,:), ALLOCATABLE :: rga_moy_data,rga_moy_mod,rga_rms_mod,rga_rms_data
  REAL(kind=8), DIMENSION(:,:), ALLOCATABLE :: rga_moy_data_MLP,rga_moy_mod_MLP,rga_rms_mod_MLP,rga_rms_data_MLP
  REAL(kind=8), DIMENSION(:,:), ALLOCATABLE :: rga_moy_data_diff,rga_rms_data_diff,rga_moy_mod_diff, &
                                               rga_rms_mod_diff,rga_mld_mod,rga_mld_data,rga_diffmld,rga_error_MLD
  REAL(kind=8), DIMENSION(:,:), ALLOCATABLE :: rga_moy_data_diff_MLP,rga_rms_data_diff_MLP,rga_moy_mod_diff_MLP, &
                                               rga_rms_mod_diff_MLP,rga_mlp_mod,rga_mlp_data,rga_diffmlp,rga_error_MLP
  INTEGER(KIND=4),DIMENSION(:,:), ALLOCATABLE :: iga_mld_mod_cumul,iga_mld_data_cumul,iga_mld_diff_cumul  
  INTEGER(KIND=4),DIMENSION(:,:), ALLOCATABLE :: iga_mlp_mod_cumul,iga_mlp_data_cumul,iga_mlp_diff_cumul  

  ! RESULTATS statistiques par classe de profondeur pour chaque profil
  INTEGER, DIMENSION(:,:,:), ALLOCATABLE :: iga_NbValProf
  INTEGER,PARAMETER :: IP_NbStat = 4
  INTEGER,PARAMETER :: IP_NbStat2 = 8 
  REAL(kind=8), DIMENSION(:,:,:,:), ALLOCATABLE :: rga_StatProf 
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_diff_loc 

  !! VERRUE: statistiques d ecart entre les deux formulations de
  !! temperature potentielle
  !REAL(kind=8), DIMENSION(:), ALLOCATABLE :: rga_DiffTetaProf,rga_DiffTetaProf2
  !INTEGER, DIMENSION(:), ALLOCATABLE :: iga_NbDiffTetaProf
  

END MODULE table_class4
