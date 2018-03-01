#!/usr/bin/env python
#PBS -N CLASS4
#PBS -j oe
#PBS -l nodes=2:ppn=16
#PBS -l walltime=03:00:00
#PBS -q multi

#---------------------------------------------------
import shlex,subprocess
import os,sys,getopt
import resource

## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


pbsworkdir  = os.getenv('pbsworkdir')
cl_dateMinZone = os.getenv('day1')
cl_dateMaxZone = os.getenv('day2')
_DBFILE_ = os.getenv('cfg')
datatype = os.getenv('type')
_NPROCS_=32
#_NPROCS_ = 16

#~~~~ Environment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
os.chdir(pbsworkdir)

EXE = os.path.join(pbsworkdir,'exe_Lecture_class4_new.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag")) 
except : pass
#command_line ="module load ipython"
#command_run = shlex.split(command_line)
#print command_run
#try :	subprocess.Popen(command_run)
#except : raise
#command_run.wait()
#
#
#command_line  = "mpirun -np %i ipython -- %s --day1=%s --day2=%s --cfg=%s" %(_NPROCS_,EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_)
#command_run = shlex.split(command_line)
#try :	subprocess.Popen(command_run)
#except : raise
print "Debut mpirun"	
#print "-np %i"%(_NPROCS_)
#os.system("module load ipython ;\
#        mpirun -np %i ipython -- %s --day1=%s --day2=%s --cfg=%s" %(_NPROCS_,EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_)
#         )
os.system("mpirun -np 32 ipython --verbose_crash=True -- %s --day1=%s --day2=%s --cfg=%s --type=%s" %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype))
#        mpirun -np 32 ipython --ipython-dir=/naviti/data2/cregnier/ipython -- %s --day1=%s --day2=%s --cfg=%s" %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_))

open(os.path.join(pbsworkdir,"OK.flag"), "a") 
