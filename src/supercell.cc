// supercell.cc
//
// Expand POSCAR to larger supercell
//      supercell POSCAR 2 2 3
//
// Created by Changning Niu on 3/18/2016.

#include "poscar.h"

using namespace std;

void supercell (Poscar *p1, Poscar *p2, int a, int b, int c) {
    int size = a * b * c;
    for (int i = 0; i < 3; i++) { // expand lattice
        p2->ddLat[0][i] = p1->ddLat[0][i] * a;
        p2->ddLat[1][i] = p1->ddLat[1][i] * b;
        p2->ddLat[2][i] = p1->ddLat[2][i] * c;
    }
    for (int i = 0; i < p1->nElem; i++) // expand # per element
        p2->nnElem[i] = p1->nnElem[i] * size;
    p2->nAtom = p1->nAtom * size;       // total number of atoms
    // Now expand atomic positions
    int num1 = 0;   // to count which atom in p1
    int num2 = 0;   // to count total atom in p2
    for (int i = 0; i < p1->nElem; i++) {
        for (int j = 0; j < p1->nnElem[i]; j++) {
            for (int k = 0; k < a; k++) {
                for (int m = 0; m < b; m++) {
                    for (int n = 0; n < c; n++) {
                        p2->ddAtom[num2][0] = (p1->ddAtom[num1][0] + k) / a;
                        p2->ddAtom[num2][1] = (p1->ddAtom[num1][1] + m) / b;
                        p2->ddAtom[num2][2] = (p1->ddAtom[num1][2] + n) / c;
                        num2++;
                    }
                }
            }
            num1++;
        }
    }
    if (num2 != p2->nAtom || num1 != p1->nAtom )
        cout << "Error when generating the supercell!\n";
}

int main (int argc, char *argv[]) {
    struct Poscar p1, p2;
    // Check input
    if (argc != 5) {
        cout << "Usage: supercell POSCAR 2 2 3\n";
        return 1;
    }
    // Read the file
    if (! read_poscar(argv[1], &p1)) {
        cout << "Failed reading file.\n";
        return 1;
    }
    p2 = p1;
    // Read supercell size
    int x[3];
    istringstream iss;
    for (int i = 0; i < 3; i++) { // read size
        iss.clear();
        iss.str(argv[i+2]);
        if (!(iss >> x[i])) { 
            cout << "Error reading supercell size input.\n";
            return 1;
        }
    }
    // Expand easy ones: lattice vectors etc.
    supercell(&p1, &p2, x[0], x[1], x[2]);
    // Output
    string str(argv[1], 0, 30); // get POSCAR name
    str.append("_");
    str.append(argv[2]);
    str.append("-");
    str.append(argv[3]);
    str.append("-");
    str.append(argv[4]);
    char *filename = &str[0];
    write_poscar(filename, &p2);
    return 0;
}
