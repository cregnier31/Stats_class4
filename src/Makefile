# Makefile for Fortran program Test_MIOL.F90
# Makefile pour n'importe quel px
# C.REGNIER 2017
# Makefile naviti
# intel/intel-17
# netcdf/netcdf-4.1_intel11_r4
#type=orca12_allege
type=orca025
#type=orca12
#type=glorys2v4
include ../macro/make_intel_$(type).macro
## Rules
.SUFFIXES:.F90 .F .f90 .mod
.F90.o:
	$(F90PT) -c $(FFLAGS) ${INCLUDE} $< -o $@ $(CPP_KEYS)

.f90.o:
	$(F90PT) -c $(FFLAGS) ${INCLUDE} $< -o $@ $(CPP_KEYS)

EXEDIR= ../bin
SRCDIR= .
SRCDIR2=module

########################################################
########################################################
########################################################
OBJECTS= ${SRCDIR2}/Inf_NaN_detection.o \
         ${SRCDIR2}/param_mod.o         \
         ${SRCDIR2}/geomlibcha_arc.o        \
         ${SRCDIR2}/Canvas.o
OBJECTS3= ${SRCDIR2}/Inf_NaN_detection.o \
	  ${SRCDIR2}/param_mod.o         \
	  ${SRCDIR2}/geomlibcha.o        \
	  ${SRCDIR2}/Canvas.o
OBJECTS2= $(SRCDIR2)/GSW_TEOS10.o \
          ${SRCDIR2}/table_CLASS4.o

#all: $(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE).exe \
#	$(EXEDIR)/CLASS4_spatial_interpolation.exe \
#	$(EXEDIR)/CLASS4_spatial_interpolation_GODAE_$(MODELE).exe
all:  $(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS.exe \
      $(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE).exe \
      $(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE)_aice.exe \
      $(EXEDIR)/CLASS4_spatial_interpolation_GODAE.exe 
aice: $(EXEDIR)/CLASS4_spatial_interpolation_GODAE.exe
coloc_aice: $(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE)_aice.exe
test: $(EXEDIR)/test_write.exe
inter_corio: $(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS.exe 
test_interp: $(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS_test.exe 

$(EXEDIR)/test_write.exe: test_write.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE).exe: $(OBJECTS3) CLASS4_create_colocfile_ASCII.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE)_aice.exe: $(OBJECTS) CLASS4_create_colocfile_ASCII.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_spatial_interpolation_GODAE.exe: $(OBJECTS2) CLASS4_spatial_interpolation_godae.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS.exe: $(OBJECTS2) CLASS4_spatial_interpolation.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS_test.exe: $(OBJECTS2) CLASS4_spatial_interpolation.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

## Utilities
cleanexe : 
	rm -f ../bin/CLASS4_create_ASCII_$(MODELE).exe ../bin/CLASS4_spatial_interpolation.exe
	rm -f ../bin/CLASS4_spatial_interpolation_GODAE_$(MODELE).exe
clean: 
	rm -rf $(SRCDIR2)/*.o $(SRCDIR2)/*.mod
	rm -rf $(SRCDIR)/*.o $(SRCDIR)/*.mod 
