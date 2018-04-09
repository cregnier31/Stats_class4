MODULE SU_DATE

   !*======================================================================
   !                       ***  MODULE CONVERT_DATE  ***
   !       Ce module réalise l'ensemble des operations a effectuer sur         *
   !   les dates                                                               *
   !       - changement de referentiel de datation                             *
   !       - formattage de dates                                               *
   !======================================================================

IMPLICIT NONE
PRIVATE
PUBLIC SU_DATE_STU90_STU50,SU_DATE_STU58_STU50,&
       SU_DATE_STU50_STU58,SU_DATE_STU85_STU50,&
       SU_DATE_STU50_STU85,SU_DATE_CAL_STU50,&
       SU_DATE_STU50_CAL,SU_DATE_JMLMC_SEC,&
       SU_DATE_SEC_JMLMC,SU_DATE_STU50_JMAHMSM,&
       SU_DATE_JMAHMSM_STU50,SU_DATE_SEC_SMC,&
       SU_DATE_SMC_SEC,SU_DATE_JMA_QUANT,&
       SU_DATE_A_QUANT_JM,SU_DATE_CAL_STU50_2,SU_DATE_STU50_CAL_2

CONTAINS

   SUBROUTINE SU_DATE_STU90_STU50(dv_sec90,dv_sec50  )
!
!****SU_DATE_STU90_STU50
!
!     Purpose:
!     --------
!       Passage d'une date (en secondes) du            
!       referentiel 01/01/1990 00H00M00S a une          
!       date (en secondes) dans le referentiel          
!       01/01/1950 00H00M00S                 
!     
!     Input : \\
!     ------
!      \begin{itemize}
!      \item dv_sec90 : Nombre de secondes ecoulees depuis le 01-Jan-1990 00:00:00                    
!
!     Output : \\
!      dv_sec50  : Nombre de secondes ecoulees depuis le 01-Jan-1950 00:00:00 
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!

  IMPLICIT NONE
!
!**   0.2 Local variables
!
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)  ::	dv_sec90   ! (E)
      REAL(KIND=8)  ::  dv_sec50   ! (S)
!
!*--------------------------------------------------------------------------
!

!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1950 =
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1990 + 1262304000
! 
      dv_sec50 = dv_sec90 + 1262304000.D0
!
!*--------------------------------------------------------------------------
!
END SUBROUTINE SU_DATE_STU90_STU50
   
!
!
!*======================================================================
!
!
    SUBROUTINE SU_DATE_STU58_STU50( dv_sec58,dv_sec50  )
!
!****SU_DATE_STU58_STU50
!
!     Purpose:
!     --------
!      Passage d'une date (en secondes) du            
!      referentiel 01/01/1958 00H00M00S a une          
!      date (en secondes) dans le referentiel          
!      01/01/1950 00H00M00S          
!     
!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec58: Nombre de secondes ecoulees depuis le 01-Jan-1958 00:00:00   
!
!     Output : \\
!      dv_sec50  : Nombre de secondes ecoulees depuis le 01-Jan-1950 00:00:00 
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
  IMPLICIT NONE
!
!**   0.2 Local variables
!
!**   0.3 Dummy variables 
!
     REAL(KIND=8) :: dv_sec58   ! (E)
     REAL(KIND=8) :: dv_sec50   ! (S)
!
!*--------------------------------------------------------------------------
!
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1950 =
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1958 + 252460800

       dv_sec50 = dv_sec58 + 2524608.D2

!
!*--------------------------------------------------------------------------
!
END SUBROUTINE SU_DATE_STU58_STU50
!
!
!*======================================================================
!
!   
     SUBROUTINE SU_DATE_STU50_STU58(dv_sec50,dv_sec58)
!
!
!****SU_DATE_STU50_STU58
!
!     Purpose:
!     --------
!      
!     Passage d'une date (en secondes) du            
!     referentiel 01/01/1950 00H00M00S a une          
!     date (en secondes) dans le referentiel          
!     01/01/1958 00H00M00S    
!     
!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec50: Nombre de secondes ecoulees depuis le                    
!         01-Jan-1950 00:00:00  
!
!     Output : \\
!      dv_sec58  : Nombre de secondes ecoulees depuis le                     
!                01-Jan-1958 00:00:00  dv
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
  IMPLICIT NONE
!
!**   0.2 Local variables
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)   :: 	dv_sec50   ! (E)
      REAL(KIND=8)   :: 	dv_sec58   ! (S)
!
!*--------------------------------------------------------------------------
!
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1958 =
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1950 - 252460800
 
      dv_sec58 = dv_sec50 - 2524608.D2
!
!*--------------------------------------------------------------------------
!
  END SUBROUTINE SU_DATE_STU50_STU58
!
!
!*======================================================================
!
!   
   SUBROUTINE  SU_DATE_STU85_STU50(dv_sec85,dv_sec50  )
!
!
!****SU_DATE_STU85_STU50
!
!     Purpose:
!     --------
!     Passage d'une date (en secondes) du            
!     referentiel 01/01/1985 00H00M00S a une          
!     date (en secondes) dans le referentiel          
!     01/01/1950 00H00M00S           
!     
!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec85  : Nombre de secondes ecoulees depuis le                    
!                         01-Jan-1985 00:00:00      
!
!     Output : \\
!      dv_sec50  : Nombre de secondes ecoulees depuis le                     
!                01-Jan-1950 00:00:00  
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
  IMPLICIT NONE
!
!**   0.2 Local variables
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)   ::	dv_sec85   ! (E)
      REAL(KIND=8)   :: dv_sec50   ! (S)
!
!*--------------------------------------------------------------------------
!
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1950 =
!**     NOMBRE DE SECONDES ECOULEES DEPUIS 1985 + 1104537600
! 
      dv_sec50 = dv_sec85 + 11045376.D2 
!
!*--------------------------------------------------------------------------
!
END SUBROUTINE SU_DATE_STU85_STU50
!
!
!*======================================================================
!
!  
 SUBROUTINE SU_DATE_STU50_STU85( dv_sec50,dv_sec85 )
!
!
!****SU_DATE_STU50_STU85 
!
!     Purpose:
!     --------
!     Passage d'une date (en secondes) du            
!     referentiel 01/01/1950 00H00M00S a une          
!     date (en secondes) dans le referentiel          
!     01/01/1985 00H00M00S                   
!
!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec50  : Nombre de secondes ecoulees depuis le                    
!                 01-Jan-1950 00:00:00    
!     Output : \\
!     dv_sec85  : Nombre de secondes ecoulees depuis le                     
!                01-Jan-1985 00:00:00  
!     
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
  IMPLICIT NONE
!
!**   0.2 Local variables
!
!**   0.3 Dummy variables 
!
     REAL(KIND=8) ::  	dv_sec50   ! (E)
     REAL(KIND=8) :: 	dv_sec85   ! (S)
!
!*--------------------------------------------------------------------------
!
!**   NOMBRE DE SECONDES ECOULEES DEPUIS 1985 =
!**   NOMBRE DE SECONDES ECOULEES DEPUIS 1950 - 1104537600
! 
      dv_sec85 = dv_sec50 - 11045376.D2 
!
!*--------------------------------------------------------------------------
!
END SUBROUTINE SU_DATE_STU50_STU85
!
!
!*======================================================================
!
! 
!
!*======================================================================
!
! 
        SUBROUTINE SU_DATE_CAL_STU50(tv_date,dv_sec50,jv_status)
!
!
!****SU_DATE_CAL_STU50
!
!     Purpose:
!     --------
!       Formattage d'une date calendaire               
!       (i.e jj-mmm-aaaa hh:mm:ss[:tttttt]) sous        
!       la forme date exprimee en secondes dans         
!       le referentiel 01/01/1950 00H00M00S   
! 
!     Input : \\
!     ------
!      \begin{itemize}
!      \item   tv_date : date calendaire (27 caracteres)   
!              (jj-MMM-aaaa hh:mm:ss:tttttt)       
!
!
!     Output : \\
!     dv_sec50  : Nombre de secondes ecoulees depuis le 01-Jan-1950 00:00:00                                      |
!     jv_status : compte rendu d'execution       
!     
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE

      INCLUDE 'su_date_var.h'
!
!**   0.2 Local variables
!   
      
      INTEGER(KIND=4)       ::    jv_ios     ! cr. i/o
      INTEGER(KIND=4)       ::    jc_su_glob_ok
      INTEGER(KIND=4)       ::    jc_su_glob_nok
      CHARACTER(LEN=3)      ::    tv_mois    ! nom du mois courant
      CHARACTER             :: 	  av_sep	 ! caractere separateur dans date
                                                 ! calendaire (lu mais ignore)
      INTEGER(KIND=2)       ::	  ev_annee   ! date calendaire decodees
      INTEGER(KIND=2)       ::	  ev_mois    ! annee/mois/jour 
      INTEGER(KIND=2)       ::	  ev_jour	 ! heure/minute/seconde/microsec.
      INTEGER(KIND=2)       ::    ev_heure   ! en entier
      INTEGER(KIND=2)       ::    ev_minute
      INTEGER(KIND=2)       ::    ev_seconde
      INTEGER(KIND=4)       ::	  jv_mcsec
      LOGICAL(KIND=2)       ::    lv_trouve  ! indicateur nom du mois correct
      PARAMETER     (jc_su_glob_ok  = 0)
      PARAMETER     (jc_su_glob_nok = 1)
!
!**   0.3 Dummy variables 
!
      CHARACTER(LEN=ec_su_date_lg_cal27)       ::	tv_date    ! (E)
      REAL(KIND=8)                             ::     dv_sec50   ! (S)
      INTEGER(KIND=4)                          ::     jv_status  ! (S)
!
!*--------------------------------------------------------------------------
!
!**     INIT. STATUS RETOUR A OK
!**     
      jv_status = jc_su_glob_ok

!**     DEFORMATTAGE DE LA DATE 
!**     (passage en entier de jour,annee,heure,minute,seconde [millisec])
!** 
      read(tv_date,fmt=tc_su_date_form_cal,iostat = jv_ios)ev_jour,av_sep,tv_mois,av_sep,ev_annee,av_sep,& 
           ev_heure,av_sep,ev_minute,av_sep,ev_seconde,av_sep,jv_mcsec

!**     SI ERREUR AU DEFORMATTAGE ALORS
      if (jv_ios .ne. 0) then
      jv_status = jc_su_glob_nok
      goto 9999

!**     FINSI
!**     ----- 
      endif

!**     CONVERSION DU MOIS EN ENTIER ([1...12])
!** 

      lv_trouve = .false.
      ev_mois   = 1

      do while ((ev_mois .le. 12) .and. (.not. lv_trouve))
        if (tv_mois .eq. tk_su_date_nom_mois(ev_mois)) then
           lv_trouve = .true.
        else
           ev_mois = ev_mois + 1
        endif
      enddo

!**     SI CONVERSION INCORRECTE ALORS
!**     --                       -----
      if (.not. lv_trouve) then
         jv_status = jc_su_glob_nok
         goto 9999

!**     FINSI
!**     -----
!
      endif

!**     CALCUL DU NOMBRE DE SECONDES ECOULEES DEPUIS 1950
!**     (CALL SU_DATE_JMAHMSM_STU50)
!** 
      CALL SU_DATE_JMAHMSM_STU50(ev_jour,ev_mois,ev_annee,ev_heure,&
                                  ev_minute,ev_seconde,jv_mcsec,dv_sec50,&
                                  jv_status)

      if (jv_status .ne. jc_su_glob_ok) then
          goto 9999
      endif

9999  continue
    RETURN
      
!
!*--------------------------------------------------------------------------
!
 END SUBROUTINE SU_DATE_CAL_STU50
!
!
!*======================================================================
!
! 
        SUBROUTINE SU_DATE_STU50_CAL(dv_sec50,tv_date,jv_status)
!
!
!****SU_DATE_STU50_CAL
!
!     Purpose:
!     --------
!       Formattage d'une date exprimee en              
!       nombre de secondes ecoulees depuis le          
!       01-Jan-1950 00H00M00S sous forme               
!       calendaire      
! 
!     Input : \\
!     ------
!      \begin{itemize}
!      \item   dv_sec50  : Nombre de secondes ecoulees depuis le 01-Jan-1950 00:00:00 
!
!     Output : \\
!      tv_date : date calendaire (27 caracteres) (jj-MMM-aaaa hh:mm:ss:tttttt)                               |
!      jv_status : compte rendu d'execution    
!     
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE

      INCLUDE 'su_date_var.h'
!
!**   0.2 Local variables
!   

      INTEGER(KIND=4)     ::	jv_ios         ! cr. i/o
      INTEGER(KIND=2)      ::	ev_jour	     ! jour dans le mois
      INTEGER(KIND=2)      ::	ev_mois	     ! numero mois dans l'annee
      INTEGER(KIND=2)      ::	ev_annee       ! annee chretienne
      INTEGER(KIND=2)      ::	ev_heure       ! heure dans le jour
      INTEGER(KIND=2)      ::	ev_minute      ! minutes dans l'heure
      INTEGER(KIND=2)      ::	ev_seconde     ! secondes dans la minuute
      INTEGER(KIND=4)     ::	jv_mcsec       ! microsecondes dans la seconde
      INTEGER(KIND=4)       ::    jc_su_glob_ok
      INTEGER(KIND=4)       ::    jc_su_glob_nok
      PARAMETER     (jc_su_glob_ok  = 0)
      PARAMETER     (jc_su_glob_nok = 1)
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)                        ::  dv_sec50   ! (E)
      CHARACTER(LEN=ec_su_date_lg_cal27)  ::  tv_date    ! (S)
      INTEGER(KIND=4)                     ::  jv_status  ! (S)
!
!*--------------------------------------------------------------------------
!                     
!**     INIT STATUS RETOUR A OK
      jv_status = jc_su_glob_ok

!**     SI  (SEC_50 < 0) ALORS
!**     --               -----
      if (dv_sec50 .lt. 0.d0) then

!**        COMPTE RENDU OPERATION = NOK
!**        ON SORT
         jv_status = jc_su_glob_nok
         goto 9999

!**     FINSI
!**     -----
      endif

!** 
!**     CONVERSION DE LA DATE SOUS LA FORME JOUR MOIS ANNEE HEURE MINUTE
!**     SECONDES MICROSECONDE : CALL SU_DATE_STU50_JMAHMSM
!**                            ----
!** 
      call su_date_stu50_jmahmsm ( dv_sec50,ev_jour,ev_mois,ev_annee,&
                                   ev_heure,ev_minute,ev_seconde,jv_mcsec,&
                                   jv_status)

      if (jv_status .ne. jc_su_glob_ok) then
          goto 9999
      endif

               
!**     FORMATTAGE SOUS FORME ASCII DE LA DATE
!** 
      write(tv_date,fmt = tc_su_date_form_cal,iostat = jv_ios)&
      ev_jour,ac_su_date_sep1,tk_su_date_nom_mois(ev_mois),ac_su_date_sep1,&
      ev_annee,ac_su_date_sep2,ev_heure,ac_su_date_sep3,ev_minute,ac_su_date_sep3,&
      ev_seconde,ac_su_date_sep3,jv_mcsec

      if (jv_ios .ne. 0) then
         jv_status = jc_su_glob_nok
         goto 9999
      endif
 9999 continue

     RETURN
!
!*--------------------------------------------------------------------------
!  
END SUBROUTINE SU_DATE_STU50_CAL
!
!
!*======================================================================
!
        SUBROUTINE SU_DATE_JMLMC_SEC(ev_jour,jv_mlsec,ev_mcsec,dv_sec)
!
!
!****SU_DATE_JMLMC_SEC
!
!     Purpose:
!     --------
!       formattage d'une date exprimee en Jour  
!       julien millisecondes microsecondes sous         
!       la forme d'une date exprimee en                 
!       secondes dans le meme referentiel 
! 
!     Input : \\
!     ------
!      \begin{itemize}
!      \item   ev_jour  : Jour julien  
!      \item   jv_mlsec : Millisecondes
!      \item   ev_mcsec : Microsecondes
!
!     Output : \\
!      dv_sec    : date exprimee en secondes
!     
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE
!
!**   0.2 Local variables
!   
!
!**   0.3 Dummy variables 
!
      INTEGER(KIND=2)      ::	     ev_jour    ! (E)
      INTEGER(KIND=4)     ::      jv_mlsec   ! (E)
      INTEGER(KIND=2)      ::      ev_mcsec   ! (E)
      REAL(KIND=8)    ::	     dv_sec     ! (S)
!
!*--------------------------------------------------------------------------
!
!**     CALCUL DU NOMBRE DE SECONDES ECOULEES DEPUIS LA REFERENCE
!**     SEC = JOUR * 86400 + MLSEC/1.D3 + MCSEC/1.D6 

      dv_sec = DBLE(ev_jour)  * 86400.D0 + DBLE(jv_mlsec) / 1.D3 + DBLE(ev_mcsec) / 1.D6  

!**    FIN SU_DATE_JMLMC_SEC
!**     ---------------------

9999  continue

      RETURN
!
!*--------------------------------------------------------------------------
!  
END SUBROUTINE SU_DATE_JMLMC_SEC
!
!
!*======================================================================
!
        SUBROUTINE  SU_DATE_SEC_JMLMC(dv_sec,ev_jour,jv_mlsec,ev_mcsec)
!
!
!**** SU_DATE_SEC_JMLMC
!
!     Purpose:
!     --------
!       Formattage d'une date exprimee en Secondes 
!       reelles sous la forme Jour Millisecondes      
!       Microsecondes dans le meme referentiel
! 
!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec    : date exprimee en secondes                                 
!
!     Output : \\
!     ev_jour  : Jour julien                                               
!     jv_mlsec : Millisecondes                                             
!     ev_mcsec : Microsecondes                                             
!     
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE
!
!**   0.2 Local variables
!   
      REAL(KIND=8)    ::         dv_trav        ! variable de travail#
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)    ::	     dv_sec     ! (E)
      INTEGER(KIND=2)      ::	     ev_jour    ! (S)
      INTEGER(KIND=4)     ::      jv_mlsec   ! (S)
      INTEGER(KIND=2)      ::      ev_mcsec   ! (S)
!     
!*--------------------------------------------------------------------------
!
      ev_jour  = INT(dv_sec / 86400.D0)
      dv_trav  = (dv_sec - (dble(ev_jour) * 86400.D0)) * 1.D3
      jv_mlsec = int(dv_trav)
      dv_trav  = (dv_trav - dble(jv_mlsec))* 1.D3
      ev_mcsec = nint(dv_trav)

      RETURN

       RETURN
!
!*--------------------------------------------------------------------------
!  
END SUBROUTINE SU_DATE_SEC_JMLMC
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_JSMC_SEC(jv_jour,jv_sec,jv_mcsec,dv_sec)
!
!
!****SU_DATE_JSMC_SEC
!
!     Purpose:
!     --------
!       Formattage d'une date exprimee en Jour         
!       julien secondes microsecondes sous              
!       la forme d'une date exprimee en                 
!       secondes dans le meme referentiel
!
!     Input : \\
!     ------
!      \begin{itemize}
!      \item jv_jour  : Jour julien                                               
!      \item jv_sec   : Secondes                                                  
!      \item jv_mcsec : Microsecondes                                             
!
!     Output : \\
!    dv_sec    : date exprimee en secondes                                 
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE
!
!**   0.2 Local variables
!   
!
!**   0.3 Dummy variables 
!
      INTEGER(KIND=4)     ::	  jv_jour    ! (E)
      INTEGER(KIND=4)     ::      jv_sec     ! (E)
      INTEGER(KIND=4)     ::      jv_mcsec   ! (E)
      REAL(KIND=8)        ::	  dv_sec     ! (S)
!      
!*--------------------------------------------------------------------------
!

!**     CALCUL DU NOMBRE DE SECONDES ECOULEES DEPUIS LA REFERENCE
!**     SEC = JOUR * 86400 + SEC + MCSEC/1.D6 

      dv_sec = DBLE(jv_jour)  * 86400.D0 + DBLE(jv_sec) +  DBLE(jv_mcsec) / 1.D6  

9999  continue

    RETURN
!      
!*--------------------------------------------------------------------------
!
END SUBROUTINE SU_DATE_JSMC_SEC
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_SEC_JSMC(dv_sec,jv_jour,jv_sec,jv_mcsec)
!
!
!****SU_DATE_SEC_JSMC
!
!     Purpose:
!     --------
!     Formattage d'une date exprimee en Secondes     
!     reelles sous la forme Jour Secondes             
!     Microsecondes dans le meme referentiel.

!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec    : date exprimee en secondes                        
!
!     Output : \\
!     jv_jour  : Jour julien                                               
!     jv_sec   : Secondes                                                  
!     jv_mcsec : Microsecondes                                      
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE
!
!**   0.2 Local variables
!   
      REAL(KIND=8)    ::         dv_trav        ! variable de travail
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)    ::	  dv_sec     ! (E)
      INTEGER(KIND=4)     ::	  jv_jour    ! (S)
      INTEGER(KIND=4)     ::      jv_sec     ! (S)
      INTEGER(KIND=4)     ::      jv_mcsec   ! (S)
!    
!*--------------------------------------------------------------------------
!
      jv_jour  = INT(dv_sec / 86400.D0)
      dv_trav  = dv_sec - (dble(jv_jour) * 86400.D0)
      jv_sec   = INT(dv_trav)
      dv_trav  = (dv_trav - dble(jv_sec))* 1.D6
      jv_mcsec = NINT(dv_trav)

9999  continue
    RETURN
!     
!*--------------------------------------------------------------------------
!     
END SUBROUTINE SU_DATE_SEC_JSMC
!
!
!*======================================================================
!     
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_STU50_JMAHMSM (dv_sec50,ev_jour,ev_mois,ev_annee,ev_heure,&
                                ev_minute,ev_seconde,jv_mcsec,jv_status)  

!
!
!****SU_DATE_STU50_JMAHMSM
!
!     Purpose:
!     --------
!     Formattage d'une date exprimee en            
!     nombre de secondes ecoulees depuis le          
!     01-Jan-1950 00:00:00 sous la forme             
!     Jour,Mois,Annee,Heure,Minutes,Secondes         
!     Microsecondes exprimes en entier 
!
!     Input : \\
!     ------
!      \begin{itemize}
!      \item  dv_sec50 : Nombre de secondes ecoulees depuis le 01-Jan-1950         
!                        00:00:00
!
!     Output : \\
!    ev_jour   : Jour          (1<= jour <=31)                             
!    ev_mois   : Mois          (1<= mois <= 12)                            
!    ev_annee  : Annee         ( > 1900)                                   
!    ev_heure  : Heure         (0 <= heure <= 23)                          
!    ev_minute : Minute        (0 <= minute <= 59)                         
!    ev_seconde: Secondes      (0 <= seconde <= 59)                       
!    jv_mcsec  : Microsecondes (0 <= mcsec < 999999)                       
!    jv_status : compte rendu d'execution
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE
      INCLUDE 'su_date_var.h'

!
!**   0.2 Local variables
!      
      INTEGER(KIND=4)     ::       jc_su_glob_ok
      PARAMETER     (jc_su_glob_ok  = 0)
      INTEGER(KIND=4)     :: jc_su_glob_nok
      PARAMETER    (jc_su_glob_nok = 1)

      INTEGER(KIND=4)     ::	jv_nb_jours	     ! nombre de jours ecoules
      INTEGER(KIND=4)     ::	jv_nb_annees	     ! nombre d'annees ecoulees

      INTEGER(KIND=2)     ::	ev_nb_annees_bis    ! nombre d'annees bissextiles
      INTEGER(KIND=2)     ::	ev_ind_bis          ! indic. annee bissextile

      REAL(KIND=8)    ::	dv_trav		     ! variable de travail

!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)         ::	dv_sec50   ! (E)
      INTEGER(KIND=2)      ::	ev_jour    ! (S)
      INTEGER(KIND=2)      ::	ev_mois	 ! (S)
      INTEGER(KIND=2)      ::	ev_annee   ! (S)
      INTEGER(KIND=2)      ::	ev_heure   ! (S)
      INTEGER(KIND=2)      ::	ev_minute  ! (S)
      INTEGER(KIND=2)      ::	ev_seconde ! (S)
      INTEGER(KIND=4)      ::	jv_mcsec   ! (S)
      INTEGER(KIND=4)      ::	jv_status  ! (S)
!     
!*--------------------------------------------------------------------------
!     

!**    INIT. STATUS RETOUR A OK
!     
      jv_status = jc_su_glob_ok

!**     SI  (SEC_50 < 0) ALORS
!**     --               -----
      if (dv_sec50 .lt. 0.d0) then

!**        COMPTE RENDU OPERATION = NOK
!**        ON SORT
         jv_status = jc_su_glob_nok
         goto 9999

!**     FINSI
!**    -----
      endif
!** 
!**     CALCUL DU NOMBRE DE JOURS ECOULEES DEPUIS 1950
! 
      jv_nb_jours = INT (dv_sec50 / 86400.D0)

!**     CALCUL HEURE
! 
      dv_trav  = dv_sec50 - DBLE(jv_nb_jours) * 86400.D0
      ev_heure = INT(dv_trav / 3600.D0)

!**     CALCUL MINUTE
! 
      dv_trav   = dv_trav - DBLE(ev_heure) * 3600.D0
      ev_minute = INT(dv_trav / 60.D0)

!**     CALCUL SECONDE
! 
      dv_trav    = dv_trav - DBLE(ev_minute) * 60.D0
      ev_seconde = INT(dv_trav)

!**     CALCUL MICROSECONDES
! 
      dv_trav  = (dv_trav - DBLE(ev_seconde)) * 1.D6
      jv_mcsec = NINT(dv_trav)

!**     AJUSTEMENT NB_JOURS HEURE MINUTE SECONDE SI LE NOMBRE
!**     DE MICROSECONDES CALCULEES EST >= 1.D6
! 
      if (jv_mcsec .ge. 1000000) then
         jv_mcsec = jv_mcsec - 1000000
         ev_seconde = ev_seconde + 1
         if (ev_seconde .ge. 60) then
             ev_seconde = ev_seconde - 60
             ev_minute  = ev_minute + 1
             if (ev_minute .ge. 60) then
                ev_minute = ev_minute - 60
                ev_heure  = ev_heure + 1
                if (ev_heure .ge. 24) then
                    ev_heure = ev_heure - 24
                    jv_nb_jours = jv_nb_jours + 1
                endif
             endif
          endif
      endif

!**     CALCUL NOMBRE D'ANNEES ECOULEES DEPUIS 1950
! 
      dv_trav      = DBLE(jv_nb_jours)
      jv_nb_annees = INT((dv_trav + 0.5) / 365.25)

!**     CALCUL ANNEE 
! 
      ev_annee = jv_nb_annees + 1950

!**    CALCUL DU NOMBRE D'ANNEES BISSEXTILES PASSEES DEPUIS 1950
! 
      ev_nb_annees_bis =  (ev_annee-1 -1900) / 4 - 12

!**     Test si annee courante bissextile
!**     ind_bis = 1 -> annee courante bissextile
!**    ind_bis = 2 -> sinon
      ev_ind_bis = MIN (MOD(ev_annee,4) + 1, 2)

!**     CALCUL DU NOMBRE DE JOURS ECOULES DANS L'ANNEE
!** 
      jv_nb_jours = jv_nb_jours - (jv_nb_annees * 365) - ev_nb_annees_bis + 1
!
!**     CALCUL NO DU MOIS DANS L'ANNEE
! 
      ev_mois = 1

      do while ((ev_mois .LE. 12) .and.&
       (jv_nb_jours .GT. ek_su_date_quant(ev_mois,ev_ind_bis)))
            ev_mois = ev_mois + 1
      enddo

      ev_mois = ev_mois - 1


!**     CALCUL DU NUMERO DU JOURS DANS LE MOIS
 
      ev_jour = jv_nb_jours -  ek_su_date_quant(ev_mois,ev_ind_bis)

 9999 continue
      RETURN
!     
!*--------------------------------------------------------------------------
!        
END SUBROUTINE SU_DATE_STU50_JMAHMSM
!
!
!*======================================================================
!     
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_JMAHMSM_STU50(ev_jour,  &
                                  ev_mois,  &
                                  ev_annee ,&
                                  ev_heure, &
                                  ev_minute,&
                                  ev_seconde,&
                                  jv_mcsec, &
                                  dv_sec50, &
                                  jv_status  )

!
!
!****SU_DATE_JMAHMSM_STU50
!
!     Purpose:
!     --------
!     Formattage d'une date exprimee en            
!     Jour,Mois,Annee,Heure,Minutes,Secondes         
!     Microsecondes (entiers) en nombre de           
!     secondes ecoulees depuis le 1/1/1950
!
!     Input : \\
!     ------
!     \begin{itemize}
!     \item   ev_jour   : Jour          (1<= jour <=31)                             
!     \item ev_mois   : Mois          (1<= mois <= 12)                            
!     \item ev_annee  : Annee         ( > 1900)                                   
!     \item ev_heure  : Heure         (0 <= heure <= 23)                          
!     \item ev_minute : Minute        (0 <= minute <= 59)                         
!     \item ev_seconde: Secondes      (0 <= seconde <= 59)                        
!     \item jv_mcsec  : Microsecondes (0 <= mcsec < 999999)                       
!                                   
!
!     Output : \\
!     dv_sec50  : Nombre de secondes ecoulees depuis le                     
!                   01-Jan-1950 00:00:00                                      
!     jv_status : compte rendu d'execution   
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!
      IMPLICIT NONE
      INCLUDE 'su_date_var.h'

!
!**   0.2 Local variables
!   
      INTEGER(KIND=4)     ::       jc_su_glob_ok
      PARAMETER     (jc_su_glob_ok  = 0)
      INTEGER(KIND=4)     :: jc_su_glob_nok
      PARAMETER    (jc_su_glob_nok = 1)
      INTEGER(KIND=4)     ::	jv_nb_annees ! nombre d'annees ecoulees depuis 1950
      INTEGER(KIND=4)     ::	jv_nb_annbis ! nombre d'annees bissextiles
      INTEGER(KIND=4)     ::	jv_nb_jours  ! nbre de jours ecoules depuis 1950
      INTEGER(KIND=4)     ::	jv_ind_bis   ! indicateur annee courante
!
!**   0.3 Dummy variables 
!
      INTEGER(KIND=2)      ::	ev_jour    ! (E)
      INTEGER(KIND=2)      ::	ev_mois	   ! (E)
      INTEGER(KIND=2)      ::	ev_annee   ! (E)
      INTEGER(KIND=2)      ::	ev_heure   ! (E)
      INTEGER(KIND=2)      ::	ev_minute  ! (E)
      INTEGER(KIND=2)      ::	ev_seconde ! (E)
      INTEGER(KIND=4)     ::	jv_mcsec   ! (E)   
      INTEGER(KIND=4)     ::	jv_status  ! (S)
      REAL(KIND=8)        ::	dv_sec50   ! (S)
!     
!*--------------------------------------------------------------------------
!   

!**     INIT. STATUS RETOUR A OK
!     
      jv_status = jc_su_glob_ok

!**     SI MOIS  INCORRECT ALORS
!**     --                  -----
      if ((ev_mois .lt. 1) .or. (ev_mois .gt. 12)) then

!**        STATUS RETOUR = NOK
!**        GOTO FIN
!**        ----
         jv_status = jc_su_glob_nok
         goto 9999

!**     FINSI
!**     -----
! 
      endif


!**     CALCUL DU NOMBRE DE JOURS ECOULES DEPUIS 1950 ET LA FIN DE
!**     L'ANNEE PRECEDENTE
! 

!**    Nombre d'annees ecoulees 
      jv_nb_annees = ev_annee - 1950

!**     Nombre d'annees bissextiles depuis 1950
      jv_nb_annbis = (ev_annee-1 -1900 ) / 4 - 12

      jv_nb_jours = (jv_nb_annees * 365) + jv_nb_annbis

!**     CALCUL DU NOMBRE DE JOURS ECOULES DEPUIS LE DEBUT DE L'ANNEE
! 

!**     on regarde si l'annee courante est une annee bissextile
!**     jv_ind_bis = 1 annee bissextile
!**     jv_ind_bis = 2 annee non bissextile

      jv_ind_bis = MIN (MOD(ev_annee,4) + 1 , 2)

      jv_nb_jours = jv_nb_jours +ek_su_date_quant(ev_mois,jv_ind_bis) + ev_jour - 1

!**    CALCUL DU NOMBRE DE SECONDES ECOULEES DEPUIS 1950
! 
      dv_sec50 = DBLE(jv_nb_jours) * 86400.D0 +&
                 DBLE(ev_heure)    * 3600.D0  +&
                 DBLE(ev_minute)   * 60.D0    +&
                 DBLE(ev_seconde)             +&
                 DBLE(jv_mcsec)    / 1.D6

9999  continue

      RETURN
!     
!*--------------------------------------------------------------------------
!     
END SUBROUTINE SU_DATE_JMAHMSM_STU50
!
!
!*======================================================================
!     
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_SEC_SMC (dv_sec,jv_sec,jv_mcsec) 
!
!
!****SU_DATE_SEC_SMC
!
!     Purpose:
!     --------
!     Formattage d'une date exprimee en            
!     secondes dans un reel sous la forme            
!     d'une date exprimee en secondes/               
!     microsecondes (dans 2 entiers) dans le         
!     meme referentiel
!
!     Input : \\
!     ------
!     \begin{itemize}
!     \item   dv_sec    : Secondes reelles
!
!     Output : \\
!      jv_sec    : Secondes                                                  
!      jv_mcsec  : Microsecondes                                             
!                     
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!     
      IMPLICIT NONE
!
!**   0.2 Local variables
!   
!
!**   0.3 Dummy variables 
!
      REAL(KIND=8)        ::	dv_sec       ! (E)
      INTEGER(KIND=4)     :: jv_sec       ! (S)
      INTEGER(KIND=4)     :: jv_mcsec     ! (S)  
!     
!*--------------------------------------------------------------------------
!     
!**     CALCUL NBRE DE SECONDES ENTIERES: IS = INT(SEC)
! 
      jv_sec = int(dv_sec)

!**     CALCUL NBRE DE MICROSECONDES: MS = NINT((SEC - IS) * 1.D6)
!**     SI MS >= 1000000 ALORS
!**     --               -----
!**        MS = MS - 1000000
!**        IS = IS + 1
!**   FINSI
!**     -----
! 
      jv_mcsec = nint( (dv_sec - dble(jv_sec)) * 1.D6)
      if (jv_mcsec .ge. 1000000) then
         jv_mcsec = jv_mcsec - 1000000
         jv_sec   = jv_sec + 1
      endif

 9999 continue
      RETURN
!     
!*--------------------------------------------------------------------------
! 
END SUBROUTINE SU_DATE_SEC_SMC
!
!
!*======================================================================
!     
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_SMC_SEC(jv_sec,jv_mcsec,dv_sec)
!
!**** SU_DATE_SMC_SEC
!
!     Purpose:
!     --------
!     
!     Formattage d'une date exprimee en           
!     secondes (dans un entier) et en micro-         
!     secondes dans la seconde (dans un              
!     entier) sous la forme d'une date               
!     exprimee en secondes (dans un reel)            
!     dans le meme referentiel.
!
!     Input : \\
!     ------
!     \begin{itemize}
!     \item     jv_sec    : Secondes                                                  
!      \item    jv_mcsec  : Microsecondes   
! 
!     Output : \\
!      dv_sec    : Secondes reelles                                          
!                     
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!     
      IMPLICIT NONE
!
!**   0.2 Local variables
!   
!
!**   0.3 Dummy variables 
      INTEGER(KIND=4)     :: jv_sec         ! (E)
      INTEGER(KIND=4)     :: jv_mcsec       ! (E)
      REAL(KIND=8)        :: dv_sec         ! (S)
!     
!*--------------------------------------------------------------------------
! 
!**     CALCUL NBRE DE SECONDES RELLE: DS = IS + MS / 1.D6
!**     (IS = SECONDES , MS = MICROSECONDES)
!* 
      dv_sec = dble(jv_sec) + (dble(jv_mcsec) / 1.D6)

 9999 continue
!     
!*--------------------------------------------------------------------------
!     
END SUBROUTINE  SU_DATE_SMC_SEC
!
!
!*======================================================================
!     
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_JMA_QUANT(jv_jour,jv_mois,jv_annee,jv_quant,jv_status )
!
!**** SU_DATE_JMA_QUANT
!
!     Purpose:
!     --------
!     
!     Calcul du quantieme (i.e. nombre de jours ecoulees depuis le debut de l'annee)
!
!     Input : \\
!     ------
!     \begin{itemize}
!     \item  jv_jour      : Jour dans le mois (1...31)                       
!     \item  jv_mois      : Mois dans l'annee (1...12)                       
!     \item  jv_annee     : Annee ( > 1900)                                                  
! 
!     Output : \\
!     jv_quant  : Quantieme (1...366)                                
!     jv_status : compte rendu d'execution                           
!                     
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!     
      IMPLICIT NONE
      INCLUDE 'su_date_var.h'
!
!**   0.2 Local variables
!   
      INTEGER(KIND=4)          ::       jc_su_glob_ok
       PARAMETER     (jc_su_glob_ok  = 0)

      INTEGER(KIND=4)          :: jc_su_glob_nok
      PARAMETER    (jc_su_glob_nok = 1)
      INTEGER(KIND=4)          :: jv_ind_bis    ! Indicateur annee bissextile
                                      ! 1 : oui ; 2 : non
      INTEGER(KIND=4)          :: jv_jour1      ! Nombre de jours precedent
                                  ! le mois passe en parametre 
!
!**   0.3 Dummy variables 
!

      INTEGER(KIND=4)          ::	jv_jour	       ! Jour
      INTEGER(KIND=4)          ::	jv_mois	       ! Mois
      INTEGER(KIND=4)          ::	jv_annee         ! Annee
      INTEGER(KIND=4)          ::	jv_quant       ! Quantieme
      INTEGER(KIND=4)          ::	jv_status      ! status de l'operation

!     
!*--------------------------------------------------------------------------
!     
!**   INIT. STATUS RETOUR A OK
!    
      jv_status = jc_su_glob_ok

!**    CALCUL QUANTIEME
!**     QUANT = JOUR1 + JOUR
!**     JOUR1 = NOMBRE DE JOURS ECOULE AVANT LE MOIS PASSE EN PARAMETRE
!**     JOUR  = JOUR DANS LE MOIS (PARAMETRE)
!
      if ((jv_mois .lt. 1) .or. (jv_mois .gt. 12)) then
         jv_status = jc_su_glob_nok
      else
!**        test si Annee bissextile
         jv_ind_bis = MIN (MOD(jv_annee,4) + 1 , 2)
         jv_jour1 = ek_su_date_quant(jv_mois,jv_ind_bis)
         jv_quant = jv_jour1 + jv_jour
      endif

!**   FIN SU_DATE_JMA_QUANT
!**    --------------------- 
      RETURN
!     
!*--------------------------------------------------------------------------
!
END SUBROUTINE SU_DATE_JMA_QUANT
!
!
!*======================================================================
!     
!
!
!*======================================================================
!     
!
 SUBROUTINE SU_DATE_A_QUANT_JM(jv_quant  ,&
                               jv_annee  ,&
                               jv_jour   ,&
                               jv_mois   ,&
                               jv_status ) 
!
!**** SU_DATE_A_QUANT_JM
!
!     Purpose:
!     --------
!     
!     Calcul du mois et du jour a partir du quantieme            
!     (i.e. nombre de jours ecoulees depuis le debut de l'annee)
!
!     Input : \\
!     ------
!     \begin{itemize}
!     \item   jv_quant     : Quantieme (1...366)                              
!      \item  jv_annee     : Annee ( > 1900)                                  
! 
!     Output : \\
!    jv_jour   : Jour dans le mois (1...31)                         
!    jv_mois   : Mois dans l'annee (1...12)                         
!    jv_status : compte rendu d'execution                           
!                     
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!     
      IMPLICIT NONE
      INCLUDE 'su_date_var.h'
!
!**   0.2 Local variables
!   
     INTEGER(KIND=4)           ::	jv_ind_bis    ! Indicateur annee bissextile
     INTEGER(KIND=4)           ::       jc_su_glob_ok
     PARAMETER     (jc_su_glob_ok  = 0)

     INTEGER(KIND=4)           :: jc_su_glob_nok
     PARAMETER    (jc_su_glob_nok = 1)
                                 ! 1 : oui ; 2 : non
!
!**   0.3 Dummy variables 
!
      INTEGER(KIND=4)    ::	jv_quant       ! Quantieme
      INTEGER(KIND=4)    ::	jv_annee       ! Annee
      INTEGER(KIND=4)    ::	jv_jour	       ! Jour
      INTEGER(KIND=4)    ::	jv_mois	       ! Mois
      INTEGER(KIND=4)    ::	jv_status      ! status de l'operation
!     
!*--------------------------------------------------------------------------

!**  INIT. STATUS RETOUR A OK
!     
      jv_status = jc_su_glob_ok

      if ((jv_quant .lt. 1) .or. (jv_quant .gt. 366 )) then
         jv_status = jc_su_glob_nok
      else
!**  test si Annee bissextile
         jv_ind_bis = MIN (MOD(jv_annee,4) + 1 , 2)
!**  recherche du mois
         jv_mois = 12
         DO WHILE ( jv_mois .GT. 0 .AND.&
            jv_quant .LE. ek_su_date_quant(jv_mois,jv_ind_bis) )
            jv_mois = jv_mois - 1
         ENDDO

         jv_jour = jv_quant - ek_su_date_quant(jv_mois,jv_ind_bis)
      endif         

      RETURN
!     
!*--------------------------------------------------------------------------
!     
END SUBROUTINE SU_DATE_A_QUANT_JM
!
!
!*======================================================================
!     
    SUBROUTINE SU_DATE_CAL_STU50_2(ndastp,jul)
!
!**** SU_DATE_CAL_STU50_2
!
!     Purpose:
!     --------
!     
!     Conversion d'une date exprimee sous forme calendaire (anneemoisjours) sous         
!     la forme d'une date exprimee en nombre de jours ecoules       
!     depuis le 01-Jan 1950 00:00:00
!
!     Input : \\
!     ------
!     \begin{itemize}
!     \item  ndastp date calendaire (15 caracteres)                             
!
!     Output : \\
!     dv_sec50  : jul Nombre de jours ecoules depuis le                     
!                01-Jan-1950 00:00:00                             
!                     
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!     
     IMPLICIT NONE 

!
!**   0.2 Local variables
!   
     INTEGER :: ndastp
     REAL    :: jul

!
!**   0.3 Dummy variables 
!
     INTEGER,PARAMETER  :: nh=0, nmin=0, nsec=0
     INTEGER(KIND=2)   ::       ny,nm,nd
     INTEGER(KIND=4)   ::	jv_nb_annees ! nombre d'annees ecoulees 1950
     INTEGER(KIND=4)   ::       jv_nb_annbis ! nombre d'annees bissextiles
     INTEGER(KIND=4)   ::	jv_nb_jours  ! nbre de jours ecoules depuis 1950
     INTEGER(KIND=4)   ::	jv_ind_bis   ! indicateur annee courante
     
     INTEGER(KIND=2),DIMENSION(12,2):: ek_su_date_quant
     DATA ek_su_date_quant  /0,31,60,91,121,152,182,213,244,274,305,335,&
                             0,31,59,90,120,151,181,212,243,273,304,334/
!   
!*--------------------------------------------------------------------------
!
!**    Recherche de l'année mois et jour
     ny   = int(ndastp/10000)
     nm   = int((ndastp - ny*10000)/100)
     nd   = ndastp - ny*10000 - nm*100

!**    TEST si le mois est incorrect  
     IF ((nm .lt. 1) .or. (nm .gt. 12)) THEN 
         print *,'Mois incorrect ' 
         STOP
     ENDIF


!**    CALCUL DU NOMBRE DE JOURS ECOULES DEPUIS 1950 ET LA FIN DE
!**     L'ANNEE PRECEDENTE
      
!**     Nombre d'annees ecoulees 
      jv_nb_annees= ny-1950


!**     Nombre d'annees bissextiles depuis 1950
      jv_nb_annbis = (ny-1 -1900 ) / 4 - 12
      jv_nb_jours = (jv_nb_annees * 365) + jv_nb_annbis


!**    CALCUL DU NOMBRE DE JOURS ECOULES DEPUIS LE DEBUT DE L'ANNEE

!**     on regarde si l'annee courante est une annee bissextile
!**     jv_ind_bis = 1 annee bissextile
!**     jv_ind_bis = 2 annee non bissextile

      jv_ind_bis = MIN (MOD(ny,4) + 1 , 2)

      jv_nb_jours = jv_nb_jours + ek_su_date_quant(nm,jv_ind_bis) + nd - 1

      jul=jv_nb_jours

!   
!*--------------------------------------------------------------------------
!
      END SUBROUTINE SU_DATE_CAL_STU50_2
!
!*======================================================================
!     
!
!*======================================================================
!     
    SUBROUTINE SU_DATE_STU50_CAL_2(dv_sec50,tv_date)
!
!**** 
!
!     Purpose:
!     --------
!     Conversion d'une date exprimee en nombre de secondes              
!     ecoulees depuis le 01-Jan-1950 00:00:00 en une date               
!     exprimee sous la forme calendaire      
!     issu de SU_DATE_STU50_CAL & su_date_SU_DATE_STU50_JMAHMSM dans su_date.f    
!     (CLS) voir F. Hernandez   
!     Input : \\
!     ------
!     \begin{itemize}
!     \item dv_sec50 : Nombre de secondes ecoulees depuis le 01-Jan-1950 00:00:00                             
!
!     Output : \\
!     tv_date : date calendaire (15 caracteres)                            
!                  (jjaaaaMMMjjhhmmss)                
!
!***  Method:
!     -------
!
!     Externals:
!     ----------
!     History:
!     --------
!      Version    Programmer      Date            Description
!      -------    ----------      ----            -----------
!      1.0        P.Sicard        14 Avril 1995   Machine for CLS Space Oceanography Group 
!      1.1        C.REGNIER        Mars 2007      Revision in Fortran 90
!*--------------------------------------------------------------------------
!
!
!**   0. DECLARATIONS
!        ------------
!
!**   0.1 Include files and modules
!     
     IMPLICIT NONE 

!
!**   0.2 Local variables
!   
      INTEGER(KIND=2)	              :: ev_jour    ! (S)
      INTEGER(KIND=2)	              :: ev_mois	 ! (S)
      INTEGER(KIND=2)                 :: ev_annee   ! (S)
      INTEGER(KIND=2)	              :: ev_heure   ! (S)
      INTEGER(KIND=2)	              :: ev_minute  ! (S)
      INTEGER(KIND=2)	              :: ev_seconde ! (S)
      INTEGER(KIND=4)	              :: jv_mcsec   ! (S)
      INTEGER(KIND=4)                 :: jv_status,jv_ios  ! (S)
      INTEGER(KIND=4)	              :: jv_nb_jours	     ! nombre de jours ecoules
      INTEGER(KIND=4)	              :: jv_nb_annees	     ! nombre d'annees ecoulees

      INTEGER(KIND=2)	              :: ev_nb_annees_bis    ! nombre d'annees bissextiles
      INTEGER(KIND=2)	              :: ev_ind_bis          ! indic. annee bissextile
      REAL(KIND=8)                    :: dv_trav	       ! variable de travail
      INTEGER(KIND=2),DIMENSION(12,2) :: ek_su_date_quant

      INTEGER(KIND=2)                 :: ec_su_date_lg_cal15
      PARAMETER (ec_su_date_lg_cal15=15)
      CHARACTER(LEN=29)              :: tc_su_date_form_cal
      DATA tc_su_date_form_cal /'(I4.4,A3,I2.2,I2.2,I2.2,I2.2)'/ 
      DATA ek_su_date_quant  /0,31,60,91,121,152,182,213,244,274,305,335,&
                             0,31,59,90,120,151,181,212,243,273,304,334/
      CHARACTER(LEN=3),DIMENSION(12)     ::	tk_su_date_nom_mois
      DATA tk_su_date_nom_mois /'JAN','FEB','MAR','APR','MAY','JUN',&
     &                          'JUL','AUG','SEP','OCT','NOV','DEC'/
!
!**   0.3 Dummy variables 
!   

    CHARACTER(LEN=ec_su_date_lg_cal15) :: tv_date    ! (S)
    REAL       	              :: dv_sec50   ! (E)
!    
!*--------------------------------------------------------------------------
!
!**    TEST d'entree
      IF (dv_sec50 .lt. 0.d0) stop
! 
!**     CALCUL DU NOMBRE DE JOURS ECOULEES DEPUIS 1950
! 
      jv_nb_jours = INT (dv_sec50 / 86400.D0)

!**     CALCUL HEURE
 
      dv_trav  = dv_sec50 - DBLE(jv_nb_jours) * 86400.D0
      ev_heure = INT(dv_trav / 3600.D0)

!**     CALCUL MINUTE
! 
      dv_trav   = dv_trav - DBLE(ev_heure) * 3600.D0
      ev_minute = INT(dv_trav / 60.D0)

!**     CALCUL SECONDE
! 
      dv_trav    = dv_trav - DBLE(ev_minute) * 60.D0
      ev_seconde = INT(dv_trav)

!**     CALCUL MICROSECONDES
! 
      dv_trav  = (dv_trav - DBLE(ev_seconde)) * 1.D6
      jv_mcsec = NINT(dv_trav)

!**     AJUSTEMENT NB_JOURS HEURE MINUTE SECONDE SI LE NOMBRE
!**     DE MICROSECONDES CALCULEES EST >= 1.D6
! 
      if (jv_mcsec .ge. 1000000) then
         jv_mcsec = jv_mcsec - 1000000
         ev_seconde = ev_seconde + 1
         if (ev_seconde .ge. 60) then
             ev_seconde = ev_seconde - 60
             ev_minute  = ev_minute + 1
             if (ev_minute .ge. 60) then
                ev_minute = ev_minute - 60
                ev_heure  = ev_heure + 1
                if (ev_heure .ge. 24) then
                    ev_heure = ev_heure - 24
                    jv_nb_jours = jv_nb_jours + 1
                endif
             endif
          endif
      endif

!**     CALCUL NOMBRE D'ANNEES ECOULEES DEPUIS 1950
! 
      dv_trav      = DBLE(jv_nb_jours)
      jv_nb_annees = INT((dv_trav + 0.5) / 365.25)

!**     CALCUL ANNEE 
 
      ev_annee = jv_nb_annees + 1950

!**     CALCUL DU NOMBRE D'ANNEES BISSEXTILES PASSEES DEPUIS 1950
! 
      ev_nb_annees_bis =  (ev_annee-1 -1900) / 4 - 12

!**     Test si annee courante bissextile
!**     ind_bis = 1 -> annee courante bissextile
!**     ind_bis = 2 -> sinon
      ev_ind_bis = MIN (MOD(ev_annee,4) + 1, 2)

!**     CALCUL DU NOMBRE DE JOURS ECOULES DANS L'ANNEE
! 
      jv_nb_jours = jv_nb_jours - (jv_nb_annees * 365) - ev_nb_annees_bis + 1

!**     CALCUL NO DU MOIS DANS L'ANNEE
!
      ev_mois = 1

      do while ((ev_mois .LE. 12) .and.(jv_nb_jours .GT. ek_su_date_quant(ev_mois,ev_ind_bis)))
            ev_mois = ev_mois + 1
      enddo

      ev_mois = ev_mois - 1

!**     CALCUL DU NUMERO DU JOURS DANS LE MOIS
! 
      ev_jour = jv_nb_jours -  ek_su_date_quant(ev_mois,ev_ind_bis)
!**      print *,'annee, mois,jj,h,min,s',ev_annee,tk_su_date_nom_mois(ev_mois),ev_jour,ev_heure,ev_minute,ev_seconde

!**     FORMATTAGE SOUS FORME ASCII DE LA DATE
 
     write(tv_date,fmt=tc_su_date_form_cal,iostat = jv_ios) ev_annee,tk_su_date_nom_mois(ev_mois),ev_jour,ev_heure,ev_minute,ev_seconde
     !IF(iostat/= 0) stop "Problème à l'ecriture de la date"
    ! write(6,fmt=tc_su_date_form_cal) ev_annee,tk_su_date_nom_mois(ev_mois),ev_jour,ev_heure,ev_minute,ev_seconde    
!    
!*--------------------------------------------------------------------------
!

  END SUBROUTINE SU_DATE_STU50_CAL_2
!
!*======================================================================
!     
!

END MODULE SU_DATE
