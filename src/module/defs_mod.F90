MODULE defs_mod

! Modifications :
! -------------
! JM. Lellouche : Adding of the variable MAXPTS
! C.E. Testut   : Adding variables from PPL
!
! ----------------------------------------------------------------------------
  USE palm_user_param, only : ip_maxcan1,ip_maxcan2,ip_maxcan3
  USE event_mod, only : EventStruct

  IMPLICIT NONE
   
  TYPE(EventStruct), TARGET :: mesg =  EventStruct(' ', 0)
  TYPE(EventStruct)         :: eh
!
! ----------------------------------------------------------------------------
! ARRAY DIMENSIONS ("HARD LIMITS")
!
! Main dimensions of problem
!
! ip_maxred     maximum number of modes
! ip_sblocz     maximum size of one sub bloc
! MAXMSK	maximum number of regional masks
! MAXPTS        maximum number of canvas gridpoints for all regional masks
! ip_maxsets	maximum number of input datasets, of observation 
!               operators, and of sets of statistical error model
!               parameters
! MAXCAN1	maximum size of canvas in first direction
! MAXCAN2	maximum size of canvas in second direction
! MAXCAN3	maximum number of variables on canvas at (x,y) location,
!           	i.e. the maximum length of the multivariate vertical
!           	sequence (MVS)
! 
#if defined key_atl12
  INTEGER, PARAMETER :: ip_maxred = 250 
  INTEGER, PARAMETER :: ip_sblocz = 9250
#else
  INTEGER, PARAMETER :: ip_maxred = 500
  INTEGER, PARAMETER :: ip_sblocz = 10000
#endif
!
#ifdef key_atl4
  INTEGER, PARAMETER :: MAXMSK  = 22 
  INTEGER, PARAMETER :: MAXPTS  = 45459 
#endif
#ifdef key_atl12
  INTEGER, PARAMETER :: MAXMSK  = 35
  INTEGER, PARAMETER :: MAXPTS  = 458287 
#endif
#if defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12
  INTEGER, PARAMETER :: MAXMSK  = 46
#endif
#if defined key_orca_r025
  INTEGER, PARAMETER :: MAXPTS  = 631343 
#endif
#if defined key_orca_r2
  INTEGER, PARAMETER :: MAXPTS  = 11399 
#endif
#if defined key_orca_r12
  INTEGER, PARAMETER :: MAXPTS  = 5675285 
#endif
!
  INTEGER, PARAMETER :: ip_maxsets = 10
  INTEGER, PARAMETER :: MAXCAN1 = ip_MAXCAN1 ! palm_user_param
  INTEGER, PARAMETER :: MAXCAN2 = ip_MAXCAN2 ! palm_user_param
  INTEGER, PARAMETER :: MAXCAN3 = ip_MAXCAN3 ! palm_user_param
!
! Satellite altimeter input -- if not used set minimum values
!
! MAXTRKS	maximum number of tracks
! MAXPASS	maximum number of passes along a given track
! MAXPTTK	maximum number of data points per track
!
  INTEGER, PARAMETER :: MAXTRKS =  200 
  INTEGER, PARAMETER :: MAXPASS =  200 
  INTEGER, PARAMETER :: MAXPTTK = 8000
!
! Local problem
!
! ip_maxsel	maximum number of predictors in selection
!
#if defined key_atl12
  INTEGER, PARAMETER :: ip_maxsel = 20000
#else
  INTEGER, PARAMETER :: ip_maxsel = 15000
#endif
!
! ----------------------------------------------------------------------------
! FORTRAN LOGICAL UNITS
!
! change these definitions if they conflict with model logical units or if 
! using a large number of input data files -- SOFA needs between 5 and 
! (8 + 2*nsets) simultaneously open files
!
! IP_LUERR	Fortran standard error logical unit
! rangeLow	lower acceptable logical unit
! rangeHigh	higher acceptable logical unit
!
  INTEGER, PARAMETER :: IP_LUERR  =   0 
  INTEGER, PARAMETER :: rangeLow  = 100 
  INTEGER, PARAMETER :: rangeHigh = 200 
!
! ----------------------------------------------------------------------------
! MISCELLANEOUS
!
! EMPTY, EMPTY2, IEMPTY, CEMPTY	
!		marks an "empty" measurement or variable
! 		-- used internally
!		-- input data values equal to EMPTY or EMPTY2 are rejected
! **NOTE** IEMPTY <<MUST>> BE A LARGE NEGATIVE NUMBER!!!
!
!
  REAL,             PARAMETER :: EMPTY  = 1e35,  EMPTY2 = 9999.0 
  INTEGER,          PARAMETER :: IEMPTY =  -22222 
  CHARACTER(LEN=4), PARAMETER :: CEMPTY = 'XXXX' 
!
! data markers
! ISIS, ISVP, ISUV, ISDS mark the corresponding type of regular observation
!   affected variables  :  SETTYPE
!
  INTEGER, PARAMETER :: ISIS = 0 
  INTEGER, PARAMETER :: ISVP = 1 
  INTEGER, PARAMETER :: ISUV = 2 
  INTEGER, PARAMETER :: ISDS = 3 
!
! bogus data markers
! ISOZR, ISONC mark the corresponding type of bogus observation
!   affected variables  :  DUPxx.duid
!   positive bogus test :  duid.lt.IEMPTY
!
  INTEGER, PARAMETER :: ISOZR = IEMPTY-1 
  INTEGER, PARAMETER :: ISONC = IEMPTY-2 
!
! misfit markers
! mark misfit history
!   affected variables   :  DUPxx%status
!   positive reject test :  status.lt.0
! 
! before model_run
! IREADY
! NOREADY, NOREADY_MSK, NOREADY_BATHY
!
! during model_run (modint.F90)
! EREJECT, EREJECT_MSK, EREJECT_ICE, EREJECT_MXLB
! EREJECTPROC
!
! after model_run (misfit_post.F90)
! ECHECK, ECHECK_MSK, ECHECK_SIGMA, ECHECK_MAX
!
! ---------------------------------
! IREADY : statut caracterisant : data est autorisee pour assimilation
!  ---------------------------------
! NOREADY(defaut) :  statut caracterisant : data est non-autorisee pour assimilation
! NOREADY_MSK :  statut caracterisant : data est non-autorisee pour assimilation car mask
!                a la fin de "read_data", apres chargement des obs, 
!                certaines prennent un status NOREADY_MSK selon les datamsk_* loades
! NOREADY_BATHY : statut caracterisant: un rejet pour des raison de bathy incompatible avec donnee
!  ---------------------------------
! EREJECT(defaut) : statut caracterisant les observations eliminees en cours de run 
!                   (au moment du calcul de l innovation).
! EREJECT_MSK : statut caracterisant: une zone geographique definie pas l utilisateur 
!               a ete ecartee en cours de run
! EREJECT_ICE : statut caracterisant: un rejet pour des raison de glace
! EREJECT_MXLB : statut caracterisant: un rejet pour des raison de MXLB
! EREJECTPROC : en multiproc le vecteur innovation global est duplique sur tous les
!               procs. Le status des obs qui ne sont pas sur le proc courant est mis a 
!               EREJECTPROC.
!  ---------------------------------
! ECHECK(defaut) : statut caracterisant les misfits eliminees apres run (au moment du check).
! ECHECK_MSK : statut caracterisant: une zone geographique definie pas l utilisateur a ete ecartee
! ECHECK_SIGMA : statut caracterisant: innovation rejetee dont la valeur absolue est inferieure ou egale a 2*sigma (climatologie)
! ECHECK_MAX : statut caracterisant : innovation rejetee dont la valeur absolue est strictement superieure a rga_misfitmax
  INTEGER, PARAMETER :: IREADY       =    0 
  INTEGER, PARAMETER :: NOREADY      =    -10 
  INTEGER, PARAMETER :: NOREADY_MSK  =    -11 
  INTEGER, PARAMETER :: NOREADY_BATHY=    -12 
!
  INTEGER, PARAMETER :: EREJECT      =   -20  
  INTEGER, PARAMETER :: EREJECT_MSK  =   -21 
  INTEGER, PARAMETER :: EREJECT_ICE  =   -22
  INTEGER, PARAMETER :: EREJECT_MXLB =   -23
  INTEGER, PARAMETER :: EREJECTPROC  =  999
!
  INTEGER, PARAMETER :: ECHECK       =   -30
  INTEGER, PARAMETER :: ECHECK_MSK   =   -31 
  INTEGER, PARAMETER :: ECHECK_SIGMA =   -32
  INTEGER, PARAMETER :: ECHECK_MAX   =   -33
!
! Ancienne valeur pour bug du a codage en dur
!
!!  INTEGER, PARAMETER :: IREADY       =    0 
!!  INTEGER, PARAMETER :: EREJECT      =   -1 
!!  INTEGER, PARAMETER :: ECHECK       =   -2 
!!  INTEGER, PARAMETER :: EREJECTMSK   =   -3 <= NOREADY_MSK
!!  INTEGER, PARAMETER :: ECHECK_SIGMA =   -4
!!  INTEGER, PARAMETER :: ECHECK_MSK   =   -5
!!  INTEGER, PARAMETER :: EREJECTPROC  =  999
!
! large "non-arithmetic" value (not to be used in add, multiply, etc.)
!
  REAL, PARAMETER :: BIG = huge(0.)
  REAL, PARAMETER :: rp_epsilon = EPSILON(0.)
  REAL :: rg_plus, rg_moins 

END MODULE defs_mod
