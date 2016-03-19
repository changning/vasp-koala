// poscar.cc
// Functions to read POSCAR
// Created by Changning Niu on 3/18/2016.

#include "poscar.h"

// Read POSCAR from VASP 5.x (elements in lin 6)
//
// 1. if line 6 doesn't contain element types, use fake values (A, B, ...)
// 2. if defined seletive dynamics, cSel = 'S', else, cSel = 'n'
// 3. if defined direct coordinates, cForm = 'D'
// 4. if defined cartesian coord., cForm = 'C'
bool read_poscar (char *file, Poscar *p) {
    ifstream infile;        // to read file
    istringstream iss;      // to read strings
    string line;            // string container
    double x, y, z;         // to read double
    char a, b, c;           // to read selective dynamics T/F
    int num;                // to read integers

    // Open the file
    infile.open(file);
    if (!infile) return false;
    getline(infile, p->head);   // line 1
    getline(infile, line);      // line 2
    iss.str(line);
    if (iss >> p->dPara) iss.clear();
    else return false;
    for (int i = 0; i < 3; i++) {   // line 3-5
        getline(infile, line);
        iss.str(line);
        if (iss >> x >> y >> z) {
            iss.clear();
            p->ddLat[i][0] = x;
            p->ddLat[i][1] = y;
            p->ddLat[i][2] = z;
        }
        else return false;
    }
    getline(infile, line);      // line 6
    iss.str(line);
    p->nAtom = 0;
    p->nElem = 0;
    if (iss >> num) {   // if line 6 starts w/ a number
        p->nAtom += num;
        while (iss >> num) {
            p->nElem++;
            p->nAtom += num;
        }
        string ssFake[10] = {"A","B","C","D","E","F","G","H","I","J"};
        for (int i = 0; i < p->nElem; i++)  // assign fake elements
            p->ssElem[i] = ssFake[i];
        cout << "Line 6 of POSCAR skips element types. I used fake ones.\n";
    }
    else {              // if line 6 starts w/ element types
        iss.clear();
        iss.str(line);
        num = 0;
        while (iss >> p->ssElem[num]) {
            num++;
            p->nElem++;
        }
        if (p->nElem == 0) return false;    // if # elem is 0, return error
        getline(infile, line);
        iss.clear();
        iss.str(line);
        for (int i = 0; i < p->nElem; i++) {// line 7: # per element
            if (iss >> num) {
                p->nnElem[i] = num;
                p->nAtom += num;
            }
            else return false;
        }
    }
    getline(infile, line);      // line 8: selective?
    if (line[0] == 'S' || line[0] == 's') {
        p->cSel = 'S';
        getline(infile, line);
        if (line[0] == 'D' || line[0] == 'd')
            p->cForm = 'D';
        else if (line[0] == 'C' || line[0] == 'c')
            p->cForm = 'C';
        else return false;
    }
    else if (line[0] == 'D' || line[0] == 'd') {
        p->cSel = 'n';
        p->cForm = 'D';
    }
    else if (line[0] == 'C' || line[0] == 'c') {
        p->cSel = 'n';
        p->cForm = 'C';
    }
    else return false;
    for (int i = 0; i < p->nAtom; i++) {    // atomic coordinates
        iss.clear();
        getline(infile, line);
        iss.str(line);
        if (iss >> x >> y >> z) {
            p->ddAtom[i][0] = x;
            p->ddAtom[i][1] = y;
            p->ddAtom[i][2] = z;
        }
        else return false;
        if (p->cSel == 'S') {
            if (iss >> a >> b >> c) {
                p->ccAtom[i][0] = a;
                p->ccAtom[i][1] = b;
                p->ccAtom[i][2] = c;
            }
            else return false;
        }
    }
    return true;
}

bool write_poscar (char *file, Poscar *p) {
    // Check if output file already exists
    ifstream infile(file);
    if (infile.good()) {
        cout << file << " already exists!\n";
        return false;
    }
    else infile.close();
    // Write POSCAR
    ofstream outfile;
    outfile.open(file);
    outfile << p->head << "\n";     // line 1: head
    outfile << setprecision(9) << p->dPara << "\n"; // line 2: lattice parameter
    for (int i = 0; i < 3; i++) {   // line 3-5: lattice vectors
        for (int j = 0; j < 3; j++)
            outfile << setw(15) << fixed << setprecision(9) << p->ddLat[i][j];
        outfile << "\n";
    }
    for (int i = 0; i < p->nElem; i++)  // line 6: element types
        outfile << setw(5) << p->ssElem[i];
    outfile << "\n";
    for (int i = 0; i < p->nElem; i++)  // line 7: # per element
        outfile << setw(5) << p->nnElem[i];
    outfile << "\n";
    if (p->cSel == 'S') {       // if selective dynamics enabled
        outfile << "Selective\n";
        outfile << p->cForm << "\n";    // cart or direc
        for (int i = 0; i < p->nAtom; i++) {    // atomic positions
            for (int j = 0; j < 3; j++)
                outfile << setw(15) << fixed << setprecision(9) << p->ddAtom[i][j];
            for (int j = 0; j < 3; j++)
                outfile << setw(3) << p->ccAtom[i][j];
            outfile << "\n";
        }
    }
    else {      // if no selective
        outfile << p->cForm << "\n";    // cart or direc
        for (int i = 0; i < p->nAtom; i++) {
            for (int j = 0; j < 3; j++)
                outfile << setw(15) << fixed << setprecision(9) << p->ddAtom[i][j];
            outfile << "\n";
        }
    }
    outfile.close();
    return true;
}
