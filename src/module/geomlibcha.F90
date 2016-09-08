!> \brief
!!
!! Description :: Module permettant de realiser la collocalisation de profils in situ sur une grille modèle
!!----------------------------------------------------------------------------
!! GEOMLIB -- canvas geometric routines for SOFA3
!! P De Mey 1999, M Bremond 1999
!! ----------------------------------------------------------------------------
!!
!! subprogram    	function
!!
!! segIntersect()	do two segments intersect?
!! inSight()		are two points in sight of each other?
!!
!! insideCell()		is point inside cell?
!! getSWnsican2ode()	return "SouthWest" node for given location
!! getVert()		get all four nodes for given SouthWest node
!! getNodeWeights()	interpolate in 2D quadrangular cell of any shape
!! bilwgt()              Compute the weights for a bilinear remapping interpolation.
!!                       This scheme is appropriate for bilinear interpolation on a
!!                       general quadrilateral grid.
!! getSWnodeWeights()	alternate interface to getNodeWeights()
!!
!! normLon()		normalize longitude range
!! LonInf ()		compare two logitudes
!! lonTest()		test if longitude lies within canvas outer limits
!! lonMin()              longitude Min
!! lonMax()              longitude Max
!!
!! geoVar()              get space variations of statistical scales
!!#if defined key_minipog || defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12
!!! DiffLon()             Difference between two longitudes for x-periodic grids
!!#endif
!<
!========================================================================

MODULE geomlibcha
  IMPLICIT NONE
 ! private
!  public :: insidecell0,insidecellstrict,distancenorm,segintersect,&
 !           getSWnode_orca_grid,normLon,inSight

  INTEGER,          PARAMETER :: IEMPTY =  -22222
  REAL,             PARAMETER :: EMPTY  = 1e35,  EMPTY2 = 9999.0
  REAL, PARAMETER :: rp_epsilon = EPSILON(0.)

  ! 2-D canvas definition
  !
  ! NCAN1			matrix dimension of canvas in first direction
  ! NCAN2		        matrix dimension of canvas in second direction
  INTEGER                          :: ncan1 = IEMPTY, ncan2  = IEMPTY
  REAL                             :: xcanmin, xcanmax, ycanmin, ycanmax

#if defined key_global
  INTEGER                                  :: ifconv  = 3
#else
  INTEGER                                  :: ifconv  = 1
#endif

CONTAINS
  !======================================================================================
  !> \brief
  !!  Description : returns model node which is to the "Southwest" of location (x,y)
  !!
  !! the SW node is the node belonging to the cell around (x,y) with the smallest
  !! (i,j) indexes -- it is not necessarily to the Southwest !
  !!
  !! (x,y) is on the grid if all four surrounding canvas nodes are model nodes
  !! if (x,y) is not on the grid, then SWnode=0 on return
  !!
  !! the node is located by an alternate dichotomy on x then y, assuming
  !! x increasing with i and y increasing with j
  !! supports all IFCONV options including x-periodic canvas
  !!
  !!=getSWnode= P De Mey, M Bremond
  !!
  !! Modifications : Jean-Michel Lellouche (Janvier 2002)
  !!     La dichotomie ne fonctionnant pas correctement pour la grille PAM,
  !!     deux cas se presentent:
  !!       - La dichotomie fournit des prox(i) pour i=1,4 tous nuls. Dans
  !!         ce cas on fait des recherches locales du noeud SW sur des
  !!         domaines fixes par les boucles en ji,jj.
  !!       - La dichotomie fournit parmi les prox(i) pour i=1,4 au moins un
  !!         non nul. Dans ce cas on part du dernier point (ic,jc) trouve
  !!         par la dichotomie et on fait la recherche du noeud SW autour du
  !!         point (ic,jc) en s en ecartant (spirale grandissante).
  !! Adaptation for OPA9 : B. Tranchant
  !! Optimization : C.E. Testut
  !! Modification By C.REGNIER Octobre 2008
  !!        - Add xcan,ycan,ida_igrd,ida_jgrd,id_nx,id_ny to the arguments
  !!        - delete this reinitialisation of vertex if a vertex is equal to 0 
  !!          (now we can find 1-2-3 points not only 4 points)  
  !!        - patch to find the nearest point in the ocean if we don't find any vertex
  !<
  !==========================================================================================


SUBROUTINE getSWnode_orca_grid( x, y, xcan, ycan, ida_kanvas,ida_igrd,ida_jgrd,id_nx, id_ny,SWnode, vertex)
!
  !
  USE MCAL, only : MCAL_compute_distance
  IMPLICIT NONE
!
  REAL(KIND=4),INTENT(IN) :: x, y
  INTEGER, INTENT(OUT):: SWnode
  INTEGER, DIMENSION(4),INTENT(OUT) :: vertex
  INTEGER, INTENT(IN) :: id_nx,id_ny 
  INTEGER, DIMENSION(id_nx,id_ny),INTENT(IN) :: ida_kanvas
  INTEGER, DIMENSION(:),INTENT(IN)           :: ida_igrd,ida_jgrd
 
  ! 2-D canvas definition
  !
  ! NCAN1			matrix dimension of canvas in first direction
  ! NCAN2		        matrix dimension of canvas in second direction
  ! XCAN(NCAN1,NCAN2)     x coordinates of canvas nodes
  ! YCAN(NCAN1,NCAN2)	y coordinates of canvas nodes
  REAL(KIND=4), DIMENSION(id_nx, id_ny), INTENT(IN) :: xcan,ycan
  

  !
  INTEGER, DIMENSION(id_nx,id_ny) :: kanvas
  INTEGER :: il_p, il_q,il_p1,il_q1, ic, jc, il_largeur,il_largeur1,p,q,largeur
  INTEGER :: il_largeur_max,ipoint
  INTEGER :: kx,ky,inddeb,indfin,ionboundary,ionvertice
#if defined key_debuggeomlib
  LOGICAL :: getVertices
#endif
  !LOGICAL :: insideCell0, insidecellstrict, around, ll_onvertice,ll_return
  LOGICAL :: around, ll_onvertice,ll_return
 
  REAL(KIND=4) :: dx,dy, x_work, y_work, x_west, y_north
  REAL(KIND=4), DIMENSION(8) :: dist
  REAL(KIND=8)       :: rl_dist
  REAL(KIND=4), DIMENSION(4) :: xv,yv
  LOGICAL, DIMENSION(4) :: lla_onvertice
  INTEGER :: icandeb,jcandeb,icandeb0,jcandeb0,icansw,jcansw,icanne,jcanne
!  REAL :: distmax,distmin,dist0,distancenorm,distdijc,rl_lon,rl_lat
  REAL(KIND=4) :: distmax,distmin,dist0,distdijc,rl_lon,rl_lat
  INTEGER :: icm1,icp1,jcm1,jcp1,dic,djc,icdijc,jcdijc,il_ivertex,il_jvertex,il_var
  INTEGER :: icansw_new,jcansw_new,il_nlargeur,il_indice,ican_new,jcan_new,il_k,il_miss
  INTEGER,DIMENSION(:),ALLOCATABLE  :: ila_var
  REAL(KIND=8),DIMENSION(:),ALLOCATABLE      :: rla_distance
  REAL(KIND=8) :: st1, st2, st3, st4
!
 ! EXTERNAL insideCell0,insidecellstrict,distancenorm
!
! Initialisation
! ==============
  vertex(:) = 0
  ncan1=id_nx
  ncan2=id_ny
  kanvas(:,:)=ida_kanvas
  il_miss=99999
  xcanmin=MINVAL(xcan)
  xcanmax=MAXVAL(xcan)
  ycanmin=MINVAL(ycan)
  ycanmax=MAXVAL(ycan)
  ll_return=.FALSE.
#if defined key_debuggeomlib
  WRITE(0,*) 'Valeurs MIN MAX :: ',xcanmin,xcanmax,ycanmin,ycanmax
#endif
!
#ifdef NO_NORMLON
#else
  IF ( x < -180. .or.  x > 180.) THEN
     WRITE(0,*) 'getSWnode_orca_grid: inconsistance avec la routine appelante x=',x
     call flush (0)
     STOP
  ENDIF
#endif
!
#if defined key_global
! no selected data in caspian sea
  IF (x >= 46. .AND. x <= 56. .AND. y >= 35. .AND. y <= 50.) THEN
      SWnode=0
      RETURN
  ENDIF
! no selected data in ANTARCTICA area
  IF ( y < MINVAL(ycan(2:ncan1-1,2)) ) THEN
      SWnode=0
      RETURN
  ENDIF
!
#endif
!
#if defined key_atl4 || defined key_atl12
! On verifie si l'observation est dans le domaine considere
  IF (x > xcanmax .OR. x < xcanmin .OR. y > ycanmax .OR. y < ycanmin) THEN
     SWnode=0
     RETURN
  ENDIF
! no selected data in the following areas ...
! Mer rouge, ocean indien, golfe d'Aden et golfe persique
  IF (x > 30. .AND. y < 31) THEN
     SWnode=0
     RETURN
  ENDIF 
! Mer Caspienne
  IF (x >= 46. .AND. x <= xcanmax .AND. y >= 35. .AND. y <= 50.) THEN
     SWnode=0
     RETURN
  ENDIF
! Mer Noire
  IF (x >= 27. .AND. x <= 43.  .AND. y >= 41. .AND. y <= 49.) THEN
     SWnode=0
     RETURN
  ENDIF
! Ocean Pacifique
  IF (     (x >= xcanmin .AND. x <= -99. .AND. y <= 20.) &
      .OR. (x >= -99. .AND. x <= -90. .AND. y <= 17.7) &
      .OR. (x >= -90. .AND. x <= -84. .AND. y <= 15.) &
      .OR. (x >= -84. .AND. x <= -78. .AND. y <= 8.65) &
      .OR. (x >= -78. .AND. x <= -70. .AND. y <= 7.73) ) THEN
     SWnode=0
     RETURN
  ENDIF
! Les points au dessus de l'arc de courbe defini par l'equation ci dessous
!  IF (y >= 62.) THEN 
!      x_work=x*1.4+32.
!      y_north=80.5-0.0013*x_work*x_work
!      IF (y > y_north) THEN
!          SWnode=0
!          RETURN 
!      ENDIF
!  ENDIF
! Les points au dessus des 7 droites definies ci dessous
  rl_x1=-103.1
  rl_y1=63.5
  rl_x2=-80
  rl_y2=74.5
  rl_a=(rl_y2-rl_y1)/(rl_x2-rl_x1)
  rl_b=rl_y1-rl_a*rl_x1
  rl_ynorth1=rl_a*x+rl_b
!
  rl_x3=-60
  rl_y3=78.8
  rl_a=(rl_y3-rl_y2)/(rl_x3-rl_x2)
  rl_b=rl_y2-rl_a*rl_x2
  rl_ynorth2=rl_a*x+rl_b
!
  rl_x4=-12
  rl_y4=81.
  rl_a=(rl_y4-rl_y3)/(rl_x4-rl_x3)
  rl_b=rl_y3-rl_a*rl_x3
  rl_ynorth3=rl_a*x+rl_b
!
  rl_x5=11
  rl_y5=79.5
  rl_a=(rl_y5-rl_y4)/(rl_x5-rl_x4)
  rl_b=rl_y4-rl_a*rl_x4
  rl_ynorth4=rl_a*x+rl_b
!
  rl_x6=30
  rl_y6=76.7
  rl_a=(rl_y6-rl_y5)/(rl_x6-rl_x5)
  rl_b=rl_y5-rl_a*rl_x5
  rl_ynorth5=rl_a*x+rl_b
!
  rl_x7=45
  rl_y7=71.4
  rl_a=(rl_y7-rl_y6)/(rl_x7-rl_x6)
  rl_b=rl_y6-rl_a*rl_x6
  rl_ynorth6=rl_a*x+rl_b
!
  rl_x8=56.5
  rl_y8=63.7
  rl_a=(rl_y8-rl_y7)/(rl_x8-rl_x7)
  rl_b=rl_y7-rl_a*rl_x7
  rl_ynorth7=rl_a*x+rl_b
!
  IF (y >= rl_ynorth1 .OR. y >= rl_ynorth2 .OR. y >= rl_ynorth3 .OR. y >= rl_ynorth4 .OR. &
      y >= rl_ynorth5 .OR. y >= rl_ynorth6 .OR. y >= rl_ynorth7 ) THEN
     SWnode=0
     RETURN
  ENDIF
#endif
!
#if defined key_neatl12 || defined key_ibi12 || defined key_ibi36
! On verifie si l'observation est dans le domaine considere
  IF (x > xcanmax .OR. x < xcanmin .OR. y > ycanmax .OR. y < ycanmin) THEN
     SWnode=0
     RETURN
  ENDIF
!
  IF (y >= 60.) THEN
     x_work=x*1.4+32.
     y_north=64.1-0.0013*x_work*x_work
     IF (y > y_north) THEN
        SWnode=0
        RETURN
     ENDIF
  ENDIF
!
  IF (x <= -16.) THEN
     x_work=y*0.54+0.013
     x_west=-20.0  +0.001*x_work*x_work
     IF (x < x_west ) THEN
        SWnode=0
        RETURN
     ENDIF
  ENDIF
!
  IF (y >= 52. .AND. x >= 13.0)  THEN
     SWnode=0
     RETURN
  ENDIF
!
  IF (y >= 36. .AND. y <= 45. .AND.  x >= 9.5) THEN
     SWnode=0
     RETURN
  ENDIF
#endif
!
#if defined key_med12 || defined key_presal
! On verifie si l'observation est dans le domaine considere
  IF (x > xcanmax .OR. x < xcanmin .OR. y > ycanmax .OR. y < ycanmin) THEN
#if defined key_debuggeomlib
     WRITE(0,*) 'Obs not inside grid : ',x,xcanmin,xcanmax,y,ycanmin,ycanmax
#endif
     SWnode=0
     RETURN
  ENDIF
#endif
!
! I - Recherche du icandeb,jcandeb
! --------------------------------
!
! 1.1 Algorithme 1 : dichotomie classique
! ---------------------------------------
!
#if defined key_debuggeomlib
    WRITE(0,*) 'Algo 1 dichotomie classique'
#endif
  ic = INT(( ncan1 + 1 ) / 2)
  jc = INT(( ncan2 + 1 ) / 2)
!
!! def  dx,dy,ll_onvertice      
! longitude
  dx = x - xcan(ic,jc)
#ifdef NO_NORMLON
#else
  IF ( ifconv /= 0 ) CALL normLon(dx)
#endif
!
! latitude
  dy = y - ycan(ic,jc)
!
  ll_onvertice=( (dx==0.0) .AND. (dy==0.0) )
  IF (ll_onvertice) THEN
! lucky : obs on vertice (ic,jc,kanvas(ic,jc))
     IF ( kanvas(ic,jc) == 0) THEN
!! on est dans la terre
#if defined key_debuggeomlib
!!debuggeomlib
        WRITE (0,*) 'RETURN onvertice,kan=0:',x,y
        WRITE (200,*) 'RETURN onvertice,kan=0:',x,y
        CALL FLUSH(200)
        WRITE (300,*) x,y,0
        CALL FLUSH(300)
!!debuggeomlib
#endif
        SWnode=0
        RETURN
     ENDIF
  ENDIF
!
  around = .false.
  ky = jc
  kx = ic
!
  DO WHILE ((.NOT.around).AND.(.NOT.ll_onvertice))
!
     kx = (kx + 1) / 2
     ky = (ky + 1) / 2
!
     IF (dx < 0.0) THEN
!
	ic = ic - kx
        IF (ic < 2) THEN
           IF (ifconv == 3) THEN ! x-periodic kanvas
!!!              ic = ncan1 -1 - ic
              ic = ncan1 - 1 + ( ic -1 )
              !print *,'x-periodic kanvas'
           ELSE
              ic = 2
           END IF
	ENDIF
!
!! redef  dx,dy,ll_onvertice 
! longitude
        dx = x - xcan(ic,jc)
#ifdef NO_NORMLON
#else
        IF ( ifconv /= 0 ) CALL normLon(dx)
#endif
! latitude
        dy = y - ycan(ic,jc)
        ll_onvertice=( (dx==0.0) .AND. (dy==0.0) )
        IF (ll_onvertice) THEN
           IF ( kanvas(ic,jc) == 0) THEN
!! on est dans la terre
#if defined key_debuggeomlib
!!debuggeomlib
        WRITE (200,*) 'RETURN onvertice,kan=0:',x,y
        CALL FLUSH(200)
        WRITE (300,*) x,y,0
        CALL FLUSH(300)
!!debuggeomlib
#endif
              SWnode=0
              RETURN
           ENDIF
        ENDIF
!
     ELSE
!
       IF (dx > 0.0) THEN
!
          ic = ic + kx
          IF (ic > (ncan1-1) ) THEN
! x-periodic kanvas ?
             IF (ifconv == 3) THEN
                ic = ic - ncan1 + 2
             ELSE
                ic = ncan1 - 1
             ENDIF
          ENDIF
!
!! redef  dx,dy,ll_onvertice      
! longitude
            dx = x - xcan(ic,jc)
#ifdef NO_NORMLON
#else
            IF ( ifconv /= 0 ) CALL normLon(dx)
#endif
! latitude
            dy = y - ycan(ic,jc)
            ll_onvertice=( (dx==0.0) .AND. (dy==0.0) )
            IF (ll_onvertice) THEN
               IF ( kanvas(ic,jc) == 0) THEN
!! on est dans la terre
#if defined key_debuggeomlib
!!debuggeomlib
        WRITE (200,*) 'RETURN onvertice,kan=0:',x,y
        CALL FLUSH(200)
        WRITE (300,*) x,y,0
        CALL FLUSH(300)
!!debuggeomlib
#endif
                  SWnode=0
                  RETURN
               ENDIF
            ENDIF
!
	ENDIF
!
     ENDIF
!
    IF (dy<0.0) THEN
!
       jc = jc - ky
       IF (jc < 2) jc = 2
!
!! redef  dx,dy,ll_onvertice      
! longitude
       dx = x - xcan(ic,jc)
#ifdef NO_NORMLON
#else
       IF ( ifconv /= 0 ) CALL normLon(dx)
#endif
! latitude
       dy = y - ycan(ic,jc)
       ll_onvertice=( (dx==0.0) .AND. (dy==0.0) )
       IF (ll_onvertice) THEN
          IF ( kanvas(ic,jc) == 0) THEN
!! on est dans la terre
#if defined key_debuggeomlib
!!debuggeomlib
        WRITE (200,*) 'RETURN onvertice,kan=0:',x,y
        CALL FLUSH(200)
        WRITE (300,*) x,y,0
        CALL FLUSH(300)
!!debuggeomlib
#endif
             SWnode=0
             RETURN
          ENDIF
       ENDIF
!
    ELSE
!
       IF (dy>0.0) THEN
          jc = jc + ky
#if defined key_global
          IF (jc > ncan2 - 3 ) jc = ncan2 - 3
#else
          IF (jc > ncan2 - 1 ) jc = ncan2 - 1 
#endif
!
!! redef  dx,dy,ll_onvertice      
! longitude
          dx = x - xcan(ic,jc)
#ifdef NO_NORMLON
#else
          IF ( ifconv /= 0 ) CALL normLon(dx)
#endif
! latitude
          dy = y - ycan(ic,jc)
          ll_onvertice=( (dx==0.0) .AND. (dy==0.0) )
          IF (ll_onvertice) THEN
             IF ( kanvas(ic,jc) == 0) THEN
!! on est dans la terre
#if defined key_debuggeomlib
!!debuggeomlib
        WRITE (200,*) 'RETURN onvertice,kan=0:',x,y
        CALL FLUSH(200)
        WRITE (300,*) x,y,0
        CALL FLUSH(300)
!!debuggeomlib
#endif
                SWnode=0
                RETURN
             ENDIF
          ENDIF
!
       ENDIF
    ENDIF
!
    around = ((kx == 1) .and. (ky == 1))
!
  ENDDO! ((.NOT.around).OR.(.NOT.ll_onvertice))
!
! 1.2 Algorithme 2 : Recherche au plus pres
! ----------------------------------------
!
  IF (ic==2) THEN
#if defined key_global
     icm1=ncan1-1
#else
     icm1=2
#endif
  ELSE
     icm1=ic-1
  ENDIF
  IF (ic==ncan1-1) THEN
#if defined key_global
     icp1=2
#else
     icp1=ncan1-1
#endif
  ELSE
     icp1=ic+1
  ENDIF
  IF (jc==2) THEN
     jcm1=2
  ELSE       
     jcm1=jc-1
  ENDIF
!
#if defined key_global
  IF (jc==ncan2-3) THEN
     jcp1=ncan2-3
#else
  IF (jc==ncan2-1) THEN
! Correction     jc=ncan1-1
     jcp1=ncan2-1 
#endif
  ELSE
     jcp1=jc+1
  ENDIF
!
  dist(1)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icm1,jcm1),ycan(icm1,jcm1))
  dist(2)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(ic,jcm1),ycan(ic,jcm1))
  dist(3)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icp1,jcm1),ycan(icp1,jcm1))
  dist(4)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icp1,jc),ycan(icp1,jc))
  dist(5)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icp1,jcp1),ycan(icp1,jcp1))
  dist(6)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(ic,jcp1),ycan(ic,jcp1))
  dist(7)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icm1,jcp1),ycan(icm1,jcp1))
  dist(8)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icm1,jc),ycan(icm1,jc))
  distmax=MAXVAL(dist(1:8))
!
  dist0=distancenorm(x,y,xcan(ic,jc),ycan(ic,jc))
!
#if defined key_debuggeomlib
!!debuggeomlib
     WRITE (120,*) 'debugalgo0',x,y,ic,jc
     WRITE (120,*) 'debugalgo0',dist0,distmax
        CALL FLUSH(120)
!!debuggeomlib
#endif
!
  IF (dist0>distmax) THEN
!
     icandeb0=ic
     jcandeb0=jc
!
     dist(1)=distancenorm(x,y,xcan(icm1,jcm1),ycan(icm1,jcm1))
     dist(2)=distancenorm(x,y,xcan(ic,jcm1),ycan(ic,jcm1))
     dist(3)=distancenorm(x,y,xcan(icp1,jcm1),ycan(icp1,jcm1))
     dist(4)=distancenorm(x,y,xcan(icp1,jc),ycan(icp1,jc))
     dist(5)=distancenorm(x,y,xcan(icp1,jcp1),ycan(icp1,jcp1))
     dist(6)=distancenorm(x,y,xcan(ic,jcp1),ycan(ic,jcp1))
     dist(7)=distancenorm(x,y,xcan(icm1,jcp1),ycan(icm1,jcp1))
     dist(8)=distancenorm(x,y,xcan(icm1,jc),ycan(icm1,jc))
     distmin=MINVAL(dist(1:8))
!
     DO WHILE ( (dist0>distmin) .AND. (dist0>distmax) )
!
        dic=0
        djc=0
        icdijc=ic
        jcdijc=jc
!
        IF ( (dist(1)==distmin).OR.(dist(7)==distmin) &
             .OR.(dist(8)==distmin) ) THEN
           dic=-1
           icdijc=icm1
        ELSE
           IF ( (dist(3)==distmin).OR.(dist(4)==distmin) &
                .OR.(dist(5)==distmin) ) THEN
              dic=1
              icdijc=icp1
           ENDIF                        
        ENDIF
!
        IF ( (dist(1)==distmin).OR.(dist(2)==distmin) &
             .OR.(dist(3)==distmin) ) THEN
           djc=-1
           jcdijc=jcm1
        ELSE
           IF ( (dist(5)==distmin).OR.(dist(6)==distmin) &
                .OR.(dist(7)==distmin) ) THEN
              djc=1
              jcdijc=jcp1
           ENDIF
        ENDIF
!
        distdijc=distmin
!
        DO WHILE ( ( distdijc < dist0 ) &
             .AND. ( (ic/=icdijc).OR.(jc/=jcdijc) ) )
!
! nouveau point central
!
           ic=icdijc
           jc=jcdijc
           dist0=distdijc
!
! on teste dans direction (dic,djc)
!
           IF ((ic+dic)==1) THEN
#if defined key_global
              icdijc=ncan1-1
#else
              icdijc=2
#endif
           ELSE
              IF ((ic+dic)==ncan1) THEN
#if defined key_global
                 icdijc=2
#else
                 icdijc=ncan1-1
#endif
              ELSE      
                 icdijc=ic+dic
              ENDIF
           ENDIF
           IF ((jc+djc)==1) THEN
              jcdijc=2
           ELSE
#if defined key_global
              IF ((jc+djc)>=(ncan2-2)) THEN
                 jcdijc=ncan2-3
#else
              IF ((jc+djc)==ncan2) THEN
                 jcdijc=ncan2-1
#endif
              ELSE
                 jcdijc=jc+djc
              ENDIF
           ENDIF
!
           distdijc=distancenorm(x,y,xcan(icdijc,jcdijc),ycan(icdijc,jcdijc))
!
        ENDDO!( distdijc < dist0 )
!
        IF (ic==2) THEN
#if defined key_global
           icm1=ncan1-1
#else
           icm1=2
#endif
        ELSE
           icm1=ic-1
        ENDIF
!
        IF (ic==ncan1-1) THEN
#if defined key_global
           icp1=2
#else
           icp1=ncan1-1
#endif
        ELSE
           icp1=ic+1
        ENDIF
!
        IF (jc==2) THEN
           jcm1=2
        ELSE       
           jcm1=jc-1
        ENDIF
!
#if defined key_global
        IF (jc==ncan2-3) THEN
           jcp1=ncan2-3
#else
        IF (jc==ncan2-1) THEN
           jcp1=ncan2-1
#endif
        ELSE
           jcp1=jc+1
        ENDIF
!
        dist(1)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icm1,jcm1),ycan(icm1,jcm1))
        dist(2)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(ic,jcm1),ycan(ic,jcm1))
        dist(3)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icp1,jcm1),ycan(icp1,jcm1))
        dist(4)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icp1,jc),ycan(icp1,jc))
        dist(5)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icp1,jcp1),ycan(icp1,jcp1))
        dist(6)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(ic,jcp1),ycan(ic,jcp1))
        dist(7)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icm1,jcp1),ycan(icm1,jcp1))
        dist(8)=distancenorm(xcan(ic,jc),ycan(ic,jc),xcan(icm1,jc),ycan(icm1,jc))
        distmax=MAXVAL(dist(1:8))
!
        dist(1)=distancenorm(x,y,xcan(icm1,jcm1),ycan(icm1,jcm1))
        dist(2)=distancenorm(x,y,xcan(ic,jcm1),ycan(ic,jcm1))
        dist(3)=distancenorm(x,y,xcan(icp1,jcm1),ycan(icp1,jcm1))
        dist(4)=distancenorm(x,y,xcan(icp1,jc),ycan(icp1,jc))
        dist(5)=distancenorm(x,y,xcan(icp1,jcp1),ycan(icp1,jcp1))
        dist(6)=distancenorm(x,y,xcan(ic,jcp1),ycan(ic,jcp1))
        dist(7)=distancenorm(x,y,xcan(icm1,jcp1),ycan(icm1,jcp1))
        dist(8)=distancenorm(x,y,xcan(icm1,jc),ycan(icm1,jc))
        distmin=MINVAL(dist(1:8))
!
     ENDDO!( (dist0>distmin) .AND. (dist0>distmax) )
!
#if defined key_debuggeomlib
!!debuggeomlib
     IF ((icandeb0/=ic).OR.(jcandeb0/=jc)) THEN
        WRITE (121,*) 'debugalgo1',x,y,ic,jc,icandeb0,jcandeb0
        WRITE (121,*) 'debugalgo1',dist0
        CALL FLUSH(121)
     ENDIF
!!debuggeomlib
#endif
!
  ENDIF!(dist0>=distmax)
!
  icandeb=ic
  jcandeb=jc
!
  ionvertice=0
  ionboundary=0
!
! II - Recherche around [icandeb,jcandeb]
! ---------------------------------------
!
#if defined key_debuggeomlib
    WRITE(0,*) 'Recherche around'
#endif
  DO ipoint=1,4
!
     SELECT CASE(ipoint)
     CASE(1)
!
! 1: test (icandeb,jcandeb)
!
        icansw=icandeb
        icanne=icansw+1
!#if defined key_global
        IF ( icansw == ncan1-1 ) icanne=2
!#endif
        jcansw=jcandeb
        jcanne=jcansw+1
!
     CASE(2)
!
! 2: test (icandeb-1,jcandeb)
!
        icansw=icandeb-1
        icanne=icandeb
!#if defined key_global
        IF ( icanne == 2 ) icansw=ncan1-1
!#endif
        jcansw=jcandeb
        jcanne=jcansw+1
!
     CASE(3)
!
! 3: test (icandeb-1,jcandeb-1)
!
        icansw=icandeb-1
        icanne=icandeb
!#if defined key_global
        IF ( icanne == 2 ) icansw=ncan1-1
!#endif
        jcansw=jcandeb-1
        jcanne=jcandeb
!
     CASE(4)
!
! 4: test (icandeb,jcandeb-1)
!
        icansw=icandeb
        icanne=icansw+1
!#if defined key_global
        IF ( icansw == ncan1-1 ) icanne=2
!#endif
        jcansw=jcandeb-1
        jcanne=jcandeb
!
     END SELECT
!
     xv(1) = xcan(icansw,jcansw) - x
     xv(2) = xcan(icansw,jcanne) - x
     xv(3) = xcan(icanne,jcanne) - x
     xv(4) = xcan(icanne,jcansw) - x
     yv(1) = ycan(icansw,jcansw) - y
     yv(2) = ycan(icansw,jcanne) - y
     yv(3) = ycan(icanne,jcanne) - y
     yv(4) = ycan(icanne,jcansw) - y
#ifdef NO_NORMLON
#else
!#if defined key_global
!  modifs cas global :
     IF ( ifconv /= 0 ) THEN
        CALL normLon(xv(1))
        CALL normLon(xv(2))
        CALL normLon(xv(3))
        CALL normLon(xv(4))
     ENDIF
!#endif
#endif
     !IF ( insidecell0(xv,yv) ) THEN
     IF ( insideCellstrict(xv,yv) ) THEN
!
        ll_return=.TRUE.
        vertex(1)=kanvas(icansw,jcansw)
        vertex(2)=kanvas(icanne,jcansw)
        vertex(3)=kanvas(icanne,jcanne)
        vertex(4)=kanvas(icansw,jcanne)
!
        IF (ANY (vertex(1:4)==0) ) THEN
! au moins un des 4 sommet est terre
!
           IF (ANY (vertex(1:4)/=0) ) THEN
! au moins un des 4 sommet est ocean
!
           IF ( .NOT.insidecellstrict(xv,yv) ) THEN
!
! obs est sur sommet ou boundary
!
! recherche si obs est only sur sommet cas classique
!
              lla_onvertice(1:4)=( (xv(1:4)==0) .AND. (yv(1:4)==0) ) 
!
              IF (ANY (lla_onvertice(1:4) ) ) THEN
                 ! obs est only sur sommet cas classique
                 IF (ionboundary/=0) THEN
                    WRITE (0,*) 'geomlib: error0 algorithme (ionboundary/=0) and ANY(lla_onvertice(1:4))',&
                         ionboundary,lla_onvertice(1:4),ionvertice
                    WRITE (0,*) 'geomlib: x,y=',x,y
                    WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                    WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                    CALL FLUSH(0)
                    STOP
                 ENDIF
!
                 IF ( ANY( lla_onvertice(1:4).AND.(vertex(1:4)/=0) ) ) THEN
! obs est sur sommet valide on pourra continuer a chercher
                    IF (ionvertice==0) THEN
! le premier trouve: il en restera 3 a tester au cas ou les cellules voisines seraient valides
                       ionvertice=3
                    ELSE
! le suivant trouve: il en reste ionvertice a tester au cas ou les cellules voisines seraient valides
                       ionvertice=ionvertice-1
                    ENDIF
                    ll_return=(ionvertice==0)
                 ENDIF
              ELSE   
! obs est sur boundary mais pas sur sommet
                 IF (ionvertice/=0) THEN
                    WRITE (0,*) 'geomlib: error0 algorithme (ionvertice/=0) and (.NOT.ANY(lla_onvertice(1:4)))',&
                         ionvertice,lla_onvertice(1:4),ionboundary
                    WRITE (0,*) 'geomlib: x,y=',x,y
                    WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                    WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                    CALL FLUSH(0)
                    STOP
                 ENDIF
                 IF (ionboundary==0) THEN
! le premier trouve: il en restera 1 a tester au cas ou la cellule voisine serait valide
                    ionboundary=1
                 ELSE
! le suivant trouve: il en reste  ionboundarya tester
                    ionboundary=ionboundary-1
                 ENDIF
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (ionboundary==0) THEN
                 WRITE (140,*) 'x,y0',x,y,ionboundary
                 CALL FLUSH(140)
                 WRITE (141,*) 'x,y0',x,y,ionboundary
                 CALL FLUSH(141)
                 ELSE
                 WRITE (141,*) 'x,y0',x,y,ionboundary
                 CALL FLUSH(141)
                 ENDIF
!!debuggeomlib
#endif
                 ll_return=(ionboundary==0)
              ENDIF!(ANY (lla_onvertice(1:4) ) )
!
           ENDIF!( .NOT.insidecellstrict(xv,yv) )
!
        ENDIF!(ANY (vertex(1:4)/=0) )

!!! Patch lorsque les 4 points ne sont pas trouvés
!       Changement C.REGNIER Octobre 2008
!       La cellule est trouvée mais c'est de la terre donc il faut rechercher
!       le point mer le plus proche  

IF (COUNT(vertex(:)==0)==4) THEN  
il_nlargeur=2
il_indice=1
!* valeur de la largeur de la recherche fixée
! en dur +allocate => pas très propre mais on fixe à 2 la longueur significative
! de recherche
ALLOCATE(ila_var(3*8))
!** Initialisation
ila_var(:)=il_miss
  DO il_largeur = 1,il_nlargeur
! Test sens vertical +1  . |
     il_p = il_largeur
      DO il_q = -il_largeur, il_largeur
      ican_new=icansw+il_p
      jcan_new=jcansw+il_q 
      IF ( ican_new <= ncan1 .AND. jcan_new <= ncan2 .AND. ican_new > 0 .AND. jcan_new > 0  ) THEN 
       ! PRINT *,'Vert ::',ican_new,jcan_new 
        ila_var(il_indice)=kanvas(ican_new,jcan_new)
      ELSE
        ila_var(il_indice)=il_miss
      ENDIF 
      il_indice= il_indice+1
     ENDDO
 ! Test sens vertical -1  | .
      il_p = -il_largeur
      il_indice=1
      DO il_q = -il_largeur, il_largeur
         ican_new=icansw+il_p
         jcan_new=jcansw+il_q 
         IF ( ican_new <= ncan1 .AND. jcan_new <= ncan2 .AND. ican_new > 0 .AND. jcan_new > 0 ) THEN     
          ! PRINT *,'Vert -1 ::',ican_new,jcan_new  
           ila_var(il_indice)=kanvas(ican_new,jcan_new)
         ELSE
           ila_var(il_indice)=il_miss
 	 ENDIF 
         il_indice= il_indice+1
      ENDDO
  ! Test sens horizontal +1   
      il_q = il_largeur
      il_indice=1
      DO il_p = -il_largeur+1, il_largeur-1
         ican_new=icansw+il_p
         jcan_new=jcansw+il_q  
         IF ( ican_new <= ncan1 .AND. jcan_new <= ncan2 .AND. ican_new > 0 .AND. jcan_new > 0  ) THEN      
          !PRINT *,'H +1 ::',ican_new,jcan_new
          ila_var(il_indice)=kanvas(ican_new,jcan_new)
        ELSE
          ila_var(il_indice)=il_miss
	ENDIF 
	il_indice= il_indice+1
      ENDDO
 ! Test sens horizontal -1  
      il_q = -il_largeur
      il_indice=1
      DO il_p = -il_largeur+1, il_largeur-1
         ican_new=icansw+il_p
         jcan_new=jcansw+il_q  
         IF ( ican_new <= ncan1 .AND. jcan_new <= ncan2 .AND. ican_new > 0 .AND. jcan_new > 0  ) THEN        
 	  !PRINT *,'H -1 ::',ican_new,jcan_new
          ila_var(il_indice)=kanvas(ican_new,jcan_new)
 	 ELSE
          ila_var(il_indice)=il_miss
         ENDIF 
         il_indice= il_indice+1
      ENDDO
   ENDDO
  
  ! IF ( COUNT( ila_var(:) == 0 ) /= SIZE( ila_var(:) ) ) THEN ! Correc bl
   IF ( ( COUNT( ila_var(:) == 0 ) + COUNT( ila_var(:) == il_miss ) ) /= SIZE( ila_var(:) ) ) THEN ! Correc bl  
   ALLOCATE (rla_distance(size(ila_var(:))))
   rla_distance(:)=0
     DO il_k=1,size(ila_var(:))
        IF ( (ila_var(il_k) /=0) .AND. (ila_var(il_k) /= il_miss) ) THEN
           il_ivertex=ida_igrd(ila_var(il_k))
           il_jvertex=ida_jgrd(ila_var(il_k))
           rl_lon=xcan(il_ivertex,il_jvertex)
           rl_lat=ycan(il_ivertex,il_jvertex)
           CALL MCAL_compute_distance(x,y,rl_lon,rl_lat,rl_dist)
           rla_distance(il_k)=rl_dist
        ENDIF
     ENDDO
     il_var=MINLOC(rla_distance, dim =1,mask = rla_distance > 0.0)
  ELSE !bl
     il_var = 0 !bl
  ENDIF !bl

   IF ( il_var /= 0 .AND. il_var < 24 ) THEN     
      vertex(1)=ila_var(il_var)
   ELSE
      !! Pas vertex trouvé on est dans le masque de la grille trop loin des données
      vertex(1)=0.
   ENDIF
ENDIF !IF (COUNT(vertex(:)==0)==4)

ENDIF!(ANY (vertex(1:4)==0) )
!
   IF (ll_return) THEN
#if defined key_debuggeomlib
      !!debuggeomlib
      IF ( vertex(1) == 0) THEN
         WRITE (201,*) 'RETURN 2',x,y
         CALL FLUSH(201)
         WRITE (300,*) x,y,0
         CALL FLUSH(300)
      ELSE
         WRITE (202,*) 'RETURN 2',x,y,vertex(1)
         CALL FLUSH(202)
         WRITE (301,*) x,y,1
         CALL FLUSH(301)
      ENDIF
      !!debuggeomlib
#endif
      SWnode = vertex(1)
      RETURN
   ENDIF!ll_return
   !
ENDIF!( insidecell0(xv,yv) )
!
ENDDO

! III - Recherche en spirale
! ----------------------------
!
#if defined key_debuggeomlib
   WRITE(0,*)  'Debut recherche spirale'
!!debuggeomlib
  IF (kanvas(icandeb,jcandeb) == 0) THEN
!
     WRITE (131,*) 'debugrate0',x,y
     WRITE (131,*) 'debugrate0',kanvas(icandeb,jcandeb),icandeb,jcandeb
     WRITE (131,*) 'debugrate0.1',xcan(icandeb,jcandeb)
     WRITE (131,*) 'debugrate0.2',ycan(icandeb,jcandeb)
     CALL FLUSH(131)
!
     WRITE (132,*) 'debugtot = 0',x,y
     CALL FLUSH(132)
!
  ELSE
!
     WRITE (133,*) 'debugrate0',x,y
     WRITE (133,*) 'debugrate0',kanvas(icandeb,jcandeb),icandeb,jcandeb
     WRITE (133,*) 'debugrate0.1',xcan(icandeb,jcandeb)
     WRITE (133,*) 'debugrate0.2',ycan(icandeb,jcandeb)
     CALL FLUSH(133)
!
     WRITE (134,*) 'debugtot  /= 0',x,y
     CALL FLUSH(134)
!
  ENDIF
!!debuggeomlib
#endif
!
  il_largeur_max = MAX(ncan1,ncan2)
!
 DO largeur = 1,il_largeur_max
!
     p = largeur
     DO q = -largeur, largeur
!
        icansw=icandeb+p
        jcansw=jcandeb+q
!
        IF (     icansw >= 2         &
             .AND. jcansw >= 2         &
#if defined key_global
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-2       ) THEN
#else
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-1       ) THEN
#endif 
!
           icanne=icansw+1
!#if defined key_global
           IF ( icansw == ncan1-1 ) icanne=2
!#endif
           jcanne=jcansw+1
!
           xv(1) = xcan(icansw,jcansw) - x
           xv(2) = xcan(icansw,jcanne) - x
           xv(3) = xcan(icanne,jcanne) - x
           xv(4) = xcan(icanne,jcansw) - x
           yv(1) = ycan(icansw,jcansw) - y
           yv(2) = ycan(icansw,jcanne) - y
           yv(3) = ycan(icanne,jcanne) - y
           yv(4) = ycan(icanne,jcansw) - y
#ifdef NO_NORMLON
#else
!#if defined key_global
!  modifs cas global :
           IF ( ifconv /= 0 ) THEN
              CALL normLon(xv(1))
              CALL normLon(xv(2))
              CALL normLon(xv(3))
              CALL normLon(xv(4))
           ENDIF
!#endif
#endif
           IF ( insidecellstrict(xv,yv) ) THEN
!
              ll_return=.TRUE.
              vertex(1)=kanvas(icansw,jcansw)
              vertex(2)=kanvas(icanne,jcansw)
              vertex(3)=kanvas(icanne,jcanne)
              vertex(4)=kanvas(icansw,jcanne)
#if defined key_debuggeomlib
!!debuggeomlib
              getVertices=( ALL(vertex(1:4)/=0) )
!!debuggeomlib
#endif
!
              IF (ANY (vertex(1:4)==0) ) THEN
! au moins un des 4 sommet est terre
!
                 IF (ANY (vertex(1:4)/=0) ) THEN
! au moins un des 4 sommet est ocean
!
                 IF ( .NOT.insidecellstrict(xv,yv) ) THEN
!
! obs est sur sommet ou boundary
!
! recherche si obs est only sur sommet cas classique
!
                    lla_onvertice(1:4)=( (xv(1:4)==0) .AND. (yv(1:4)==0) ) 
!
                    IF (ANY (lla_onvertice(1:4) ) ) THEN
! obs est only sur sommet cas classique
                       IF (ionboundary/=0) THEN
                          WRITE (0,*) 'geomlib: error1 algorithme (ionboundary/=0) and ANY(lla_onvertice(1:4))',&
                               ionboundary,lla_onvertice(1:4),ionvertice
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF ( ANY( lla_onvertice(1:4).AND.(vertex(1:4)/=0) ) ) THEN
! obs est sur sommet valide on pourra continuer a chercher
                          IF (ionvertice==0) THEN
! le premier trouve: il en restera 3 a tester au cas ou les cellules voisines seraient valides
                             ionvertice=3
                          ELSE
! le suivant trouve: il en reste ionvertice a tester au cas ou les cellules voisines seraient valides
                             ionvertice=ionvertice-1
                          ENDIF
                          ll_return=(ionvertice==0)
                       ENDIF
                    ELSE   
! obs est sur boundary mais pas sur sommet
                       IF (ionvertice/=0) THEN
                          WRITE (0,*) 'geomlib: error algorithme1 (ionvertice/=0) and (.NOT.ANY(lla_onvertice(1:4)))',&
                               ionvertice,lla_onvertice(1:4),ionboundary
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF (ionboundary==0) THEN
! le premier trouve: il en restera 1 a tester au cas ou la cellule voisine serait valide
                          ionboundary=1
                       ELSE
! le suivant trouve: il en reste ionvertice a tester
                          ionboundary=ionboundary-1
                       ENDIF
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (ionboundary==0) THEN
                 WRITE (140,*) 'x,y1',x,y,ionboundary
                 CALL FLUSH(140)
                 WRITE (141,*) 'x,y1',x,y,ionboundary
                 CALL FLUSH(141)
                 ELSE
                 WRITE (141,*) 'x,y1',x,y,ionboundary
                 CALL FLUSH(141)
                 ENDIF
!!debuggeomlib
#endif
                       ll_return=(ionboundary==0)
                    ENDIF!(ANY (lla_onvertice(1:4) ) )
!
                 ENDIF!( .NOT.insidecellstrict(xv,yv) )
!
                 ENDIF!(ANY (vertex(1:4)/=0) )
!
!                 vertex(1:4)=0
!
              ENDIF!(ANY (vertex(1:4)==0) )
!
              IF (ll_return) THEN
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (getVertices) THEN
                    IF ( vertex(1) == 0) THEN
                       WRITE (203,*) 'RETURN 3',x,y,vertex(1),largeur
                       CALL FLUSH(203)
                       WRITE (300,*) x,y,0
                       CALL FLUSH(300)
                    ELSE
                       WRITE (204,*) 'RETURN 4',x,y,vertex(1),largeur
                       CALL FLUSH(204)
                       WRITE (301,*) x,y,1
                       CALL FLUSH(301)
                    ENDIF
                 ELSE
                    IF (vertex(1) == 0) THEN
                       WRITE (205,*) 'RETURN 5',x,y,largeur
                       CALL FLUSH(205)
                    ELSE
                       WRITE (206,*) 'RETURN 6',x,y,largeur
                       CALL FLUSH(206)
                    ENDIF
                    WRITE (300,*) x,y,0
                    CALL FLUSH(300)
                 ENDIF
!!debuggeomlib
#endif
                 SWnode = vertex(1)
                 RETURN
              ENDIF!ll_return
!
           ENDIF!( insidecell0(xv,yv) )
!
        ENDIF
!
     ENDDO
!
     p = -largeur
     IF (largeur==1) THEN
        inddeb=1
        indfin=1
     ELSE
        inddeb=-largeur
        indfin=largeur
     ENDIF
     DO q = inddeb, indfin
!
        icansw=icandeb+p
        jcansw=jcandeb+q
!
        IF (     icansw >= 2         &
             .AND. jcansw >= 2         &
#if defined key_global
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-2       ) THEN
#else
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-1       ) THEN
#endif 
!
           icanne=icansw+1
!#if defined key_global
           IF ( icansw == ncan1-1 ) icanne=2
!#endif
           jcanne=jcansw+1

           xv(1) = xcan(icansw,jcansw) - x
           xv(2) = xcan(icansw,jcanne) - x
           xv(3) = xcan(icanne,jcanne) - x
           xv(4) = xcan(icanne,jcansw) - x
           yv(1) = ycan(icansw,jcansw) - y
           yv(2) = ycan(icansw,jcanne) - y
           yv(3) = ycan(icanne,jcanne) - y
           yv(4) = ycan(icanne,jcansw) - y
#ifdef NO_NORMLON
#else
!#if defined key_global
!  modifs cas global :
           IF ( ifconv /= 0 ) THEN
              CALL normLon(xv(1))
              CALL normLon(xv(2))
              CALL normLon(xv(3))
              CALL normLon(xv(4))
           ENDIF
!#endif
#endif

           IF ( insidecellstrict(xv,yv) ) THEN
  !
             
              st1 = xv(1)*yv(2) - yv(1)*xv(2)
              st2 = xv(2)*yv(3) - yv(2)*xv(3)
              st3 = xv(3)*yv(4) - yv(3)*xv(4)
              st4 = xv(4)*yv(1) - yv(4)*xv(1)
               
              ll_return=.TRUE.
              vertex(1)=kanvas(icansw,jcansw)
              vertex(2)=kanvas(icanne,jcansw)
              vertex(3)=kanvas(icanne,jcanne)
              vertex(4)=kanvas(icansw,jcanne)
#if defined key_debuggeomlib
              WRITE(0,*) 'On est dans insidecellstrict',insidecellstrict(xv,yv),ll_return
              WRITE(0,*) 'paramètres xv,yv :: ',xv,yv
              WRITE(0,*) 'paramètres w :: ',icansw,jcansw
              WRITE(0,*) 'paramètres e :: ',icanne,jcanne
              WRITE(0,*) 'vertex (1) :: ',kanvas(icansw,jcansw)
              WRITE(0,*) 'vertex (2) :: ',kanvas(icanne,jcansw)
              WRITE(0,*) 'vertex (3) :: ',kanvas(icanne,jcanne)
              WRITE(0,*) 'vertex (4) :: ',kanvas(icansw,jcanne)
              !WRITE(0,*) 'kanvas :: ',kanvas(icanne,:)
!!debuggeomlib
              getVertices=( ALL(vertex(1:4)/=0) )
              WRITE(0,*) 'vertex',vertex(1:4)
!!debuggeomlib
#endif
!
              IF (ANY (vertex(1:4)==0) ) THEN
! au moins un des 4 sommet est terre
#if defined key_debuggeomlib
                 WRITE(0,*) 'au moins un des 4 sommet est terre'
#endif
!
                 IF (ANY (vertex(1:4)/=0) ) THEN
! au moins un des 4 sommet est ocean
!
                 IF ( .NOT.insidecellstrict(xv,yv) ) THEN
!
! obs est sur sommet ou boundary
!
! recherche si obs est only sur sommet cas classique
!
                    lla_onvertice(1:4)=( (xv(1:4)==0) .AND. (yv(1:4)==0) ) 
!
                    IF (ANY (lla_onvertice(1:4) ) ) THEN
! obs est only sur sommet cas classique
                       IF (ionboundary/=0) THEN
                          WRITE (0,*) 'geomlib: error2 algorithme (ionboundary/=0) and ANY(lla_onvertice(1:4))',&
                               ionboundary,lla_onvertice(1:4),ionvertice
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF ( ANY( lla_onvertice(1:4).AND.(vertex(1:4)/=0) ) ) THEN
                          IF (ionvertice==0) THEN
! le premier trouve: il en restera 3 a tester au cas ou les cellules voisines seraient valides
                             ionvertice=3
                          ELSE
! le suivant trouve: il en reste ionvertice a tester au cas ou les cellules voisines seraient valides
                             ionvertice=ionvertice-1
                          ENDIF
                          ll_return=(ionvertice==0)
                       ENDIF
                    ELSE   
! obs est sur boundary mais pas sur sommet
                       IF (ionvertice/=0) THEN
                          WRITE (0,*) 'geomlib: error2 algorithme (ionvertice/=0) and (.NOT.ANY(lla_onvertice(1:4)))',&
                               ionvertice,lla_onvertice(1:4),ionboundary
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF (ionboundary==0) THEN
! le premier trouve: il en restera 1 a tester au cas ou la cellule voisine serait valide
                          ionboundary=1
                       ELSE
! le suivant trouve: il en reste ionvertice a tester
                          ionboundary=ionboundary-1
                       ENDIF
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (ionboundary==0) THEN
                 WRITE (140,*) 'x,y2',x,y,ionboundary
                 CALL FLUSH(140)
                 WRITE (141,*) 'x,y2',x,y,ionboundary
                 CALL FLUSH(141)
                 ELSE
                 WRITE (141,*) 'x,y2',x,y,ionboundary
                 CALL FLUSH(141)
                 ENDIF
!!debuggeomlib
#endif
                       ll_return=(ionboundary==0)
                    ENDIF!(ANY (lla_onvertice(1:4) ) )
!
                 ENDIF!( .NOT.insidecellstrict(xv,yv) )
!
                 ENDIF!(ANY (vertex(1:4)/=0) )
!
!                 vertex(1:4)=0
!
              ENDIF!(ANY (vertex(1:4)==0) )
!
              IF (ll_return) THEN
#if defined key_debuggeomlib
!!debuggeomlib:
                 IF (getVertices) THEN
                    IF ( vertex(1) == 0) THEN
                       WRITE (203,*) 'RETURN 3',x,y,vertex(1),largeur
                       CALL FLUSH(203)
                       WRITE (300,*) x,y,0
                       CALL FLUSH(300)
                    ELSE
                       WRITE (204,*) 'RETURN 4',x,y,vertex(1),largeur
                       CALL FLUSH(204)
                       WRITE (301,*) x,y,1
                       CALL FLUSH(301)
                    ENDIF
                 ELSE
                    IF (vertex(1) == 0) THEN
                       WRITE (205,*) 'RETURN 5',x,y,largeur
                       CALL FLUSH(205)
                    ELSE
                       WRITE (206,*) 'RETURN 6',x,y,largeur
                       CALL FLUSH(206)
                    ENDIF
                    WRITE (300,*) x,y,0
                    CALL FLUSH(300)
                 ENDIF
!!debuggeomlib
#endif
                 SWnode = vertex(1)
                 RETURN
              ENDIF!ll_return
!
           ENDIF!( insidecell0(xv,yv) )
!
        ENDIF
!
     ENDDO
!
     q = largeur
     DO p = -largeur+1, largeur-1
!
        icansw=icandeb+p
        jcansw=jcandeb+q
!
        IF (     icansw >= 2         &
             .AND. jcansw >= 2         &
#if defined key_global
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-2       ) THEN
#else
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-1       ) THEN
#endif 
!
           icanne=icansw+1
!#if defined key_global
           IF ( icansw == ncan1-1 ) icanne=2
!#endif
           jcanne=jcansw+1
!
           xv(1) = xcan(icansw,jcansw) - x
           xv(2) = xcan(icanne,jcansw) - x
           xv(3) = xcan(icanne,jcanne) - x
           xv(4) = xcan(icansw,jcanne) - x
 
           yv(1) = ycan(icansw,jcansw) - y
           yv(2) = ycan(icanne,jcansw) - y
           yv(3) = ycan(icanne,jcanne) - y
           yv(4) = ycan(icansw,jcanne) - y


          ! xv(1) = xcan(icansw,jcansw) - x
          ! xv(2) = xcan(icansw,jcanne) - x
          ! xv(3) = xcan(icanne,jcanne) - x
          ! xv(4) = xcan(icanne,jcansw) - x
          ! yv(1) = ycan(icansw,jcansw) - y
          ! yv(2) = ycan(icansw,jcanne) - y
          ! yv(3) = ycan(icanne,jcanne) - y
          ! yv(4) = ycan(icanne,jcansw) - y

#ifdef NO_NORMLON
#else
!#if defined key_global
!  modifs cas global :
           IF ( ifconv /= 0 ) THEN
              CALL normLon(xv(1))
              CALL normLon(xv(2))
              CALL normLon(xv(3))
              CALL normLon(xv(4))
           ENDIF
!#endif
#endif
           IF ( insidecellstrict(xv,yv) ) THEN
!
            ll_return=.TRUE.
            vertex(1)=kanvas(icansw,jcansw)
            vertex(2)=kanvas(icanne,jcansw)
            vertex(3)=kanvas(icanne,jcanne)
            vertex(4)=kanvas(icansw,jcanne)
#if defined key_debuggeomlib
!!debuggeomlib
              getVertices=( ALL(vertex(1:4)/=0) )
!!debuggeomlib
#endif
!
              IF (ANY (vertex(1:4)==0) ) THEN
! au moins un des 4 sommet est terre
!
                 IF (ANY (vertex(1:4)/=0) ) THEN
! au moins un des 4 sommet est ocean
!
                 IF ( .NOT.insidecellstrict(xv,yv) ) THEN
!
! obs est sur sommet ou boundary
!
! recherche si obs est only sur sommet cas classique
!
                    lla_onvertice(1:4)=( (xv(1:4)==0) .AND. (yv(1:4)==0) ) 
!
                    IF (ANY (lla_onvertice(1:4) ) ) THEN
! obs est only sur sommet cas classique
                       IF (ionboundary/=0) THEN
                          WRITE (0,*) 'geomlib: error3 algorithme (ionboundary/=0) and ANY(lla_onvertice(1:4) )',&
                               ionboundary,lla_onvertice(1:4),ionvertice
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF ( ANY( lla_onvertice(1:4).AND.(vertex(1:4)/=0) ) ) THEN
                          IF (ionvertice==0) THEN
! le premier trouve: il en restera 3 a tester au cas ou les cellules voisines seraient valides
                             ionvertice=3
                          ELSE
! le suivant trouve: il en reste ionvertice a tester au cas ou les cellules voisines seraient valides
                             ionvertice=ionvertice-1
                          ENDIF
                          ll_return=(ionvertice==0)
                       ENDIF
                    ELSE   
! obs est sur boundary mais pas sur sommet
                       IF (ionvertice/=0) THEN
                          WRITE (0,*) 'geomlib: error3 algorithme (ionvertice/=0) and (.NOT.ANY(lla_onvertice(1:4)))',&
                               ionvertice,lla_onvertice(1:4),ionboundary
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF (ionboundary==0) THEN
! le premier trouve: il en restera 1 a tester au cas ou la cellule voisine serait valide
                          ionboundary=1
                       ELSE
! le suivant trouve: il en reste ionvertice a tester
                          ionboundary=ionboundary-1
                       ENDIF
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (ionboundary==0) THEN
                 WRITE (140,*) 'x,y3',x,y,ionboundary
                 CALL FLUSH(140)
                 WRITE (141,*) 'x,y3',x,y,ionboundary
                 CALL FLUSH(141)
                 ELSE
                 WRITE (141,*) 'x,y3',x,y,ionboundary
                 CALL FLUSH(141)
                 ENDIF
!!debuggeomlib
#endif
                       ll_return=(ionboundary==0)
                    ENDIF!(ANY (lla_onvertice(1:4) ) )
!
                 ENDIF!( .NOT.insidecellstrict(xv,yv) )
!
                 ENDIF!(ANY (vertex(1:4)/=0) )
!
!                 vertex(1:4)=0
!
              ENDIF!(ANY (vertex(1:4)==0) )
!
              IF (ll_return) THEN
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (getVertices) THEN
                    IF ( vertex(1) == 0) THEN
                       WRITE (203,*) 'RETURN 3',x,y,vertex(1),largeur
                       CALL FLUSH(203)
                       WRITE (300,*) x,y,0
                       CALL FLUSH(300)
                    ELSE
                       WRITE (204,*) 'RETURN 4',x,y,vertex(1),largeur
                       CALL FLUSH(204)
                       WRITE (301,*) x,y,1
                       CALL FLUSH(301)
                    ENDIF
                 ELSE
                    IF (vertex(1) == 0) THEN
                       WRITE (205,*) 'RETURN 5',x,y,largeur
                       CALL FLUSH(205)
                    ELSE
                       WRITE (206,*) 'RETURN 6',x,y,largeur
                       CALL FLUSH(206)
                    ENDIF
                    WRITE (300,*) x,y,0
                    CALL FLUSH(300)
                 ENDIF
!!debuggeomlib
#endif
                 !!* Cas particulier 
                 SWnode = vertex(1)
                 RETURN
              ENDIF!ll_return
!
           ENDIF!( insidecell0(xv,yv) )
!
        ENDIF
!
     ENDDO
!
     IF (largeur/=1) THEN
     q = -largeur
     DO p = -largeur+1, largeur-1
!
        icansw=icandeb+p
        jcansw=jcandeb+q
!
        IF (     icansw >= 2         &
             .AND. jcansw >= 2         &
#if defined key_global
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-2       ) THEN
#else
             .AND. icansw <= ncan1-1 &
             .AND. jcansw <= ncan2-1       ) THEN
#endif 
!
           icanne=icansw+1
!#if defined key_global
           IF ( icansw == ncan1-1 ) icanne=2
!#endif
           jcanne=jcansw+1
!
           xv(1) = xcan(icansw,jcansw) - x
           xv(2) = xcan(icansw,jcanne) - x
           xv(3) = xcan(icanne,jcanne) - x
           xv(4) = xcan(icanne,jcansw) - x
           yv(1) = ycan(icansw,jcansw) - y
           yv(2) = ycan(icansw,jcanne) - y
           yv(3) = ycan(icanne,jcanne) - y
           yv(4) = ycan(icanne,jcansw) - y
#ifdef NO_NORMLON
#else
!#if defined key_global
!  modifs cas global :
           IF ( ifconv /= 0 ) THEN
              CALL normLon(xv(1))
              CALL normLon(xv(2))
              CALL normLon(xv(3))
              CALL normLon(xv(4))
           ENDIF
!#endif
#endif
           IF ( insidecellstrict(xv,yv) ) THEN
!
              ll_return=.TRUE.
              vertex(1)=kanvas(icansw,jcansw)
              vertex(2)=kanvas(icanne,jcansw)
              vertex(3)=kanvas(icanne,jcanne)
              vertex(4)=kanvas(icansw,jcanne)
#if defined key_debuggeomlib
              WRITE(0,*) 'insidecellstrict'
!!debuggeomlib
              getVertices=( ALL(vertex(1:4)/=0) )
!!debuggeomlib
#endif
!
              IF (ANY (vertex(1:4)==0) ) THEN
! au moins un des 4 sommet est terre
!
                 IF (ANY (vertex(1:4)/=0) ) THEN
! au moins un des 4 sommet est ocean
!
                 IF ( .NOT.insidecellstrict(xv,yv) ) THEN
!
! obs est sur sommet ou boundary
!
! recherche si obs est only sur sommet cas classique
!
                    lla_onvertice(1:4)=( (xv(1:4)==0) .AND. (yv(1:4)==0) ) 
!
                    IF (ANY (lla_onvertice(1:4) ) ) THEN
! obs est only sur sommet cas classique
                       IF (ionboundary/=0) THEN
                          WRITE (0,*) 'geomlib4: error algorithme (ionboundary/=0) and ANY(lla_onvertice(1:4))',&
                               ionboundary,lla_onvertice(1:4),ionvertice
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF ( ANY( lla_onvertice(1:4).AND.(vertex(1:4)/=0) ) ) THEN
                          IF (ionvertice==0) THEN
! le premier trouve: il en restera 3 a tester au cas ou les cellules voisines seraient valides
                             ionvertice=3
                          ELSE
! le suivant trouve: il en reste ionvertice a tester au cas ou les cellules voisines seraient valides
                             ionvertice=ionvertice-1
                          ENDIF
                          ll_return=(ionvertice==0)
                       ENDIF
                    ELSE   
! obs est sur boundary mais pas sur sommet
                       IF (ionvertice/=0) THEN
                          WRITE (0,*) 'geomlib: error4 algorithme (ionvertice/=0) and (.NOT.ANY(lla_onvertice(1:4)))',&
                               ionvertice,lla_onvertice(1:4),ionboundary
                          WRITE (0,*) 'geomlib: x,y=',x,y
                          WRITE (0,*) 'geomlib: icandeb,jcandeb,largeur=',icandeb,jcandeb,largeur
                          WRITE (0,*) 'geomlib:icansw,jcansw,icansw,jcanne=',icansw,jcansw,icansw,jcanne
                          CALL FLUSH(0)
                          STOP
                       ENDIF
                       IF (ionboundary==0) THEN
! le premier trouve: il en restera 1 a tester au cas ou la cellule voisine serait valide
                          ionboundary=1
                       ELSE
! le suivant trouve: il en reste ionvertice a tester
                          ionboundary=ionboundary-1
                       ENDIF
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (ionboundary==0) THEN
                 WRITE (140,*) 'x,y4',x,y,ionboundary
                 CALL FLUSH(140)
                 WRITE (141,*) 'x,y4',x,y,ionboundary
                 CALL FLUSH(141)
                 ELSE
                 WRITE (141,*) 'x,y4',x,y,ionboundary
                 CALL FLUSH(141)
                 ENDIF
!!debuggeomlib
#endif
                       ll_return=(ionboundary==0)
                    ENDIF!(ANY (lla_onvertice(1:4) ) )
!
                 ENDIF!( .NOT.insidecellstrict(xv,yv) )
!
                 ENDIF!(ANY (vertex(1:4)/=0) )
!
!                 vertex(1:4)=0
!
              ENDIF!(ANY (vertex(1:4)==0) )
!
              IF (ll_return) THEN
#if defined key_debuggeomlib
!!debuggeomlib
                 IF (getVertices) THEN
                    IF ( vertex(1) == 0) THEN
                       WRITE (203,*) 'RETURN 3',x,y,vertex(1),largeur
                       CALL FLUSH(203)
                       WRITE (300,*) x,y,0
                       CALL FLUSH(300)
                    ELSE
                       WRITE (204,*) 'RETURN 4',x,y,vertex(1),largeur
                       CALL FLUSH(204)
                       WRITE (301,*) x,y,1
                       CALL FLUSH(301)
                    ENDIF
                 ELSE
                    IF (vertex(1) == 0) THEN
                       WRITE (205,*) 'RETURN 5',x,y,largeur
                       CALL FLUSH(205)
                    ELSE
                       WRITE (206,*) 'RETURN 6',x,y,largeur
                       CALL FLUSH(206)
                    ENDIF
                    WRITE (300,*) x,y,0
                    CALL FLUSH(300)
                 ENDIF
!!debuggeomlib
#endif
!                 SWnode = vertex(1)
!       Changement C.REGNIER Novembre 2008
!       La cellule est trouvée mais c'est de la terre donc il faut rechercher
!       le point mer le plus proche  
                 IF (COUNT(vertex(:)==0)==4) THEN  
                    il_nlargeur=2
                    il_indice=1
                    !* valeur de la largeur de la recherche fixée
                    ! en dur +allocate => à changer
                    ALLOCATE(ila_var(3*8))
                    DO il_largeur1 = 1,il_nlargeur
                       ! Test sens vertical +1  . |
                       il_p1 = il_largeur1
                       DO il_q1 = -il_largeur1, il_largeur1
                          ican_new=icansw+il_p1
                          jcan_new=jcansw+il_q1  
                          ila_var(il_indice)=kanvas(ican_new,jcan_new)
                          il_indice= il_indice+1
                       ENDDO
                       ! Test sens vertical -1  | .
                       il_p1 = -il_largeur1
                       DO il_q1 = -il_largeur1, il_largeur1
                          ican_new=icansw+il_p1
                          jcan_new=jcansw+il_q1  
                          ila_var(il_indice)=kanvas(ican_new,jcan_new)
                          il_indice= il_indice+1
                       ENDDO
   
                       ! Test sens horizontal +1   
                       il_q1 = il_largeur1
                       DO il_p1 = -il_largeur1+1, il_largeur1-1
                          ican_new=icansw+il_p1
                          jcan_new=jcansw+il_q1  
                          ila_var(il_indice)=kanvas(ican_new,jcan_new)
                          il_indice= il_indice+1
                       ENDDO
                       
                       ! Test sens horizontal -1  
                       il_q1 = -il_largeur1
                       DO il_p1 = -il_largeur1+1, il_largeur1-1
                          ican_new=icansw+il_p1
                          jcan_new=jcansw+il_q1  
                          ila_var(il_indice)=kanvas(ican_new,jcan_new)
                          il_indice= il_indice+1
                       ENDDO
                    ENDDO
                    ALLOCATE (rla_distance(size(ila_var(:))))
                    rla_distance(:)=0
                    DO il_k=1,size(ila_var(:))
                       IF (ila_var(il_k) /=0) THEN
                          il_ivertex=ida_igrd(ila_var(il_k))
                          il_jvertex=ida_jgrd(ila_var(il_k))
                          rl_lon=xcan(il_ivertex,il_jvertex)
                          rl_lat=ycan(il_ivertex,il_jvertex)
                          CALL MCAL_compute_distance(x,y,rl_lon,rl_lat,rl_dist)
                          rla_distance(il_k)=rl_dist
                       ENDIF
                    ENDDO
                    il_var=MINLOC(rla_distance, dim =1,mask = rla_distance > 0.0)
#if defined key_debuggeomlib
        WRITE(0,*) '-------------------------------'
        WRITE(0,*) 'Distance',il_var
        WRITE(0,*) '-------------------------------'
#endif
                    IF ( il_var /= 0 .AND. il_var < 24 ) THEN     
                       vertex(1)=ila_var(il_var)
                    ELSE
                       !! Pas vertex trouvé on est dans le masque de la grille trop loin des données
                       vertex(1)=0.
                    ENDIF
                 ENDIF
                 RETURN
              ENDIF!ll_return
!
           ENDIF!( insidecell0(xv,yv) )
           !
        ENDIF
!
     ENDDO
!#if defined key_debuggeomlib
!     WRITE(0,*) 'SPIRALE4'
!#endif
  ENDIF!(largeur/=1)
!
ENDDO

#if defined key_debuggeomlib
   WRITE(0,*) 'RECHERCHE SPIRALE OK !!'
#endif

#if defined key_debuggeomlib
  WRITE (0,*) "Fin get node "
  WRITE(0,*) 'return', ll_return
!!debuggeomlib
  IF (kanvas(icandeb,jcandeb) == 0) THEN
     WRITE (131,*) 'debugrate2',x,y,largeur,icandeb,jcandeb
     CALL FLUSH(131)
  ELSE
     WRITE (133,*) 'debugrate2',x,y,largeur,icandeb,jcandeb
     CALL FLUSH(133)
  ENDIF
  WRITE (300,*) x,y,0
  CALL FLUSH(300)
  IF ( (ionboundary /= 0) .OR. (ionvertice /= 0) ) THEN
     WRITE (135,*) 'debugrate2',x,y,largeur,icandeb,jcandeb,ionboundary,ionvertice
     CALL FLUSH(135)
  ENDIF
!!debuggeomlib
#endif
!
  SWnode = 0
!
  RETURN

contains
!
!
!==========================================================================
!==========================================================================
! Fonctions et subroutines necessaires à getSWnode_orca_grid
!
!> \brief
!! Description : determines whether two line segments (P1,P2) and (P3,P4) intersect
!! where P1{x1,y1}, P2{x2,y2}, P3{x3,y3}, P1{x4,y4}
!!
!! will return .false. (no intersection) if three/four points are exactly
!! collinear -- this is the fastest configuration to solve: if must report
!! touching lines, change both .ge.'s to .gt.'s and add after both tests 
!! dot-product math to check whether collinear segments are distinct
!!
!! perf: about six million intersections checked per second on O2000
!!
!!=segIntersect= P De Mey (with good help from R Sedgewick)
!!
!<
!========================================================================
LOGICAL FUNCTION segIntersect ( x1, y1, x2, y2, x3, y3, x4, y4 )

  IMPLICIT NONE

  REAL :: x1, y1, x2, y2, x3, y3, x4, y4 
  REAL :: dx, dy, dx1, dy1, dx2, dy2

  segIntersect = .false.

  dx  = x2 - x1
  dy  = y2 - y1
  dx1 = x3 - x1
  dy1 = y3 - y1
  dx2 = x4 - x2
  dy2 = y4 - y2

  IF ( (dx*dy1-dy*dx1)*(dx*dy2-dy*dx2).GE.0.0 ) RETURN

  dx  = x4 - x3
  dy  = y4 - y3

  IF ( (dx*dy1-dy*dx1)*(dx*dy2-dy*dx2).GE.0.0 ) RETURN

  segIntersect = .true.

  RETURN
END FUNCTION segIntersect 

!========================================================================
!
!> brief
!! Description : two-dimensional line-of-sight algorithm with straight wall segments
!! determines whether P2 is visible from P1 (true/false)
!!
!! to optimize : see Shamos and Hoey (1976) using binary trees
!! (described in Sedgewick 1983)
!!
!!=inSight= P De Mey
!!
!<
!==========================================================================

!!LOGICAL FUNCTION inSight ( x1, y1, x2, y2, nw, xw1, xw2, yw1, yw2 )
!!
!!  IMPLICIT NONE
!!  
!!  REAL :: x1, y1, x2, y2
!!  REAL :: x3, y3, x4, y4
!!  INTEGER :: nw
!!  REAL, DIMENSION(nw) :: xw1, yw1, xw2, yw2
!!
!!  LOGICAL :: segIntersect
!!!  EXTERNAL segIntersect
!!  INTEGER kseg
!!
!!  inSight = .true.
!!
!!  DO kseg = 1, nw
!!    x3 = xw1(kseg)
!!    y3 = yw1(kseg)
!!    x4 = xw2(kseg)
!!    y4 = yw2(kseg)
!!    IF ( segIntersect(x1,y1,x2,y2,x3,y3,x4,y4) ) THEN
!!	inSight = .false.
!!	RETURN
!!    END IF
!!  END DO
!!  
!!  RETURN
!!END FUNCTION inSight

!========================================================================
!> \brief
!! Description : determines whether point (xi,yi) lies inside or on boundary of
!! quadrangle of any shape on a plane
!!
!! xv(4), yv(4) are the coordinates of the vertices
!!   vertices must follow each other (ordered clockwise or anticlockwise)
!!
!! perf: about six million quads checked per second on O2000
!!
!!=insideCell= P De Mey
!<
!==========================================================================

LOGICAL FUNCTION insideCell( xi, yi, xv, yv )

  IMPLICIT NONE
  
  REAL :: xi, yi
  REAL, DIMENSION(4) :: xv, yv
  REAL :: st1, st2, st3, st4

  st1 = (xi-xv(1))*(yi-yv(2)) - (yi-yv(1))*(xi-xv(2))
  st2 = (xi-xv(2))*(yi-yv(3)) - (yi-yv(2))*(xi-xv(3))
  st3 = (xi-xv(3))*(yi-yv(4)) - (yi-yv(3))*(xi-xv(4))
  st4 = (xi-xv(4))*(yi-yv(1)) - (yi-yv(4))*(xi-xv(1))

  insideCell =  st1*st2.GE.0.0 .AND. st2*st3.GE.0.0 &
     .AND. st3*st4.GE.0.0 .AND. st4*st1.GE.0.0
  RETURN
END FUNCTION insideCell

!==============================================================================
!> \brief
!! Description : determines whether point (0.0,0.0) lies inside or on boundary of
!! quadrangle of any shape on a plane
!!
!! xv(4), yv(4) are the coordinates of the vertices
!!   vertices must follow each other (ordered clockwise or anticlockwise)
!!
!! perf: about six million quads checked per second on O2000
!!
!!=insideCell0= P De Mey
!<
!=================================================================================
LOGICAL FUNCTION insideCell0( xv, yv )
!

  IMPLICIT NONE

  REAL(KIND=4) ::  xv(4), yv(4)
  REAL(KIND=4) :: st1, st2, st3, st4

  st1 = xv(1)*yv(2) - yv(1)*xv(2)
  st2 = xv(2)*yv(3) - yv(2)*xv(3)
  st3 = xv(3)*yv(4) - yv(3)*xv(4)
  st4 = xv(4)*yv(1) - yv(4)*xv(1)
 
  insideCell0 =  st1*st2.GE.0.0 .AND. st2*st3.GE.0.0 &
     .AND. st3*st4.GE.0.0 .AND. st4*st1.GE.0.0
  
  RETURN 
END FUNCTION insideCell0

!================================================================================
!> \brief
!!
!! Description : Compute distance between (x0,y0) and (xcan0,ycan0) considering space as plane
!!
!!  USE comgen_mod, only : ifconv
!<
!================================================================================
REAL FUNCTION distancenorm( x0,y0,xcan0,ycan0)

  IMPLICIT NONE
  !
  REAL(KIND=4) :: x0,y0,xcan0,ycan0
  REAL(KIND=4) :: dx,dy
  dx =  x0 - xcan0
#ifdef NO_NORMLON
#else
#if defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12 || defined key_orca_r1 ||  defined key_orca_r12_allege
  IF ( ifconv /= 0 ) CALL normLon(dx)
#endif
#endif
  dy = y0 - ycan0
!
  distancenorm= dx*dx+dy*dy
!
  RETURN 
!
END FUNCTION distancenorm

!========================================================================
!> \brief
!!
!! Description : determines whether point (0.0,0.0) lies inside but not on boundary of
!! quadrangle of any shape on a plane
!!
!! xv(4), yv(4) are the coordinates of the vertices
!!   vertices must follow each other (ordered clockwise or anticlockwise)
!!
!! perf: about six million quads checked per second on O2000
!!
!!=insideCell0= P De Mey
!<
!=======================================================================
LOGICAL FUNCTION insideCellstrict( xv, yv )

  IMPLICIT NONE

  REAL(KIND=4) ::  xv(4), yv(4)
  REAL(KIND=4) :: st1, st2, st3, st4

  st1 = xv(1)*yv(2) - yv(1)*xv(2)
  st2 = xv(2)*yv(3) - yv(2)*xv(3)
  st3 = xv(3)*yv(4) - yv(3)*xv(4)
  st4 = xv(4)*yv(1) - yv(4)*xv(1)

  insideCellstrict =  st1*st2.GT.0.0 .AND. st2*st3.GT.0.0 &
     .AND. st3*st4.GT.0.0 .AND. st4*st1.GT.0.0
  
  RETURN 
END FUNCTION insideCellstrict

END SUBROUTINE getSWnode_orca_grid

!========================================================================
!> \brief
!!
!! Description : normalize longitude value or difference across dateline
!!
!!=normLon= P De Mey, M Bremond
!!
!<
!========================================================================
SUBROUTINE normLon( xLon )


  IMPLICIT NONE

  REAL(KIND=4) :: xLon

  IF (( xLon .LE. 180.0 ).AND.( xLon .GT. -180.0)) THEN
      RETURN
  ELSE
      IF ((xLon .GT. 180.0).AND.( xLon .LE. 360.0)) THEN
!cnf          xLon = xLon - 180.0
          xLon = xLon - 360.0
	  RETURN
      ELSE
	  IF ((xLon .GT. -360.0).AND.( xLon .LE. -180.0)) THEN
!cnf              xLon = xLon + 180.0
              xLon = xLon + 360.0
	      RETURN
	  ELSE

! rerange in [0,360[

  xLon = MOD(MOD(xLon,360.0)+360.0,360.0)

! rerange in ]-180,180]
		 
              IF ( xLon.GT.180.0 ) xLon = xLon - 360.0
	      RETURN
	  END IF
      END IF
  END IF

END SUBROUTINE normLon


!========================================================================
#ifdef key_weights_method_PDM
!> \brief
!! Description : interpolation in a quadrangle of any shape on a plane using a
!! hyperbolic paraboloid interpolation surface
!!
!! xv(4), yv(4) are the coordinates at the vertices
!!   vertices must follow each other (ordered clockwise or anticlockwise)
!!   vertices must be distinct (quadrangle must not be singular)
!! xi, yi are the coordinates of interpolation point
!! c(4) gives the linear coefficients of the interpolation at the
!!      corresponding vertices
!!
!! Notes:
!!   dangerous in remote extrapolation as with any 2nd-degree surface
!!  fast, but not a single check is done
!!   perf: about two million interpolations per second on O2000
!!
!!=getNodeWeights= P De Mey (with help from R Baraille and MAPLE V)
!<
!========================================================================
SUBROUTINE getNodeWeights( xi, yi, xv, yv, c )


  IMPLICIT NONE

  REAL, INTENT(IN) :: xi, yi
  REAL, DIMENSION(4),INTENT(IN) ::  xv, yv
  REAL, DIMENSION(4),INTENT(OUT) :: c

  REAL :: hx2, hx3, hx4, hxi, hy2, hy3, hy4, hyi
  REAL :: x23, x34, x42, y23, y34, y42
  REAL :: p2, p3, p4, pi, p23, p34, p42, d

  hx2 = xv(2) - xv(1)
  hx3 = xv(3) - xv(1)
  hx4 = xv(4) - xv(1)
  hxi = xi - xv(1)
  hy2 = yv(2) - yv(1)
  hy3 = yv(3) - yv(1)
  hy4 = yv(4) - yv(1)
  hyi = yi - yv(1)

  x23 = hx3 - hx2
  x34 = hx4 - hx3
  x42 = hx2 - hx4
  y23 = hy3 - hy2
  y34 = hy4 - hy3
  y42 = hy2 - hy4
  p2  = hx2*hy2
  p3  = hx3*hy3
  p4  = hx4*hy4
  pi  = hxi*hyi
  p23 = hx3*hy2 - hx2*hy3
  p34 = hx4*hy3 - hx3*hy4
  p42 = hx2*hy4 - hx4*hy2
  
  d  = p2*p34 + p3*p42 + p4*p23
  c(1) =   (p2*y34+p3*y42+p4*y23)*hxi &
     - (p2*x34+p3*x42+p4*x23)*hyi &
     - (p23+p34+p42)*pi
  c(1) = c(1) / d + 1.0
  c(2) = -hy3*hy4*x34*hxi + hx3*hx4*y34*hyi + p34*pi
  c(2) = c(2) / d
  c(3) = -hy2*hy4*x42*hxi + hx2*hx4*y42*hyi + p42*pi
  c(3) = c(3) / d
  c(4) = -hy2*hy3*x23*hxi + hx2*hx3*y23*hyi + p23*pi
  c(4) = c(4) / d

  RETURN
END SUBROUTINE getNodeWeights
#endif
!========================================================================
!> \brief
!!
!! an interface to getNodeWeights for which only the SW node must be specified
!! assumes that SWnode is valid
!!
!!=getSWnodeWeights= P De Mey
!! modified by B. Tranchant - 06/06/2001
!! JM Lellouche 18/11/2004 : Reecriture
!<
!===========================================================================

SUBROUTINE getSWnodeWeights( x, y, xcan,ycan,vertex, c )

!  USE comgen_mod
  USE PARAM_MOD
  IMPLICIT NONE

  INTEGER, DIMENSION(4), INTENT(IN) :: vertex
  INTEGER :: iv
  REAL(KIND=4), INTENT(IN) :: x, y
  REAL, DIMENSION(4), INTENT(OUT) :: c

!
  REAL(KIND=4) :: xx,rg_plus, rg_moins
  REAL(KIND=4), DIMENSION(4) :: xv, yv
  REAL(KIND=4) :: rl_sum
  REAL(KIND=4), DIMENSION(:,:), INTENT(IN) :: xcan,ycan

#if defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12 || defined key_orca_r12_allege || defined key_atl12 || defined key_atl12_zNEATL36 || defined key_orca_r1 || defined key_med12 || defined key_ibi12 || defined key_ibi36
#ifdef key_weights_method_OASIS
  REAL(KIND=4) :: xvmin,yvmin,xvmax,yvmax
  INTEGER :: iamb1, iamb2
#endif
#endif

#if defined key_minipog || defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12 ||  defined key_orca_r12_allege || defined key_atl12 || defined key_atl12_zNEATL36 || defined key_orca_r1 || defined key_med12 || defined key_ibi12 || defined key_ibi36
  REAL(KIND=4) :: DiffLon
  EXTERNAL DiffLon
#endif

#if ! defined key_weights_method_PDM && ! defined key_weights_method_OASIS
  write(0,*) 'getSWnodeWeights: manque cle  key_weights_method_PDM ou key_weights_method_OASIS'
  call flush(0)
  STOP
#endif

!
! Initialisation
! --------------
  c(1:4) = 0.0
  xx = x
!
! Longitudes et latitudes des 4 points
! ------------------------------------
  DO iv = 1, 4
#if defined key_minipog && defined key_weights_method_PDM
    xv(iv) = DiffLon( xcan(igrd(vertex(iv)),jgrd(vertex(iv))) , xx )
#endif
#if defined key_minipog && defined key_weights_method_OASIS
    xv(iv) = xcan(igrd(vertex(iv)),jgrd(vertex(iv)))
#endif
#if defined key_weights_method_PDM
#if defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12 || defined key_orca_r1 || defined key_orca_r12_allege 
    xv(iv) = DiffLon( xcan(igrd(vertex(iv)),jgrd(vertex(iv))) , xx )
#endif
#if defined key_atl12 || defined key_atl4 || defined key_atl12_zNEATL36 || defined key_med12 || defined key_ibi12 || defined key_ibi36
    xv(iv) = xcan(igrd(vertex(iv)),jgrd(vertex(iv))) - xx
#endif
#endif
#if defined key_weights_method_OASIS
     xv(iv) = xcan(igrd(vertex(iv)),jgrd(vertex(iv)))
#endif
#ifdef NO_NORMLON
#else
    IF ( ifconv.NE.0 ) CALL normLon( xv(iv) )
#endif
#ifdef key_weights_method_PDM
    yv(iv) = ycan(igrd(vertex(iv)),jgrd(vertex(iv))) - y
#endif
#ifdef key_weights_method_OASIS
    yv(iv) = ycan(igrd(vertex(iv)),jgrd(vertex(iv)))
#endif
  END DO

!
! Calcul des poids (doivent etre compris entre 0 et 1)
! ----------------------------------------------------
#ifdef key_weights_method_PDM
  CALL getNodeWeights(0.0,0.0,xv,yv,c)
#endif
#ifdef key_weights_method_OASIS
#if defined key_minipog
!
! Constantes pour gerer l 'ambiguite des 360 degres
! ---------------------------------------------------
  iamb1 = 10   ! dlam < iamb1 * dphi
  iamb2 = 3    ! traitement special si : iamb2 * lam < max(lam)
!
! Normalisation des longitudes : [-180,180[ --> [0,360[  
!------------------------------------------------------
  DO WHILE (    xv(1) < 0. .OR.  xv(1) > 360. &
           .OR. xv(2) < 0. .OR.  xv(2) > 360. &
           .OR. xv(3) < 0. .OR.  xv(2) > 360. &
           .OR. xv(4) < 0. .OR.  xv(2) > 360.)
    IF ( xv(1) < 0.   ) xv(1) = xv(1) + 360.
    IF ( xv(1) > 360. ) xv(1) = xv(1) - 360.
    IF ( xv(2) < 0.   ) xv(2) = xv(2) + 360.
    IF ( xv(2) > 360. ) xv(2) = xv(2) - 360.
    IF ( xv(3) < 0.   ) xv(3) = xv(3) + 360.
    IF ( xv(3) > 360. ) xv(3) = xv(3) - 360.
    IF ( xv(4) < 0.   ) xv(4) = xv(4) + 360.
    IF ( xv(4) > 360. ) xv(4) = xv(4) - 360.
  END DO
!
  xvmin = MIN( xv(1),xv(2),xv(3),xv(4) )
  xvmax = MAX( xv(1),xv(2),xv(3),xv(4) )
  yvmin = MIN( yv(1),yv(2),yv(3),yv(4) ) 
  yvmax = MAX( yv(1),yv(2),yv(3),yv(4) )
!
  IF ( (( xvmax - xvmin ) / ( yvmax - yvmin )) > iamb1 ) THEN
      IF ( iamb2 * xv(1) < xvmax ) xv(1) = xv(1) + 360.
      IF ( iamb2 * xv(2) < xvmax ) xv(2) = xv(2) + 360.
      IF ( iamb2 * xv(3) < xvmax ) xv(3) = xv(3) + 360.
      IF ( iamb2 * xv(4) < xvmax ) xv(4) = xv(4) + 360.
  ENDIF
!
  DO WHILE ( ( xx < 0. ).OR.( xx > 360. ) )
    IF ( xx < 0.   ) xx = xx + 360.
    IF ( xx > 360. ) xx = xx - 360.
  END DO
!
  xvmin = MIN( xv(1),xv(2),xv(3),xv(4) )
  IF ( xx < xvmin ) xx = xx + 360.
#endif
#if defined key_orca_r2 || defined key_orca_r025 || defined key_orca_r12 || defined key_orca_r1 || defined key_orca_r12_allege
! Constantes pour gerer l 'ambiguite des 360 degres
! ---------------------------------------------------
#if defined key_orca_r2
  iamb1 = 10   ! dlam < iamb1 * dphi
#endif
#if defined key_orca_r1
  iamb1 = 10   ! dlam < iamb1 * dphi
#endif
#if defined key_orca_r025
! correction bug!!(pas clair pourquoi)
  iamb1 = 217
#endif
#if defined key_orca_r12 || defined key_orca_r12_allege
! correction bug!!(pas clair pourquoi)
  iamb1 = 10
#endif

  iamb2 = 3    ! traitement special si : iamb2 * lam < max(lam)
  !
! Normalisation des longitudes : [-180,180[ --> [0,360[
!------------------------------------------------------
  DO WHILE (    xv(1) < 0. .OR.  xv(1) > 360. &
           .OR. xv(2) < 0. .OR.  xv(2) > 360. &
           .OR. xv(3) < 0. .OR.  xv(3) > 360. &
           .OR. xv(4) < 0. .OR.  xv(4) > 360.)
    IF ( xv(1) < 0.   ) xv(1) = xv(1) + 360.
    IF ( xv(1) > 360. ) xv(1) = xv(1) - 360.
    IF ( xv(2) < 0.   ) xv(2) = xv(2) + 360.
    IF ( xv(2) > 360. ) xv(2) = xv(2) - 360.
    IF ( xv(3) < 0.   ) xv(3) = xv(3) + 360.
    IF ( xv(3) > 360. ) xv(3) = xv(3) - 360.
    IF ( xv(4) < 0.   ) xv(4) = xv(4) + 360.
    IF ( xv(4) > 360. ) xv(4) = xv(4) - 360.
  END DO
!
  xvmin = MIN( xv(1),xv(2),xv(3),xv(4) )
  xvmax = MAX( xv(1),xv(2),xv(3),xv(4) )
  yvmin = MIN( yv(1),yv(2),yv(3),yv(4) )
  yvmax = MAX( yv(1),yv(2),yv(3),yv(4) )
!
  DO WHILE ( ( xx < 0. ).OR.( xx > 360. ) )
    IF ( xx < 0.   ) xx = xx + 360.
    IF ( xx > 360. ) xx = xx - 360.
  END DO
!
  IF ( (( xvmax - xvmin ) / ( yvmax - yvmin )) > iamb1 ) THEN
     WRITE(766,*) 'debug (iamb1,y,xx)=',iamb1,y,xx
     WRITE(766,*) 'debug xv(1:4)=',xv(1:4)
     WRITE(766,*) 'debug yv(1:4)=',yv(1:4)
     WRITE(766,*) 'debug (( xvmax - xvmin ) / ( yvmax - yvmin ))=',(( xvmax - xvmin ) / ( yvmax - yvmin ))
     CALL FLUSH(766)
  ENDIF
!
  IF ( (( xvmax - xvmin ) / ( yvmax - yvmin )) > iamb1 ) THEN
      IF ( iamb2 * xv(1) < xvmax ) xv(1) = xv(1) + 360.
      IF ( iamb2 * xv(2) < xvmax ) xv(2) = xv(2) + 360.
      IF ( iamb2 * xv(3) < xvmax ) xv(3) = xv(3) + 360.
      IF ( iamb2 * xv(4) < xvmax ) xv(4) = xv(4) + 360.
  ENDIF
!
  xvmin = MIN( xv(1),xv(2),xv(3),xv(4) )
  IF ( xx < xvmin ) xx = xx + 360.
#endif

!
  CALL bilwgt(yv(1),yv(4),yv(2),yv(3),xv(1),xv(4),xv(2),xv(3), &
              c(1),c(4),c(2),c(3), &
              y,xx)
#endif

!
! Somme des poids (doit etre egale a 1)
! -------------------------------------
!  rl_sum=SUM(c)
!
! Print des poids et de la somme dans un fichier
! ----------------------------------------------
!  write(9997,'(5(f10.5))') c(1),c(2),c(3),c(4),rl_sum
!  call flush(9997)

!
! Test sur la somme a la precision machine pres
! Test sur les poids a la precision machine pres
! ---------------------------------------------
!  IF (     rl_sum < rg_moins           .OR. rl_sum > rg_plus  &         
!      .OR. ANY(c(1:4) < - rp_epsilon)  .OR. ANY(c(1:4) > rg_plus)) THEN
!      write(900,*) xx,y,rl_sum
!      call flush(900)
#ifdef key_weights_method_PDM
!      write(1000,'(5x,f10.5,20x,f10.5)') xv(4)+xx,xv(3)+xx
!      write(1000,'(5x,f10.5,20x,f10.5)') yv(4)+y,yv(3)+y
#endif
#ifdef key_weights_method_OASIS
!      write(1000,'(5x,f10.5,20x,f10.5)') xv(4),xv(3)
!      write(1000,'(5x,f10.5,20x,f10.5)') yv(4),yv(3)
#endif
!      write(1000,'(20x,f10.5)') xx
!      write(1000,'(20x,f10.5)') y
#ifdef key_weights_method_PDM
!      write(1000,'(5x,f10.5,20x,f10.5)') xv(1)+xx,xv(2)+xx
!      write(1000,'(5x,f10.5,20x,f10.5)') yv(1)+y,yv(2)+y
#endif
#ifdef key_weights_method_OASIS
!      write(1000,'(5x,f10.5,20x,f10.5)') xv(1),xv(2)
!      write(1000,'(5x,f10.5,20x,f10.5)') yv(1),yv(2)
#endif
!      write(1000,'(f10.5,5x,f10.5)') c(4),c(3)
!      write(1000,'(f10.5,5x,f10.5)') c(1),c(2)
!      write(1000,*) ' '
!      call flush(1000)
!  ENDIF

  RETURN
END SUBROUTINE getSWnodeWeights
!========================================================================
#ifdef key_weights_method_OASIS
!-------------------------------------------------------------------
!> \brief
!!                     ROUTINE bilwgt
!!                   ******************
!!
!!   Purpose :
!!   -------
!!     Compute the weights for a bilinear remapping interpolation
!!     scheme.
!!
!!   Method :
!!   ------
!!     This scheme is appropriate for bilinear interpolation on a
!!     general quadrilateral grid. This scheme is also used in OASIS.
!!
!!     See the SCRIP interpolation manual.
!!
!!  Input :
!!   -----
!!      argument
!!           pphimm, : latitudes of the four corners of the
!!           pphimp,   quadrilateral cell
!!           pphipm,
!!           pphipp
!!           plammm, : longitudes of the four corners of the
!!           plammp,   quadrilateral cell
!!           plampm,
!!           plampp
!!           pphi,   : latitude / longitude of the observation
!!           plam      point
!!
!!   Output :
!!   ------
!!      argument
!!           pbiwmm, : interpolation weights at four corners of
!!           pbiwmp,   the quadrilateral cell
!!           pbiwpm,
!!           pbiwpp
!!   References :      none
!!   ----------
!!     Jones, P.: A user's guide for SCRIP: A Spherical Coordinate
!!     Remapping and Interpolation Package. Version 1.4. Los Almos.
!!      http://www.acl.lanl.gov/climate/software/SCRIP/SCRIPmain.html
!!
!!   Modifications :
!!   -------------
!!      original : 02-09 (S. Valcke) Oasis module
!!      addition : 02-11 (N. Daget) adapatation to ORCA
!!      addition : 02-12 (A. Weaver) reorganization
!!      addition : 04-09 (N. Daget) remove stafun.h
!!      addition : 04-11 (JM. Lellouche) Adaptation to SAM1/SAM2 platform
!<
!-------------------------------------------------------------------

SUBROUTINE bilwgt( pphimm, pphimp, pphipm, pphipp, &
                   plammm, plammp, plampm, plampp, &
                   pbiwmm, pbiwmp, pbiwpm, pbiwpp, &
                   pphi  , plam                    )

  IMPLICIT NONE
!
  REAL, INTENT(IN) :: pphimm, pphimp, pphipm, pphipp
  REAL, INTENT(IN) :: plammm, plammp, plampm, plampp
  REAL, INTENT(OUT) :: pbiwmm, pbiwmp, pbiwpm, pbiwpp
  REAL, INTENT(IN) :: pphi, plam
!
  REAL :: zdth1, zdth2, zdth3, zdthp
  REAL :: zdph1, zdph2, zdph3, zdphp
  REAL :: zmat1, zmat2, zmat3, zmat4
  REAL :: zdeli, zdelj
  REAL :: ziguess, zjguess, zeps, zdeterm, zpi
  INTEGER :: jiter,itermax
  REAL :: z2pi, zhpi
!
  zdth1 = pphipm - pphimm
  zdth2 = pphimp - pphimm
  zdth3 = pphipp - pphipm - zdth2
!
  zdph1 = plampm - plammm
  zdph2 = plammp - plammm
  zdph3 = plampp - plampm
!
  zpi=2.0 * asin( 1.0 )
!
  z2pi = 2.0 * zpi
!
  IF ( zdph1 >  3.0 * zpi ) zdph1 = zdph1 - z2pi
  IF ( zdph2 >  3.0 * zpi ) zdph2 = zdph2 - z2pi
  IF ( zdph3 >  3.0 * zpi ) zdph3 = zdph3 - z2pi
  IF ( zdph1 < -3.0 * zpi ) zdph1 = zdph1 + z2pi
  IF ( zdph2 < -3.0 * zpi ) zdph2 = zdph2 + z2pi
  IF ( zdph3 < -3.0 * zpi ) zdph3 = zdph3 + z2pi
!
  zdph3 = zdph3 - zdph2
!
  ziguess = 0.5
  zjguess = 0.5
!
  itermax = 100
  zeps    = 1.e-10
!
! ... Iterate to determine (i,j) in new coordinate system
  jiter_loop: DO jiter = 1, itermax
!
    zdthp = pphi - pphimm - zdth1 * ziguess &
                          - zdth2 * zjguess &
                          - zdth3 * ziguess * zjguess
    zdphp = plam - plammm
!
    zhpi = 0.5 * zpi
    IF ( zdphp >  3.0 * zhpi ) zdphp = zdphp - z2pi
    IF ( zdphp < -3.0 * zhpi ) zdphp = zdphp + z2pi
!
    zdphp = zdphp - zdph1*ziguess - zdph2*zjguess - zdph3*ziguess*zjguess
!
    zmat1 = zdth1 + zdth3 * zjguess
    zmat2 = zdth2 + zdth3 * ziguess
    zmat3 = zdph1 + zdph3 * zjguess
    zmat4 = zdph2 + zdph3 * ziguess
!
! ... Matrix determinant
    zdeterm = zmat1 * zmat4 - zmat2 * zmat3
!
    zdeli = ( zdthp * zmat4 - zmat2 * zdphp) / zdeterm
    zdelj = ( zmat1 * zdphp - zdthp * zmat3) / zdeterm
    IF ( ABS( zdeli ) < zeps .AND. &
         ABS( zdelj ) < zeps       ) EXIT jiter_loop
    ziguess = ziguess + zdeli
    zjguess = zjguess + zdelj
!
  END DO jiter_loop
!
  IF ( jiter <= itermax ) THEN
!
! ... Successfully found i,j, now compute the weights
      pbiwmm = ( 1.0 - ziguess ) * ( 1.0 - zjguess )
      pbiwmp = ( 1.0 - ziguess ) *         zjguess
      pbiwpm =         ziguess   * ( 1.0 - zjguess )
      pbiwpp =         ziguess   *         zjguess
  ELSE
      write(0,*) 'Obs lat/lon  : ',pphi, plam
      write(0,*) 'Grid lats    : ',pphimm, pphimp, pphipm, pphipp
      write(0,*) 'Grid lons    : ',plammm, plammp, plampm, plampp
      write(0,*) 'Current i,j  : ',ziguess, zjguess
      write(0,*) 'Weights      : ',pbiwmm, pbiwmp, pbiwpm, pbiwpp
      write(0,*) 'jiter        = ',jiter
      write(0,*) 'zeps         = ',zeps
      write(0,*) 'zdeli, zdelj = ',zdeli, zdelj
      write(0,*) ' ' 
      write(0,*) ' Iterations for i,j exceed max iteration count!'
      call flush(0)
      STOP
  ENDIF
!
  RETURN
!
END SUBROUTINE bilwgt
#endif


END MODULE geomlibcha
