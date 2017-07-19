#:/bin/ksh
YEAR="2016"
YEAR="2017"
#MODEL="GIOPS"
#MODEL="FOAM"
#MODEL="PSY4V2R2"
MODEL="PSY4V3R1"
#ZONE="ANT"
#ECH="pers"
#ECH="fcst"
#for zone in ANT  ; do 
for zone in ARC ANT  ; do 
    ZONE=${zone}
 #   for ech in pers forecast best; do
    for ech in best; do
        ECH=$ech
        echo $ECH
#   python ./Launch_stats_total.py ${YEAR} ${MODEL} ${ZONE} ${ECH} serietemp1
#   python ./Launch_stats_total.py ${YEAR} ${MODEL} ${ZONE} ${ECH} serietemp2
#   python ./Launch_stats_total.py ${YEAR} ${MODEL} ${ZONE} ${ECH} index_skill
    python ./Launch_stats_total.py ${YEAR} ${MODEL} ${ZONE} ${ECH} 2Dstats
#   python ./Launch_stats_total.py ${YEAR} ${MODEL} ${ZONE} ${ECH} skill_ts
    done
done

