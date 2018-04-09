!---------------------------------------------------------------------------------------
!
!                          ---   MODULE BOITE  --- 
!
!---------------------------------------------------------------------------------------

! Auteur: FHZ Mars 2007
! Ceci est le module des variables globales du module boite
! inclu la definition des classes de profondeur

MODULE table_boite

  ! VARIABLES DES REGIONS
  INTEGER :: ig_nbregion,ig_typegrid,ig_typedata ! nbre de regions 
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
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_listlon
  REAL(kind=8), DIMENSION(:,:,:), ALLOCATABLE :: rga_listlat
  REAL(kind=8), DIMENSION(:), ALLOCATABLE :: rga_IDboite
  REAL(kind=4)  :: rg_IDboiteVal_Def

END MODULE table_boite
