MODULE NUMERIC_REC


INTERFACE realft
MODULE PROCEDURE realft_dp, &
                 realft_sp
!		SUBROUTINE realft_dp(data,isign,zdata)
!		USE nrtype
!		REAL(DP), DIMENSION(:), INTENT(INOUT) :: data
!		INTEGER(I4B), INTENT(IN) :: isign
!		COMPLEX(DPC), DIMENSION(:), OPTIONAL, TARGET :: zdata
!		END SUBROUTINE realft_dp
!BL
!		SUBROUTINE realft_sp(data,isign,zdata)
!		USE nrtype
!		REAL(SP), DIMENSION(:), INTENT(INOUT) :: data
!		INTEGER(I4B), INTENT(IN) :: isign
!		COMPLEX(SPC), DIMENSION(:), OPTIONAL, TARGET :: zdata
!		END SUBROUTINE realft_sp
END INTERFACE
INTERFACE four1
MODULE PROCEDURE  four1_dp,&
                  four1_sp
!		SUBROUTINE four1_dp(data,isign)
!		USE nrtype
!		COMPLEX(DPC), DIMENSION(:), INTENT(INOUT) :: data
!		INTEGER(I4B), INTENT(IN) :: isign
!		END SUBROUTINE four1_dp
!BL
!		SUBROUTINE four1_sp(data,isign)
!		USE nrtype
!		COMPLEX(SPC), DIMENSION(:), INTENT(INOUT) :: data
!		INTEGER(I4B), INTENT(IN) :: isign
!		END SUBROUTINE four1_sp
	END INTERFACE

 INTERFACE fourrow
 MODULE PROCEDURE fourrow_dp, &
                  fourrow_sp     
!		SUBROUTINE fourrow_dp(data,isign)
!		USE nrtype
!               COMPLEX(DPC), DIMENSION(:,:), INTENT(INOUT) :: data
!		INTEGER(I4B), INTENT(IN) :: isign
!		END SUBROUTINE fourrow_dp
!!BL
!		SUBROUTINE fourrow_sp(data,isign)
!		USE nrtype
!		COMPLEX(SPC), DIMENSION(:,:), INTENT(INOUT) :: data
!		INTEGER(I4B), INTENT(IN) :: isign
!		END SUBROUTINE fourrow_sp
	END INTERFACE
CONTAINS
! 
!-----------------------------------------------------------------------
!             
SUBROUTINE realft_sp(data,isign,zdata)
    !
    !**** realft_sp
    !     Purpose :
    !     Compute real fourier transform
    ! 
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       Numerical recipies    1/08/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 
    !
	USE nrtype; USE nrutil, ONLY : assert,assert_eq,zroots_unity
	IMPLICIT NONE
	REAL(SP), DIMENSION(:), INTENT(INOUT) :: data
	INTEGER(I4B), INTENT(IN) :: isign
	COMPLEX(SPC), DIMENSION(:), OPTIONAL, TARGET :: zdata
	INTEGER(I4B) :: n,ndum,nh,nq
	COMPLEX(SPC), DIMENSION(size(data)/4) :: w
	COMPLEX(SPC), DIMENSION(size(data)/4-1) :: h1,h2
	COMPLEX(SPC), DIMENSION(:), POINTER :: cdata
	COMPLEX(SPC) :: z
	REAL(SP) :: c1=0.5_sp,c2
    !
    !*-------------------------------------------------------------
    !
	n=size(data)
	call assert(iand(n,n-1)==0, 'n must be a power of 2 in realft_sp')
	nh=n/2
	nq=n/4
	if (present(zdata)) then
		ndum=assert_eq(n/2,size(zdata),'realft_sp')
		cdata=>zdata
		if (isign == 1) cdata=cmplx(data(1:n-1:2),data(2:n:2),kind=spc)
	else
		allocate(cdata(n/2))
		cdata=cmplx(data(1:n-1:2),data(2:n:2),kind=spc)
	end if
	if (isign == 1) then
		c2=-0.5_sp
		call four1(cdata,+1)
	else
		c2=0.5_sp
	end if
	w=zroots_unity(sign(n,isign),n/4)
	w=cmplx(-aimag(w),real(w),kind=spc)
	h1=c1*(cdata(2:nq)+conjg(cdata(nh:nq+2:-1)))
	h2=c2*(cdata(2:nq)-conjg(cdata(nh:nq+2:-1)))
	cdata(2:nq)=h1+w(2:nq)*h2
	cdata(nh:nq+2:-1)=conjg(h1-w(2:nq)*h2)
	z=cdata(1)
	if (isign == 1) then
		cdata(1)=cmplx(real(z)+aimag(z),real(z)-aimag(z),kind=spc)
	else
		cdata(1)=cmplx(c1*(real(z)+aimag(z)),c1*(real(z)-aimag(z)),kind=spc)
		call four1(cdata,-1)
	end if
	if (present(zdata)) then
		if (isign /= 1) then
			data(1:n-1:2)=real(cdata)
			data(2:n:2)=aimag(cdata)
		end if
	else
		data(1:n-1:2)=real(cdata)
		data(2:n:2)=aimag(cdata)
		deallocate(cdata)
	end if
!
!*-------------------------------------------------------
!
	END SUBROUTINE realft_sp
!
!*==================================================
!
        SUBROUTINE realft_dp(data,isign,zdata)
    !
    !**** realft_dp
    !     Purpose :
    !     Compute real fourier transform
    ! 
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       Numerical recipies    1/08/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 
    	USE nrtype; USE nrutil, ONLY : assert,assert_eq,zroots_unity
	IMPLICIT NONE
	REAL(DP), DIMENSION(:), INTENT(INOUT) :: data
	INTEGER(I4B), INTENT(IN) :: isign
	COMPLEX(DPC), DIMENSION(:), OPTIONAL, TARGET :: zdata
	INTEGER(I4B) :: n,ndum,nh,nq
	COMPLEX(DPC), DIMENSION(size(data)/4) :: w
	COMPLEX(DPC), DIMENSION(size(data)/4-1) :: h1,h2
	COMPLEX(DPC), DIMENSION(:), POINTER :: cdata
	COMPLEX(DPC) :: z
	REAL(DP) :: c1=0.5_dp,c2
	n=size(data)
	call assert(iand(n,n-1)==0, 'n must be a power of 2 in realft_dp')
	nh=n/2
	nq=n/4
	if (present(zdata)) then
		ndum=assert_eq(n/2,size(zdata),'realft_dp')
		cdata=>zdata
		if (isign == 1) cdata=cmplx(data(1:n-1:2),data(2:n:2),kind=spc)
	else
		allocate(cdata(n/2))
		cdata=cmplx(data(1:n-1:2),data(2:n:2),kind=spc)
	end if
	if (isign == 1) then
		c2=-0.5_dp
		call four1(cdata,+1)
	else
		c2=0.5_dp
	end if
	w=zroots_unity(sign(n,isign),n/4)
	w=cmplx(-aimag(w),real(w),kind=dpc)
	h1=c1*(cdata(2:nq)+conjg(cdata(nh:nq+2:-1)))
	h2=c2*(cdata(2:nq)-conjg(cdata(nh:nq+2:-1)))
	cdata(2:nq)=h1+w(2:nq)*h2
	cdata(nh:nq+2:-1)=conjg(h1-w(2:nq)*h2)
	z=cdata(1)
	if (isign == 1) then
		cdata(1)=cmplx(real(z)+aimag(z),real(z)-aimag(z),kind=dpc)
	else
		cdata(1)=cmplx(c1*(real(z)+aimag(z)),c1*(real(z)-aimag(z)),kind=dpc)
		call four1(cdata,-1)
	end if
	if (present(zdata)) then
		if (isign /= 1) then
			data(1:n-1:2)=real(cdata)
			data(2:n:2)=aimag(cdata)
		end if
	else
		data(1:n-1:2)=real(cdata)
		data(2:n:2)=aimag(cdata)
		deallocate(cdata)
	end if
	END SUBROUTINE realft_dp
!
!*==================================================
!

SUBROUTINE four1_sp(data,isign)
    !
    !**** four1_sp
    !     Purpose :
    !      
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       Numerical recipies    1/08/2007    created
    !
    !*-------------------------------------------------------------
    !
    !
    !** ++  Local Declarations 	
        USE nrtype; USE nrutil, ONLY : arth,assert
!	USE nr, ONLY : fourrow
	IMPLICIT NONE
	COMPLEX(SPC), DIMENSION(:), INTENT(INOUT) :: data
	INTEGER(I4B), INTENT(IN) :: isign
	COMPLEX(SPC), DIMENSION(:,:), ALLOCATABLE :: dat,temp
	COMPLEX(DPC), DIMENSION(:), ALLOCATABLE :: w,wp
	REAL(DP), DIMENSION(:), ALLOCATABLE :: theta
	INTEGER(I4B) :: n,m1,m2,j
	n=size(data)
	call assert(iand(n,n-1)==0, 'n must be a power of 2 in four1_sp')
	m1=2**ceiling(0.5_sp*log(real(n,sp))/0.693147_sp)
	m2=n/m1
	allocate(dat(m1,m2),theta(m1),w(m1),wp(m1),temp(m2,m1))
	dat=reshape(data,shape(dat))
	call fourrow(dat,isign)
	theta=arth(0,isign,m1)*TWOPI_D/n
	wp=cmplx(-2.0_dp*sin(0.5_dp*theta)**2,sin(theta),kind=dpc)
	w=cmplx(1.0_dp,0.0_dp,kind=dpc)
	do j=2,m2
		w=w*wp+w
		dat(:,j)=dat(:,j)*w
	end do
	temp=transpose(dat)
	call fourrow(temp,isign)
	data=reshape(temp,shape(data))
	deallocate(dat,w,wp,theta,temp)
	END SUBROUTINE four1_sp
!
!==============================================================
!
	SUBROUTINE four1_dp(data,isign)
    !
    !**** four1_dp
    !     Purpose :
    !      double precision
    !     History
    !     -------
    !      Version    Programmer    Date       Description
    !      ---------------------------------------------
    !       1.0       Numerical recipies    1/08/2007    created
    !
    !*-------------------------------------------------------------
    !
    	USE nrtype; USE nrutil, ONLY : arth,assert
!	USE nr, ONLY : fourrow
	IMPLICIT NONE
	COMPLEX(DPC), DIMENSION(:), INTENT(INOUT) :: data
	INTEGER(I4B), INTENT(IN) :: isign
	COMPLEX(DPC), DIMENSION(:,:), ALLOCATABLE :: dat,temp
	COMPLEX(DPC), DIMENSION(:), ALLOCATABLE :: w,wp
	REAL(DP), DIMENSION(:), ALLOCATABLE :: theta
	INTEGER(I4B) :: n,m1,m2,j
	n=size(data)
	call assert(iand(n,n-1)==0, 'n must be a power of 2 in four1_dp')
	m1=2**ceiling(0.5_sp*log(real(n,sp))/0.693147_sp)
	m2=n/m1
	allocate(dat(m1,m2),theta(m1),w(m1),wp(m1),temp(m2,m1))
	dat=reshape(data,shape(dat))
	call fourrow(dat,isign)
	theta=arth(0,isign,m1)*TWOPI_D/n
	wp=cmplx(-2.0_dp*sin(0.5_dp*theta)**2,sin(theta),kind=dpc)
	w=cmplx(1.0_dp,0.0_dp,kind=dpc)
	do j=2,m2
		w=w*wp+w
		dat(:,j)=dat(:,j)*w
	end do
	temp=transpose(dat)
	call fourrow(temp,isign)
	data=reshape(temp,shape(data))
	deallocate(dat,w,wp,theta,temp)
!
!*--------------------------------------------
!
  	END SUBROUTINE four1_dp
!
!*==================================================
!
SUBROUTINE fourrow_sp(data,isign)
	USE nrtype; USE nrutil, ONLY : assert,swap
	IMPLICIT NONE
	COMPLEX(SPC), DIMENSION(:,:), INTENT(INOUT) :: data
	INTEGER(I4B), INTENT(IN) :: isign
	INTEGER(I4B) :: n,i,istep,j,m,mmax,n2
	REAL(DP) :: theta
	COMPLEX(SPC), DIMENSION(size(data,1)) :: temp
	COMPLEX(DPC) :: w,wp
	COMPLEX(SPC) :: ws
!
!*--------------------------------------------
!	n=size(data,2)
	call assert(iand(n,n-1)==0, 'n must be a power of 2 in fourrow_sp')
	n2=n/2
	j=n2
	do i=1,n-2
		if (j > i) call swap(data(:,j+1),data(:,i+1))
		m=n2
		do
			if (m < 2 .or. j < m) exit
			j=j-m
			m=m/2
		end do
		j=j+m
	end do
	mmax=1
	do
		if (n <= mmax) exit
		istep=2*mmax
		theta=PI_D/(isign*mmax)
		wp=cmplx(-2.0_dp*sin(0.5_dp*theta)**2,sin(theta),kind=dpc)
		w=cmplx(1.0_dp,0.0_dp,kind=dpc)
		do m=1,mmax
			ws=w
			do i=m,n,istep
				j=i+mmax
				temp=ws*data(:,j)
				data(:,j)=data(:,i)-temp
				data(:,i)=data(:,i)+temp
			end do
			w=w*wp+w
		end do
		mmax=istep
	end do
!
!*-----------------------------------------------------
!
	END SUBROUTINE fourrow_sp
!
!*==================================================
!
	SUBROUTINE fourrow_dp(data,isign)
	USE nrtype; USE nrutil, ONLY : assert,swap
	IMPLICIT NONE
	COMPLEX(DPC), DIMENSION(:,:), INTENT(INOUT) :: data
	INTEGER(I4B), INTENT(IN) :: isign
	INTEGER(I4B) :: n,i,istep,j,m,mmax,n2
	REAL(DP) :: theta
	COMPLEX(DPC), DIMENSION(size(data,1)) :: temp
	COMPLEX(DPC) :: w,wp
	COMPLEX(DPC) :: ws
	n=size(data,2)
	call assert(iand(n,n-1)==0, 'n must be a power of 2 in fourrow_dp')
	n2=n/2
	j=n2
	do i=1,n-2
		if (j > i) call swap(data(:,j+1),data(:,i+1))
		m=n2
		do
			if (m < 2 .or. j < m) exit
			j=j-m
			m=m/2
		end do
		j=j+m
	end do
	mmax=1
	do
		if (n <= mmax) exit
		istep=2*mmax
		theta=PI_D/(isign*mmax)
		wp=cmplx(-2.0_dp*sin(0.5_dp*theta)**2,sin(theta),kind=dpc)
		w=cmplx(1.0_dp,0.0_dp,kind=dpc)
		do m=1,mmax
			ws=w
			do i=m,n,istep
				j=i+mmax
				temp=ws*data(:,j)
				data(:,j)=data(:,i)-temp
				data(:,i)=data(:,i)+temp
			end do
			w=w*wp+w
		end do
		mmax=istep
	end do
!
!*-----------------------------------------------------
!
	END SUBROUTINE fourrow_dp

!
!=============================================================
!

END MODULE NUMERIC_REC
