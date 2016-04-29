// mc-gen.cc
//
// Created by Changning Niu on 3/22/2016.

#include "poscar.h"




int main () {
    // Find if this is a new job or restart
    int latest = find_latest_poscar();
    string file1 = "POSCARs/POSCAR-" + format(latest);
    string file2 = "POSCARs/POSCAR-" + format(latest+1);
    Poscar pos1, pos2;

    // If it's a new job, just swap
    if ( latest == 0 ) {
        swap(pos1, pos2);
        write_poscar (pos1, file1);
        write_poscar (pos2, file2);
        return 0;
    }
    
    // If it's a restart
