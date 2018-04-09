MODULE MIOL_CHAR
!
  !*======================================================================
  !                       ***  MODULE  MIOL_CHAR ***
  !                Ce module lit les tableaux netcdf de charactères
  !                2 modules sont issus de la nouvelle version de MIOL
  !                qui n'est pas encore implémentée et les autres modules
  !                sont des modifications pour des tableaux spéciaux 
  !                                                                         *
  !                                                                         *
  !======================================================================
  !
 INTERFACE CHAR_read_field_NC
     MODULE PROCEDURE CHAR_read_field2D_NC, &
                      MIOL_read_field_C_2D_filename,&
                      CHAR_read_field1D_NC,&
                      MIOL_read_field_C_1D_fileid
  END INTERFACE 

CONTAINS
!
!*======================================================================
!
  SUBROUTINE CHAR_read_field2D_NC(cd_filename, &   ! Name of the NetCDF file
       cd_varname, &                                 ! Variable name
       id_dim,&                                      ! character dimension
       cdpa_value, &                                 ! Variable values 2D array
       ida_dimsize)                                  ! Length of each dimension

    USE netcdf
    IMPLICIT NONE

    !!=====================================================================
    !!
    !! Description: Read the 2D data values from a Netcdf file. 
    !! 
    !! Use: You have to declarate the array rdpa_value in the main program
    !! as a pointer: CHARACTER(LEN=?), POINTER, DIMENSION(:,:,:) :: cdpa_value
    !!
    !! History :
    !!        !  06/2006  (F. Messal) F90
    !!        !  04/2007 C.REGNIER
    !!=====================================================================

    !----------------------------------------------------------------------

    CHARACTER(LEN=255), INTENT(IN) :: cd_filename                         
    CHARACTER(LEN=255), INTENT(IN) :: cd_varname    
    CHARACTER(LEN=id_dim), POINTER, DIMENSION(:,:) :: cdpa_value
    INTEGER, INTENT(OUT), DIMENSION(2), OPTIONAL :: ida_dimsize
    INTEGER(KIND=4)                              ::id_dim
    CHARACTER(LEN=255), DIMENSION(3) :: cla_dimname
    CHARACTER(LEN=100) :: cl_tmp
    INTEGER, DIMENSION(3) :: ila_dimsize, ila_dimids
    INTEGER :: il_nbdim, il_type, il_file_id, il_var_id, il_err, il_ji

    !----------------------------------------------------------------------
    ! get variable rank
    PRINT *,'CHAR_read_field2D_NC'
    CALL hdlerr(NF90_OPEN(TRIM(cd_filename), NF90_NOWRITE, il_file_id))
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id)) 
    CALL hdlerr(NF90_INQUIRE_VARIABLE(il_file_id, il_var_id, cl_tmp, il_type, &
         il_nbdim, ila_dimids))

    IF (il_nbdim.NE.3) THEN
       WRITE(0,*) "MIOL_read_ncvar_field read_field2D_NC : array dimension error. "
       CALL flush(0)
       STOP
    ENDIF

    !----------------------------------------------------------------------
    ! read lenght of dimensions

    DO il_ji = 1, il_nbdim
       CALL hdlerr(NF90_INQUIRE_DIMENSION(il_file_id, ila_dimids(il_ji), &
            cla_dimname(il_ji), ila_dimsize(il_ji)))
    ENDDO

    !----------------------------------------------------------------------
    ! memory allocation

    ALLOCATE(cdpa_value(ila_dimsize(2), ila_dimsize(3)),stat=il_err)
    IF ( il_err /= 0 ) THEN
       WRITE(0,*) "MIOL_read_ncvar_field : cdpa_value memory allocation error. "
       CALL flush(0)
       STOP
    ENDIF

    !----------------------------------------------------------------------
    ! read values 

    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
    CALL hdlerr(NF90_GET_VAR(il_file_id,il_var_id,cdpa_value))

    !----------------------------------------------------------------------
    ! close file
    CALL hdlerr(NF90_CLOSE(il_file_id))

    !----------------------------------------------------------------------
    ! complete the correct lenght of dimensions

    IF (PRESENT(ida_dimsize)) THEN
       ida_dimsize = SHAPE(cdpa_value)
    ENDIF

  END SUBROUTINE CHAR_read_field2D_NC
!
!=============================================================================
!
  SUBROUTINE MIOL_read_field_C_2D_filename(cd_filename, &   ! Name of the NetCDF file
       cd_varname, &                                ! Variable name
       cdpa_value, &
       id_stringsize, &
       ida_dimsize)                                 ! Length of each dimension

       USE netcdf
       IMPLICIT NONE

       !!=====================================================================
       !!
       !! Description: Read the 2D data values from a Netcdf file.
       !!
       !! Use: You have to declarate the array rdpa_value in the main program
       !! as a pointer: CHARACTER(LEN=14), POINTER, DIMENSION(:) :: cdpa_value
       !!
       !! History :
       !!        !  09/2006  (F. Messal) F90
       !!
       !!=====================================================================

       !----------------------------------------------------------------------

       CHARACTER(LEN=255), INTENT(IN) :: cd_filename                                
       CHARACTER(LEN=255), INTENT(IN) :: cd_varname
       CHARACTER(LEN=255), DIMENSION(:), POINTER :: cdpa_value
       INTEGER :: id_stringsize
       INTEGER, INTENT(OUT), DIMENSION(2), OPTIONAL :: ida_dimsize
       CHARACTER(LEN=255), DIMENSION(2) :: cla_dimname
       INTEGER :: il_stringsize, il_dim
       CHARACTER(LEN=id_stringsize), DIMENSION(:), ALLOCATABLE :: cla_tmp
       CHARACTER(LEN=100) :: cl_tmp
       INTEGER, DIMENSION(2) :: ila_dimsize, ila_dimids
       INTEGER :: il_nbdim, il_type, il_file_id, il_var_id, il_err, il_ji

       !----------------------------------------------------------------------
       ! get variable rank
       PRINT *,'MIOL_read_field_C_2D_filename' 
       CALL hdlerr(NF90_OPEN(TRIM(cd_filename), NF90_NOWRITE, il_file_id))
       CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
       CALL hdlerr(NF90_INQUIRE_VARIABLE(il_file_id, il_var_id, cl_tmp, il_type, &
                   il_nbdim, ila_dimids))
       IF (il_nbdim.NE.2) THEN
          WRITE(0,*) "MIOL_read_ncvar_field read_field_C_2D_filename : array dimension error. "
          CALL flush(0)
          STOP
       ENDIF


       !----------------------------------------------------------------------
       ! read lenght of dimensions

       DO il_ji = 1, il_nbdim
          CALL hdlerr(NF90_INQUIRE_DIMENSION(il_file_id, ila_dimids(il_ji), &
                      cla_dimname(il_ji), ila_dimsize(il_ji)))
          print *,'dim:: ',cla_dimname(il_ji), ila_dimsize(il_ji)

       ENDDO
       il_stringsize = ila_dimsize(1)
       il_dim = ila_dimsize(2)

       !----------------------------------------------------------------------
       ! memory allocation

       ALLOCATE(cdpa_value(il_dim),stat=il_err)
       IF ( il_err /= 0 ) THEN
          WRITE(0,*) "MIOL_read_ncvar_field : cdpa_value memory allocation error. "
          CALL flush(0)
          STOP
       ENDIF

       ALLOCATE(cla_tmp(il_dim),stat=il_err)
       IF ( il_err /= 0 ) THEN
          WRITE(0,*) "MIOL_read_ncvar_field : cla_tmp memory allocation error. "
          CALL flush(0)
          STOP
       ENDIF

       !----------------------------------------------------------------------
       ! read values

       CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
       CALL hdlerr(NF90_GET_VAR(il_file_id,il_var_id,cla_tmp))
       cdpa_value(:) = cla_tmp(:)
       !----------------------------------------------------------------------
       ! close file
          CALL hdlerr(NF90_CLOSE(il_file_id))

       !----------------------------------------------------------------------
       ! complete the correct lenght of dimensions

       !IF (PRESENT(ida_dimsize)) THEN
       !   ida_dimsize = SHAPE(cdpa_value)
       !ENDIF


  END SUBROUTINE MIOL_read_field_C_2D_filename
!
!=============================================================================
!
  SUBROUTINE CHAR_read_field1D_NC(cd_filename, &   ! Name of the NetCDF file
       cd_varname, &                                 ! Variable name
       id_dim,&                                      ! character dimension
       cdpa_value, &                                 ! Variable values 2D array
       ida_dimsize)                                  ! Length of each dimension
!
    USE netcdf
    IMPLICIT NONE
!
    !!=====================================================================
    !!
    !! Description: Read the 2D data values from a Netcdf file. 
    !! 
    !! Use: You have to declarate the array rdpa_value in the main program
    !! as a pointer: CHARACTER(LEN=?), POINTER, DIMENSION(:) :: cdpa_value
    !!
    !! History :
    !!        !  06/2006  (F. Messal) F90
    !!        !  04/2007 C.REGNIER
    !!=====================================================================
    !
    !----------------------------------------------------------------------
!
    CHARACTER(LEN=255), INTENT(IN) :: cd_filename                         
    CHARACTER(LEN=255), INTENT(IN) :: cd_varname    
    CHARACTER(LEN=id_dim), POINTER, DIMENSION(:) :: cdpa_value
    INTEGER, INTENT(OUT), DIMENSION(1), OPTIONAL :: ida_dimsize
    INTEGER(KIND=4)                              ::id_dim
    CHARACTER(LEN=255), DIMENSION(2) :: cla_dimname
    CHARACTER(LEN=100) :: cl_tmp
    INTEGER, DIMENSION(2) :: ila_dimsize, ila_dimids
    INTEGER :: il_nbdim, il_type, il_file_id, il_var_id, il_err, il_ji

    !----------------------------------------------------------------------
    ! get variable rank
    PRINT *,'CHAR_read_field1D_NC'
    CALL hdlerr(NF90_OPEN(TRIM(cd_filename), NF90_NOWRITE, il_file_id))
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id)) 
    CALL hdlerr(NF90_INQUIRE_VARIABLE(il_file_id, il_var_id, cl_tmp, il_type, &
         il_nbdim, ila_dimids))

    IF (il_nbdim.NE.2) THEN
       WRITE(0,*) "MIOL_read_ncvar_field CHAR_read_field1D_NC : array dimension error. "
       CALL flush(0)
       STOP
    ENDIF

    !----------------------------------------------------------------------
    ! read lenght of dimensions

    DO il_ji = 1, il_nbdim
       CALL hdlerr(NF90_INQUIRE_DIMENSION(il_file_id, ila_dimids(il_ji), &
            cla_dimname(il_ji), ila_dimsize(il_ji)))
    ENDDO

    !----------------------------------------------------------------------
    ! memory allocation
    ALLOCATE(cdpa_value(ila_dimsize(2)),stat=il_err)
    IF ( il_err /= 0 ) THEN
       WRITE(0,*) "MIOL_read_ncvar_field : cdpa_value memory allocation error. "
       CALL flush(0)
       STOP
    ENDIF

    !----------------------------------------------------------------------
    ! read values 
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
    CALL hdlerr(NF90_GET_VAR(il_file_id,il_var_id,cdpa_value))

    !----------------------------------------------------------------------
    ! close file
    CALL hdlerr(NF90_CLOSE(il_file_id))

    !----------------------------------------------------------------------
    ! complete the correct lenght of dimensions

    IF (PRESENT(ida_dimsize)) THEN
       ida_dimsize = SHAPE(cdpa_value)
    ENDIF

  END SUBROUTINE CHAR_read_field1D_NC
!
!=============================================================================
!
!
  SUBROUTINE  MIOL_read_field_C_1D_fileidBIS(cd_filename, &   ! Name of the NetCDF file
       cd_varname, &                                 ! Variable name
       cda_value, &                                  ! Variable values 1D array
       id_dimsize,&                                  ! Length of each dimension
       ida_dimsize)                                  


    USE netcdf
    IMPLICIT NONE
    !
    !!=====================================================================
    !!
    !! Description: Read the 1D data values from a Netcdf file. 
    !! 
    !! Use: You have to declarate the array rdpa_value in the main program
    !! as a pointer: CHARACTER(LEN=256), POINTER, DIMENSION(:) :: cdpa_value
    !!
    !! History :
    !!        !  04/2007 C.REGNIER
    !!=====================================================================
    !
    !----------------------------------------------------------------------
    !
    CHARACTER(LEN=255), INTENT(IN) :: cd_filename                         
    CHARACTER(LEN=255), INTENT(IN) :: cd_varname    
    CHARACTER(LEN=1), DIMENSION(:),POINTER :: cda_value
    INTEGER, INTENT(OUT), DIMENSION(1), OPTIONAL :: ida_dimsize
    INTEGER(KIND=4)                              :: id_dimsize
    CHARACTER(LEN=255), DIMENSION(1)             :: cla_dimname
    CHARACTER(LEN=1), DIMENSION(:),ALLOCATABLE      :: cla_tmp
    CHARACTER(LEN=100) :: cl_tmp
    INTEGER, DIMENSION(1) :: ila_dimsize, ila_dimids
    INTEGER :: il_nbdim, il_type, il_file_id, il_var_id, il_err, il_ji,il_i
    !
    !*------------------------------------------------
    !
    PRINT *,'MIOL_read_field_C_1D_fileidBIS'
    ALLOCATE (cla_tmp(id_dimsize))
    ALLOCATE (cda_value(id_dimsize)) 
    !** get variable rank
    CALL hdlerr(NF90_OPEN(TRIM(cd_filename), NF90_NOWRITE, il_file_id))
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id)) 
    CALL hdlerr(NF90_INQUIRE_VARIABLE(il_file_id, il_var_id, cl_tmp, il_type, &
         il_nbdim, ila_dimids))
    IF (il_nbdim.NE.1) THEN
       WRITE(0,*) "MIOL_read_ncvar_field MIOL_read_field_C_1D_fileid : array dimension error. "
       CALL flush(0)
       STOP
    ENDIF
    !----------------------------------------------------------------------
    !** read lenght of dimensions
    DO il_ji = 1, il_nbdim
       CALL hdlerr(NF90_INQUIRE_DIMENSION(il_file_id, ila_dimids(il_ji), &
            cla_dimname(il_ji), ila_dimsize(il_ji)))
    ENDDO
    !----------------------------------------------------------------------
    !** read values 
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
    CALL hdlerr(NF90_GET_VAR(il_file_id,il_var_id,cla_tmp,start = (/ 1 /), count = (/ ila_dimsize(1) /),stride =(/ 1/)))
     cda_value(:)=cla_tmp(:)
    CALL hdlerr(NF90_CLOSE(il_file_id))
    IF (ALLOCATED (cla_tmp)) DEALLOCATE(cla_tmp)
  END SUBROUTINE MIOL_read_field_C_1D_fileidBIS
!
!==========================================================================
! 
!
  SUBROUTINE  MIOL_read_field_C_2D_fileidBIS(cd_filename, &   ! Name of the NetCDF file
       cd_varname, &                                 ! Variable name
       cda_value, &                                  ! Variable values 1D array
       id_dimsize,&                                  ! Length of each dimension
       ida_dimsize)                                  

    USE netcdf
    IMPLICIT NONE
    !
    !!=====================================================================
    !!
    !! Description: Read the 1D data values from a Netcdf file. 
    !! 
    !! Use: You have to declarate the array rdpa_value in the main program
    !! as a pointer: CHARACTER(LEN=256), POINTER, DIMENSION(:) :: cdpa_value
    !!
    !! History :
    !!        !  04/2007 C.REGNIER
    !!=====================================================================
    !
    !----------------------------------------------------------------------
    !
    CHARACTER(LEN=255), INTENT(IN) :: cd_filename                         
    CHARACTER(LEN=255), INTENT(IN) :: cd_varname    
    CHARACTER(LEN=1), DIMENSION(:,:),POINTER :: cda_value
    INTEGER, INTENT(OUT), DIMENSION(2), OPTIONAL :: ida_dimsize
    INTEGER(KIND=4)                              :: id_dimsize
    CHARACTER(LEN=255), DIMENSION(2)             :: cla_dimname
    CHARACTER(LEN=1), DIMENSION(:,:),ALLOCATABLE      :: cla_tmp
    CHARACTER(LEN=100) :: cl_tmp
    INTEGER, DIMENSION(2) :: ila_dimsize, ila_dimids
    INTEGER :: il_nbdim, il_type, il_file_id, il_var_id, il_err, il_ji,il_i
    !
    !*------------------------------------------------
    !
    !** get variable rank
    PRINT *,'MIOL_read_field_C_2D_fileidBIS'
    CALL hdlerr(NF90_OPEN(TRIM(cd_filename), NF90_NOWRITE, il_file_id))
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id)) 
    CALL hdlerr(NF90_INQUIRE_VARIABLE(il_file_id, il_var_id, cl_tmp, il_type, &
         il_nbdim, ila_dimids))
    IF (il_nbdim.NE.2) THEN
       WRITE(0,*) "MIOL_read_field_C_2D_fileidBIS : array dimension error. "
       CALL flush(0)
       STOP
    ENDIF
    !----------------------------------------------------------------------
    !** read lenght of dimensions
    DO il_ji = 1, il_nbdim
       CALL hdlerr(NF90_INQUIRE_DIMENSION(il_file_id, ila_dimids(il_ji), &
            cla_dimname(il_ji), ila_dimsize(il_ji)))
!!$            print *,'cla_dimname,ila_dimsize',cla_dimname(il_ji), ila_dimsize(il_ji),il_ji

    ENDDO
    ALLOCATE (cla_tmp(ila_dimsize(1),ila_dimsize(2)))
    ALLOCATE (cda_value(ila_dimsize(1),ila_dimsize(2)))
    !----------------------------------------------------------------------
    !** read values 
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
    CALL hdlerr(NF90_GET_VAR(il_file_id,il_var_id,cla_tmp,start = (/ 1,1 /), count = (/ ila_dimsize(1),ila_dimsize(2) /),stride =(/ 1,1 /)))
    cda_value(:,:)=cla_tmp(:,:)
    CALL hdlerr(NF90_CLOSE(il_file_id))
    IF (ALLOCATED (cla_tmp)) DEALLOCATE(cla_tmp)
  END SUBROUTINE MIOL_read_field_C_2D_fileidBIS
!
!==========================================================================
! 
  SUBROUTINE  MIOL_read_field_C_1D_fileid(cd_filename, &   ! Name of the NetCDF file
       cd_varname, &                                 ! Variable name
       cda_value, &                                  ! Variable values 1D array
       id_dimsize,&                                  ! Length of each dimension
       ida_dimsize)                                  
        
    
    USE netcdf
    IMPLICIT NONE
    !
    !!=====================================================================
    !!
    !! Description: Read the 1D data values from a Netcdf file. 
    !! 
    !! Use: You have to declarate the array rdpa_value in the main program
    !! as a pointer: CHARACTER(LEN=256), POINTER, DIMENSION(:) :: cdpa_value
    !!
    !! History :
    !!        !  09/2006  (F. Messal) F90
    !!        !  04/2007 C.REGNIER
    !!=====================================================================
    !
    !----------------------------------------------------------------------
    !
    CHARACTER(LEN=255), INTENT(IN) :: cd_filename                         
    CHARACTER(LEN=255), INTENT(IN) :: cd_varname    
    CHARACTER(LEN=255), DIMENSION(1), INTENT(OUT):: cda_value
    INTEGER, INTENT(OUT), DIMENSION(1), OPTIONAL :: ida_dimsize
    INTEGER(KIND=4)                              :: id_dimsize
    CHARACTER(LEN=255), DIMENSION(1) :: cla_dimname
    CHARACTER(LEN=id_dimsize), DIMENSION(1) :: cla_tmp
    CHARACTER(LEN=100) :: cl_tmp
    INTEGER, DIMENSION(1) :: ila_dimsize, ila_dimids
    INTEGER :: il_nbdim, il_type, il_file_id, il_var_id, il_err, il_ji
    !
    !----------------------------------------------------------------------
    ! get variable rank
    PRINT *,'MIOL_read_field_C_1D_fileid'
    CALL hdlerr(NF90_OPEN(TRIM(cd_filename), NF90_NOWRITE, il_file_id))
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id)) 
    CALL hdlerr(NF90_INQUIRE_VARIABLE(il_file_id, il_var_id, cl_tmp, il_type, &
         il_nbdim, ila_dimids))
    IF (il_nbdim.NE.1) THEN
       WRITE(0,*) "MIOL_read_ncvar_field MIOL_read_field_C_1D_fileid : array dimension error. "
       CALL flush(0)
       STOP
    ENDIF

    !----------------------------------------------------------------------
    ! read lenght of dimensions

    DO il_ji = 1, il_nbdim
       CALL hdlerr(NF90_INQUIRE_DIMENSION(il_file_id, ila_dimids(il_ji), &
            cla_dimname(il_ji), ila_dimsize(il_ji)))
    ENDDO

    !----------------------------------------------------------------------
    ! read values 
    CALL hdlerr(NF90_INQ_VARID(il_file_id, cd_varname, il_var_id))
    CALL hdlerr(NF90_GET_VAR(il_file_id,il_var_id,cla_tmp))
    cda_value(1) = cla_tmp(1)
    !----------------------------------------------------------------------
    ! close file
    CALL hdlerr(NF90_CLOSE(il_file_id))

    !----------------------------------------------------------------------
    ! complete the correct lenght of dimensions

    IF (PRESENT(ida_dimsize)) THEN
       ida_dimsize = SHAPE(cda_value)
    ENDIF

  END SUBROUTINE MIOL_read_field_C_1D_fileid
!
!==========================================================================
! 
  SUBROUTINE hdlerr(istatus)

    USE netcdf

    INTEGER, INTENT(IN) :: istatus

    IF(istatus.NE.NF90_NOERR) THEN
       WRITE(0,*) 'HDLERR erreur :', NF90_STRERROR(istatus)
       CALL flush(0)
       STOP
    ENDIF
    RETURN

  END SUBROUTINE hdlerr

!
!==============================================================================
!
END MODULE MIOL_CHAR
