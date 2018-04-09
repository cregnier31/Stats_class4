!---------------------------------------------------------------------------------------
!
!                          ---   MODULE BOITE  --- 
!
!---------------------------------------------------------------------------------------

! Auteur: FHZ Mars 2007
! Ceci est le module des variables globales du module boite

MODULE table_boite

  ! VARIABLES DES REGIONS
  INTEGER :: ig_nbregion ! nbre de regions 
  ! type de region (1,2 ou 3)
  INTEGER, DIMENSION(:), ALLOCATABLE :: iga_typeregion
  ! Numero identite de la region
  REAL(kind=8), DIMENSION(:), ALLOCATABLE :: rga_valeur1
  ! valeur par defaut pour l identite des regions
  REAL(kind=8) :: rg_valeur0  !
  ! Nombre de bloc pour la region
  INTEGER, DIMENSION(:), ALLOCATABLE :: iga_listnbbloc
  ! Quatre caracteristiques d un bloc (rectangle ou rond)
  REAL(kind=8), DIMENSION(:,:), ALLOCATABLE :: rga_info
  ! Nombre de points caracteristiques pour les blocs des regions "3"
  INTEGER, DIMENSION(:,:), ALLOCATABLE :: iga_listnbpoint
  ! Caracteristiques pour les blocs compliques
  real(kind=8), dimension(:,:,:), allocatable :: rga_listlon
  real(kind=8), dimension(:,:,:), allocatable :: rga_listlat

END MODULE table_boite
