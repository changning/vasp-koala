#ifndef KOALA_POSCAR_H
#define KOALA_POSCAR_H
// poscar.h
// Created by Changning Niu on 3/18/2016.

#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>

using namespace std;

// Structure for POSCAR
struct Poscar {
    string  head;           // head line
    double  dPara;          // lattice parameter
    double  ddLat[3][3];    // lattice vectors
    int     nElem;          // # of elements
    string  ssElem[20];     // name of elements
    int     nnElem[20];     // # of atoms of each element
    int     nAtom;          // # of all atoms
    char    cForm;          // directional or cartesian
    char    cSel;           // selective relaxation
    double  ddAtom[9999][3]; // atomic positions
    char    ccAtom[9999][3]; // selective dynamics
};

bool read_poscar(char *file, Poscar *p);

bool write_poscar(char *file, Poscar *p);


#endif // KOALA_POSCAR_H
