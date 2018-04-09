# Makefile for Fortran program Class 4
# Modifs C.REGNIER Janvier 2010
type=glorys2v4
type=orca12_allege
#type=cglors
include ../../macro/make_intel_$(type).macro
#include ../../macro/make_intel.macro
#include ../../macro/make_intel_orca12_allege.macro

# Rules
.SUFFIXES:.F90 .F .f90 .mod
.f90.o:
	$(F90PT) $(INCLUDE) $(FFLAGS) -c $< -o $@ $(CPP_KEYS)
.F90.o:
	$(F90PT) $(INCLUDE) $(FFLAGS) -c $< -o $@ $(CPP_KEYS)
#-------------------------------
EXEDIR= ../../bin
SRCDIR= ./module
OBJDIR= ./module
SRCDIR2= .
OBJDIR2= .
SRCDIR3= ./module2

#--------------------------------
OBJ = $(SRCDIR3)/hydro_potentiel.o \
      $(SRCDIR)/table_ARGO.o   \
      $(SRCDIR)/table_bathy.o \
      $(SRCDIR)/bathy.o \
      $(SRCDIR)/table_boite.o \
      $(SRCDIR)/table_class4.o \
      $(SRCDIR)/boite.o \
      $(SRCDIR)/boite_bins.o \
      $(SRCDIR)/diag_class4.o \
      $(SRCDIR)/read_ARGO.o  

OBJ2 = $(SRCDIR)/table_boite.o \
      $(SRCDIR)/boite_bins.o

OBJ3 = $(SRCDIR3)/hydro_potentiel.o \
      $(SRCDIR)/table_EN3.o   \
      $(SRCDIR)/table_bathy.o \
      $(SRCDIR)/bathy.o \
      $(SRCDIR)/table_boite.o \
      $(SRCDIR)/table_class4_EN3.o \
      $(SRCDIR)/boite.o \
      $(SRCDIR)/boite_bins.o \
      $(SRCDIR)/diag_class4_EN3.o \
      $(SRCDIR)/read_EN3.o

OBJ4 = $(SRCDIR3)/hydro_potentiel.o \
       $(SRCDIR)/table_ARGO.o   \
       $(SRCDIR)/table_bathy.o \
       $(SRCDIR)/bathy.o \
       $(SRCDIR)/table_boite.o \
       $(SRCDIR)/table_class4_new.o \
       $(SRCDIR)/boite.o \
       $(SRCDIR)/dens1d.o \
       $(SRCDIR)/boite_bins.o \
       $(SRCDIR)/diag_class4_new.o \
       $(SRCDIR)/read_ARGO.o  

all: $(EXEDIR)/Lecture_class4.exe \
     $(EXEDIR)/Lecture_class4_MLD.exe \
     $(EXEDIR)/Creation_zone.exe

test: $(EXEDIR)/Lecture_class4.exe 

change_path:
	@echo ""
	@echo "-------- Change path in module --------"
	@perl -pi -e "s|il_ficlog,file=.*|il_ficlog,file='${PWD}/../exe/'//TRIM(cd_LogFile),form='FORMATTED',&|g" ${PWD}/Lecture_class4.f90
	@perl -pi -e "s|il_ficsynth,file=.*|il_ficsynth,file='${PWD}/../exe/'//TRIM(cd_SynthFile),form='FORMATTED',&|g" ${PWD}/Lecture_class4.f90

	@perl -pi -e "s|FP_BoxDefFile=.*|FP_BoxDefFile='${PWD}/../utils/File_boxes.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|FP_DepthDefFile =.*|FP_DepthDefFile ='${PWD}/../utils/fic_tri_prof.in'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|FP_ParamNameFile =.*|FP_ParamNameFile ='${PWD}/../utils/param_names.in'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|FP_Deptht =.*|FP_Deptht ='${PWD}/../utils/deptht.in'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|FP_E3t =.*|FP_E3t ='${PWD}/../utils/e3t_0.in'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_FicRejetBathy =.*|cg_FicRejetBathy ='${PWD}/../exe/RejetProfilBathy.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_FicStatBoite =.*|cg_FicStatBoite ='${PWD}/../exe/ResultStatBoite.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_FicDiffTEMP =.*|cg_FicDiffTEMP ='${PWD}/../exe/ResultAnoTEMP.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_FicDiffTEMP_2 =.*|cg_FicDiffTEMP_2 ='${PWD}/../exe/Bad_points_TEMP_CORIO.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_FicDiffPSAL =.*|cg_FicDiffPSAL ='${PWD}/../exe/ResultAnoPSAL.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_FicDiffPSAL_2 =.*|cg_FicDiffPSAL_2 ='${PWD}/../exe/Bad_points_PSAL_CORIO.txt'|g" ${PWD}/module/table_class4.f90
	@perl -pi -e "s|cg_log=.*|cg_log='${PWD}/../exe/pb_profils.txt'|g" ${PWD}/module/table_class4.f90


$(EXEDIR)/Lecture_class4.exe: $(OBJ) $(SRCDIR2)/Lecture_class4.o
	$(F90) -o $@  $(LD_FLAGS) $? $(LIBRARY) 
#	@perl -pi -e "s|FP_ParamNameFile =.*|FP_ParamNameFile ='param_names_${type}.in'|g" ${PWD}/module/table_class4.f90

$(EXEDIR)/Lecture_class4_MLD.exe: $(OBJ4) $(SRCDIR2)/Lecture_class4_MLD.o
	$(F90) -o $@  $(LD_FLAGS) $? $(LIBRARY) 

$(EXEDIR)/Creation_zone.exe: $(OBJ2) $(SRCDIR2)/Creation_zone.o
	$(F90) -o $@  $(LD_FLAGS) $? $(LIBRARY)

$(EXEDIR)/Lecture_class4_EN3.exe: $(OBJ3) $(SRCDIR2)/Lecture_class4_EN3.o
	$(F90) -o $@  $(LD_FLAGS) $? $(LIBRARY) 

## Utilities
cleanexe : 
	rm $(EXEDIR)/*.exe
clean :
	rm -rf $(SRCDIR)/*.mod
	rm -rf $(SRCDIR)/*.o 
	rm -rf $(SRCDIR3)/*.o $(SRCDIR3)/*.mod 
	rm -rf $(SRCDIR2)/*.o	
	rm -rf $(SRCDIR2)/*.mod
