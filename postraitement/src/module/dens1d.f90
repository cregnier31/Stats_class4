MODULE dens1d

  IMPLICIT NONE
  PRIVATE
  PUBLIC sigma0

CONTAINS

  FUNCTION sigma0 (ptemp,psal)

    !! --------------------------------------------------------------------
    !! ** Purpose :   Compute the in situ density (ratio rho/rau0) and the
    !!      potential volumic mass (Kg/m3) from potential temperature and
    !!      salinity fields using an equation of state defined through the
    !!     namelist parameter neos.
    !!
    !! ** Method  :
    !!       Jackett and McDougall (1994) equation of state.
    !!         the in situ density is computed directly as a function of
    !!         potential temperature relative to the surface (the opa t
    !!         variable), salt and pressure (assuming no pressure variation
    !!         along geopotential surfaces, i.e. the pressure p in decibars
    !!         is approximated by the depth in meters.
    !!              prd(t,s,p) = ( rho(t,s,p) - rau0 ) / rau0
    !!              rhop(t,s)  = rho(t,s,0)
    !!         with pressure                      p        decibars
    !!              potential temperature         t        deg celsius
    !!              salinity                      s        psu
    !!              reference volumic mass        rau0     kg/m**3
    !!              in situ volumic mass          rho      kg/m**3
    !!              in situ density anomalie      prd      no units
    !! --------------------------------------------------------------------

    ! --- Declaration
    !Arguments
    REAL(KIND=4) :: ptemp,psal
    REAL(KIND=4) :: sigma0
    !Local variables
    REAL(KIND=4) ::  zws,zr1,zr2,zr3,zr4,zrau0=1000.

    ! --- Calcul densité

    !square root of interpolated S
    zws = SQRT(ABS(psal)) 

    ! compute volumic mass pure water at atm pressure
    zr1 = ( ( ( ( 6.536332e-9*ptemp-1.120083e-6 )*ptemp+1.001685e-4)*ptemp -9.095290e-3 )*ptemp+6.793952e-2 )*ptemp+999.842594
    ! seawater volumic mass atm pressure
    zr2= ( ( ( 5.3875e-9*ptemp-8.2467e-7 )*ptemp+7.6438e-5 ) *ptemp -4.0899e-3 ) *ptemp+0.824493 
    zr3= ( -1.6546e-6*ptemp+1.0227e-4 ) *ptemp-5.72466e-3
    zr4= 4.8314e-4

    ! potential volumic mass (reference to the surface)
    sigma0 = ( zr4*psal + zr3*zws + zr2 ) *psal + zr1 -zrau0

  END FUNCTION sigma0

END MODULE dens1d
