#!/bin/bash
USAGE="Usage: $0 num (with POSCAR in current directory)"
if [ ! -f POSCAR ]; then
    echo "I can't find a POSCAR here!"
    exit
fi
if [ "$#" == "0" ]; then
    echo "$USAGE"
    exit
fi
a11=`awk 'NR==3 {print $1}' POSCAR`
a12=`awk 'NR==3 {print $2}' POSCAR`
a13=`awk 'NR==3 {print $3}' POSCAR`
a21=`awk 'NR==4 {print $1}' POSCAR`
a22=`awk 'NR==4 {print $2}' POSCAR`
a23=`awk 'NR==4 {print $3}' POSCAR`
a31=`awk 'NR==5 {print $1}' POSCAR`
a32=`awk 'NR==5 {print $2}' POSCAR`
a33=`awk 'NR==5 {print $3}' POSCAR`
n=`awk 'NR==7 {for(i=1;i<=NF;i++) t+=$i; print t; t=0}' POSCAR`
a1=`echo "scale=6;sqrt($a11^2+$a12^2+$a13^2)" | bc -l`
a2=`echo "scale=6;sqrt($a21^2+$a22^2+$a23^2)" | bc -l`
a3=`echo "scale=6;sqrt($a31^2+$a32^2+$a33^2)" | bc -l`
aa=`echo "scale=6;e(l($a1*$a2*$a3/$n)/3)" | bc -l`
k1=`echo "scale=3;$1*$aa/$a1" | bc`
k2=`echo "scale=3;$1*$aa/$a2" | bc`
k3=`echo "scale=3;$1*$aa/$a3" | bc`
printf "%3.0f%3.0f%3.0f\n" $k1 $k2 $k3
