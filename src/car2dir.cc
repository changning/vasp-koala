// dir2car.cc
//
// Converts POSCAR in direct format to cartesian format
//
// Created by Changning Niu on 3/18/2016.

#include "poscar.h"
#include "matrix.h"

using namespace std;

int main (int argc, char *argv[]) {
    struct Poscar p1, p2; // p1: original;  p2: output

    // Check input
    if (argc != 2) {
        cout << "Usage: dir2car POSCAR\n";
        return 1;
    }
    // Read the file
    if (! read_poscar(argv[1], &p1)) {
        cout << "Failed reading file.\n";
        return 1;
    }
    // See if it's already cartesian
    if (p1.cForm == 'D') {
        cout << "POSCAR is already in Direct format.\n";
        return 1;
    }
    // Convert direct to cartesian for atomic positions
    p2 = p1;
    matrix_inverse(p2.ddLat, p1.ddLat);
    matrix_product(p1.nAtom, p1.ddAtom, p1.ddLat, p2.ddAtom);
    p2.cForm = 'D';
    // Output
    string str(argv[1], 0, 30);
    str.append("_Dir");
    char *filename = &str[0];
    write_poscar(filename, &p2);
    return 0;
}
