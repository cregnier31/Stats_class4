MODULE table_ARGO
  !*======================================================================
  !                       ***  MODULE table_ARGO  ***
  !                Ce module definit des variables globales pour read ARGO
  !                                                                           *
  !                                                                           *
  !======================================================================
  !

  CHARACTER(len=30) :: cg_TEMP_badprof = 'ListeTEMPbadprof.txt'
  CHARACTER(len=30) :: cg_PSAL_badprof = 'ListePSALbadprof.txt'
  INTEGER,PARAMETER            :: IP_STRING2=2,IP_STRING4=4,IP_STRING8 = 8,IP_STRING16 = 16
  INTEGER,PARAMETER            :: IP_STRING32=32,IP_STRING64=64,IP_STRING256=256
  INTEGER,PARAMETER            :: IP_STRING1=1,IP_STRING12=12
  INTEGER(KIND=4),PARAMETER    :: ip_parameter=4

  INTEGER(KIND=4)              :: ig_nprof  ! nbre de profil (dimension) dans fichier NetCDF Coriolis
  INTEGER(KIND=4)              :: ig_nlevels ! nbre de profondeur (dimension) dans fichier NetCDF Coriolis

  INTEGER(KIND=4),PARAMETER    :: ip_ParamTot = 36
  INTEGER(KIND=4),PARAMETER    :: &
       &  ip_TEMP=1,&
       &  ip_PSAL=2,&
       &  ip_DEPH=3,&
       &  ip_PRES=4,&
       &  ip_HDCST_TEMP=5,&
       &  ip_HDCST_PSAL=6,&
       &  ip_ANA_TEMP=7,&
       &  ip_ANA_PSAL=8,&
       &  ip_FRCST1D_TEMP=9,&
       &  ip_FRCST1D_PSAL=10,&
       &  ip_FRCST3D_TEMP=11,&
       &  ip_FRCST3D_PSAL=12,&
       &  ip_FRCST5D_TEMP=13,&
       &  ip_FRCST5D_PSAL=14,&
       &  ip_FRCST6D_TEMP=15,&
       &  ip_FRCST6D_PSAL=16,&
       &  ip_PERS_TEMP=17,&
       &  ip_PERS_PSAL=18,&
       &  ip_PERS3D_TEMP=19,&
       &  ip_PERS3D_PSAL=20,&
       &  ip_PERS6D_TEMP=21,&
       &  ip_PERS6D_PSAL=22,&
       &  ip_TMLEV05=23,&
       &  ip_SMLEV05=24,&
       &  ip_TMMED=25,&
       &  ip_SMMED=26,&
       &  ip_TMARV=27,&
       &  ip_SMARV=28,&
       &  ip_TMLEV09=29,&
       &  ip_SMLEV09=30,&
       &  ip_TMARV11=31,&
       &  ip_SMARV11=32,&
       &  ip_TMLEV98=33,&
       &  ip_SMLEV98=34,&
       &  ip_TMLEV13=35,&
       &  ip_SMLEV13=36
        

 ! Liste des parametres usuels des fichiers CLASS 4
  CHARACTER(len=IP_STRING16),DIMENSION(ip_ParamTot) :: cga_param

  ! Tableau des parametres effectivement utilises dans un fichier CLASS4
  CHARACTER(len=IP_STRING16),DIMENSION(:),ALLOCATABLE :: cga_param_use

  ! Nombre effectif de parametres dans le fichier
  INTEGER(KIND=4)              :: ig_param_use

  ! tableau des correspondances d indices
  ! des parametres pour chaque profil
  INTEGER(KIND=4),DIMENSION(:,:),ALLOCATABLE         :: iga_IndParam
  ! tableau logique 2D des parametres presents pour le profil

  CHARACTER(len=IP_STRING16),DIMENSION(:,:,:),POINTER  :: cgpa_STATION_PARAMETERS
  CHARACTER(len=IP_STRING16),DIMENSION(:,:,:,:),POINTER  :: cgpa_STATION_PARAMETERS2
  CHARACTER(len=IP_STRING1),DIMENSION(:,:),POINTER   :: cgpa_TEMP_QC,cgpa_TEMP_ADJUSTED_QC
  CHARACTER(len=IP_STRING1),DIMENSION(:,:),POINTER   :: cgpa_PRES_QC,cgpa_PRES_ADJUSTED_QC
  CHARACTER(len=IP_STRING1),DIMENSION(:,:),POINTER   :: cgpa_DEPH_QC,cgpa_DEPH_ADJUSTED_QC
  CHARACTER(len=IP_STRING1),DIMENSION(:,:),POINTER   :: cgpa_PSAL_QC,cgpa_PSAL_ADJUSTED_QC
  CHARACTER(len=IP_STRING1), DIMENSION(:,:), POINTER  :: cgpa_PARAMETERINT
 
  CHARACTER(len=12), DIMENSION(:),ALLOCATABLE       :: cga_PARAMETERINT
 

  CHARACTER(len=IP_STRING8),DIMENSION(:,:),POINTER     :: cgpa_PLATFORM_NUMBER
  CHARACTER(len=IP_STRING4),DIMENSION(:,:),POINTER     :: cgpa_DATA_STATE_INDICATOR
  LOGICAL :: lg_DATA_STATE_INDICATOR,lg_DEPH,lg_PRES,lg_PSAL,lg_PERS3D_TEMP,lg_PERS3D_PSAL,lg_PERS6D_TEMP,lg_PERS6D_PSAL,&
             lg_PERS_TEMP,lg_PERS_PSAL,lg_SMLEV05,lg_SMLEV98,lg_SMLEV09,lg_TMLEV05,lg_TMLEV98,lg_TMLEV09,lg_PLAT,&
             lg_STATION_PARAMETERS,lg_INST_REFERENCE,lg_WMO_INST_TYPE,lg_JULD_QC,lg_POSITION_QC,lg_TEMP,&
             lg_DATA_MODE,lg_LON,lg_LAT,lg_JULD,lg_HDCT_TEMP,lg_HDCT_PSAL,lg_ANA_TEMP,lg_ANA_PSAL,&
             lg_FCST1D_TEMP,lg_FCST1D_PSAL,lg_FCST3D_TEMP,lg_FCST3D_PSAL,lg_FCST5D_TEMP,lg_FCST5D_PSAL,&
             lg_FCST6D_TEMP,lg_FCST6D_PSAL,lg_SMARV,lg_TMARV,lg_SMARV11,lg_TMARV11,lg_TMMED,lg_SMMED,lg_TMLEV13,lg_SMLEV13
  CHARACTER(len=IP_STRING64),DIMENSION(:,:),POINTER    :: cgpa_INST_REFERENCE
  CHARACTER(len=IP_STRING4),DIMENSION(:,:),POINTER     :: cgpa_WMO_INST_TYPE

  CHARACTER(len=IP_STRING1),DIMENSION(:),POINTER     :: cgpa_POSITION_QC,cgpa_JULD_QC,cgpa_DATA_MODE


  CHARACTER(LEN=255)     :: cg_lon='LONGITUDE',cg_lat='LATITUDE',cg_station='STATION_PARAMETERS'
  CHARACTER(LEN=255)     :: cg_plateform='PLATFORM_NUMBER',cg_data_state='DATA_STATE_INDICATOR'
  CHARACTER(LEN=255)     :: cg_inst_reference='INST_REFERENCE',cg_wmo_inst_type='WMO_INST_TYPE'
  CHARACTER(LEN=255)     :: cg_juld='JULD',cg_juld_qc='JULD_QC',cg_position_qc='POSITION_QC'
  CHARACTER(LEN=255)     :: cg_data_mode='DATA_MODE'  
  CHARACTER(LEN=255)     :: cg_stationCLASS4='PARAMETERINT',cg_stationCLASS4_ARMOR='PARAMETERINT2'
  CHARACTER(LEN=255)     :: cg_deph='DEPH',cg_deph_qc='DEPH_QC',cg_deph_adjusted='DEPH_ADJUSTED'
  CHARACTER(LEN=255)     :: cg_deph_adjusted_qc='DEPH_ADJUSTED_QC',cg_deph_adjusted_error='DEPH_ADJUSTED_ERROR'
  CHARACTER(LEN=255)     :: cg_pres='PRES',cg_pres_qc='PRES_QC',cg_pres_adjusted='PRES_ADJUSTED'
  CHARACTER(LEN=255)     :: cg_pres_adjusted_qc='PRES_ADJUSTED_QC',cg_pres_adjusted_error='PRES_ADJUSTED_ERROR'
  CHARACTER(LEN=255)     :: cg_temp='TEMP',cg_temp_qc='TEMP_QC',cg_temp_adjusted='TEMP_ADJUSTED'
  CHARACTER(LEN=255)     :: cg_temp_adjusted_qc='TEMP_ADJUSTED_QC',cg_temp_adjusted_error='TEMP_ADJUSTED_ERROR'
  CHARACTER(LEN=255)     :: cg_psal='PSAL', cg_psal_qc='PSAL_QC',cg_psal_adjusted='PSAL_ADJUSTED'
  CHARACTER(LEN=255)     :: cg_psal_adjusted_qc='PSAL_ADJUSTED_QC',cg_psal_adjusted_error='PSAL_ADJUSTED_ERROR'
  CHARACTER(LEN=255)                                 :: cl_HDCST_TEMP='HDCST_TEMP',cl_HDCST_PSAL='HDCST_PSAL'
  CHARACTER(LEN=255)                                 :: cl_ANA_TEMP='ANA_TEMP',cl_ANA_PSAL='ANA_PSAL'                   
  CHARACTER(LEN=255)                                 :: cl_FRCST1D_TEMP='FRCST1D_TEMP',cl_FRCST1D_PSAL='FRCST1D_PSAL'
  CHARACTER(LEN=255)                                 :: cl_FRCST3D_TEMP='FRCST3D_TEMP',cl_FRCST3D_PSAL='FRCST3D_PSAL'
  CHARACTER(LEN=255)                                 :: cl_FRCST5D_TEMP='FRCST5D_TEMP',cl_FRCST5D_PSAL='FRCST5D_PSAL'
  CHARACTER(LEN=255)                                 :: cl_FRCST6D_TEMP='FRCST6D_TEMP',cl_FRCST6D_PSAL='FRCST6D_PSAL'
  CHARACTER(LEN=255)                                 :: cl_PERS3D_TEMP='PERS3D_TEMP',cl_PERS3D_PSAL='PERS3D_PSAL'
  CHARACTER(LEN=255)                                 :: cl_PERS6D_TEMP='PERS6D_TEMP',cl_PERS6D_PSAL='PERS6D_PSAL'
  CHARACTER(LEN=255)                                 :: cl_TMLEV05='TMLEV05',cl_SMLEV05='SMLEV05', cl_TMMED='TMMED',cl_TMLEV98='TMLEV98',cl_SMLEV98='SMLEV98'
  CHARACTER(LEN=255)                                 :: cl_SMMED='SMMED', cl_TMARV='TMARV', cl_SMARV='SMARV', cl_TMARV11='TMARV11', cl_SMARV11='SMARV11'
  CHARACTER(LEN=255)                                 :: cl_PERS_TEMP='PERS_TEMP',cl_PERS_PSAL='PERS_PSAL'
  CHARACTER(LEN=255)                                 :: cl_TMLEV09='TMLEV09',cl_SMLEV09='SMLEV09',cl_TMLEV13='TMLEV13',cl_SMLEV13='SMLEV13'
  CHARACTER(LEN=255)                                 :: cg_filename
  CHARACTER(LEN=255), DIMENSION(:), POINTER          :: clpa_dimname

  REAL(KIND=8),DIMENSION(:),POINTER                  :: dgpa_JULD,dgpa_LONGITUDE,dgpa_LATITUDE
  REAL(KIND=8)                                       :: rgp_missvalue
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_TEMP,rgpa_TEMP_ADJUSTED,rgpa_TEMP_ADJUSTED_ERROR
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_PRES,rgpa_PRES_ADJUSTED,rgpa_PRES_ADJUSTED_ERROR
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_PSAL,rgpa_PSAL_ADJUSTED,rgpa_PSAL_ADJUSTED_ERROR
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_DEPH,rgpa_DEPH_ADJUSTED,rgpa_DEPH_ADJUSTED_ERROR

  ! Class 4
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_HDCST_TEMP,rgpa_HDCST_PSAL,rgpa_ANA_TEMP,rgpa_ANA_PSAL
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_FRCST1D_TEMP,rgpa_FRCST1D_PSAL,rgpa_FRCST3D_TEMP,rgpa_FRCST3D_PSAL
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_FRCST5D_TEMP,rgpa_FRCST5D_PSAL,rgpa_FRCST6D_TEMP,rgpa_FRCST6D_PSAL
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_PERS3D_TEMP,rgpa_PERS3D_PSAL,rgpa_PERS6D_TEMP,rgpa_PERS6D_PSAL
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_PERS_TEMP,rgpa_PERS_PSAL,rgpa_TMLEV98,rgpa_SMLEV98
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_TMLEV05,rgpa_SMLEV05,rgpa_TMMED
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_SMMED,rgpa_TMARV,rgpa_SMARV,rgpa_TMARV11,rgpa_SMARV11
  REAL(KIND=4),DIMENSION(:,:),POINTER                :: rgpa_TMLEV09,rgpa_SMLEV09,rgpa_TMLEV13,rgpa_SMLEV13
  INTEGER(kind=4),DIMENSION(:),ALLOCATABLE           :: iga_BathyProfil
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE            :: rga_DepthVal,rga_PresVal
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE            :: rga_TempVal 
#if defined key_computePot
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE            :: rga_TempPotVal !,rga_TempPotVal2
#endif
  REAL(KIND=4),DIMENSION(:,:),ALLOCATABLE            :: rga_PsalVal
  REAL(kind=4)  :: rg_DepthVal_Def,rg_TempVal_Def,rg_PsalVal_Def
  REAL(kind=8)  :: rg_PsalVal_Def_R8
  INTEGER(kind=4),DIMENSION(:),ALLOCATABLE :: iga_MesTempVal,iga_MesPsalVal
  REAL(kind=4),DIMENSION(:),ALLOCATABLE :: rga_TempDepthMin,rga_TempDepthMax,rga_PsalDepthMin,rga_PsalDepthMax

  PUBLIC ::  affect_table_ARGO

CONTAINS

  SUBROUTINE affect_table_ARGO

    IMPLICIT NONE
    cga_param(ip_TEMP)=        'TEMP        ' 
    cga_param(ip_PSAL)=        'PSAL        ' 
    cga_param(ip_DEPH)=        'DEPH        ' 
    cga_param(ip_PRES)=        'PRES        ' 
    cga_param(ip_HDCST_TEMP)=  'HDCST_TEMP  ' 
    cga_param(ip_HDCST_PSAL)=  'HDCST_PSAL  ' 
    cga_param(ip_ANA_TEMP)=    'ANA_TEMP    ' 
    cga_param(ip_ANA_PSAL)=    'ANA_PSAL    ' 
    cga_param(ip_FRCST1D_TEMP)='FRCST1D_TEMP' 
    cga_param(ip_FRCST1D_PSAL)='FRCST1D_PSAL' 
    cga_param(ip_FRCST3D_TEMP)='FRCST3D_TEMP' 
    cga_param(ip_FRCST3D_PSAL)='FRCST3D_PSAL' 
    cga_param(ip_FRCST5D_TEMP)='FRCST5D_TEMP' 
    cga_param(ip_FRCST5D_PSAL)='FRCST5D_PSAL' 
    cga_param(ip_FRCST6D_TEMP)='FRCST6D_TEMP' 
    cga_param(ip_FRCST6D_PSAL)='FRCST6D_PSAL' 
    cga_param(ip_PERS_TEMP)=   'PERS_TEMP   '
    cga_param(ip_PERS_PSAL)=   'PERS_PSAL   '
    cga_param(ip_PERS3D_TEMP)= 'PERS3D_TEMP ' 
    cga_param(ip_PERS3D_PSAL)= 'PERS3D_PSAL ' 
    cga_param(ip_PERS6D_TEMP)= 'PERS6D_TEMP ' 
    cga_param(ip_PERS6D_PSAL)= 'PERS6D_PSAL ' 
    cga_param(ip_TMLEV05)=     'TMLEV05     ' 
    cga_param(ip_SMLEV05)=     'SMLEV05     ' 
    cga_param(ip_TMMED)=       'TMMED       ' 
    cga_param(ip_SMMED)=       'SMMED       ' 
    cga_param(ip_TMARV)=       'TMARV       ' 
    cga_param(ip_SMARV)=       'SMARV       '
    cga_param(ip_TMLEV09)=     'TMLEV09     ' 
    cga_param(ip_SMLEV09)=     'SMLEV09     ' 
    cga_param(ip_TMARV11)=     'TMARV11     ' 
    cga_param(ip_SMARV11)=     'SMARV11     '
    cga_param(ip_TMLEV98)=     'TMLEV98     ' 
    cga_param(ip_SMLEV98)=     'SMLEV98     ' 
    cga_param(ip_TMLEV13)=     'TMLEV13     ' 
    cga_param(ip_SMLEV13)=     'SMLEV13     ' 


   !** variable par defaut des tableaux valide:
    ! attention il faudra en fait le recuperer depuis
    ! un attribut "fillvalue" du fichier NetCDF 
    rg_DepthVal_Def = 99999.
    rg_TempVal_Def = 99999.
    rg_PsalVal_Def = 99999.
    rg_PsalVal_Def_R8= 99999.

  END SUBROUTINE affect_table_ARGO

END MODULE table_ARGO
