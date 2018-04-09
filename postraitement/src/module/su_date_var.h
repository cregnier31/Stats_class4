! *****************************************************************************
! *                                                                           *
! * Fichier : SU_DATE_VAR.H                                                   *
! *                                                                           *
! *****************************************************************************
! *                                                                           *
! * ROLE   :                                                                  *
! *                                                                           *
! *    Donnees propres de la machine SU_DATE                                  *
! *                                                                           *
! * FICHIERS A INCLURE AVANT CELUI-CI :                                       *
! *                                                                           *
! *****************************************************************************
! *                                                                           *
! *                                      P.Sicard                             *
! *                                      CLS Space Oceanography Group         *
! *                                      14 Avril 1995                        *
! *                                                                           *
! *****************************************************************************


!-----------------------------------------------------------------------------!
!                              C O N S T A N T E S                            !
!-----------------------------------------------------------------------------!


!**    Compte rendu operation
!**    ----------------------
!      INTEGER(KIND=4)           ::       jc_su_glob_ok
!      PARAMETER     (jc_su_glob_ok  = 0)

!      INTEGER(KIND=4)           :: jc_su_glob_nok
!      PARAMETER    (jc_su_glob_nok = 1)

!    Constantes Mathematiques
!    ------------------------

!**         PI
!**         --
      REAL(KIND=8)    ::   dc_su_glob_pi
      PARAMETER   (dc_su_glob_pi = 3.141592653589793D0)

!**         Constante de Gravite
!**         --------------------
      REAL(KIND=8)    ::   dc_su_grav
      PARAMETER      (dc_su_grav = 9.807D0)

!**         Rotation de la TERRE
!**         --------------------
      REAL(KIND=8)    ::   dc_su_omega
      PARAMETER      (dc_su_omega = 7.272205D-5)

!**         Conversion Degree -> radian
!**         ---------------------------
      REAL(KIND=8)    ::  dc_su_glob_cdr
      PARAMETER     (dc_su_glob_cdr = dc_su_glob_pi / 180.D+00)


!**  Longueur d'une date calendaire en ASCII exprimee sous la forme :
!**  jj-MMM-aaaa hh:mm:ss:tttttt
!**  --------------------------------------------------------------------

      INTEGER(KIND=2)   :: 	 ec_su_date_lg_cal27
      PARAMETER (ec_su_date_lg_cal27 = 27)

!**  Longueur d'une date calendaire en ASCII exprimee sous la forme :
!**  aaaa-jjjThh:mm:ss                 
!**  --------------------------------------------------------------------

      INTEGER(KIND=2)   ::      ec_su_date_lg_cal17
      PARAMETER (ec_su_date_lg_cal17 = 17) 


 !**     Table des noms de mois reconnus 
 !**     ------------------------------- 

       CHARACTER(LEN=3),DIMENSION(12)        ::  tk_su_date_nom_mois 
       DATA tk_su_date_nom_mois /'JAN','FEB','MAR','APR','MAY','JUN',&
                                 'JUL','AUG','SEP','OCT','NOV','DEC'/

 !**     Tables des nombres de jours ecoules avant chaque mois de l'annee
 !**     ek_quant (1...12,1) pour les annees bissextiles
 !**     ek_quant (1...12,2) pour les annees non bissextiles
 !**     ---------------------------------------------------------------

       INTEGER(KIND=2),DIMENSION(12,2) ::   ek_su_date_quant
       data ek_su_date_quant /0,31,60,91,121,152,182,213,244,274,305,335,& 
                              0,31,59,90,120,151,181,212,243,273,304,334/

 !**     Tables du nombre de jours par mois
 !**     ek_nbjmois(1...12,1) pour les annees bissextiles
 !**     ek_nbjmois(1...12,2) pour les annees non bissextiles
 !**     ---------------------------------------------------------------

       INTEGER(KIND=2),DIMENSION(12,2)   ::ek_su_date_nbjmois
       data ek_su_date_nbjmois /31,29,31,30,31,30,31,31,30,31,30,31,&      
                                31,28,31,30,31,30,31,31,30,31,30,31/

 !**     Format d'une date calendaire ASCII
 !**     ----------------------------------

       CHARACTER(LEN=52)     ::   tc_su_date_form_cal
       DATA  tc_su_date_form_cal /'(I2.2,A1,A3,A1,I4.4,A1,I2.2,A1,I2.2,A1,I2.2,A1,I6.6)'/ 

!**     Definition des separateurs dans les dates calendaires
!**     (i.e dates sous la forme jj-MMM-aaaa hh:mm:ss)
!**     1er separateur  : '-'
!**     2eme separateur : ' '
!**     3eme separateur : ':'
!**     ------------------------------------------------------

      CHARACTER    ::  ac_su_date_sep1
      PARAMETER (ac_su_date_sep1 ='-')

      CHARACTER    ::  ac_su_date_sep2
      PARAMETER (ac_su_date_sep2 =' ')

      CHARACTER    ::  ac_su_date_sep3
      PARAMETER (ac_su_date_sep3 =':')

!**     Nom du fichier des ecarts TUC-TAI utilise
!**     -----------------------------------------
      CHARACTER(LEN=60)    ::  tc_su_date_ficTucTai
      PARAMETER (tc_su_date_ficTucTai = 'CVL_IFINT:TUC_TAI.DAT')


!**   N.U.L d'acces au fichier de ecarts TUC-TAI
!**     ------------------------------------------
      INTEGER(KIND=4)    ::      jc_su_date_nul
      PARAMETER (jc_su_date_nul = 9)

!-----------------------------------------------------------------------------!
!                                   T Y P E S                                 !
!-----------------------------------------------------------------------------!

!**     Structure de gestion des sauts TUC-TAI
!**     --------------------------------------
      structure /s_su_date_saut/
           REAL(KIND=8)         ::  dv_ecart  !correction TUC-TAI en secondes
           CHARACTER(LEN=32)    ::  tv_datdeb !date debut correction TUC/TAI AAAA MM JJ incluse
           CHARACTER(LEN=32)    ::  tv_datfin !date fin   correction TUC/TAI AAAA MM JJ excluse
      endstructure

      structure /s_su_date_TucTAi/
       INTEGER(KIND=2)          ::  ev_nbecarts      !nbre de corrections TUC/TAI
       record /s_su_date_saut/&        !Tableau des ecarts TUC/TAI depuis le debut 
               sw_tcta (20)    !de la mission (surdimensionnee !!)
      endstructure

!-----------------------------------------------------------------------------!
!                              V A R I A B L E S                              !
!-----------------------------------------------------------------------------!



!**     Indicateur d'initialisation de conversion des dates de TAI en TUC
!**     -----------------------------------------------------------------
      LOGICAL*2      lv_su_date
      !LOGICAL,(DIMENSION=2)  ::      lv_su_date

!**     Nombre de relations TUC-TAI lues dans le fichier des ecarts
!**     -----------------------------------------------------------
      INTEGER(KIND=2)   ::    ev_su_date_nbecarts

!**     Jour julien de debut du 1er ecart TUC/TAI
!**     -----------------------------------------
      INTEGER(KIND=2)   ::    ev_su_date_jjdeb1

!**     Jour julien de fin   du 1er ecart TUC/TAI
!**     -----------------------------------------
      INTEGER(KIND=2)   ::    ev_su_date_jjfin1    

!**     Ecart 1 TUC/TAI en secondes              
!**     ---------------------------
       REAL(KIND=8)      ::    dv_su_date_ecart1   

!**     Jour julien de debut du 2ie ecart TUC/TAI
!**     -----------------------------------------
      INTEGER(KIND=2)   ::   ev_su_date_jjdeb2    

!**     Jour julien de fin   du 2ie ecart TUC/TAI
!**     -----------------------------------------
      INTEGER(KIND=2)   ::   ev_su_date_jjfin2   

!**    Ecart 2 TUC/TAI en secondes              
!**     ---------------------------
       REAL(KIND=8)     ::   dv_su_date_ecart2   


!-----------------------------------------------------------------------------!
!                                C O M M O N S                                !
!-----------------------------------------------------------------------------!

  COMMON /c_su_date/ &
   dv_su_date_ecart1  , dv_su_date_ecart2,&
   ek_su_date_quant   , ek_su_date_nbjmois,&
   ev_su_date_nbecarts ,  lv_su_date,&
   ev_su_date_jjdeb1   ,  ev_su_date_jjfin1,&
   ev_su_date_jjdeb2   ,  ev_su_date_jjfin2,&
   tk_su_date_nom_mois  ,  tc_su_date_form_cal
 
 

!-----------------------------------------------------------------------------!
!                          I N I T A L I S A T I O N S                        !
!-----------------------------------------------------------------------------!

!**     Indicateur d'initialisation de conversion des dates de TAI en TUC
!**     -----------------------------------------------------------------
      DATA      lv_su_date /.false./

!**     Nombre de relations TUC-TAI lues dans le fichier des ecarts
!**     -----------------------------------------------------------
      DATA      ev_su_date_nbecarts /0/

!**     Jour julien de debut du 1er ecart TUC/TAI
!**     -----------------------------------------
      DATA      ev_su_date_jjdeb1 /0/

!**     Jour julien de fin   du 1er ecart TUC/TAI
!**     -----------------------------------------
      DATA      ev_su_date_jjfin1 /0/   

!**     Ecart 1 TUC/TAI en secondes              
!**    ---------------------------
      DATA      dv_su_date_ecart1 /0.D0/  

!**     Jour julien de debut du 2ie ecart TUC/TAI
!**     -----------------------------------------
      DATA      ev_su_date_jjdeb2 /0/   

!**     Jour julien de fin   du 2ie ecart TUC/TAI
!**     -----------------------------------------
      DATA      ev_su_date_jjfin2 /0/  

!**     Ecart 2 TUC/TAI en secondes              
!**     ---------------------------
      DATA      dv_su_date_ecart2 /0.D0/  


