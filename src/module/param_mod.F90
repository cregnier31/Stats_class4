!> \brief
!* Module param mode
!! module definissant les paramètres des différents modèles MERCATOR : nombre maximum 
!! de points dans le canvas (nb de points ocean), nombre de points en x et en y
!!
!!   C.REGNIER      Octobre 2008
!!   C.REGNIER      Mai 2013 Maj new conf
! ##TODO :: Integrer conf MED 
!<
!!
MODULE PARAM_MOD

!** CONFIG ORCA1
#if defined key_orca_r1
!! NATL12
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "orca_1"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_maxgrd = 58235
  INTEGER, PARAMETER :: ip_jpiglo = 362 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 256 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 50     !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension ofglobal domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    ""    --> jpk     = jpkdta,     
                             jpk     = jpkdta,         &  !: number of vertical levels
                             ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type(between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islandsjpnisl  = 800
#endif

!** CONFIG PSY2V4R1/PSY2V4R2/PSY2V4R4
#if defined key_atl12
!! NATL12
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "ATL12"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_maxgrd = 1236657  !1236837 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 1612 !1615 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 1585 !1585 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 50     !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension ofglobal domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    ""    --> jpk     = jpkdta,     
                             jpk     = jpkdta,         &  !: number of vertical levels
                             ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type (between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islands
                             jpnisl  = 800
#endif
#if defined key_med12
!! MED12 
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "MED12"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_maxgrd = 55333  !55333 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 567 !1615 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 264 !1585 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 75     !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension of global domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    ""    --> jpk     = jpkdta,     
                             jpk     = jpkdta,         &  !: number of vertical levels
                             ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type (between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islands
                             jpnisl  = 800
#endif

#if defined key_atl12_zNEATL36 
!! zoom NEATL36 surNATL12
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "ATL12_zNEATL36"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_maxgrd = 205749 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 487 !1615 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 734 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 50  !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension ofglobal domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    ""    --> j
                             jpk     = jpkdta,         &  !: number of vertical levels
                            ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type (between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islands
                             jpnisl  = 800
#endif

#if defined key_neatl12 
!! NEATL12
  CHARACTER (len=16), PARAMETER :: cp_cfg = "neatl12"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_maxgrd = 135992 !135992 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 367 !367 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 634 !634 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 50  !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension of global domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    ""    --> j
                             jpk     = jpkdta,         &  !: number of vertical levels
                             ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type (between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islands
                             jpnisl  = 800
#endif

#if defined key_ibi12
!! NEATL36
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "ibi12"        !: name of the configuration 
  INTEGER, PARAMETER ::  jp_cfg = 36  !: resolution of the configuration (degrees)
  INTEGER, PARAMETER :: ip_maxgrd =  134074 ! 1183265 ! 1183079!1183079 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 367 ! 1093 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 634 !1894 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 75  !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension of global domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    " "    --> j
                             jpk     = jpkdta,         &  !: number of vertical levels
                             ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type (between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islands
                             jpnisl  = 800 
#endif

#if defined key_ibi36
!! NEATL36
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "ibi36"        !: name of the configuration 
  INTEGER, PARAMETER ::  jp_cfg = 36  !: resolution of the configuration (degrees)
  INTEGER, PARAMETER :: ip_maxgrd =  1183265 ! 1183079!1183079 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 1093 ! 1093 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 1894 !1894 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta  = 50  !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension of global domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    "                  "    --> j
                             jpk     = jpkdta,         &  !: number of vertical levels
                             ! Domain characteristics
                             jperio  =   0   ,      &  !: lateral cond. type (between 0 and 6)
                             jpisl   =  18   ,      &  !: number of islands
                             jpnisl  = 800 
#endif

! Config PSY3V3R1 / PSY3V3R3
#if defined key_orca_r025 
  !! PSY3
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "orca025"        !: name of the configuration 
  INTEGER, PARAMETER :: jp_cfg = 025       !: resolution of the configuration (degrees)
!  INTEGER, PARAMETER :: ip_maxgrd = 901044 !901046 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_maxgrd = 901044 !901046 ! maximum number of grid points
  INTEGER, PARAMETER :: ip_jpiglo = 1442   !1442 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 1021   !1021 ! number of grid points y
  INTEGER, PARAMETER :: jpkdta = 50       !: number of levels      ( >= jpk    )
  INTEGER, PARAMETER ::      jpiglo  = ip_jpiglo,      &  !: 1st dimension of global domain --> i
                             jpjglo  = ip_jpjglo,      &  !: 2nd    ""    --> j
                             jpk     = jpkdta,         &  !: number of verticallevels
                             ! Domain characteristics
                            jperio  =    4  ,      &  !: lateral cond. type (between 0 and 6)
                            jpisl   =  150  ,      &  !: number of islands
                            jpnisl  = 3000            !: maximum number of points per island
#endif

#if defined key_orca12_old 
  ! PSY4
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "orca12"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_jpiglo = 4322 !4322 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 3059 !3059 ! number of grid points y
  INTEGER, PARAMETER :: ip_maxgrd = 8120041 !8120041 ! maximum number of grid points
  INTEGER, PARAMETER :: jpkdta  = 50 ,         &  !: number of levels           > or = to jpk
                                        ! total domain matrix size
                        jpiglo  = ip_jpiglo,      &  !: first  dimension of global domain --> i
                        jpjglo  = ip_jpjglo,      &  !: second dimension of global domain --> j
                        jpk     = jpkdta,      &  !: number of vertical levels
! Domain characteristics
                        jperio  =    4  ,      &  !: lateral cond. type (between 0 and 6)
                        jpisl   =  150  ,      &  !: number of islands
                        jpnisl  = 3000            !: maximum number of points per island
#endif
!! PSY4V2R2
#if defined key_orca_r12
! PSY4
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "orca12"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_jpiglo = 4322 !4322 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 3059 !3059 ! number of grid points y
 !!   INTEGER, PARAMETER :: ip_maxgrd = 8118760 ! maximum number of gridpoints
  !INTEGER, PARAMETER :: ip_maxgrd = 8123087 ! maximum number of gridpoints
  INTEGER, PARAMETER :: ip_maxgrd = 8120416 ! maximum number of gridpoints
  !INTEGER, PARAMETER :: ip_maxgrd = 8118760 ! maximum number of gridpoints
  INTEGER, PARAMETER :: jpkdta  = 50 ,         &  !: number of levels > or = to jpk
                                        ! total domain matrix size
                        jpiglo  = ip_jpiglo,      &  !: first  dimension of global domain --> i
                        jpjglo  = ip_jpjglo,      &  !: second dimension of global domain --> j
                        jpk     = jpkdta,      &  !: number of vertical levels
! Domain characteristics
                        jperio  =    4  ,      &  !: lateral cond. type (between 0 and 6)
                        jpisl   =  150  ,      &  !: number of islands
                        jpnisl  = 3000            !: maximum number of pointsper island

#endif
#if defined key_orca_r12_allege
  INTEGER, PARAMETER :: ip_jpiglo = 1440 !4322 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 1019 !3059 ! number of grid points y
  INTEGER, PARAMETER :: ip_maxgrd = 900473 !901046 ! maximum number of grid points
  INTEGER, PARAMETER :: jpkdta  = 50, &  !: number of levels > or = to jpk
                        jpiglo  = ip_jpiglo,      &  !: first  dimension of global domain --> i
                        jpjglo  = ip_jpjglo,      &  !: second dimension of global domain --> j
                        jpk     = jpkdta,      &  !: number of vertical levels
! Domain characteristics
                        jperio  =    4  ,      &  !: lateral cond. type (between 0 and 6)
                        jpisl   =  150  ,      &  !: number of islands
                        jpnisl  = 3000            !: maximum number of pointsper island
#endif
!! PRESAL
#if defined key_presal
! PSY4
  CHARACTER (len=16), PARAMETER ::  cp_cfg = "presal"        !: name of the configuration 
  INTEGER, PARAMETER :: ip_jpiglo = 361 !4322 ! number of grid points x
  INTEGER, PARAMETER :: ip_jpjglo = 397 !3059 ! number of grid points y
  INTEGER, PARAMETER :: ip_maxgrd = 84573  ! maximum number of gridpoints
  INTEGER, PARAMETER :: jpkdta  = 50 ,         &  !: number of levels > or = to jpk
                                        ! total domain matrix size
                        jpiglo  = ip_jpiglo,      &  !: first  dimension of global domain --> i
                        jpjglo  = ip_jpjglo,      &  !: second dimension of global domain --> j
                        jpk     = jpkdta,      &  !: number of vertical levels 
! Domain characteristics
                         jperio  =   0            !: lateral cond. type (between 0 and 6)
#endif

  INTEGER, PUBLIC, PARAMETER ::    &   !: 
      jpni   = 1,                   &  !: number of processors following i 
      jpnj   = 1,                   &  !: number of processors following j
      jpreci = 1,                   &  !: number of columns for overlap 
      jprecj = 1                       !: number of rows    for overlap 

INTEGER,          PARAMETER         :: IEMPTY =  -22222
INTEGER, DIMENSION(ip_maxgrd)       :: igrd  = IEMPTY
INTEGER, DIMENSION(ip_maxgrd)       :: jgrd = IEMPTY
!
INTEGER ,PARAMETER  ::  jpi = jpiglo,   &  !: first  dimension
                        jpj =jpjglo,    &  !: second dimension
                        jpim1 = jpi-1,  &  !: innerdomain indices
                        jpjm1 = jpj-1,   &  !:   ""
                        jpkm1 = jpk-1,   &  !:   ""
                        jpij  = jpi*jpj                  

END MODULE PARAM_MOD
