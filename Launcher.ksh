##
# Launcher compilation
# C.REGNIER

system="med12"
system="orca12"
#system="orca025"
#system="MEDRYS1V1"


make clean SYSTEM=${system} || exit 1
make all SYSTEM=${system} || exit 1
