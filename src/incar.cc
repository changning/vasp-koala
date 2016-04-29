// outcar.cc
//
// Created by Changning Niu on 3/20/2016.

#include "outcar.h"
#include "mystring.h"

// read_incar_line: 
// It assumes this is a line with only one '='
bool read_incar_line (string str, Incar *incar) {
    string lstr, rstr;              // left/right part
    string r1str;                   // 1st item of right
    istringstream iss;
    if (str.find("=") == string::npos) {
        cout << "No = in this line: " << str << "\n";
        return false;               // report error if no =
    }
    iss.str(trim(str));             // trim and read line
    getline(iss, lstr, '=')         // get left part
    lstr = trim(lstr);              // trim left part
    getline(iss, rstr, '=');        // get right part
    rstr = trim(rstr);              // trim right part
    iss.clear();
    iss.str(rstr);                  // iss right part
    switch (lstr) {
        case "SYSTEM":              // if it's SYSTEM
            incar->system = rstr;   // read entire right
            break;
        case "ISTART":
            if (! iss >> incar->istart) {
                cout << "Error reading ISTART.\n";
                return false;
            }
            break;
        case "ICHARG":
            if (! iss >> incar->icharg) {
                cout << "Error reading ICHARG.\n";
                return false;
            }
            break;
        case "NELM":
            if (! iss >> incar->nelm) {
                cout << "Error reading NELM.\n";
                return false;
            }
            break;
        case "EDIFF":
            if (! iss >> incar->ediff) {
                cout << "Error reading EDIFF.\n";
                return false;
            }
            break;
        case "IBRION":
            if (! iss >> incar->ibrion) {
                cout << "Error reading IBRION.\n";
                return false;
            }
            break;
        case "NSW":
            if (! iss >> incar->nsw) {
                cout << "Error reading NSW.\n";
                return false;
            }
            break;
        case "EDIFFG":
            if (! iss >> incar->ediffg) {
                cout << "Error reading EDIFFG.\n";
                return false;
            }
            break;
        case "ISIF":
            if (! iss >> incar->isif) {
                cout << "Error reading ISIF.\n";
                return false;
            }
            break;
        case "ENCUT":
            if (! iss >> incar->encut) {
                cout << "Error reading encut.\n";
                return false;
            }
            break;
        case "ISMEAR":
            if (! iss >> incar->ismear) {
                cout << "Error reading ISMEAR.\n";
                return false;
            }
            break;
        case "SIGMA":
            if (! iss >> incar->sigma) {
                cout << "Error reading SIGMA.\n";
                return false;
            }
            break;
        case "ISYM":
            if (! iss >> incar->isym) {
                cout << "Error reading ISYM.\n";
                return false;
            }
            break;
    }

bool read_incar (char *file, Incar *incar) {
    ifstream infile;                // to read file
    istringstream iss;              // to read strings
    string line;                    // string holder
    string part1, part2;            // part of a string
    // Open file
    infile.open(file);
    if (!infile) {                  // if file not exist
        cout << "Cannot find " << file << ".\n";
        return false;
    }
    // Delete all lines w/o '='; split a line w/ ';'

    // Read all flags in INCAR
    while (getline(infile, line)) {     // read all lines
        if (line.find("=") == string::npos)
            continue;                   // skip lines w/o '='
        if (line.find(";") == string::npos) {

        iss.clear();                    // clear iss flags
        trim(line);                     // trim spaces
        iss.str(line);                  // put line to iss
        if (getline(iss, part, '=')) {  // left part of =
            trim(part);                 // trim spaces
            switch (part) {
                case "SYSTEM":
                    incar->system
