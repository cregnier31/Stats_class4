############################################################################
# Makefile
#
# Makefile pour compiler tout les programmes de pre et postraitment TEP_CLASS4
# C.REGNIER
#
#############################################################################
#
#
#################################################################################
#SYSTEM=orca025
##SYSTEM=orca12
##SYSTEM=atl12
##SYSTEM=med12
#SYSTEM=ibi36

#include macro/make_$(SYSTEM).macro
MAKE=gmake
DIR_HOME=${PWD}
DIR_PRE=$(DIR_HOME)/src
DIR_POST=$(DIR_HOME)/postraitement/src
DIR_MACRO=$(DIR_HOME)/macro 

all: 
	@set -x; \
        cd $(DIR_MACRO); ln -f -s make_intel_$(SYSTEM)_${MACHINE}.macro make_intel.macro 2>&1; \
        cd $(DIR_PRE); $(MAKE) 1> $(DIR_HOME)/compile_pretreatment.txt 2>&1; \
        cd $(DIR_POST); $(MAKE) 1> $(DIR_HOME)/compile_postreatement.txt 2>&1; \


clean: 
	@set -x; \
	/bin/rm -f compile_*.txt
	cd $(DIR_MACRO); ln -f -s make_intel_$(SYSTEM)_${MACHINE}.macro make_intel.macro 2>&1; \
	cd $(DIR_PRE); $(MAKE) clean ; \
        cd $(DIR_POST); $(MAKE) clean; \

