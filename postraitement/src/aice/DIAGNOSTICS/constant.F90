!  nom du programme : constants.f90
!  creation : novembre 2008
!  auteur : Besnard (CLS)
!
!  fonction : source contenant les constantes utiles au programmes coards.f90
!-----------------------------------------------------------------------

      module constant

!-----------------------------------------------------------------------

      implicit none

      save

!-----------------------------------------------------------------------

      real (kind = 8), parameter :: &
         DIFF_obs_mod = 935965.2, & ! PSY3V2R2
         DIFF_1900_1950 = 18262.5, &
         precis = 0.1, &
         sec2hour = 3600., &
         hour2day = 24.

      integer, parameter :: &
         INIT = 0, &
         UNITE = 1

!-----------------------------------------------------------------------

      end module constant

!-----------------------------------------------------------------------

