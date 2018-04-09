PROGRAM test_write

   USE netcdf
   USE MCAL
   USE MIOL
   USE MIOL_param
   IMPLICIT NONE

   INTEGER(KIND=4)     :: il_filid,il_variable_id,il_status
   CHARACTER(LEN=256)  :: cl_varname,cd_outputVarname,cd_outputFile
   CHARACTER(LEN=20), DIMENSION(29) :: cda_dephvarname

   cda_dephvarname(1)='DEPH                '
   cda_dephvarname(2)='DEPH                '
   cda_dephvarname(3)='DEPH                '
   cda_dephvarname(4)='DEPH                '
   cda_dephvarname(5)='DEPH_ADJUSTED       '
   cda_dephvarname(6)='DEPH_ADJUSTED       '
   cda_dephvarname(7)='DEPH_ADJUSTED       '
   cda_dephvarname(8)='DEPH_ADJUSTED       '
   cda_dephvarname(9)='DEPH_ADJUSTED       '
   cda_dephvarname(10)='PRES               '
   cda_dephvarname(11)='PRES               '
   cda_dephvarname(12)='PRES               '
   cda_dephvarname(13)='PRES               '
   cda_dephvarname(14)='PRES               '
   cda_dephvarname(15)='PRES               '
   cda_dephvarname(16)='PRES               '
   cda_dephvarname(17)='PRES               '
   cda_dephvarname(18)='PRES'
   cda_dephvarname(19)='PRES'
   cda_dephvarname(20)='PRES'
   cda_dephvarname(21)='PRES_ADJUSTED      '
   cda_dephvarname(22)='PRES_ADJUSTED      '
   cda_dephvarname(23)='PRES_ADJUSTED      '
   cda_dephvarname(24)='PRES_ADJUSTED      '
   cda_dephvarname(25)='PRES_ADJUSTED      '
   cda_dephvarname(26)='PRES_ADJUSTED      '
   cda_dephvarname(27)='PRES_ADJUSTED      '
   cda_dephvarname(28)='PRES_ADJUSTED      '
   cda_dephvarname(29)='PRES_ADJUSTED      '
   cd_outputFile="/homelocal-px/px-137/cregnier/tmp/CO_DMQCGL01_20060331_PR_XB_MERC.nc"
   print *,cda_dephvarname
   il_status = NF90_OPEN(cd_outputFile, &
        NF90_WRITE, &
        il_filid)
   il_status = NF90_REDEF(il_filid)
   IF (il_status .NE. NF90_NOERR) THEN
      WRITE(0,*) ' write_interp_field : problem encountered '
      CALL flush(0)
      STOP 
   ENDIF
   cd_outputVarname="DEPH_VAR_CHOICE2"
   il_status = (NF90_INQ_VARID(il_filid, &
                 TRIM(cd_outputVarname), &
                 il_variable_id))
    IF (il_status .EQ. NF90_NOERR) THEN
         WRITE(0,*) 'Variable existante  :: ',TRIM(cd_outputVarname)
    ELSE
       il_status = NF90_ENDDEF(il_filid)
       WRITE(0,*) 'Write variable :: ',TRIM(cd_outputVarname)
       CALL MIOL_write_field_NC (il_filid, &
            cd_outputVarname, &
            'CP', &
            cda_dephvarname(:),&
            20)
         WRITE(0,*) 'Write Variable ok  :: ',TRIM(cd_outputVarname)
   ENDIF
   !      
   il_status = NF90_CLOSE(il_filid)
   !
END PROGRAM test_write
