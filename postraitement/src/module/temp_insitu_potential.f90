!******************************************************************************
!******************************************************************************
!******************************************************************************
!
!  FHZ Avril 2008 repris d une routine de F. Messal
!
SUBROUTINE tempot (pf, p0, t0, s0, theta)
  !
  ! procedure de calcul de la temperature potentielle
  ! a partir de pf pression a la surface, p0 pression in situ
  ! t0 et s0 temperature et salinite in situ
  !
  ! p pression en dbar
  ! t temperature en degre.c
  ! s salinite en sal78
  !
  ! E. Dombrowsky & S. Houry 6/86
  ! M. Benkira 07/2004 - 
  !
  !
  IMPLICIT NONE
  INTEGER :: i,n
  REAL(KIND=8), INTENT(IN) ::  p0, t0, s0, pf
  REAL(KIND=8), INTENT(OUT)::  theta
  REAL(KIND=8) ::  p, s, t, h, xk, q, fnadtg
  !
  p = p0
  t = t0
  s = s0
  h = pf - p
  n = INT(ABS(h)/1000 + 1)
  h = REAL(h/n,8)
  DO i = 1, n
     xk = h*fnadtg(p,t,s)
     t  = t + .5d0*xk
     q  = xk
     p  = p + .5d0*xk
     xk = h*fnadtg(p,t,s)
     t  = t + .29298322d0*(xk-q)
     q  = .58578644d0*xk + .121320344d0*q
     xk = h*fnadtg(p,t,s)
     t  = t + 1.707106781d0*(xk-q)
     q  = 3.414213562d0*xk - 4.121320344d0*q
     p  = p + .5d0*h
     xk = h*fnadtg(p,t,s)
     t  = t + (xk-2.d0*q)/6.d0
  ENDDO
  theta = t
  !
  RETURN
  !
END  SUBROUTINE tempot
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
!
      DOUBLE PRECISION FUNCTION fnadtg (p, t, s)
!
! fonction annexe pour le calcul de la temperature potentielle
! p en dbar
! t en degre.c
! s en sal78
!
! E. Dombrowsky & S. Houry 6/86
!
      IMPLICIT NONE
!
      REAL (KIND=8) :: p,t,s,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12
      REAL (KIND=8) :: b13,b14,b15
!
      b1 = -2.1687d-16
      b2 = 1.8676d-14
      b3 = -4.6206d-13
      b4 = .0000000000027759d0
      b5 = -.00000000011351d0
      b6 = -5.4481d-14
      b7 = .000000000008733d0
      b8 = -.00000000067795d0
      b9 = .000000018932d0
      b10 = -.000000042393d0
      b11 = .0000018932d0
      b12 = .00000000062228d0
      b13 = -.00000006836d0
      b14 = .0000085258d0
      b15 = .000035803d0
      fnadtg = (((b1*t+b2)*t+b3)*p+((b4*t+b5)*(s-35)+((b6*t+b7)*t+b8) &
         *t+b9))*p+(b10*t+b11)*(s-35)+((b12*t+b13)*t+b14)*t+b15
!
     RETURN
!
!
      END FUNCTION fnadtg 
!
!******************************************************************************
!******************************************************************************
!******************************************************************************
