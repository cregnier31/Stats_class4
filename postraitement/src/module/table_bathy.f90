!---------------------------------------------------------------------------------------
!
!                          ---   MODULE BATHY  --- 
!
!---------------------------------------------------------------------------------------

! Auteur: FHZ Avril 2008
! Ceci est le module des variables globales du module bathy

MODULE table_bathy

  ! Nom du Fichier Bathy
  CHARACTER(LEN=255)    :: cg_BathyFile
  ! Type de fichier bathy: 1=CLS / 2=Etopo2
  INTEGER               :: ig_BathyType
  ! Taille du fichier bathy
  INTEGER               :: ig_nbBathyLon,ig_nbBathyLat
  ! Georeferencement: ig_LongitudeBound:180    [-180,180[
  !                   ig_LongitudeBound:360    [0,360[
  INTEGER :: ig_LongitudeBound
  ! Variable bathy
  REAL(KIND=8), DIMENSION(:), POINTER :: rgpa_BathyLonValue,rgpa_BathyLatValue
  INTEGER(KIND=4), DIMENSION(:,:), POINTER :: igpa_BathyValue 

END MODULE table_bathy
