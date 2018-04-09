#####################################################################
# Program : class-convertor Makefile
#
# Version    Date          Author     Notes
# 1.0      28/12/07       N. PENE
# 1.1      28/03/08       C.REGNIER   portage arctique1 : creation macro
# 1.1      01/12/08       S.BESNARD   modif ajout arborescence bin/obj/src
#
# Inputs  :
#
# Notes   :
#
#
#####################################################################
#include ../make_intel.macro
include /home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/macro/make_intel_orca12_stereo.macro
.SUFFIXES:.F90 .F .f90 .mod
.F90.o:
	$(F90) -c $(FFLAGS) ${INCLUDE} $< -o $@  $(CPP_KEYS)

BINDIR=.

########################################################
BIN = \
    bin/MCAL_SEAICE_STATS
	
OBJ = \
	$(OBJDIR)/getfreelu.o \
	$(OBJDIR)/table_boite.o \
	$(OBJDIR)/boite.o \
	$(OBJDIR)/Create_MaskBoite_stereo.o

all: $(BIN)

$(BIN): $(OBJ)
	$(COMPILE) $(OBJ) $(FFLAGS) $(LIB) -o $@
	@echo "Executable acheve"

$(OBJDIR)/%.o: $(SRCDIR)/%.F90
	$(COMPILE) $(INCLUDE) $(FFLAGS) -c $< -o $@

clean: 
	/bin/rm -r $(OBJ) $(SRCDIR)/*.mod $(BIN)
