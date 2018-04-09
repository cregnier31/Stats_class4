!> \brief
!!
!! Description :: Module permettant de realiser la construction du canvas assimiliation
!!                => but du canvas : s'affranchir des points terre pour créer un vecteur contenant 
!!                   tout les points mer
!<
!!
MODULE CANVAS

PUBLIC GenereCanvas

CONTAINS
!
!> /brief
!!**** ComputeCanvas
!!
!!     Purpose : compute canvas values for each grid 
!!
!!***  Method:
!!     -------
!!      @param ida_maskvalue : matrice of mask value
!!      @param ida_kanvas    : canvas values
!!      @param idpa_igrd     : correspondance between igrd point and ip_jpiglo point
!!      @param idpa_jgrd     : correspondance between jgrd point and ip_jpjglo point
!!     Externals:
!!     ----------
!!     History:
!!     --------
!!      Version    Programmer      Date            Description
!!      -------    ----------      ----            -----------
!!      1.0        C.REGNIER       29/10/2008      Made about source from PALM
!! ##TODO :: Integrer conf MED 
!!
!<
!*--------------------------------------------------------------------------------

SUBROUTINE GenereCanvas(ida_maskvalue,idpa_kanvas,idpa_igrd,idpa_jgrd)

!
!** + DECLARATIONS
!
  USE param_mod
  IMPLICIT NONE
  INTEGER, DIMENSION(:,:),INTENT(IN)              :: ida_maskvalue
  INTEGER, DIMENSION(:,:),POINTER,INTENT(OUT)     :: idpa_kanvas
  INTEGER, DIMENSION(:),POINTER,INTENT(OUT)       :: idpa_igrd,idpa_jgrd
  !
  INTEGER                                 :: il_kg,il_i,il_j,il_longrid,il_latgrid

!
! Allocation
ALLOCATE (idpa_kanvas(ip_jpiglo,ip_jpjglo))
ALLOCATE (idpa_igrd(ip_maxgrd))
ALLOCATE (idpa_jgrd(ip_maxgrd))

il_longrid=size(ida_maskvalue(:,1))
il_latgrid=size(ida_maskvalue(1,:))

!* Test si le masque d'entrée correspond bien au modele passé en paramètre dans la clé
IF (il_longrid /= ip_jpiglo .AND. il_latgrid /= ip_jpjglo) THEN
   WRITE (0,*)  ,'La grille modèle ne correspond pas au modèle defini dans la clé ',il_longrid,ip_jpiglo,il_latgrid,ip_jpjglo
   STOP
ENDIF
!
!-----------------------------------------------------------
!
! Initialisation
  idpa_kanvas(:,:)=0
  idpa_igrd(:)=0
  idpa_jgrd(:)=0
  il_kg=0
!
#if defined key_global
   DO il_j=2,ip_jpjglo-3
     DO il_i=2,ip_jpiglo-1
#else
  DO il_j=2,ip_jpjglo-1
    DO il_i=2,ip_jpiglo-1
#endif
        IF ( ida_maskvalue(il_i,il_j) /= 0 .AND. ida_maskvalue(il_i,il_j) /= 9999 ) THEN
           il_kg=il_kg+1
           idpa_igrd(il_kg)=il_i
           idpa_jgrd(il_kg)=il_j
           idpa_kanvas(il_i,il_j)=il_kg
        ENDIF
     ENDDO
  ENDDO
  
  IF ( il_kg /= ip_maxgrd ) then
     WRITE(0,*) "GenereCanvas: warning il_kg /= ip_maxgrd", il_kg,ip_maxgrd
     call flush(0)
  ENDIF

#if defined key_debug  
  WRITE (0,*) 'nb points du kanvas ::',il_kg
#endif

END SUBROUTINE GenereCanvas

END MODULE CANVAS
