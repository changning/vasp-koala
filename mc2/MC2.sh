#! /bin/bash
#PBS -N mc2
#PBS -l walltime=1:00:00:00
#PBS -l nodes=4:ppn=20
#PBS -j oe
#PBS -m ae

################################################################################
#                      How to use this job script                              #
#         1. Prepare files in the current directory:                           #
#             job       - this script to submit to a batch system              #
#             INCAR     - use modest accuracy                                  #
#             KPOINTS   - use modest accuracy                                  #
#             POSCAR_a  - one of the two initial POSCAR                        #
#             POSCAR_b  - the other POSCAR                                     #
#             POTCAR_xx - multiple POTCARs for related elements                #
#         2. Submit the job to the batch system                                #
#             qsub job                                                         #
#         3. Resubmit the job to restart                                       #
#                                                                              #
#                    --- Requirements of POSCAR ---                            #
#             POSCAR must follow standard VASP 5 format.                       #
#                Line 6: name of elements                                      #
#                Line 7: number of atoms of each element                       #
#                Line 8: direct or cartesian                                   #
#                Line 9-: Atomic coordinates                                   #
#                                                                              #
#           Updated by Changning Niu on Apr 6, 2016.                           #
################################################################################

## !!! You may want to change these flags:
T=300   # temperature used in the Metropolis criterion
VASP=$HOME/Apps/VASP/Ruby/VASP_5.4.1/bin/vasp_std   # path to vasp executable
MPI=mpiexec     # mpi command
#module load intelmpi      # environment settings to run vasp

####### Now the code starts. Edit at your own risk.
DEBUG=0     # enable debug reports, 1=yes, 0=no

# Define output directories and files
DIR=$PBS_O_WORKDIR  # current working directory
POS=$DIR/POSCARs    # directory to save all intermediate POSCARs
OUT=$DIR/OUT        # directory to save all vasp outputs
TMP=$DIR/TMP        # temporary directories (a/b) to run vasp
ETOT=$DIR/Etot.txt  # file to save intermediate energies
ERR=$DIR/error.txt  # file to report errors defined in the script

# Check files and create directories 
cd $DIR
rm -f $ERR              # delete error file if exists
if [ ! -f INCAR ]; then
    echo "INCAR not found!" >> $ERR; exit
elif [ ! -f KPOINTS ]; then
    echo "KPOINTS not found!" >> $ERR; exit
elif [ ! -f POSCAR_a ]; then
    echo "POSCAR_a not found!" >> $ERR; exit
elif [ ! -f POSCAR_b ]; then
    echo "POSCAR_b not found!" >> $ERR; exit
elif ! ls POTCAR_* 1>/dev/null 2>&1; then
    echo "No POTCAR_xx found!" >> $ERR; exit
fi
mkdir -p $POS ${TMP}_a ${TMP}_b $OUT

# If this is a new calculation
if ! ls $POS/POSCAR_* 1>/dev/null 2>&1; then    # if no POSCARs/POSCAR_* found
    cp $DIR/{INCAR,KPOINTS} ${TMP}_a
    cp $DIR/{INCAR,KPOINTS} ${TMP}_b
    cp $DIR/POSCAR_a ${TMP}_a/POSCAR
    cp $DIR/POSCAR_b ${TMP}_b/POSCAR
    # Crate POTCAR based on POSCAR elements
    nElem_a=`sed -n 6p $DIR/POSCAR_a | wc -w`   # count no. of elements
    nElem_b=`sed -n 6p $DIR/POSCAR_b | wc -w`
    test $DEBUG -eq 1 && echo "Line 73: $nElem_a $nElem_b"
    for i in `seq 1 $nElem_a`; do
        elem=`sed -n 6p $DIR/POSCAR_a | awk -v x="$i" '{print $x}'`
        if [ ! -f $DIR/POTCAR_$elem ]; then
            echo "POTCAR_$elem not found!" >> $ERR
            exit
        fi
        cat $DIR/POTCAR_$elem >> ${TMP}_a/POTCAR
    done
    for i in `seq 1 $nElem_b`; do
        elem=`sed -n 6p $DIR/POSCAR_b | awk -v x="$i" '{print $x}'`
        if [ ! -f $DIR/POTCAR_$elem ]; then
            echo "POTCAR_$elem not found!" >> $ERR
            exit
        fi
        cat $DIR/POTCAR_$elem >> ${TMP}_b/POTCAR
    done
    # Run vasp
    cd ${TMP}_a; $MPI $VASP > vasp.out
    cd ${TMP}_b; $MPI $VASP > vasp.out
    # Collect files and data
    cp ${TMP}_a/CONTCAR $POS/POSCAR_0001_a
    cp ${TMP}_b/CONTCAR $POS/POSCAR_0001_b
    cp ${TMP}_a/vasp.out $OUT/vasp_0001_a
    cp ${TMP}_b/vasp.out $OUT/vasp_0001_b
    etot_a=`grep fr_e ${TMP}_a/vasprun.xml | awk 'END {print $3}'`
    etot_b=`grep fr_e ${TMP}_b/vasprun.xml | awk 'END {print $3}'`
    etot=`echo "($etot_a)+($etot_b)" | bc`
    printf "0001%10.3f%10.3f%10.3f\n" $etot_a $etot_b $etot >> $ETOT
fi

# The main loop
while [ true ]; do  # this loop keeps checking $DIR/stop and exits if found
    # First swap atoms within each POSCAR. We call this intra-swap.
    flag_a=1  # whether swap is accepted, 0=no, 1=yes
    flag_b=1
    count=0 # how many times of intra-swap in this loop?
    # This "while" loop structure allows user to accelerate convergence with
    # more than one intra-swap between inter-swaps, e.g., when the phase
    # prefers ordering. The default is 1, that is, just 1 intra-swap between
    # inter-swaps. To use more, change `test $count -ge 1` to larger numbers,
    # so the code will continue intra-swap until that number as long as the
    # previous intra-swap is accepted.
    while [ true ]; do
        rm -rf ${TMP}_a/* ${TMP}_b/*
        test $flag_a -ne 1 && break
        test $flag_b -ne 1 && break
        test $count -ge 1 && break
        test $DEBUG -eq 1 && echo "Line 115: $flag_a $flag_b $count"
        # Find the latest POSCAR_xxxx_a/b
        cd $POS
        old_file_a=`ls POSCAR_*_a | sort | tail -1`
        old_count=`echo $old_file_a | sed "s/_/\ /g" | awk '{print $2}'`
        old_file_b=POSCAR_${old_count}_b
        # Count the no. of atoms & no. of atoms of each element
        nAtom_a=`awk 'NR==7 {for(i=1;i<=NF;i++) t+=$i; print t; t=0}' $old_file_a`
        nAtom_b=`awk 'NR==7 {for(i=1;i<=NF;i++) t+=$i; print t; t=0}' $old_file_b`
        nElem_a=`sed -n 6p $old_file_a | wc -w`
        nElem_b=`sed -n 6p $old_file_b | wc -w`
        # Assign element type to each atom, save in each TMP dir
        rm -f ${TMP}_a/POStemp ${TMP}_b/POStemp
        ntot=0
        for i in `seq 1 $nElem_a`; do
            nEachElem=`sed -n 7p $old_file_a | awk -v x="$i" '{print $x}'`
            eachElem=`sed -n 6p $old_file_a | awk -v x="$i" '{print $x}'`
            num=$[ntot+1]
            ntot=$[ntot+nEachElem]
            test $DEBUG -eq 1 && echo "Line 134: $nEachElem $eachElem $num $ntot"
            for l in `seq $num $ntot`; do
                sed -n $[l+8]p $old_file_a | awk -v x="$eachElem" '{print $0, x}' >> ${TMP}_a/POStemp
            done
        done
        if [ $ntot -ne $nAtom_a ]; then
            echo "Error when assigning elements for $old_file_a" >> $ERR
            exit
        fi
        ntot=0
        for i in `seq 1 $nElem_b`; do
            nEachElem=`sed -n 7p $old_file_b | awk -v x="$i" '{print $x}'`
            eachElem=`sed -n 6p $old_file_b | awk -v x="$i" '{print $x}'`
            num=$[ntot+1]
            ntot=$[ntot+nEachElem]
            for l in `seq $num $ntot`; do
                sed -n $[l+8]p $old_file_b | awk -v x="$eachElem" '{print $0, x}' >> ${TMP}_b/POStemp
            done
        done
        if [ $ntot -ne $nAtom_b ]; then
            echo "Error when assigning elements for $old_file_b" >> $ERR
            exit
        fi
        # Intra-swap and make sure they are not the same element
        while [ true ]; do
            # generate two rand nums for each POSCAR
            rand_a=`shuf -i 1-$nAtom_a -n 2 | sort -g`
            rand_b=`shuf -i 1-$nAtom_b -n 2 | sort -g`
            rand_a1=`echo $rand_a | awk '{print $1}'`
            rand_a2=`echo $rand_a | awk '{print $2}'`
            rand_b1=`echo $rand_b | awk '{print $1}'`
            rand_b2=`echo $rand_b | awk '{print $2}'`
            # are we swapping two atoms of the same element?
            swap_a1=`awk -v x="$rand_a1" 'NR==x {print $4}' ${TMP}_a/POStemp`
            swap_a2=`awk -v x="$rand_a2" 'NR==x {print $4}' ${TMP}_a/POStemp`
            swap_b1=`awk -v x="$rand_b1" 'NR==x {print $4}' ${TMP}_b/POStemp`
            swap_b2=`awk -v x="$rand_b2" 'NR==x {print $4}' ${TMP}_b/POStemp`
            [ $swap_a1 != $swap_a2 ] && [ $swap_b1 != $swap_b2 ] && break
        done
        # Make the real POSCARs after swaps, also create correct POTCARs
        sed -i "${rand_a1}s/${swap_a1}/${swap_a2}/" ${TMP}_a/POStemp
        sed -i "${rand_a2}s/${swap_a2}/${swap_a1}/" ${TMP}_a/POStemp
        sed -i "${rand_b1}s/${swap_b1}/${swap_b2}/" ${TMP}_b/POStemp
        sed -i "${rand_b2}s/${swap_b2}/${swap_b1}/" ${TMP}_b/POStemp
        sort -k 4 ${TMP}_a/POStemp -o ${TMP}_a/POStemp
        sort -k 4 ${TMP}_b/POStemp -o ${TMP}_b/POStemp
        head -n 5 $old_file_a > ${TMP}_a/POSCAR
        head -n 5 $old_file_b > ${TMP}_b/POSCAR
        for f in a b; do
            # get the element types in the sorted POStemp
            nAtom=`cat ${TMP}_$f/POStemp | wc -l`
            nBands=0
            for i in `seq 1 $nAtom`; do
                elem=`awk -v x="$i" 'NR==x {print $4}' ${TMP}_$f/POStemp`
                last=`awk 'NR==6 {print $NF}' ${TMP}_$f/POSCAR`
                test "$elem" != "$last" && echo -n "$elem  " >> ${TMP}_$f/POSCAR
            done
            echo "" >> ${TMP}_$f/POSCAR
            # count num of atoms of each element, and generate POTCAR
            nElem=`sed -n 6p ${TMP}_$f/POSCAR | wc -w`
            for i in `seq 1 $nElem`; do
                elem=`awk -v x="$i" 'NR==6 {print $x}' ${TMP}_$f/POSCAR`
                num=`grep $elem ${TMP}_$f/POStemp | wc -l`
                echo -n "$num  " >> ${TMP}_$f/POSCAR
                cat $DIR/POTCAR_$elem >> ${TMP}_$f/POTCAR
                nElec=`awk 'NR==2 {print $1}' $DIR/POTCAR_$elem`
                nBands=`echo "scale=3;$nBands+$nElec*$num/2+2*$num" | bc`
            done
            nBands=`printf "%.0f" $nBands`
            cp $DIR/INCAR ${TMP}_$f
            echo "NBANDS = $nBands" >> ${TMP}_$f/INCAR
            echo "" >> ${TMP}_$f/POSCAR
            sed -n 8p POSCAR_${old_count}_$f >> ${TMP}_$f/POSCAR
            awk '{print $1, $2, $3}' ${TMP}_$f/POStemp >> ${TMP}_$f/POSCAR
        done
        # Run vasp
        cp $DIR/KPOINTS ${TMP}_a
        cp $DIR/KPOINTS ${TMP}_b
        cd ${TMP}_a; $MPI $VASP > vasp.out
        cd ${TMP}_b; $MPI $VASP > vasp.out
        # Calculate probabilities
        old_etot_a=`sed "/####/d" $ETOT | awk 'END {print $2}'`
        old_etot_b=`sed "/####/d" $ETOT | awk 'END {print $3}'`
        old_etot=`echo "($old_etot_a)+($old_etot_b)" | bc`
        new_etot_a=`grep fr_e ${TMP}_a/vasprun.xml | awk 'END {print $3}'`
        new_etot_b=`grep fr_e ${TMP}_b/vasprun.xml | awk 'END {print $3}'`
        new_etot=`echo "($new_etot_a)+($new_etot_b)" | bc`
        if [ `echo "($new_etot_a)<=($old_etot_a)" | bc` -eq 1 ]; then
            flag_a=1
            p_a=1
        else
            p_a=`echo "scale=6;e((($old_etot_a)-($new_etot_a))*11654.35/$T)" | bc -l`
            rand=`echo "scale=6;$RANDOM/32768" | bc`
            flag_a=0
            test `echo "($p_a)>($rand)" | bc` -eq 1 && flag_a=1
        fi
        if [ `echo "($new_etot_b)<=($old_etot_b)" | bc` -eq 1 ]; then
            flag_b=1
            p_b=1
        else
            p_b=`echo "scale=6;e((($old_etot_b)-($new_etot_b))*11654.35/$T)" | bc -l`
            rand=`echo "scale=6;$RANDOM/32768" | bc`
            flag_b=0
            test `echo "($p_b)>($rand)" | bc` -eq 1 && flag_b=1
        fi
        # Save files and data depending on acceptence
        new_count=`echo "$old_count+1" | bc`
        new_count=`printf "%0*d" 4 $new_count`
        if [ $flag_a -eq 0 ] && [ $flag_b -eq 0 ]; then
            printf "####%10.3f%10.3f%10.3f%7.2f%7.2f\n" \
                $new_etot_a $new_etot_b $new_etot $p_a $p_b >> $ETOT
        elif [ $flag_a -eq 1 ] && [ $flag_b -eq 0 ]; then
            cp ${TMP}_a/CONTCAR $POS/POSCAR_${new_count}_a
            cp $POS/$old_file_b $POS/POSCAR_${new_count}_b
            cp ${TMP}_a/vasp.out $OUT/vasp_${new_count}_a
            printf "${new_count}%10.3f%10.3f%10.3f%7.2f%7.2f\n" $new_etot_a \
                $old_etot_b `echo "$new_etot_a+$old_etot_b"|bc` $p_a $p_b >> $ETOT
        elif [ $flag_a -eq 0 ] && [ $flag_b -eq 1 ]; then
            cp $POS/$old_file_a $POS/POSCAR_${new_count}_a
            cp ${TMP}_b/CONTCAR $POS/POSCAR_${new_count}_b
            cp ${TMP}_b/vasp.out $OUT/vasp_${new_count}_b
            printf "${new_count}%10.3f%10.3f%10.3f%7.2f%7.2f\n" $old_etot_a \
                $new_etot_b `echo "$old_etot_a+$new_etot_b"|bc` $p_a $p_b >> $ETOT
        elif [ $flag_a -eq 1 ] && [ $flag_b -eq 1 ]; then
            count=$[count+1]
            cp ${TMP}_a/CONTCAR $POS/POSCAR_${new_count}_a
            cp ${TMP}_b/CONTCAR $POS/POSCAR_${new_count}_b
            cp ${TMP}_a/vasp.out $OUT/vasp_${new_count}_a
            cp ${TMP}_b/vasp.out $OUT/vasp_${new_count}_b
            printf "${new_count}%10.3f%10.3f%10.3f%7.2f%7.2f\n" $new_etot_a \
                $new_etot_b $new_etot $p_a $p_b >> $ETOT
        fi
        if [ -f $DIR/stop ]; then
            rm -f $DIR/stop; exit
        fi
        rm -rf ${TMP}_a/* ${TMP}_b/*
    done
    #### Now we swap atoms between two POSCARs
    rm -rf ${TMP}_a/* ${TMP}_b/*
    # Find the latest POSCAR_xxxx_a/b
    cd $POS
    old_file_a=`ls POSCAR_*_a | sort | tail -1`
    old_count=`echo $old_file_a | sed "s/_/\ /g" | awk '{print $2}'`
    old_file_b=POSCAR_${old_count}_b
    # Count the no. of atoms & no. of atoms of each element
    nAtom_a=`awk 'NR==7 {for(i=1;i<=NF;i++) t+=$i; print t; t=0}' $old_file_a`
    nAtom_b=`awk 'NR==7 {for(i=1;i<=NF;i++) t+=$i; print t; t=0}' $old_file_b`
    nElem_a=`sed -n 6p $old_file_a | wc -w`
    nElem_b=`sed -n 6p $old_file_b | wc -w`
    # Assign element type to each atom, save in each TMP dir
    rm -f ${TMP}_a/POStemp ${TMP}_b/POStemp
    ntot=0
    for i in `seq 1 $nElem_a`; do
        nEachElem=`sed -n 7p $old_file_a | awk -v x="$i" '{print $x}'`
        eachElem=`sed -n 6p $old_file_a | awk -v x="$i" '{print $x}'`
        num=$[ntot+1]
        ntot=$[ntot+nEachElem]
        for l in `seq $num $ntot`; do
            sed -n $[l+8]p $old_file_a | awk -v x="$eachElem" '{print $0, x}' >> ${TMP}_a/POStemp
        done
    done
    if [ $ntot -ne $nAtom_a ]; then
        echo "Error when assigning elements for $old_file_a" >> $ERR
        exit
    fi
    ntot=0
    for i in `seq 1 $nElem_b`; do
        nEachElem=`sed -n 7p $old_file_b | awk -v x="$i" '{print $x}'`
        eachElem=`sed -n 6p $old_file_b | awk -v x="$i" '{print $x}'`
        num=$[ntot+1]
        ntot=$[ntot+nEachElem]
        for l in `seq $num $ntot`; do
            sed -n $[l+8]p $old_file_b | awk -v x="$eachElem" '{print $0, x}' >> ${TMP}_b/POStemp
        done
    done
    if [ $ntot -ne $nAtom_b ]; then
        echo "Error when assigning elements for $old_file_b" >> $ERR
        exit
    fi
    # swap two random atom between two POSCARs
    while [ true ]; do
        rand_a=`shuf -i 1-$nAtom_a -n 1`
        rand_b=`shuf -i 1-$nAtom_b -n 1`
        swap_a=`awk -v x="$rand_a" 'NR==x {print $4}' ${TMP}_a/POStemp`
        swap_b=`awk -v x="$rand_b" 'NR==x {print $4}' ${TMP}_b/POStemp`
        [ $swap_a != $swap_b ] && break
    done
    sed -i "${rand_a}s/${swap_a}/${swap_b}/" ${TMP}_a/POStemp
    sed -i "${rand_b}s/${swap_b}/${swap_a}/" ${TMP}_b/POStemp
    # Sort by element and generate new POSCARs
    sort -k 4 ${TMP}_a/POStemp -o ${TMP}_a/POStemp
    sort -k 4 ${TMP}_b/POStemp -o ${TMP}_b/POStemp
    head -n 5 $old_file_a > ${TMP}_a/POSCAR
    head -n 5 $old_file_b > ${TMP}_b/POSCAR
    for f in a b; do
        # get the element types in the sorted POStemp
        nAtom=`cat ${TMP}_$f/POStemp | wc -l`
        nBands=0
        for i in `seq 1 $nAtom`; do
            elem=`awk -v x="$i" 'NR==x {print $4}' ${TMP}_$f/POStemp`
            last=`awk 'NR==6 {print $NF}' ${TMP}_$f/POSCAR`
            test "$elem" != "$last" && echo -n "$elem  " >> ${TMP}_$f/POSCAR
        done
        echo "" >> ${TMP}_$f/POSCAR
        # count num of atoms of each element, and generate POTCAR
        nElem=`sed -n 6p ${TMP}_$f/POSCAR | wc -w`
        for i in `seq 1 $nElem`; do
            elem=`awk -v x="$i" 'NR==6 {print $x}' ${TMP}_$f/POSCAR`
            num=`grep $elem ${TMP}_$f/POStemp | wc -l`
            echo -n "$num  " >> ${TMP}_$f/POSCAR
            cat $DIR/POTCAR_$elem >> ${TMP}_$f/POTCAR
            nElec=`awk 'NR==2 {print $1}' $DIR/POTCAR_$elem`
            nBands=`echo "scale=3;$nBands+$nElec*$num/2+2*$num" | bc`
        done
        nBands=`printf "%.0f" $nBands`
        cp $DIR/INCAR ${TMP}_$f
        echo "NBANDS = $nBands" >> ${TMP}_$f/INCAR
        echo "" >> ${TMP}_$f/POSCAR
        sed -n 8p POSCAR_${old_count}_$f >> ${TMP}_$f/POSCAR
        awk '{print $1, $2, $3}' ${TMP}_$f/POStemp >> ${TMP}_$f/POSCAR
    done
    # Run vasp
    cp $DIR/KPOINTS ${TMP}_a
    cp $DIR/KPOINTS ${TMP}_b
    cd ${TMP}_a; $MPI $VASP > vasp.out
    cd ${TMP}_b; $MPI $VASP > vasp.out
    # Calculate probabilities
    old_etot_a=`sed "/####/d" $ETOT | awk 'END {print $2}'`
    old_etot_b=`sed "/####/d" $ETOT | awk 'END {print $3}'`
    old_etot=`echo "($old_etot_a)+($old_etot_b)" | bc`
    new_etot_a=`grep fr_e ${TMP}_a/vasprun.xml | awk 'END {print $3}'`
    new_etot_b=`grep fr_e ${TMP}_b/vasprun.xml | awk 'END {print $3}'`
    new_etot=`echo "($new_etot_a)+($new_etot_b)" | bc`
    if [ `echo "($new_etot)<=($old_etot)" | bc` -eq 1 ]; then
        flag=1      # whether to accept this swap, 1=yes, 0=no
        p=1
    else
        p=`echo "scale=6;e((($old_etot)-($new_etot))*11654.35/$T)" | bc -l`
        rand=`echo "scale=6;$RANDOM/32768" | bc`
        flag=0
        test `echo "($p)>($rand)" | bc` -eq 1 && flag=1
    fi
    # Save files and data depending on acceptence
    new_count=`echo "$old_count+1" | bc`
    new_count=`printf "%0*d" 4 $new_count`
    if [ $flag -eq 0 ]; then
        printf "####%10.3f%10.3f%10.3f%7.2f\n" \
            $new_etot_a $new_etot_b $new_etot $p >> $ETOT
    else
        cp ${TMP}_a/CONTCAR $POS/POSCAR_${new_count}_a
        cp ${TMP}_b/CONTCAR $POS/POSCAR_${new_count}_b
        cp ${TMP}_a/vasp.out $OUT/vasp_${new_count}_a
        cp ${TMP}_b/vasp.out $OUT/vasp_${new_count}_b
        printf "${new_count}%10.3f%10.3f%10.3f%7.2f\n" \
            $new_etot_a $new_etot_b $new_etot $p >> $ETOT
    fi
    if [ -f $DIR/stop ]; then
        rm -f $DIR/stop; exit
    fi
    rm -rf ${TMP}_a/* ${TMP}_b/*
done
