MODULE STATS

  !*======================================================================
  !                       ***  MODULE Moyenne  ***
  !         Ce module réalise des stats sur des series temporelles            *
  !                                                                           *
  !                                                                           *
  !======================================================================


  IMPLICIT NONE
  PRIVATE nrerror
  PUBLIC avevarsdev,moment,corre,rms_1field,rms_2fields,find,correl,autocorre

CONTAINS
  !
!  SUBROUTINE avevarsdev(rda_data,rd_ave,rd_sdev,rd_var)
  SUBROUTINE avevarsdev(rda_data,rd_ave,rd_sdev)
    !
    !**** avevarsdev
    !
    !     Purpose:
    !     --------
    !       Pour une serie temporelle donnée, cette routine retourne sa moyenne
    !       son ecart type, sa variance 
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item il_n : nombre de données 
    !      \item rda_data : vecteur de données 
    ! 
    !     Output : \\
    !      \item rd_ave : moyenne
    !      \item rd_sdev : ecart type 
    !      \item rd_var : variance
    !***  Method:
    !     -------
    !     Externals:
    !     ----------
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !      1.0        C.REGNIER        Mai 2007      Issu de Numerical Recipies
    !*--------------------------------------------------------------------------
    !
    USE nrtype
    IMPLICIT NONE
    !
    !**   0. DECLARATIONS
    INTEGER(KIND=4)                       :: il_n
    REAL(SP),DIMENSION(:),ALLOCATABLE     :: rl_s
    !
    !**   0.3 Dummy variables
    !
    REAL(KIND=4), DIMENSION(:),INTENT(IN) :: rda_data
    REAL(KIND=4), INTENT(OUT)             :: rd_ave,rd_sdev
!    REAL(KIND=4), OPTIONAL                :: rd_var
    REAL(KIND=4)                          :: rl_var
    !
    !*--------------------------------------------------------------------------
    !
    !Initialisation
    ALLOCATE(rl_s(size(rda_data)))
    rl_s=0.
    rl_var=0.
    rd_sdev=0.
    !
    il_n=size(rda_data)
    IF (il_n <= 1) print*,'Subroutine avevarstd : n doit etre superieur a 2 !!'
    !** Premier passage :: obtention de la moyenne
    rd_ave=sum(rda_data(:))/il_n
    !** Deuxieme passage pour obtenir le 2eme troisieme et quatrième moment de
    ! la deviation par rapport à la moyenne
    rl_s(:)=rda_data(:)-rd_ave
    rl_var=dot_product(rl_s,rl_s)
    !** Correction de la formule
    rl_var=(rl_var-sum(rl_s)**2/il_n)/(il_n-1)
    rd_sdev=sqrt(rl_var)

!   
!****************************************************************** 
  END SUBROUTINE avevarsdev
!
!====================================================================================
!
!
  SUBROUTINE moment(rda_data,rd_ave,rd_adev,rd_sdev,rd_var,rd_skew,rd_kurt)
    !
    !**** moment
    !
    !     Purpose:
    !     --------
    !       Pour une serie temporelle donnée, cette routine retourne sa moyenne
    !       son ecart moyen, son ecart type, sa variance et le skewness et curtosis
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item il_n : nombre de données 
    !      \item rda_data : vecteur de données 
    ! 
    !     Output : \\
    !      \item rd_ave : moyenne
    !      \item rd_adev : ecart moyen
    !      \item rd_sdev : ecart type 
    !      \item rd_var : variance
    !      \item rd_skew : skewness
    !      \item rd_kurt : kurtosis
    !
    !***  Method:
    !     -------
    !     Externals:
    !     ----------
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !      1.0        C.REGNIER        Mai 2007      Issu de Numerical Recipies
    !*--------------------------------------------------------------------------
    !
    USE nrtype
    IMPLICIT NONE
    !
    !**   0. DECLARATIONS
    INTEGER(KIND=4)                        :: il_n
    REAL(SP),DIMENSION(:),ALLOCATABLE      :: rl_p,rl_s
    REAL(KIND=4)                           :: rl_ep

    !
    !**   0.3 Dummy variables
    !
    REAL(KIND=4), DIMENSION(:),INTENT(IN)  :: rda_data
    REAL(KIND=4),INTENT(OUT)               :: rd_ave,rd_sdev,rd_var,rd_adev
    REAL(KIND=4),OPTIONAL                  :: rd_skew,rd_kurt
    !
    !*--------------------------------------------------------------------------
    !
    ALLOCATE(rl_p(size(rda_data)))
    ALLOCATE(rl_s(size(rda_data)))

    il_n=size(rda_data)
    IF (il_n <= 1) print*,'Subroutine moment : n doit etre superieur a 2 !'
    !** Premier passage :: obtention de la moyenne
    rd_ave=sum(rda_data(:))/il_n
    !** Deuxieme passage pour obtenir le 2eme troisieme et quatrième moment de
    ! la deviation par rapport à la moyenne
    !Initialisation
    rl_s=0.
    rl_ep=0.
    rd_adev=0.
    rd_var=0.
    rd_skew=0.
    rd_kurt=0.
 
    rl_s(:)=rda_data(:)-rd_ave
    rl_ep=sum(rl_s(:))
    rd_adev=sum(abs(rl_s(:)))/il_n
    rl_p(:)=rl_s(:)*rl_s(:)
    rd_var=sum(rl_p(:))
    rl_p(:)=rl_p(:)*rl_s(:)
    rd_skew=sum(rl_p(:))
    rl_p(:)=rl_p(:)*rl_s(:)
    rd_kurt=sum(rl_p(:))
    !** Correction de la formule
    rd_var=(rd_var-rl_ep**2/il_n)/(il_n-1)
    rd_sdev=sqrt(rd_var)
    IF(rd_var /= 0 )THEN
       rd_skew=rd_skew/(il_n*(rd_sdev**3))
       rd_kurt=rd_kurt/(il_n*rd_var**2)-3.0_sp
    ELSE
       CALL nrerror('Subroutine moment : NO SKEW OR KURTOSIS WHEN ZERO VARIANCE IN MOMENT')
    ENDIF
    DEALLOCATE(rl_p)
    DEALLOCATE(rl_s)

    !****************************************************************** 
  END SUBROUTINE moment
  !
  !*======================================================================
  !
  SUBROUTINE corre(x,y,r)
    !
    !**** corre
    !
    !     Purpose:
    !     --------
    !       Pour deux series temporelle données d'une même taille cette routine
    !       calcule leur coefficient de corrélation r 
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item x : 1ere serie 
    !      \item y : 2eme serie 
    ! 
    !     Output : \\
    !      \item r : coefficient de correlation
    !
    !***  Method:
    !     -------
    !     Externals:
    !     ----------
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !      1.0        C.REGNIER        Mai 2007      Issu de Numerical Recipies
    !*--------------------------------------------------------------------------
    !
    !
    USE nrtype
    IMPLICIT NONE
    !**   0. DECLARATIONS
    REAL(SP), DIMENSION(:),ALLOCATABLE     :: xt,yt
    REAL(SP)                               :: ax,ay,df,sxx,sxy,syy,t
    INTEGER(I4B)                           :: n 
     
    !
    !**   0.3 Dummy variables
    !
    REAL(SP),INTENT(OUT) :: r
    REAL(SP),DIMENSION(:),INTENT(IN) :: x,y
    !
    !*--------------------------------------------------------------------------
    !
    ALLOCATE(xt(size(x)))
    ALLOCATE(yt(size(x)))

    n=assert_eq2(size(x),size(y),'corre')
    !**Calcul de la moyenne
    ax=sum(x)/n
    ay=sum(y)/n
    !**Calcul des coefficients de correlation
    xt(:)=x(:)-ax
    yt(:)=y(:)-ay
    sxx=dot_product(xt,xt)
    syy=dot_product(yt,yt)
    sxy=dot_product(xt,yt)
    r=sxy/(sqrt(sxx*syy))
    DEALLOCATE(xt)
    DEALLOCATE(yt)
    !      
    !*--------------------------------------------------------------------------
    ! 
  END SUBROUTINE corre
  !      
  !*==============================================================================================
  !
 SUBROUTINE autocorre(x,xt,il_dtime2)
    !
    !**** autocorre
    !
    !     Purpose:
    !     --------
    !       Pour une serie temporelle données d'une même taille cette routine
    !       calcule l'autocorrelation 
    !
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item x : 1ere serie 
    !      \item y : 2eme serie 
    ! 
    !     Output : \\
    !      \item r : coefficient de correlation
    !
    !***  Method:
    !     -------
    !     Externals:
    !     ----------
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !      1.0        C.REGNIER        Mai 2007      Issu de Numerical Recipies
    !*--------------------------------------------------------------------------
    !
    !
    USE nrtype
    IMPLICIT NONE
    !**   0. DECLARATIONS
    REAL(SP), DIMENSION(:),INTENT(OUT)      :: xt
    REAL(SP), DIMENSION(:),ALLOCATABLE      :: c
    REAL(SP)                                :: ax,df,rl_err
    INTEGER(I4B)                            :: n
    INTEGER(KIND=4)                         :: il_i,il_j
    INTEGER(I4B),DIMENSION(:),ALLOCATABLE   :: il_dtime
  !  INTEGER(I4B),DIMENSION(:),POINTER       :: il_dtime2
     INTEGER(I4B),DIMENSION(:),INTENT(OUT)   :: il_dtime2

    !
    !**   0.3 Dummy variables
    !
    REAL(SP),DIMENSION(:),INTENT(IN) :: x
    !
    !*--------------------------------------------------------------------------
    !
   ! ALLOCATE(xt(size(x)))
    ALLOCATE(c(size(x)))
    ALLOCATE(il_dtime(size(x)))
  !  ALLOCATE(il_dtime2(size(x)))

    n=size(x)
    !**Calcul de la moyenne
    ax=sum(x)/n
    !**Calcul des coefficients de correlation
    xt(:)=x(:)-ax
    !** Calcul correlation function
      
      do il_i=1,n
        c(il_i)=0.d0
        do il_j=1,n+1-il_i
          c(il_i)=c(il_i)+xt(il_j)*xt(il_i+il_j-1)
        enddo
      enddo
!     normalise the correlation function
      xt(1)=c(1)/dble(n)
      do il_i=2,n
        xt(il_i)=(c(il_i)/dble(n+1-il_i))/xt(1)
      enddo
      xt(1)=1.d0
      il_dtime=(/0:n-1:1/)
      il_dtime2=(/1:n:1/)
      
      !Erreur
       rl_err=sqrt(dot_product(2.d0*il_dtime2,(1-xt))**2/dble(n))
    !      
    !*--------------------------------------------------------------------------
    ! 
  END SUBROUTINE autocorre

!
!*======================================================================
!
  SUBROUTINE nrerror (string)
    ! Report a message then die
    CHARACTER(LEN=*),INTENT(IN) :: STRING
    WRITE(*,*) 'nrerror:',string
    PRINT *,'Program terminated by nrerror'
  END SUBROUTINE nrerror
!
!*======================================================================
!
  FUNCTION assert_eq2(n1,n2,string)
    CHARACTER(LEN=*),INTENT(IN):: string
    INTEGER,INTENT(IN) :: n1,n2
    INTEGER :: assert_eq2
    IF (n1==n2) THEN
       assert_eq2=n1
    ELSE
       WRITE(*,*) 'nerror : an assert_eq failed with this tag :',&
            string
       STOP 'PROGRAM terminated by assert_eq2'
    ENDIF
  END FUNCTION assert_eq2
!
!*======================================================================
!
  SUBROUTINE find(rda_data1,rda_data2,il_data1_ini,il_data1_fin,il_data2_ini,il_data2_fin,il_size)
    !
    !**** find
    !     Purpose :
    !     Compute the comparison between two times series and find the indices
    ! 
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       C.REGNIER    06/06/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 
    !

    !    IMPLICIT NONE
    INTEGER,PARAMETER                             :: SP = KIND(1.0)
    INTEGER(KIND=4)                               :: il_size1,il_size2,il_i,il_ind,il_ind2,il_data,il_size
    INTEGER(KIND=4)                               :: il_pas1,il_pas2,il_indi_ind,il_indf_ind,il_indi_ref,il_indf_ref
    INTEGER(KIND=4)                               :: il_data1_ini,il_data1_fin,il_data2_ini,il_data2_fin
    REAL(KIND=4),DIMENSION(:),TARGET,INTENT(IN)   :: rda_data1,rda_data2
    REAL(KIND=4),DIMENSION(:),POINTER             :: rla_data_ref,rla_data_ind
    !
    !*-------------------------------------------------------------
    !
    il_size1=size(rda_data1)
    il_size2=size(rda_data2)
    il_pas1=rda_data1(2)-rda_data1(1)
    il_pas2=rda_data2(2)-rda_data2(1)
    !** Test
    IF (il_pas1 /= il_pas2) THEN
       PRINT *,"Les deux series n'ont pas la même discrétisation!!",il_pas1,il_pas2
       STOP
    ENDIF
    !** Recherche de la longeur max
    IF(il_size1.LT.il_size2)THEN
       PRINT *,'data2 plus grand'
       il_data=2
       il_ind=il_size2
       il_ind2=il_size1
       rla_data_ref=>rda_data2(:)
       rla_data_ind=>rda_data1(:)
    ELSEIF(il_size2.LT.il_size1)THEN
       PRINT *,'data1 plus grand'
       il_data=1
       il_ind=il_size1
       il_ind2=il_size2
       rla_data_ref=>rda_data1(:)
       rla_data_ind=>rda_data2(:)
    ELSE
       Print *,'Series egales'
       il_data=1
       il_ind2=il_size2
       rla_data_ref=>rda_data1(:)
       rla_data_ind=>rda_data2(:)
    ENDIF
    il_indi_ref=0
    il_indf_ref=0
    il_indi_ind=0
    il_indf_ind=0
    !
    !** On test le recouvrement entre les deux series
    !* Cas 1      rla_data_ref        |---------------------------------------|
    !             rla_data_ind              |---------------------------|

    IF (rla_data_ref(1).LT.rla_data_ind(1).AND.&
         rla_data_ref(il_ind).GT.rla_data_ind(il_ind2))THEN
       il_indi_ind=1
       il_indf_ind=il_ind2
       PRINT *,'RECOUVREMENT entre les deux SERIES'
       DO il_i=1,il_ind
          IF(int(rla_data_ref(il_i)).EQ.int(rla_data_ind(1))) THEN
             il_indi_ref=il_i
          ELSEIF(int(rla_data_ref(il_i)).EQ.int(rla_data_ind(il_ind2))) THEN
             il_indf_ref=il_i          
          ENDIF
       ENDDO
       !    print *,'ref ',rla_data_ref(il_indi_ref:il_indf_ref),size(rla_data_ref(il_indi_ref:il_indf_ref))
       !    print *,'ind ',rla_data_ind(1:il_ind2),size(rla_data_ind(1:il_ind2))
       !* Cas 2
       !            rla_data_ref                   |---------------------------------------|
       !            rla_data_ind              |---------------------------|
    ELSEIF (rla_data_ref(1).GT.rla_data_ind(1).AND.&
         rla_data_ref(il_ind).GT.rla_data_ind(il_ind2))THEN
       il_indi_ref=1
       il_indf_ind=il_ind2
       DO il_i=1,il_ind2
          IF(int(rla_data_ind(il_i)).EQ.int(rla_data_ref(1))) THEN
             il_indi_ind=il_i
          ENDIF
       ENDDO
       DO il_i=1,il_ind
          IF(int(rla_data_ref(il_i)).EQ.int(rla_data_ind(il_ind2))) THEN
             il_indf_ref=il_i
          ENDIF
       ENDDO
       !* Cas 3
       !            rla_data_ref                   |---------------------------------------|
       !            rla_data_ind                                    |---------------------------|
    ELSEIF (rla_data_ref(1).LT.rla_data_ind(1).AND.&   
         rla_data_ref(il_ind).LT.rla_data_ind(il_ind2))THEN
       PRINT *,'CAS 3'
       il_indi_ind=1
       il_indf_ref=il_ind
       DO il_i=1,il_ind2
          IF(int(rla_data_ind(il_i)).EQ.int(rla_data_ref(il_ind))) THEN
             il_indf_ind=il_i
          ENDIF
       ENDDO
       DO il_i=1,il_ind
          IF(int(rla_data_ref(il_i)).EQ.int(rla_data_ind(1))) THEN
             il_indi_ref=il_i
          ENDIF
       ENDDO
       !* Cas 4  Pas de recouvrement 
       !            rla_data_ref            |-------------------|
       !            rla_data_ind                                   |----------| 
       !  ou 
       !            rla_data_ref                         |-------------------|
       !            rla_data_ind            |----------| 


    ELSEIF (rla_data_ref(1).LT.rla_data_ind(1).AND.&   
         rla_data_ref(il_ind).LT.rla_data_ind(1).OR. &
         rla_data_ref(1).GT.rla_data_ind(il_ind2).AND.&   
         rla_data_ref(il_ind).LT.rla_data_ind(il_ind2)) THEN
       Print *,'PAS de recouvrement!!'
       il_indi_ref=0
       il_indf_ref=0
       il_indi_ind=0
       il_indf_ind=0

    ELSE
       Print *,'Cas pas possible :)'

    ENDIF

    IF(il_data.EQ.1) THEN
       il_data1_ini=il_indi_ref
       il_data1_fin=il_indf_ref
       il_data2_ini=il_indi_ind
       il_data2_fin=il_indf_ind 
       il_size=size(rla_data_ind(il_indi_ind:il_indf_ind))
   !    ALLOCATE(rda_data1out())
   !    ALLOCATE(rda_data2out())
   !    rda_data1out=rla_data_ind(il_indi_ind:il_indf_ind)
   !    rda_data2out=rla_data_ref(il_indi_ref:il_indf_ref)

    ELSEIF(il_data.EQ.2) THEN
       il_data1_ini=il_indi_ind
       il_data1_fin=il_indf_ind
       il_data2_ini=il_indi_ref
       il_data2_fin=il_indf_ref
       il_size=size(rla_data_ind(il_indi_ind:il_indf_ind))
  !    ALLOCATE(rda_data1out())
  !    ALLOCATE(rda_data2out())
  !    rda_data1out(:)=rla_data_ref(il_indi_ref:il_indf_ref)
  !    rda_data2out(:)=rla_data_ind(il_indi_ind:il_indf_ind)

    ENDIF
    
!Print *,'Indices',il_indi_ref,il_indf_ref,il_indi_ind,il_indf_ind

    !
    !*-------------------------------------------------------------
    !
  END SUBROUTINE find
!
!*======================================================================
!
  SUBROUTINE moyenne(rda_data,rd_ave)
    !
    !**** avevarsdev
    !
    !     Purpose:
    !     --------
    !       Pour une serie temporelle donnée, cette routine retourne sa moyenne
    !     Input : \\
    !     ------
    !      \begin{itemize}
    !      \item rda_data : vecteur de données 
    ! 
    !     Output : \\
    !      \item rd_ave : moyenne
 
    !***  Method:
    !     -------
    !     Externals:
    !     ----------
    !     History:
    !     --------
    !      Version    Programmer      Date            Description
    !      -------    ----------      ----            -----------
    !      1.0        C.REGNIER        Mai 2007      Issu de Numerical Recipies
    !*--------------------------------------------------------------------------
    !
      IMPLICIT NONE
    !
    !**   0. DECLARATIONS
    INTEGER(KIND=4)                         :: il_n
    !
    !**   0.3 Dummy variables
    !
    REAL(KIND=4), DIMENSION(:),INTENT(IN)  :: rda_data
    REAL(KIND=4),INTENT(OUT)               :: rd_ave
    !
    !*--------------------------------------------------------------------------
    !
    il_n=size(rda_data)
    IF (il_n <= 1) print*, 'Subroutine moyenne : n doit etre superieur a 2 !'
    !** Premier passage :: obtention de la moyenne
    rd_ave=sum(rda_data(:))/il_n
  
  END SUBROUTINE moyenne
!
!*======================================================================
!

  SUBROUTINE rms_2fields(rda_data1,rda_data2,rl_rms)
    !
    !**** find
    !     Purpose :
    !     Compute the rms between two times series 
    ! 
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       C.REGNIER    06/06/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 
    !

    !    IMPLICIT NONE
    REAL(KIND=4),DIMENSION(:),INTENT(IN)          :: rda_data1,rda_data2
    REAL(KIND=4),DIMENSION(:),ALLOCATABLE         :: rla_diff
    REAL(KIND=4)                                  :: rl_moy,rl_sdev
    REAL(KIND=4) ,INTENT(OUT)                     :: rl_rms
    !
    !*--------------------------------------------
    IF (size(rda_data1).NE.size(rda_data2)) THEN
       PRINT *,'Times series with differents length'
       GOTO 110 ! pas beau le goto mais bon ...
    ENDIF
    ALLOCATE(rla_diff(size(rda_data1)))
    rla_diff=rda_data1-rda_data2
    CALL avevarsdev(rla_diff,rl_moy,rl_sdev)
    rl_rms=sqrt(rl_moy**2+rl_sdev**2)

110 END SUBROUTINE rms_2fields
 
  SUBROUTINE rms_1field(rda_data1,rl_rms)
    !
    !**** find
    !     Purpose :
    !     Compute the rms of a time serie
    ! 
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       C.REGNIER    06/06/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 
    !
    REAL(KIND=4),DIMENSION(:),INTENT(IN)          :: rda_data1
    REAL(KIND=4)                                  :: rl_moy,rl_sdev
    REAL(KIND=4) ,INTENT(OUT)                     :: rl_rms
    !
    !*--------------------------------------------
    CALL avevarsdev(rda_data1,rl_moy,rl_sdev)
    rl_rms=sqrt(rl_moy**2+rl_sdev**2)
 !
 !*-------------------------------------------------------------
 !    
  END SUBROUTINE rms_1field
!
!*====================================================
!

   FUNCTION correl(data1,data2)
    !
    !**** correl
    !     Purpose :
    !     Compute coumpute the correlation betwen 2 fonctions
    !      you could compute the autorrelation if data1 = data2
    ! 
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       Numerical recipies    1/08/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 
    !	
     USE NUMERIC_REC
     USE nrtype; USE nrutil, ONLY : assert,assert_eq
 !    USE nr, ONLY : realft
     IMPLICIT NONE
     REAL(SP), DIMENSION(:), INTENT(INOUT) :: data1,data2
     REAL(SP), DIMENSION(size(data1)) :: correl
     COMPLEX(SPC), DIMENSION(size(data1)/2) :: cdat1,cdat2
     INTEGER(I4B) :: no2,n
  !*--------------------------------------------
    n=assert_eq(size(data1),size(data2),'correl')
     call assert(iand(n,n-1)==0, 'n must be a power of 2 in correl')
     no2=n/2
     call realft(data1,1,cdat1)
     call realft(data2,1,cdat2)
     cdat1(1)=cmplx(real(cdat1(1))*real(cdat2(1))/no2, &
          aimag(cdat1(1))*aimag(cdat2(1))/no2, kind=spc)
     cdat1(2:)=cdat1(2:)*conjg(cdat2(2:))/no2
     call realft(correl,-1,cdat1)
   END FUNCTION correl
!
!*==================================================
!
!=============================================================
!=============================================================
!
END MODULE STATS
