#!/bin/ksh 

# Date calculations using Korn shell
# Calendar date from Julian Day Number

j2d()
{
  typeset -i day month year tmpday centuries
  typeset -Z2 day month

  ((tmpday = $1 + 712164))
  ((centuries = (4 * tmpday - 1) / 146097))
  ((tmpday += centuries - centuries/4))
  ((year = (4 * tmpday - 1) / 1461))
  ((tmpday -= (1461 * year) / 4))
  ((month = (10 * tmpday - 5) / 306))
  ((day = tmpday - (306 * month + 5) / 10))
  ((month += 2))
  ((year += month/12))
  ((month = month % 12 + 1))

   print $day $month $year
}

# Date calculations using Korn shell
# Julian Day Number from calendar date
# jj mm aaaa

d2j()
{
  typeset -i day month year tmpmonth tmpyear

  day=$1;  month=$2;  year=$3
  ((tmpmonth = 12 * year + month - 3))
  ((tmpyear = tmpmonth / 12))
  print $(( (734 * tmpmonth + 15) / 24 -  2 * tmpyear + \
  tmpyear/4 - tmpyear/100 + tmpyear/400 + day - 712164 ))
} 

j2d2()
{
  typeset -i day month year tmpday centuries
  typeset -Z2 day month

  ((tmpday = $1 + 712164))
  ((centuries = (4 * tmpday - 1) / 146097))
  ((tmpday += centuries - centuries/4))
  ((year = (4 * tmpday - 1) / 1461))
  ((tmpday -= (1461 * year) / 4))
  ((month = (10 * tmpday - 5) / 306))
  ((day = tmpday - (306 * month + 5) / 10))
  ((month += 2))
  ((year += month/12))
  ((month = month % 12 + 1))

   print $year$month$day
}

d2j2()
{
  typeset -i day month year tmpmonth tmpyear
  yyyymmdd=$1
  year=`echo $yyyymmdd | cut -c1-4`
  month=`echo $yyyymmdd | cut -c5-6`
  day=`echo $yyyymmdd | cut -c7-8`

  ((tmpmonth = 12 * year + month - 3))
  ((tmpyear = tmpmonth / 12))
  print $(( (734 * tmpmonth + 15) / 24 -  2 * tmpyear + \
  tmpyear/4 - tmpyear/100 + tmpyear/400 + day - 712164 ))
} 


function isHindcast {
    # return "1" if Hindcast, else "0". G.Vinay/FMessal
    fic=$1
    date_F=$(echo ${fic##*/} | awk -F"_" '{print $3}')
    #echo ' date_F = ' $date_F
    date_B=$(echo ${fic##*/} | cut -d'_' -f6 | cut -c2-9) 
    #echo ' date_B = ' $date_B
    difference=$(quel_diff $date_B $date_F)
    case $difference in
        8|9|10|11|12|13|14)echo "1";;
        *)echo "0";;
    esac
}

function isNowcast {
    # return "1" if Hindcast, else "0". G.Vinay/FMessal
    fic=$1
    date_F=$(echo ${fic##*/} | awk -F"_" '{print $3}')
    #echo ' date_F = ' $date_F
    date_B=$(echo ${fic##*/} | cut -d'_' -f6 | cut -c2-9) 
    #echo ' date_B = ' $date_B
    difference=$(quel_diff $date_B $date_F)
    case $difference in
        1|2|3|4|5|6|7)echo "1";;
        *)echo "0";;
    esac
}


function isHindcastRTR {
    # return "1" if HindcastRTR, else "0" C.REGNIER
    fic=$1
    date_F=$(echo ${fic##*/} | awk -F"_" '{print $3}')
    #echo ' date_F = ' $date_F
    date_B=$(echo ${fic##*/} | cut -d'_' -f6 | cut -c2-9)
    #echo ' date_B = ' $date_B
    difference=$(quel_diff $date_B $date_F)
    #echo ' diff = ' $difference
    case $difference in
        0|1|2|3|4|5|6|7|8|9|10|11|12|13|14)echo "1";;
        *)echo "0";;
    esac
}

function isForecast1 {
    # set -vx
    # return "1" if forecast1, else "0". G.Vinay/FMessal
    fic=$1
    date_F=$(echo ${fic##*/} | awk -F"_" '{print $3}')
    date_B=$(echo ${fic##*/} | cut -d'_' -f6 | cut -c2-9)
    difference=$(quel_diff $date_F $date_B)
    case $difference in
        0|1|2|3|4|5|6)echo "1";;
        *)echo "0";;
    esac
}

function isForecast2 {
    # set -vx
    # return "1" if forecast1, else "0". G.Vinay/FMessal
    fic=$1
    date_F=$(echo ${fic##*/} | awk -F"_" '{print $3}')
    date_B=$(echo ${fic##*/} | cut -d'_' -f6 | cut -c2-9)
    difference=$(quel_diff $date_F $date_B)
    case $difference in
        7|8|9|10|11|12|13)echo "1";;
        *)echo "0";;
    esac
}
