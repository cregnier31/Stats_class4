!--------------------------------------------------------------
 SUBROUTINE getFreeLU ( LU )

! get free Fortran logical unit

!=getFreeLU=getfreelu= P De Mey


   IMPLICIT NONE
   INTEGER,intent(out) :: LU
   integer :: testLU
   LOGICAL :: isOpened

! we have to try everything since we don't know when a LU is freed

   DO testLU = 100,200
     INQUIRE ( unit=testLU, opened=isOpened )
     IF ( .NOT. isOpened ) THEN
         LU = testLU
         RETURN
     END IF
   END DO

! bypass event()

   WRITE ( 0, '(a)') '-FATAL- no free logical units available'
   STOP '-FATAL- no free logical units available'

 END SUBROUTINE getFreeLU

!--------------------------------------------------------------
