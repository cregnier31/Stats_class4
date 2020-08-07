##
# Launcher compilation
# C.REGNIER

##system="med12"
##system="orca12"
system="orca025"
#system="MEDRYS1V1"
machine="local"

make clean SYSTEM=${system} MACHINE=${machine} || exit 1
make all SYSTEM=${system} MACHINE=${machine} || exit 1
