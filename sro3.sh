#!/bin/bash

# INPUTS
min=$1
max=$2
pos=$3

# CODE
dir=`pwd`
$HOME/Apps/Koala/bin/neighbor $pos $min $max
neigh=neighbor_${pos}_${min}-${max}
elem=`sed -n 6p $pos | wc -w`
x11=`awk 'NR==3 {print $2}' $neigh`
x12=`awk 'NR==3 {print $3}' $neigh`
x13=`awk 'NR==3 {print $4}' $neigh`
x22=`awk 'NR==4 {print $3}' $neigh`
x23=`awk 'NR==4 {print $4}' $neigh`
x33=`awk 'NR==5 {print $4}' $neigh`
x=`echo "$x11+$x22+$x33+$x12*2+$x13*2+$x23*2" | bc`
e1=`awk 'NR==6 {print $1}' $pos`
e2=`awk 'NR==6 {print $2}' $pos`
e3=`awk 'NR==6 {print $3}' $pos`
n1=`awk 'NR==7 {print $1}' $pos`
n2=`awk 'NR==7 {print $2}' $pos`
n3=`awk 'NR==7 {print $3}' $pos`
c1=`echo "scale=6;$n1/($n1+$n2+$n3)" | bc`
c2=`echo "scale=6;$n2/($n1+$n2+$n3)" | bc`
c3=`echo "scale=6;$n3/($n1+$n2+$n3)" | bc`
sro11=`echo "scale=6;($x11/$x/$c1-$c1)/(1-$c1)" | bc`
sro12=`echo "scale=6;1-$x12/$x/$c1/$c2" | bc`
sro13=`echo "scale=6;1-$x13/$x/$c1/$c3" | bc`
sro22=`echo "scale=6;($x22/$x/$c2-$c2)/(1-$c2)" | bc`
sro23=`echo "scale=6;1-$x23/$x/$c2/$c3" | bc`
sro33=`echo "scale=6;($x33/$x/$c3-$c3)/(1-$c3)" | bc`
printf "$e1-$e1%8.2f\n" $sro11 >  SRO.txt
printf "$e1-$e2%8.2f\n" $sro12 >> SRO.txt
printf "$e1-$e3%8.2f\n" $sro13 >> SRO.txt
printf "$e2-$e2%8.2f\n" $sro22 >> SRO.txt
printf "$e2-$e3%8.2f\n" $sro23 >> SRO.txt
printf "$e3-$e3%8.2f\n" $sro33 >> SRO.txt
sort SRO.txt -o SRO.txt
rm -f SRO.txt $neigh
