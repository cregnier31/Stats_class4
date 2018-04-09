 MODULE extend_MIOL


   INTERFACE extend_MIOL_inquire_dimensions_NC
      MODULE PROCEDURE extend_MIOL_inquiref_dimensions_NC, &
                       extend_MIOL_inquireu_dimensions_NC
   END INTERFACE

 CONTAINS
  !******************************************************************************
 
 
 
        SUBROUTINE extend_MIOL_inquiref_dimensions_NC (cd_filename, &
                                               id_nbdim, &
                                               cdpa_dimname, &
                                               idpa_dimlen)
 
          USE netcdf
          IMPLICIT NONE
 
 
          !!=====================================================================
          !!
          !! Description: This function reads the number, the name and the length
          !!              of a NetCDF file dimensions. This function uses pointers,
          !!              so you don’t have to know the correct dimensions of the
          !!              data arrays.
          !!
          !! cd_filename       A NetCDF filename. You must specify the complete path.
          !! il_nbdim          Returned number of dimensions.
          !! cdpa_dimname      Returned vector of nbdim names corresponding to
          !!                     the name of the dimensions.
          !! idpa_dimlen       Returned vector of nbdim values corresponding to the
          !!                     length of the dimensions.
          !!
          !! History :
          !!        !  11/2006  (F. Messal)
          !!
          !!=====================================================================
 
          !----------------------------------------------------------------------
 
          CHARACTER(LEN=*),                 INTENT(IN) :: cd_filename
          INTEGER,                          INTENT(OUT) :: id_nbdim
          INTEGER, DIMENSION(:),            POINTER :: idpa_dimlen
          CHARACTER(LEN=255), DIMENSION(:), POINTER :: cdpa_dimname
 
          INTEGER :: il_file_id, il_nbvar, il_ji, il_status
 
 
          !----------------------------------------------------------------------
          ! Open file
          il_status = fi_ncError(NF90_OPEN(TRIM(cd_filename), &
                                           NF90_NOWRITE, &
                                           il_file_id))
 
          !----------------------------------------------------------------------
          ! Inquire the number of dimensions
          il_status = fi_ncError(NF90_INQUIRE(il_file_id, &
                                              id_nbdim))
 
          !----------------------------------------------------------------------
          ! Memory allocation
          ALLOCATE(idpa_dimlen(id_nbdim), &
                   stat=il_status)
          il_status = fi_memError(il_status, ' idpa_dimlen')
 
          ALLOCATE(cdpa_dimname(id_nbdim), &
                   stat=il_status)
          il_status = fi_memError(il_status, ' cdpa_dimname')
 
 
          !----------------------------------------------------------------------
          ! Read dimension
          DO il_ji = 1, id_nbdim
             il_status = fi_ncError(NF90_INQUIRE_DIMENSION(il_file_id, &
                                                           il_ji, &
                                                           cdpa_dimname(il_ji), &
                                                           idpa_dimlen(il_ji)))
          ENDDO
 
 
          !----------------------------------------------------------------------
          ! Close file
          il_status = fi_ncError(NF90_CLOSE(il_file_id))
 
 
          !**********************************************************************
          ! Error functions
 
          CONTAINS
 
          FUNCTION fi_ncError(id_status) RESULT (il_result)
 
             INTEGER :: id_status, il_result
 
             IF ( id_status.NE.NF90_NOERR ) THEN
                WRITE(0,*) ' MIOL_inquiref_dimensions_NC (NetCDF Handle error):', &
                           NF90_STRERROR(id_status)
                CALL flush(0)
                STOP
             ENDIF
 
             il_result = id_status
 
          END FUNCTION fi_ncError
 
 
          FUNCTION fi_memError(id_status, cd_variable) RESULT(il_result)
 
             INTEGER :: id_status, il_result
             CHARACTER(LEN=*) :: cd_variable
 
             IF ( id_status .NE. 0 ) THEN
                WRITE(0,*) ' MIOL_inquiref_dimensions_NC (memory allocation or deallocation error) :', &
                           TRIM(cd_variable)
                CALL flush(0)
                STOP
             ENDIF
             il_result = id_status
 
          END FUNCTION fi_memError
 
 
        END SUBROUTINE extend_MIOL_inquiref_dimensions_NC
 
  !******************************************************************************
  !******************************************************************************
  !******************************************************************************
   !******************************************************************************
  !******************************************************************************
  !******************************************************************************
 
 
 
        SUBROUTINE extend_MIOL_inquireu_dimensions_NC (id_file_id, &
                                               id_nbdim, &
                                               cdpa_dimname, &
                                               idpa_dimlen)
 
          USE netcdf
          IMPLICIT NONE
 
 
          !!=====================================================================
          !!
          !! Description: This function reads the number, the name and the length
          !!              of a NetCDF file dimensions. This function uses pointers,
          !!              so you don’t have to know the correct dimensions of the
          !!              data arrays.
          !!
          !! id_file_id        A NetCDF file Id.
          !! il_nbdim          Returned number of dimensions.
          !! cdpa_dimname      Returned vector of nbdim names corresponding to
          !!                     the name of the dimensions.
          !! idpa_dimlen       Returned vector of nbdim values corresponding to the
          !!                     length of the dimensions.
          !!
          !! History :
          !!        !  11/2006  (F. Messal)
          !!
          !!=====================================================================
 
          !----------------------------------------------------------------------
 
          INTEGER,                          INTENT(IN) :: id_file_id
          INTEGER,                          INTENT(OUT) :: id_nbdim
          INTEGER, DIMENSION(:),            POINTER :: idpa_dimlen
          CHARACTER(LEN=255), DIMENSION(:), POINTER :: cdpa_dimname
 
          INTEGER :: il_nbvar, il_ji, il_status
 
          !----------------------------------------------------------------------
          ! Inquire the number of dimensions
          il_status = fi_ncError(NF90_INQUIRE(id_file_id, &
                                              id_nbdim))
 
          !----------------------------------------------------------------------
          ! Memory allocation
          ALLOCATE(idpa_dimlen(id_nbdim), &
                   stat=il_status)
          il_status = fi_memError(il_status, ' idpa_dimlen')
 
          ALLOCATE(cdpa_dimname(id_nbdim), &
                   stat=il_status)
          il_status = fi_memError(il_status, ' cdpa_dimname')
 
 
          !----------------------------------------------------------------------
          ! Read dimension
          DO il_ji = 1, id_nbdim
             il_status = fi_ncError(NF90_INQUIRE_DIMENSION(id_file_id, &
                                                           il_ji, &
                                                           cdpa_dimname(il_ji), &
                                                           idpa_dimlen(il_ji)))
          ENDDO
 
 
          !**********************************************************************
          ! Error functions
 
          CONTAINS
 
          FUNCTION fi_ncError(id_status) RESULT (il_result)
 
             INTEGER :: id_status, il_result
 
             IF ( id_status.NE.NF90_NOERR ) THEN
                WRITE(0,*) ' MIOL_inquireu_dimensions_NC (NetCDF Handle error):', &
                           NF90_STRERROR(id_status)
                CALL flush(0)
                STOP
             ENDIF
 
             il_result = id_status
 
          END FUNCTION fi_ncError
 
 
          FUNCTION fi_memError(id_status, cd_variable) RESULT(il_result)
 
             INTEGER :: id_status, il_result
             CHARACTER(LEN=*) :: cd_variable
 
             IF ( id_status .NE. 0 ) THEN
                WRITE(0,*) ' MIOL_inquireu_dimensions_NC (memory allocation or deallocation error) :', &
                           TRIM(cd_variable)
                CALL flush(0)
                STOP
             ENDIF
             il_result = id_status
 
          END FUNCTION fi_memError
 
 
        END SUBROUTINE extend_MIOL_inquireu_dimensions_NC
 
  !******************************************************************************
  !******************************************************************************
  !******************************************************************************


END MODULE extend_MIOL
