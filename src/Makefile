# Makefile for Fortran program Test_MIOL.F90
# Makefile pour n'importe quel px
# C.REGNIER 2010
# faire module load pgi/pgi-8.0
#       module load netcdf/netcdf-4.0_pgi80_r4
#       module load mft/mft-3.1
include ../macro/make_intel_orca12_meteo.macro
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
         ${SRCDIR2}/geomlibcha.o        \
         ${SRCDIR2}/Canvas.o

OBJECTS2= $(SRCDIR2)/GSW_TEOS10.o \
          ${SRCDIR2}/table_CLASS4.o

amsr: $(EXEDIR)/CLASS4_spatial_interpolation_GODAE_AMSR.exe 
aice: $(EXEDIR)/CLASS4_spatial_interpolation_GODAE.exe 
#all: $(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE).exe \
#	$(EXEDIR)/CLASS4_spatial_interpolation.exe \
#	$(EXEDIR)/CLASS4_spatial_interpolation_GODAE_$(MODELE).exe
all:  $(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS.exe \
      $(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE).exe \
      $(EXEDIR)/CLASS4_spatial_interpolation_GODAE.exe \
      $(EXEDIR)/CLASS4_spatial_interpolation_GODAE_AMSR.exe 

$(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE)_test.exe: $(OBJECTS) CLASS4_create_colocfile_ASCII.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_create_colocfile_ASCII_$(MODELE).exe: $(OBJECTS) CLASS4_create_colocfile_ASCII.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_spatial_interpolation_GODAE_AMSR.exe: $(OBJECTS2) CLASS4_spatial_interpolation_godae_AMSR.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_spatial_interpolation_GODAE.exe: $(OBJECTS2) CLASS4_spatial_interpolation_godae.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)

$(EXEDIR)/CLASS4_spatial_interpolation_CORIOLIS.exe: $(OBJECTS2) CLASS4_spatial_interpolation.o
	$(F90) -o $@ $? $(LD_FLAGS) $(LIBRARY)


## Utilities
cleanexe : 
	rm -f ../bin/CLASS4_create_ASCII_$(MODELE).exe ../bin/CLASS4_spatial_interpolation.exe
	rm -f ../bin/CLASS4_spatial_interpolation_GODAE_$(MODELE).exe
clean: 
	rm -rf $(SRCDIR2)/*.o $(SRCDIR2)/*.mod
	rm -rf $(SRCDIR)/*.o $(SRCDIR)/*.mod 
