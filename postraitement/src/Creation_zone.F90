PROGRAM Creation_zone
!
!* Programme permettant de réaliser des fichiers ascii contenant
!* la description de zones régulières servant aux diagnostiques class4
!* Il permet également de créer un fichier mask contenant pour chacun des
!* couples lon/lat le numéro de la zone associée 
!*
! Programmer      Date         Description
! C.REGNIER      16/09/2010     Creation
!** ++  MODULES used
  USE MIOL
  USE netcdf
  USE boite_bins
  USE table_boite
!
IMPLICIT NONE
INTEGER(KIND=4)               :: il_comp,il_narg,iargc,il_ji,il_jj,&
                                 il_nbx,il_nby,il_status,il_nbdim,il_file_id,il_err,jv_status,il_fichier
CHARACTER(LEN=255)            :: cl_input,cl_lonmin,cl_lonmax,&
                                 cl_latmin,cl_latmax,cl_res,cl_mask,cl_output,cl_file
CHARACTER(LEN=255),DIMENSION(:),ALLOCATABLE      :: cla_dimname
INTEGER(KIND=4),DIMENSION(:),ALLOCATABLE         :: ila_dimlen
REAL(KIND=8)                  :: rl_lonmin,rl_lonmax,rl_latmin,rl_latmax,rl_res,rl_box
REAL(KIND=8), PARAMETER       :: rl_northlimit=89., rl_southlimit=-89.
REAL(KIND=8),ALLOCATABLE, DIMENSION(:) :: rla_longitude, rla_latitude
REAL(KIND=8),ALLOCATABLE, DIMENSION(:,:) :: rla_lon2, rla_lat2,rla_mask
INTEGER(KIND=4),ALLOCATABLE, DIMENSION(:,:) :: ila_mask
!-------------------------


il_narg=iargc()

IF (il_narg.lt.12) THEN
    PRINT *,'----------- Read usage-----------------------'
    PRINT *,'--------------------------------------------'
    PRINT *,' Read arguments'
    print *,' -lgmin :: enter lon min'
    print *,' -lgmax :: enter lon max'
    print *,' -ltmin :: enter lat min'
    print *,' -ltmax :: enter lat max'
    print *,' -r : size of cells in degree'                         
    print *,' -o : output files'                         
    STOP
ENDIF

DO il_ji=1,il_narg
        CALL getarg(il_ji,cl_input)
        IF (cl_input .EQ. '-lgmin') THEN
          CALL getarg(il_ji+1,cl_lonmin)
          READ(cl_lonmin,*) rl_lonmin
        ELSE IF (cl_input .EQ. '-lgmax') THEN
          CALL getarg(il_ji+1,cl_lonmax)
          READ(cl_lonmax,*) rl_lonmax
        ELSE IF (cl_input .EQ. '-ltmin') THEN 
          CALL getarg(il_ji+1,cl_latmin) 
          READ(cl_latmin,*) rl_latmin
        ELSE IF (cl_input .EQ. '-ltmax') THEN 
          CALL getarg(il_ji+1,cl_latmax) 
          READ(cl_latmax,*) rl_latmax
        ELSE IF (cl_input .EQ. '-r' ) THEN
          CALL getarg(il_ji+1,cl_res)
          READ(cl_res,*) rl_res
        ELSE IF (cl_input .EQ. '-o' ) THEN
          CALL getarg(il_ji+1,cl_output)
        ENDIF
ENDDO           

PRINT *,'LON MIN MAX  :: ',rl_lonmin,rl_lonmax
PRINT *,'LAT MIN MAX  :: ',rl_latmin,rl_latmax
PRINT *,'RESOLUTION :: ',rl_res

!** Nombre de valeurs en x et y
il_nbx = NINT((rl_lonmax-rl_lonmin)/rl_res) + 1
il_nby = NINT((rl_latmax-rl_latmin)/rl_res) + 1
!* Allocation
ALLOCATE(rla_longitude(il_nbx), &
         stat=il_status)
!il_status = fi_memError(il_status, ' rla_longitude',cl_fonction)
            
ALLOCATE(rla_latitude(il_nby), &
         stat=il_status)
!il_status = fi_memError(il_status, ' rla_latitude',cl_fonction)


DO il_ji=1,il_nbx
   rla_longitude(il_ji) = rl_lonmin + (il_ji-1)*rl_res
ENDDO
DO il_ji=1,il_nby
   rla_latitude(il_ji)  = rl_latmin + (il_ji-1)*rl_res
ENDDO
il_comp=0

CALL MIOL_getFreeLu(il_fichier)
cl_file='/home/qualif/CLASS4/Lecture_Class4_V2.0/utils/'//'position_'//TRIM(cl_res)//'deg.txt'
OPEN(il_fichier,FILE=TRIM(cl_file),position='APPEND',form='FORMATTED',STATUS='old')

DO il_ji=1,il_nbx-1
  DO il_jj=1,il_nby-1
      il_comp=il_comp+1
    !  PRINT *,'Lonmin, latmin , lonmax, latmax ',il_comp,rla_longitude(il_ji),rla_latitude(il_jj),rla_longitude(il_ji),rla_latitude(il_jj+1),rla_longitude(il_ji+1)
   !   WRITE(40,fmt=('I5,1x,F6.1,1x,F6.1,1x,F6.1,1x,F6.1')) il_comp,rla_longitude(il_ji),rla_latitude(il_jj),rla_longitude(il_ji+1),rla_latitude(il_jj+1)
      WRITE(il_fichier,9001) il_comp,rla_longitude(il_ji),rla_latitude(il_jj),rla_longitude(il_ji+1),rla_latitude(il_jj+1)
!      print *,'valeurs ::',il_comp,rla_longitude(il_ji),rla_latitude(il_jj),rla_longitude(il_ji+1),rla_latitude(il_jj+1)
  ENDDO
ENDDO
CLOSE(il_fichier)
!*
ALLOCATE(rla_lon2(il_nbx,il_nby))
ALLOCATE(rla_lat2(il_nbx,il_nby))
ALLOCATE(ila_mask(il_nbx,il_nby))
CALL LireDefBoitebins (cl_file,jv_status)

DO il_ji=1,il_nby
  DO il_jj=1,il_nbx
     rla_lon2(il_jj,il_ji)=rla_longitude(il_jj)
     rla_lat2(il_jj,il_ji)=rla_latitude(il_ji)
     CALL IdentifierBoiteBins(rla_longitude(il_jj),rla_latitude(il_ji),rl_box,il_err)
     ila_mask(il_jj,il_ji)=rl_box
  ENDDO
ENDDO
!** Creation fichier mask
il_nbdim=2
ALLOCATE(cla_dimname(il_nbdim))
ALLOCATE(ila_dimlen(il_nbdim))
cla_dimname(1) = 'x'
cla_dimname(2) = 'y'

ila_dimlen(1) = il_nbx
ila_dimlen(2) = il_nby
cl_mask=cl_output
PRINT *,'OK 4',cl_mask,cla_dimname,ila_dimlen(1),ila_dimlen(2)
!PRINT *,'------------------------------------'
!PRINT *,'OK 4 bis'
call MIOL_create_file_NC(TRIM(cl_mask),&
                         il_nbdim,&
                         cla_dimname,&
                         ila_dimlen)
!CALL MIOL_close_file_NC(il_file_id)
!STOP
PRINT *,'OK 4 bis',size(rla_lon2),size(rla_lat2)
call MIOL_openw_file_NC(TRIM(cl_mask), il_file_id)
PRINT *,'OK 5',cl_mask
CALL MIOL_write_field_NC(il_file_id, &
                         'longitude' , &
                         'XY', &
                         rla_lon2)
CALL MIOL_write_field_NC(il_file_id, &
                         'latitude' , &
                         'XY', &
                         rla_lat2)
CALL MIOL_write_field_NC(il_file_id, &
                         'mask' , &
                         'XY', &
                         ila_mask)

PRINT *,'OK 6',cl_mask
CALL MIOL_close_file_NC(il_file_id)
PRINT *,'Nombre de valeurs :: ',il_nbx,il_nby
!PRINT *,'Longitude :: ',rla_longitude
!PRINT *,'Latitude :: ',rla_latitude

9001 FORMAT(I5,' ',F6.1,' ',F6.1,' ',F6.1,' ',F6.1)

END PROGRAM
