
!-------------------------------------------
!> \brief
!! Module arithmetique regroupant des fonctions de base
!<
!---------------------------------------

MODULE arithme

IMPLICIT NONE

PRIVATE
PUBLIC  max,max_1D,max_2D,min_1D,min_2D

CONTAINS
!> \brief
!!
!!***max_1D
!!
!!  Purpose : Compute the max of 2 data
!!
!!     History:
!!     --------
!!      Version    Programmer      Date            Description
!!      -------    ----------      ----            -----------
!!      1.0        C.REGNIER       03/2007          
!<

REAL FUNCTION max(rl_N1,rl_N2)


  REAL(KIND=4)  :: rl_N1,rl_N2
!
!*------------       
!
               IF (rl_N1 .GE. rl_N2) THEN
                    max = rl_N1
               ELSE
                   max = rl_N2
               ENDIF
         
               RETURN
END FUNCTION max
!
!*===========================================================
!> \brief
!!
!!
!!***max_1D
!!
!!  Purpose : Compute the max of 1D vector and find the position
!!
!!     History:
!!     --------
!!      Version    Programmer      Date            Description
!!      -------    ----------      ----            -----------
!!      1.0        C.REGNIER       03/2007          
!<

REAL FUNCTION max_1D(rla_vec,il_pos,il_len)

  REAL(KIND=4),DIMENSION(il_len)  :: rla_vec
  REAL(KIND=4)                    :: rl_max 
  INTEGER                         :: il_pos,il_len,il_i

!
!*------------       
!
          rl_max=rla_vec(1)
          il_pos=1
              DO il_i=2,il_len        
                 IF(rl_max.lt.rla_vec(il_i)) THEN
                    rl_max=rla_vec(il_i)
                    il_pos=il_i
                  ELSE
                   EXIT
                 ENDIF
             ENDDO
          max_1D=rl_max



RETURN
END FUNCTION max_1D
!
!*===========================================================
!> \brief
!!
!!
!!***min_1D
!!
!!  Purpose : Compute the min of 1D vector and find the position
!!
!!     History:
!!     --------
!!      Version    Programmer      Date            Description
!!      -------    ----------      ----            -----------
!!      1.0        C.REGNIER       03/2007          
!<
!---------------------------------------------------------------
REAL FUNCTION min_1D(rla_vec,il_pos,il_len)


  REAL(KIND=4),DIMENSION(il_len)  :: rla_vec
  REAL(KIND=4)                    :: rl_min 
  INTEGER                         :: il_pos,il_len,il_i

!
!*------------       
!
          rl_min=rla_vec(1)
          il_pos=1
              DO il_i=2,il_len        
                 IF(rl_min.gt.rla_vec(il_i)) THEN
                    rl_min=rla_vec(il_i)
                    il_pos=il_i
                  ELSE
                   EXIT
                 ENDIF
             ENDDO
          min_1D=rl_min



RETURN
END FUNCTION min_1D

!
!*===========================================================
!> \brief
!!***max_2D
!!
!!  Purpose : Compute the max of 2D matrix 
!!
!!     History:
!!     --------
!!      Version    Programmer      Date            Description
!!      -------    ----------      ----            -----------
!!      1.0        C.REGNIER       03/2007          
!<
!------------------------------------------------------------------
REAL FUNCTION max_2D(rla_vec,il_len1,il_len2,il_max1,il_max2)
!
  REAL(KIND=4),DIMENSION(il_len1,il_len2)  :: rla_vec
  REAL(KIND=4)                    :: rl_max 
  INTEGER                         :: il_len1,il_len2,il_i,il_j
  INTEGER,OPTIONAL                 :: il_max1,il_max2
!
!*------------       
!
          rl_max=rla_vec(1,1)
          il_max1=1
          il_max2=2
          
          DO il_i=1,il_len1      
             DO il_j=1,il_len2
                 IF(rl_max.lt.rla_vec(il_i,il_j)) THEN
                    rl_max=rla_vec(il_i,il_j)
                    il_max1=il_i
                    il_max2=il_j
                   ELSE
                    rl_max=rl_max
                 ENDIF
               ENDDO
            ENDDO
          max_2D=rl_max
RETURN
END FUNCTION max_2D
!
!*===========================================================
!
!-----------------------------------------
!> \brief
!!***min_2D
!!
!!  Purpose : Compute the min of 2D matrix 
!!
!!     History:
!!     --------
!!      Version    Programmer      Date            Description
!!      -------    ----------      ----            -----------
!!      1.0        C.REGNIER       03/2007          
!<
!---------------------------------------------------------------

REAL FUNCTION min_2D(rla_vec,il_len1,il_len2,il_min1,il_min2)
!
  REAL(KIND=4),DIMENSION(il_len1,il_len2)  :: rla_vec
  REAL(KIND=4)                    :: rl_min 
  INTEGER                         :: il_len1,il_len2,il_i,il_j
  INTEGER,OPTIONAL                 :: il_min1,il_min2
!
!*------------       
!
          rl_min=rla_vec(1,1)
          il_min1=1
          il_min2=2
          
          DO il_i=1,il_len1      
             DO il_j=1,il_len2
                 IF(rl_min.gt.rla_vec(il_i,il_j)) THEN
                    rl_min=rla_vec(il_i,il_j)
                    il_min1=il_i
                    il_min2=il_j
                   ELSE
                    rl_min=rl_min
                 ENDIF
               ENDDO
            ENDDO
          min_2D=rl_min
RETURN
END FUNCTION min_2D



END MODULE arithme
