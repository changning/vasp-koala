// dir2car.cc
//
// Converts POSCAR in direct format to cartesian format
//
// Created by Changning Niu on 3/18/2016.

#include "poscar.h"
#include "matrix.h"
#include <iterator> // to use begin(), end()

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
    if (p1.cForm == 'C') {
        cout << "POSCAR is already in Cartesian format.\n";
        return 1;
    }
    // Convert direct to cartesian for atomic positions
    p2 = p1;
    matrix_product(p1.nAtom, p1.ddAtom, p1.ddLat, p2.ddAtom);
    // Output
    string str(argv[1], 0, 30);
    str.append("_Cart");
    char *filename = &str[0];
    write_poscar(filename, &p2);
    return 0;
}
